package submitter

import (
	"context"
	"crypto/ecdsa"
	"encoding/binary"
	"fmt"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

// Type3Evidence represents the evidence structure for Type 3 rollup (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)
// This matches the Evidence struct in Type3EvidenceVerifier.sol
type Type3Evidence struct {
	// L2 data (derived trustlessly from L1 batches)
	L2BlockNumber  uint64
	L2BlockHash    common.Hash
	L2StateRoot    common.Hash
	WithdrawalRoot common.Hash
	OutputRoot     common.Hash

	// L1 source information
	L1BlockNumber uint64
	L1BlockHash   common.Hash
	L1TxIndex     uint64
	L1TxHash      common.Hash
	BatchData     []byte

	// Merkle proofs (for on-chain verification)
	StateProof      [][32]byte // []bytes32 in Solidity
	WithdrawalProof [][32]byte // []bytes32 in Solidity
	BatchProof      [][32]byte // []bytes32 in Solidity
	L2HeaderRLP     []byte
}

// EvidenceSubmitter submits evidence to RAT contract
type EvidenceSubmitter struct {
	l1Client    *ethclient.Client
	privateKey  *ecdsa.PrivateKey
	ratContract common.Address
	gasLimit    uint64
	maxGasPrice uint64
}

// NewEvidenceSubmitter creates a new evidence submitter
func NewEvidenceSubmitter(
	l1RPCURL string,
	privateKey *ecdsa.PrivateKey,
	ratContract common.Address,
	gasLimit uint64,
	maxGasPrice uint64,
) (*EvidenceSubmitter, error) {
	client, err := ethclient.Dial(l1RPCURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to L1: %w", err)
	}

	return &EvidenceSubmitter{
		l1Client:    client,
		privateKey:  privateKey,
		ratContract: ratContract,
		gasLimit:    gasLimit,
		maxGasPrice: maxGasPrice,
	}, nil
}

// SubmitEvidence submits evidence to RAT contract
func (s *EvidenceSubmitter) SubmitEvidence(
	ctx context.Context,
	testID [32]byte,
	systemConfig common.Address,
	batchIndex uint32,
	evidenceData []byte,
	deadline *big.Int,
) (*types.Receipt, error) {
	// Check deadline
	now := time.Now().Unix()
	if deadline.Int64()-now < 600 { // 10 minutes buffer
		return nil, fmt.Errorf("deadline too close: %d seconds remaining", deadline.Int64()-now)
	}

	// Build calldata
	calldata, err := s.BuildSubmitEvidenceCalldata(systemConfig, batchIndex, evidenceData)
	if err != nil {
		return nil, fmt.Errorf("failed to build calldata: %w", err)
	}

	// Get from address
	from := crypto.PubkeyToAddress(s.privateKey.PublicKey)

	// Estimate gas
	gas, err := s.EstimateGas(ctx, from, calldata)
	if err != nil {
		return nil, fmt.Errorf("failed to estimate gas: %w", err)
	}

	// Get gas price
	gasPrice, err := s.l1Client.SuggestGasPrice(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get gas price: %w", err)
	}

	// Cap gas price
	if gasPrice.Uint64() > s.maxGasPrice {
		gasPrice = new(big.Int).SetUint64(s.maxGasPrice)
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
		gas,
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

	fmt.Printf("Submitted evidence transaction: %s\n", signedTx.Hash().Hex())

	// Wait for receipt
	receipt, err := s.WaitForReceipt(ctx, signedTx.Hash(), 5*time.Minute)
	if err != nil {
		return nil, fmt.Errorf("failed to get receipt: %w", err)
	}

	if receipt.Status != 1 {
		return receipt, fmt.Errorf("transaction reverted")
	}

	return receipt, nil
}

// BuildSubmitEvidenceCalldata builds the calldata for submitEvidence
// Function signature: submitEvidence(address systemConfig, uint32 batchIndex, bytes calldata evidenceData)
func (s *EvidenceSubmitter) BuildSubmitEvidenceCalldata(
	systemConfig common.Address,
	batchIndex uint32,
	evidenceData []byte,
) ([]byte, error) {
	// Function selector: submitEvidence(address,uint32,bytes)
	// keccak256("submitEvidence(address,uint32,bytes)") = 0x...
	// For now, manually encode

	// Method ID (first 4 bytes of keccak256)
	methodID := crypto.Keccak256([]byte("submitEvidence(address,uint32,bytes)"))[:4]

	// Encode parameters
	// address systemConfig (32 bytes, left-padded)
	systemConfigPadded := common.LeftPadBytes(systemConfig.Bytes(), 32)

	// uint32 batchIndex (32 bytes, left-padded)
	batchIndexBytes := make([]byte, 32)
	binary.BigEndian.PutUint32(batchIndexBytes[28:], batchIndex)

	// bytes evidenceData (offset + length + data)
	// Offset to dynamic data (3 * 32 = 96 bytes)
	offset := make([]byte, 32)
	binary.BigEndian.PutUint64(offset[24:], 96)

	// Length of evidenceData
	length := make([]byte, 32)
	binary.BigEndian.PutUint64(length[24:], uint64(len(evidenceData)))

	// Pad evidenceData to 32-byte boundary
	paddedData := evidenceData
	if len(evidenceData)%32 != 0 {
		padding := 32 - (len(evidenceData) % 32)
		paddedData = append(evidenceData, make([]byte, padding)...)
	}

	// Concatenate all
	calldata := make([]byte, 0)
	calldata = append(calldata, methodID...)
	calldata = append(calldata, systemConfigPadded...)
	calldata = append(calldata, batchIndexBytes...)
	calldata = append(calldata, offset...)
	calldata = append(calldata, length...)
	calldata = append(calldata, paddedData...)

	return calldata, nil
}

// EstimateGas estimates gas for evidence submission
func (s *EvidenceSubmitter) EstimateGas(
	ctx context.Context,
	from common.Address,
	data []byte,
) (uint64, error) {
	msg := ethereum.CallMsg{
		From: from,
		To:   &s.ratContract,
		Data: data,
	}

	gas, err := s.l1Client.EstimateGas(ctx, msg)
	if err != nil {
		return 0, fmt.Errorf("failed to estimate gas: %w", err)
	}

	// Add 20% buffer
	return gas * 120 / 100, nil
}

// WaitForReceipt waits for transaction receipt
func (s *EvidenceSubmitter) WaitForReceipt(
	ctx context.Context,
	txHash common.Hash,
	timeout time.Duration,
) (*types.Receipt, error) {
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	ticker := time.NewTicker(3 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return nil, fmt.Errorf("timeout waiting for receipt")
		case <-ticker.C:
			receipt, err := s.l1Client.TransactionReceipt(ctx, txHash)
			if err == nil {
				return receipt, nil
			}
		}
	}
}

// Close closes the L1 client connection
func (s *EvidenceSubmitter) Close() {
	if s.l1Client != nil {
		s.l1Client.Close()
	}
}

// EncodeType3Evidence encodes Type3Evidence struct using Solidity ABI encoding
// This matches the Evidence struct in Type3EvidenceVerifier.sol:
// struct Evidence {
//     uint256 l2BlockNumber;
//     bytes32 l2BlockHash;
//     bytes32 l2StateRoot;
//     bytes32 withdrawalRoot;
//     bytes32 outputRoot;
//     uint256 l1BlockNumber;
//     bytes32 l1BlockHash;
//     uint256 l1TxIndex;
//     bytes32 l1TxHash;
//     bytes   batchData;
//     bytes32[] stateProof;
//     bytes32[] withdrawalProof;
//     bytes32[] batchProof;
//     bytes     l2HeaderRLP;
// }
func EncodeType3Evidence(ev *Type3Evidence) ([]byte, error) {
	// Define the Evidence struct type for ABI encoding
	// Based on Type3EvidenceVerifier.sol Evidence struct
	uint256Type, _ := abi.NewType("uint256", "", nil)
	bytes32Type, _ := abi.NewType("bytes32", "", nil)
	bytesType, _ := abi.NewType("bytes", "", nil)
	bytes32ArrayType, _ := abi.NewType("bytes32[]", "", nil)

	// Define arguments
	arguments := abi.Arguments{
		{Type: uint256Type},        // l2BlockNumber
		{Type: bytes32Type},        // l2BlockHash
		{Type: bytes32Type},        // l2StateRoot
		{Type: bytes32Type},        // withdrawalRoot
		{Type: bytes32Type},        // outputRoot
		{Type: uint256Type},        // l1BlockNumber
		{Type: bytes32Type},        // l1BlockHash
		{Type: uint256Type},        // l1TxIndex
		{Type: bytes32Type},        // l1TxHash
		{Type: bytesType},          // batchData
		{Type: bytes32ArrayType},   // stateProof
		{Type: bytes32ArrayType},   // withdrawalProof
		{Type: bytes32ArrayType},   // batchProof
		{Type: bytesType},          // l2HeaderRLP
	}

	// Pack the values
	packed, err := arguments.Pack(
		new(big.Int).SetUint64(ev.L2BlockNumber),
		ev.L2BlockHash,
		ev.L2StateRoot,
		ev.WithdrawalRoot,
		ev.OutputRoot,
		new(big.Int).SetUint64(ev.L1BlockNumber),
		ev.L1BlockHash,
		new(big.Int).SetUint64(ev.L1TxIndex),
		ev.L1TxHash,
		ev.BatchData,
		ev.StateProof,
		ev.WithdrawalProof,
		ev.BatchProof,
		ev.L2HeaderRLP,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to pack evidence: %w", err)
	}

	return packed, nil
}
