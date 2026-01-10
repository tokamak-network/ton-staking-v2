package client

import (
	"context"
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"log"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/l2sync"
)

// OutputRootProof represents the Optimism OutputRootProof structure
// This matches the Solidity struct in Type3EvidenceVerifier.sol
type OutputRootProof struct {
	Version                  [32]byte // bytes32 version (always 0x0)
	StateRoot                [32]byte // bytes32 stateRoot
	MessagePasserStorageRoot [32]byte // bytes32 messagePasserStorageRoot
	LatestBlockHash          [32]byte // bytes32 latestBlockhash
}

// StateLeafEvidence represents the on-chain StateLeafEvidence structure
// This matches the Solidity struct in Type3EvidenceVerifier.sol
type StateLeafEvidence struct {
	// Leaf A (state trie의 첫 번째 리프)
	LeafAKey   [32]byte   // bytes32 leafAKey
	LeafAValue []byte     // bytes leafAValue
	LeafAProof [][]byte   // bytes[] leafAProof

	// Leaf B (인접한 두 번째 리프)
	LeafBKey   [32]byte   // bytes32 leafBKey
	LeafBValue []byte     // bytes leafBValue
	LeafBProof [][]byte   // bytes[] leafBProof

	// State context
	StateRoot   [32]byte // bytes32 stateRoot (deprecated, use OutputRootProof.StateRoot)
	BlockNumber *big.Int // uint256 blockNumber

	// Output Root Proof (for rootClaim verification)
	OutputRootProof OutputRootProof // OutputRootProof outputRootProof
}

// SubmitStateLeafEvidence submits StateLeaf evidence to RAT contract
// This is the main function that RAT client calls to prove validator attention
func SubmitStateLeafEvidence(
	ctx context.Context,
	ratContract *bind.BoundContract,
	transactor *bind.TransactOpts,
	testId [32]byte,
	leaves *l2sync.AdjacentLeaves,
) (*types.Transaction, error) {
	log.Printf("Submitting StateLeaf evidence to RAT contract",
		"testId", common.BytesToHash(testId[:]).Hex(),
		"blockNumber", leaves.BlockNumber,
		"stateRoot", leaves.StateRoot.Hex())

	// 1. Convert AdjacentLeaves to StateLeafEvidence (Solidity struct format)
	evidence := &StateLeafEvidence{
		LeafAKey:    leaves.LeafA.Key,
		LeafAValue:  leaves.LeafA.Value,
		LeafAProof:  leaves.ProofA,
		LeafBKey:    leaves.LeafB.Key,
		LeafBValue:  leaves.LeafB.Value,
		LeafBProof:  leaves.ProofB,
		StateRoot:   leaves.StateRoot,
		BlockNumber: big.NewInt(int64(leaves.BlockNumber)),
	}

	// 2. ABI encode the StateLeafEvidence struct
	evidenceData, err := encodeStateLeafEvidence(evidence)
	if err != nil {
		return nil, fmt.Errorf("failed to encode evidence: %w", err)
	}

	log.Printf("Encoded StateLeaf evidence",
		"evidenceSize", len(evidenceData),
		"proofANodes", len(evidence.LeafAProof),
		"proofBNodes", len(evidence.LeafBProof))

	// 3. Call RAT.submitEvidence(testId, evidenceType=1, evidenceData)
	evidenceType := uint8(1) // StateLeaf type

	tx, err := submitEvidenceTransaction(
		ctx,
		ratContract,
		transactor,
		testId,
		evidenceType,
		evidenceData,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to submit evidence transaction: %w", err)
	}

	log.Printf("Evidence transaction submitted",
		"txHash", tx.Hash().Hex(),
		"nonce", tx.Nonce(),
		"gasLimit", tx.Gas())

	return tx, nil
}

// encodeStateLeafEvidence encodes StateLeafEvidence struct to ABI format
func encodeStateLeafEvidence(evidence *StateLeafEvidence) ([]byte, error) {
	// Define the StateLeafEvidence struct type for ABI encoding
	// This must match the Solidity struct exactly:
	// struct StateLeafEvidence {
	//     bytes32 leafAKey;
	//     bytes   leafAValue;
	//     bytes[] leafAProof;
	//     bytes32 leafBKey;
	//     bytes   leafBValue;
	//     bytes[] leafBProof;
	//     bytes32 stateRoot;
	//     uint256 blockNumber;
	//     OutputRootProof outputRootProof;
	// }

	stateLeafEvidenceType, err := abi.NewType("tuple", "", []abi.ArgumentMarshaling{
		{Name: "leafAKey", Type: "bytes32"},
		{Name: "leafAValue", Type: "bytes"},
		{Name: "leafAProof", Type: "bytes[]"},
		{Name: "leafBKey", Type: "bytes32"},
		{Name: "leafBValue", Type: "bytes"},
		{Name: "leafBProof", Type: "bytes[]"},
		{Name: "stateRoot", Type: "bytes32"},
		{Name: "blockNumber", Type: "uint256"},
		{Name: "outputRootProof", Type: "tuple", Components: []abi.ArgumentMarshaling{
			{Name: "version", Type: "bytes32"},
			{Name: "stateRoot", Type: "bytes32"},
			{Name: "messagePasserStorageRoot", Type: "bytes32"},
			{Name: "latestBlockhash", Type: "bytes32"},
		}},
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create type: %w", err)
	}

	arguments := abi.Arguments{
		{Type: stateLeafEvidenceType},
	}

	// Pack the evidence struct
	packed, err := arguments.Pack(evidence)
	if err != nil {
		return nil, fmt.Errorf("failed to pack evidence: %w", err)
	}

	return packed, nil
}

// submitEvidenceTransaction submits evidence to RAT contract
func submitEvidenceTransaction(
	ctx context.Context,
	ratContract *bind.BoundContract,
	transactor *bind.TransactOpts,
	testId [32]byte,
	evidenceType uint8,
	evidenceData []byte,
) (*types.Transaction, error) {
	// RAT.submitEvidence(bytes32 testId, uint8 evidenceType, bytes calldata evidenceData)
	tx, err := ratContract.Transact(
		transactor,
		"submitEvidence",
		testId,
		evidenceType,
		evidenceData,
	)
	if err != nil {
		return nil, fmt.Errorf("submitEvidence transaction failed: %w", err)
	}

	return tx, nil
}

// WaitForEvidenceSubmission waits for evidence submission transaction to be mined
func WaitForEvidenceSubmission(
	ctx context.Context,
	client bind.DeployBackend,
	tx *types.Transaction,
) (*types.Receipt, error) {
	log.Printf("Waiting for evidence submission transaction to be mined",
		"txHash", tx.Hash().Hex())

	receipt, err := bind.WaitMined(ctx, client, tx)
	if err != nil {
		return nil, fmt.Errorf("failed to wait for transaction: %w", err)
	}

	if receipt.Status == types.ReceiptStatusFailed {
		return receipt, fmt.Errorf("evidence submission transaction failed")
	}

	log.Printf("Evidence submission successful",
		"txHash", receipt.TxHash.Hex(),
		"blockNumber", receipt.BlockNumber,
		"gasUsed", receipt.GasUsed)

	return receipt, nil
}

// ParseEvidenceSubmittedEvent parses EvidenceSubmitted event from receipt
func ParseEvidenceSubmittedEvent(receipt *types.Receipt) (map[string]interface{}, error) {
	// Event signature: EvidenceSubmitted(bytes32 indexed testId, address indexed validator, address indexed systemConfig, uint32 batchIndex)
	eventSignature := []byte("EvidenceSubmitted(bytes32,address,address,uint32)")
	eventTopic := common.BytesToHash(eventSignature)

	for _, vLog := range receipt.Logs {
		if len(vLog.Topics) > 0 && vLog.Topics[0] == eventTopic {
			// Found EvidenceSubmitted event
			return map[string]interface{}{
				"testId":       vLog.Topics[1],
				"validator":    common.HexToAddress(vLog.Topics[2].Hex()),
				"systemConfig": common.HexToAddress(vLog.Topics[3].Hex()),
				"rawLog":       vLog,
			}, nil
		}
	}

	return nil, fmt.Errorf("EvidenceSubmitted event not found")
}
