package submitter

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"log"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/evidence"
)

// AdjacentLeavesSubmitter submits adjacent leaves evidence to RAT contract
type AdjacentLeavesSubmitter struct {
	l1Client    *ethclient.Client
	privateKey  *ecdsa.PrivateKey
	ratContract common.Address
	gasLimit    uint64
	maxGasPrice *big.Int
}

// NewAdjacentLeavesSubmitter creates a new adjacent leaves submitter
func NewAdjacentLeavesSubmitter(
	l1RPCURL string,
	privateKey *ecdsa.PrivateKey,
	ratContract common.Address,
	gasLimit uint64,
	maxGasPrice *big.Int,
) (*AdjacentLeavesSubmitter, error) {
	client, err := ethclient.Dial(l1RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}

	// Verify connection
	chainID, err := client.ChainID(context.Background())
	if err != nil {
		return nil, fmt.Errorf("failed to get chain ID: %w", err)
	}

	from := crypto.PubkeyToAddress(privateKey.PublicKey)
	log.Printf("Created submitter: l1RPC=%s, chainID=%v, ratContract=%s, from=%s",
		l1RPCURL,
		chainID,
		ratContract.Hex(),
		from.Hex())

	return &AdjacentLeavesSubmitter{
		l1Client:    client,
		privateKey:  privateKey,
		ratContract: ratContract,
		gasLimit:    gasLimit,
		maxGasPrice: maxGasPrice,
	}, nil
}

// SubmitEvidence submits state leaf evidence to RAT contract
func (s *AdjacentLeavesSubmitter) SubmitEvidence(
	ctx context.Context,
	systemConfig common.Address,
	batchIndex uint32,
	randomValue *big.Int,
	ev *evidence.StateLeafEvidence,
) (*types.Receipt, error) {
	log.Printf("Submitting state leaf evidence: systemConfig=%s, batchIndex=%d, randomValue=%v, leafA.key=%s, leafB.key=%s",
		systemConfig.Hex(),
		batchIndex,
		randomValue,
		ev.LeafAKey.Hex(),
		ev.LeafBKey.Hex())

	// Validate evidence
	if err := ev.Validate(); err != nil {
		return nil, fmt.Errorf("evidence validation failed: %w", err)
	}

	// Verify range (leafA.key < randomValue <= leafB.key)
	if !ev.VerifyRange(randomValue) {
		return nil, fmt.Errorf("random value %s not in range (%s, %s]",
			randomValue, ev.LeafAKey.Hex(), ev.LeafBKey.Hex())
	}

	// Encode evidence
	evidenceData, err := ev.Encode()
	if err != nil {
		return nil, fmt.Errorf("failed to encode evidence: %w", err)
	}

	log.Printf("Evidence encoded: size=%d, stateRoot=%s",
		len(evidenceData),
		ev.StateRoot.Hex())

	// Build calldata for submitEvidence(address systemConfig, uint32 batchIndex, bytes calldata evidence)
	calldata, err := s.buildCalldata(systemConfig, batchIndex, evidenceData)
	if err != nil {
		return nil, fmt.Errorf("failed to build calldata: %w", err)
	}

	// Get sender address
	from := crypto.PubkeyToAddress(s.privateKey.PublicKey)

	// Estimate gas
	gasLimit, err := s.estimateGas(ctx, from, calldata)
	if err != nil {
		log.Printf("Gas estimation failed, using default: error=%v, default=%d", err, s.gasLimit)
		gasLimit = s.gasLimit
	}

	// Get gas price
	gasPrice, err := s.l1Client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get gas price: %w", err)
	}

	// Cap gas price
	if s.maxGasPrice != nil && gasPrice.Cmp(s.maxGasPrice) > 0 {
		log.Printf("Gas price capped: suggested=%s, max=%s", gasPrice, s.maxGasPrice)
		gasPrice = s.maxGasPrice
	}

	// Get nonce
	nonce, err := s.l1Client.PendingNonceAt(ctx, from)
	if err != nil {
		return nil, fmt.Errorf("failed to get nonce: %w", err)
	}

	// Get chain ID
	chainID, err := s.l1Client.ChainID(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get chain ID: %w", err)
	}

	// Build transaction
	tx := types.NewTransaction(
		nonce,
		s.ratContract,
		big.NewInt(0), // value
		gasLimit,
		gasPrice,
		calldata,
	)

	// Sign transaction
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), s.privateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to sign transaction: %w", err)
	}

	// Send transaction
	if err := s.l1Client.SendTransaction(ctx, signedTx); err != nil {
		return nil, fmt.Errorf("failed to send transaction: %w", err)
	}

	txHash := signedTx.Hash()
	log.Printf("Transaction sent: txHash=%s, from=%s, to=%s, gasLimit=%d, gasPrice=%v, nonce=%d",
		txHash.Hex(),
		from.Hex(),
		s.ratContract.Hex(),
		gasLimit,
		gasPrice,
		nonce)

	// Wait for receipt
	receipt, err := s.waitForReceipt(ctx, txHash)
	if err != nil {
		return nil, fmt.Errorf("failed to get receipt: %w", err)
	}

	if receipt.Status == 0 {
		return receipt, fmt.Errorf("transaction failed: %s", txHash.Hex())
	}

	log.Printf("Evidence submitted successfully: txHash=%s, blockNumber=%v, gasUsed=%d",
		txHash.Hex(),
		receipt.BlockNumber,
		receipt.GasUsed)

	return receipt, nil
}

// buildCalldata builds calldata for submitEvidence function
func (s *AdjacentLeavesSubmitter) buildCalldata(systemConfig common.Address, batchIndex uint32, evidenceData []byte) ([]byte, error) {
	// Function selector: submitEvidence(address,uint32,bytes)
	// Keccak256("submitEvidence(address,uint32,bytes)") = 0x...
	selector := crypto.Keccak256([]byte("submitEvidence(address,uint32,bytes)"))[:4]

	// Encode parameters
	// address systemConfig (padded to 32 bytes)
	// uint32 batchIndex (padded to 32 bytes)
	// bytes evidenceData

	calldata := make([]byte, 0, 4+32+32+32+len(evidenceData))
	calldata = append(calldata, selector...)

	// systemConfig (address, left-padded to 32 bytes)
	calldata = append(calldata, common.LeftPadBytes(systemConfig.Bytes(), 32)...)

	// batchIndex (uint32, left-padded to 32 bytes)
	batchIndexBytes := make([]byte, 32)
	batchIndexBytes[28] = byte(batchIndex >> 24)
	batchIndexBytes[29] = byte(batchIndex >> 16)
	batchIndexBytes[30] = byte(batchIndex >> 8)
	batchIndexBytes[31] = byte(batchIndex)
	calldata = append(calldata, batchIndexBytes...)

	// evidenceData offset (uint256)
	offset := big.NewInt(96) // 32 + 32 + 32
	calldata = append(calldata, common.LeftPadBytes(offset.Bytes(), 32)...)

	// evidenceData length (uint256)
	length := big.NewInt(int64(len(evidenceData)))
	calldata = append(calldata, common.LeftPadBytes(length.Bytes(), 32)...)

	// evidenceData (bytes, padded to 32-byte boundary)
	calldata = append(calldata, evidenceData...)
	padding := (32 - (len(evidenceData) % 32)) % 32
	if padding > 0 {
		calldata = append(calldata, make([]byte, padding)...)
	}

	return calldata, nil
}

// estimateGas estimates gas for the transaction
func (s *AdjacentLeavesSubmitter) estimateGas(ctx context.Context, from common.Address, calldata []byte) (uint64, error) {
	msg := ethereum.CallMsg{
		From:     from,
		To:       &s.ratContract,
		Gas:      0,
		GasPrice: nil,
		Value:    big.NewInt(0),
		Data:     calldata,
	}

	gasLimit, err := s.l1Client.EstimateGas(ctx, msg)
	if err != nil {
		return 0, err
	}

	// Add 20% buffer
	gasLimit = gasLimit * 120 / 100

	return gasLimit, nil
}

// waitForReceipt waits for transaction receipt
func (s *AdjacentLeavesSubmitter) waitForReceipt(ctx context.Context, txHash common.Hash) (*types.Receipt, error) {
	for i := 0; i < 120; i++ { // Wait up to 120 * 2s = 4 minutes
		receipt, err := s.l1Client.TransactionReceipt(ctx, txHash)
		if err == nil {
			return receipt, nil
		}

		if err != ethereum.NotFound {
			return nil, err
		}

		// Wait 2 seconds before retry
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case <-time.After(2 * time.Second):
		}
	}

	return nil, fmt.Errorf("transaction not mined after 4 minutes")
}

// Close closes the L1 client connection
func (s *AdjacentLeavesSubmitter) Close() {
	if s.l1Client != nil {
		s.l1Client.Close()
	}
}
