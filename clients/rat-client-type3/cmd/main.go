package main

import (
	"fmt"
	"log"
	"math/big"
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
			&cli.Uint64Flag{
				Name:  "start-block",
				Usage: "Block number to start monitoring from",
				Value: 0,
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
	config.StartBlockNumber = c.Uint64("start-block")

	// Load private key
	if err := config.LoadPrivateKey(); err != nil {
		return fmt.Errorf("failed to load private key: %w", err)
	}

	// Validate
	if err := config.Validate(); err != nil {
		return fmt.Errorf("invalid config: %w", err)
	}

	// Create adjacent leaves service (State Root as Target mode)
	adjacentConfig := &client.AdjacentServiceConfig{
		L1RPCURL:         config.L1RPCURL,
		RATContract:      config.RATContract,
		PollInterval:     config.PollInterval,
		Confirmations:    config.Confirmations,
		StartBlockNumber: config.StartBlockNumber,
		L2RPCURL:         config.GetPrimaryRPC(),
		OpNodeRPCURL:     "",        // Not used for now
		StateDBPath:      "",         // Not used (using RPC mode)
		StakingContract:  common.Address{}, // Not used
		ValidatorAddress: config.ValidatorAddress,
		PrivateKey:       config.GetPrivateKey(),
		DeadlineBuffer:   config.DeadlineBuffer,
		GasLimit:         config.GasLimit,
		MaxGasPrice:      new(big.Int).SetUint64(config.MaxGasPrice),
	}

	service, err := client.NewRATClientAdjacentService(adjacentConfig)
	if err != nil {
		return fmt.Errorf("failed to create service: %w", err)
	}

	// Start service
	if err := service.Start(); err != nil {
		return fmt.Errorf("failed to start service: %w", err)
	}
	defer service.Stop()

	log.Printf("\nRAT Client running in Adjacent Leaves mode (State Root as Target)")
	log.Printf("Press Ctrl+C to stop...")

	// Wait forever (service runs in background)
	select {}
}
