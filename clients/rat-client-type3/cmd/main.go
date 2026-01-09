package main

import (
	"fmt"
	"log"
	"os"

	"github.com/ethereum/go-ethereum/common"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/client"
	"github.com/urfave/cli/v2"
)

const Version = "0.1.0-alpha"

func main() {
	app := &cli.App{
		Name:    "rat-client-type3",
		Usage:   "RAT Client for Type 3 Rollups (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)",
		Version: Version,
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:     "l1-rpc",
				Usage:    "L1 RPC endpoint",
				EnvVars:  []string{"L1_RPC_URL"},
				Required: true,
			},
			&cli.StringFlag{
				Name:     "l2-rpc",
				Usage:    "L2 RPC endpoint",
				EnvVars:  []string{"L2_RPC_URL"},
				Required: true,
			},
			&cli.StringFlag{
				Name:     "private-key",
				Usage:    "Private key (hex)",
				EnvVars:  []string{"PRIVATE_KEY"},
				Required: true,
			},
			&cli.StringFlag{
				Name:     "rat-contract",
				Usage:    "RAT contract address",
				Required: true,
			},
			&cli.StringFlag{
				Name:     "system-config",
				Usage:    "SystemConfig address",
				Required: true,
			},
		},
		Action: run,
	}

	if err := app.Run(os.Args); err != nil {
		log.Fatal(err)
	}
}

func run(c *cli.Context) error {
	log.Printf("RAT Client Type 3 v%s", Version)

	// Build config
	config := client.DefaultConfig()
	config.L1RPCURL = c.String("l1-rpc")
	config.RPCURLs = []string{c.String("l2-rpc")} // Use L2 RPC as the primary RPC
	config.PrivateKeyHex = c.String("private-key")
	config.RATContract = common.HexToAddress(c.String("rat-contract"))
	config.SystemConfig = common.HexToAddress(c.String("system-config"))

	// Load private key
	if err := config.LoadPrivateKey(); err != nil {
		return fmt.Errorf("failed to load private key: %w", err)
	}

	// Validate
	if err := config.Validate(); err != nil {
		return fmt.Errorf("invalid config: %w", err)
	}

	// Create service
	service, err := client.NewRATClientService(config)
	if err != nil {
		return fmt.Errorf("failed to create service: %w", err)
	}

	// Start service
	if err := service.Start(); err != nil {
		return fmt.Errorf("failed to start service: %w", err)
	}
	defer service.Stop()

	log.Printf("\nNOTE: Core verification logic not yet implemented:")
	log.Printf("  - Batch fetching: TODO")
	log.Printf("  - Batch decoding: TODO")
	log.Printf("  - Trustless EVM execution: TODO")
	log.Printf("  - Merkle proof generation: TODO")
	log.Printf("  - Evidence submission: TODO")
	log.Printf("\nPress Ctrl+C to stop...")

	// Wait for service
	service.Wait()

	return nil
}
