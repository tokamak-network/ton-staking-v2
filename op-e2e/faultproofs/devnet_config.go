package faultproofs

import (
	"encoding/json"
	"os"
	"path/filepath"

	"github.com/ethereum/go-ethereum/common"
)

// DevnetConfig represents the .devnet/addresses.json configuration
type DevnetConfig struct {
	ChainID          int64           `json:"chainId"`
	RPCURL           string          `json:"rpcUrl"`
	RAT              common.Address  `json:"rat"`
	RATImpl          common.Address  `json:"ratImpl"`
	ProxyAdmin       common.Address  `json:"proxyAdmin"`
	TON              common.Address  `json:"ton"`
	WTON             common.Address  `json:"wton"`
	SeigManager      common.Address  `json:"seigManager"`
	Layer2Manager    common.Address  `json:"layer2Manager"`
	L1BridgeRegistry common.Address  `json:"l1BridgeRegistry"`
	SystemConfig     common.Address  `json:"systemConfig"`
	Accounts         AccountsConfig  `json:"accounts"`
	PrivateKeys      PrivateKeysConfig `json:"privateKeys"`
}

type AccountsConfig struct {
	Deployer  common.Address `json:"deployer"`
	Validator common.Address `json:"validator"`
}

type PrivateKeysConfig struct {
	Deployer  string `json:"deployer"`
	Validator string `json:"validator"`
}

// LoadDevnetConfig loads configuration from .devnet/addresses.json
func LoadDevnetConfig() (*DevnetConfig, error) {
	// Try multiple possible paths
	paths := []string{
		"../.devnet/addresses.json",           // from op-e2e directory
		"../../.devnet/addresses.json",        // from op-e2e/faultproofs
		".devnet/addresses.json",              // from project root
	}

	// Also check DEVNET_CONFIG_PATH environment variable
	if envPath := os.Getenv("DEVNET_CONFIG_PATH"); envPath != "" {
		paths = append([]string{envPath}, paths...)
	}

	var configPath string
	for _, p := range paths {
		if _, err := os.Stat(p); err == nil {
			configPath = p
			break
		}
		// Try absolute path
		absPath, _ := filepath.Abs(p)
		if _, err := os.Stat(absPath); err == nil {
			configPath = absPath
			break
		}
	}

	if configPath == "" {
		return nil, os.ErrNotExist
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	var config DevnetConfig
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, err
	}

	return &config, nil
}

// IsDevnetAvailable checks if devnet configuration exists
func IsDevnetAvailable() bool {
	_, err := LoadDevnetConfig()
	return err == nil
}
