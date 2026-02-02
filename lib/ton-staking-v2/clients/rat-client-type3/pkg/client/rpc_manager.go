package client

import (
	"context"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/ethereum/go-ethereum/rpc"
)

// RPCStatus represents the health status of an RPC endpoint
type RPCStatus struct {
	URL            string
	IsHealthy      bool
	LastCheckTime  time.Time
	LastError      error
	FailureCount   int
	SuccessCount   int
	LatencyMs      int64
}

// RPCManager manages multiple RPC endpoints with failover support
type RPCManager struct {
	urls          []string
	statuses      map[string]*RPCStatus
	statusMutex   sync.RWMutex

	// Config
	healthCheckInterval time.Duration
	healthCheckTimeout  time.Duration
	maxFailures         int

	// Background health check
	ctx    context.Context
	cancel context.CancelFunc
	wg     sync.WaitGroup
}

// NewRPCManager creates a new RPC manager with failover support
func NewRPCManager(urls []string) *RPCManager {
	ctx, cancel := context.WithCancel(context.Background())

	manager := &RPCManager{
		urls:                urls,
		statuses:            make(map[string]*RPCStatus),
		healthCheckInterval: 30 * time.Second,
		healthCheckTimeout:  5 * time.Second,
		maxFailures:         3,
		ctx:                 ctx,
		cancel:              cancel,
	}

	// Initialize statuses
	for _, url := range urls {
		manager.statuses[url] = &RPCStatus{
			URL:       url,
			IsHealthy: true, // Assume healthy initially
		}
	}

	// Start background health checks
	manager.wg.Add(1)
	go manager.backgroundHealthCheck()

	return manager
}

// GetHealthyRPC returns a healthy RPC URL with failover
func (m *RPCManager) GetHealthyRPC() (string, error) {
	m.statusMutex.RLock()
	defer m.statusMutex.RUnlock()

	// Try healthy RPCs first
	for _, url := range m.urls {
		status := m.statuses[url]
		if status.IsHealthy {
			return url, nil
		}
	}

	// No healthy RPC found, try the first one anyway
	if len(m.urls) > 0 {
		log.Printf("⚠️  No healthy RPC found, using first RPC: %s", m.urls[0])
		return m.urls[0], nil
	}

	return "", fmt.Errorf("no RPC URLs configured")
}

// GetAllHealthyRPCs returns all healthy RPC URLs
func (m *RPCManager) GetAllHealthyRPCs() []string {
	m.statusMutex.RLock()
	defer m.statusMutex.RUnlock()

	var healthyRPCs []string
	for _, url := range m.urls {
		if m.statuses[url].IsHealthy {
			healthyRPCs = append(healthyRPCs, url)
		}
	}

	return healthyRPCs
}

// TryWithFailover tries to execute a function with RPC failover
// It will try each healthy RPC in order until one succeeds
func (m *RPCManager) TryWithFailover(fn func(rpcURL string) error) error {
	healthyRPCs := m.GetAllHealthyRPCs()

	// If no healthy RPCs, try all RPCs
	if len(healthyRPCs) == 0 {
		healthyRPCs = m.urls
	}

	var lastErr error
	for i, url := range healthyRPCs {
		log.Printf("Trying RPC [%d/%d]: %s", i+1, len(healthyRPCs), url)

		err := fn(url)
		if err == nil {
			// Success!
			m.recordSuccess(url)
			return nil
		}

		// Failed, record and try next
		log.Printf("⚠️  RPC failed: %s - %v", url, err)
		m.recordFailure(url, err)
		lastErr = err
	}

	// All RPCs failed
	return fmt.Errorf("all RPCs failed, last error: %w", lastErr)
}

// CheckHealth performs a health check on a specific RPC
func (m *RPCManager) CheckHealth(url string) error {
	ctx, cancel := context.WithTimeout(m.ctx, m.healthCheckTimeout)
	defer cancel()

	startTime := time.Now()

	// Try to connect and get chain ID
	client, err := rpc.DialContext(ctx, url)
	if err != nil {
		return fmt.Errorf("failed to dial: %w", err)
	}
	defer client.Close()

	// Try to call eth_chainId
	var chainID string
	err = client.CallContext(ctx, &chainID, "eth_chainId")
	if err != nil {
		return fmt.Errorf("failed to get chain ID: %w", err)
	}

	latency := time.Since(startTime).Milliseconds()

	// Update status
	m.statusMutex.Lock()
	if status, ok := m.statuses[url]; ok {
		status.LatencyMs = latency
		status.LastCheckTime = time.Now()
	}
	m.statusMutex.Unlock()

	return nil
}

// recordSuccess records a successful RPC call
func (m *RPCManager) recordSuccess(url string) {
	m.statusMutex.Lock()
	defer m.statusMutex.Unlock()

	if status, ok := m.statuses[url]; ok {
		status.SuccessCount++
		status.FailureCount = 0 // Reset failure count on success
		status.IsHealthy = true
		status.LastError = nil
	}
}

// recordFailure records a failed RPC call
func (m *RPCManager) recordFailure(url string, err error) {
	m.statusMutex.Lock()
	defer m.statusMutex.Unlock()

	if status, ok := m.statuses[url]; ok {
		status.FailureCount++
		status.LastError = err
		status.LastCheckTime = time.Now()

		// Mark as unhealthy if too many failures
		if status.FailureCount >= m.maxFailures {
			status.IsHealthy = false
			log.Printf("❌ RPC marked as unhealthy: %s (failures: %d)", url, status.FailureCount)
		}
	}
}

// backgroundHealthCheck runs periodic health checks on all RPCs
func (m *RPCManager) backgroundHealthCheck() {
	defer m.wg.Done()

	ticker := time.NewTicker(m.healthCheckInterval)
	defer ticker.Stop()

	for {
		select {
		case <-m.ctx.Done():
			return
		case <-ticker.C:
			m.performHealthChecks()
		}
	}
}

// performHealthChecks checks health of all RPCs
func (m *RPCManager) performHealthChecks() {
	for _, url := range m.urls {
		err := m.CheckHealth(url)

		if err == nil {
			// Health check passed
			m.statusMutex.Lock()
			if status, ok := m.statuses[url]; ok {
				// If was unhealthy, mark as healthy again
				if !status.IsHealthy {
					log.Printf("✅ RPC recovered: %s", url)
				}
				status.IsHealthy = true
				status.FailureCount = 0
				status.LastError = nil
			}
			m.statusMutex.Unlock()
		} else {
			// Health check failed
			m.recordFailure(url, err)
		}
	}
}

// GetStatus returns the status of a specific RPC
func (m *RPCManager) GetStatus(url string) *RPCStatus {
	m.statusMutex.RLock()
	defer m.statusMutex.RUnlock()

	if status, ok := m.statuses[url]; ok {
		// Return a copy to avoid race conditions
		return &RPCStatus{
			URL:           status.URL,
			IsHealthy:     status.IsHealthy,
			LastCheckTime: status.LastCheckTime,
			LastError:     status.LastError,
			FailureCount:  status.FailureCount,
			SuccessCount:  status.SuccessCount,
			LatencyMs:     status.LatencyMs,
		}
	}

	return nil
}

// GetAllStatuses returns the status of all RPCs
func (m *RPCManager) GetAllStatuses() []*RPCStatus {
	m.statusMutex.RLock()
	defer m.statusMutex.RUnlock()

	var statuses []*RPCStatus
	for _, url := range m.urls {
		if status, ok := m.statuses[url]; ok {
			statuses = append(statuses, &RPCStatus{
				URL:           status.URL,
				IsHealthy:     status.IsHealthy,
				LastCheckTime: status.LastCheckTime,
				LastError:     status.LastError,
				FailureCount:  status.FailureCount,
				SuccessCount:  status.SuccessCount,
				LatencyMs:     status.LatencyMs,
			})
		}
	}

	return statuses
}

// PrintStatus prints the status of all RPCs
func (m *RPCManager) PrintStatus() {
	statuses := m.GetAllStatuses()

	log.Printf("========================================")
	log.Printf("RPC Status Report")
	log.Printf("========================================")

	for i, status := range statuses {
		healthSymbol := "✅"
		if !status.IsHealthy {
			healthSymbol = "❌"
		}

		log.Printf("[%d] %s %s", i+1, healthSymbol, status.URL)
		log.Printf("    Healthy: %v", status.IsHealthy)
		log.Printf("    Success: %d, Failures: %d", status.SuccessCount, status.FailureCount)
		log.Printf("    Latency: %dms", status.LatencyMs)
		log.Printf("    Last Check: %s", status.LastCheckTime.Format(time.RFC3339))
		if status.LastError != nil {
			log.Printf("    Last Error: %v", status.LastError)
		}
		log.Printf("----------------------------------------")
	}
}

// Stop stops the RPC manager
func (m *RPCManager) Stop() {
	m.cancel()
	m.wg.Wait()
}

// DialEthClient dials an eth client with failover
func (m *RPCManager) DialEthClient(ctx context.Context) (*ethclient.Client, error) {
	var client *ethclient.Client
	var rpcURL string

	err := m.TryWithFailover(func(url string) error {
		var err error
		client, err = ethclient.DialContext(ctx, url)
		if err != nil {
			return err
		}
		rpcURL = url
		return nil
	})

	if err != nil {
		return nil, err
	}

	log.Printf("✅ Connected to RPC: %s", rpcURL)
	return client, nil
}
