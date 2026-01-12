package evidence

import (
	"fmt"
	"math/big"

	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/l2sync"
)

// OutputRootProof represents Optimism OutputRootProof structure
// This matches the Solidity struct in Type3EvidenceVerifier.sol
type OutputRootProof struct {
	Version                  [32]byte    // Version (always 0x0)
	StateRoot                common.Hash // L2 state root
	MessagePasserStorageRoot common.Hash // L2ToL1MessagePasser storage root
	LatestBlockHash          common.Hash // L2 block hash
}

// DivergenceWitness represents divergence point witness data
// This proves that there are no other leaves between LeafA and LeafB
type DivergenceWitness struct {
	DivergenceNode  []byte // RLP-encoded branch node at divergence point
	IndexA          uint8  // Slot index where LeafA is located (0-15)
	IndexB          uint8  // Slot index where LeafB is located (0-15)
	DivergenceDepth uint64 // Depth of divergence node from root
}

// StateLeafEvidence represents evidence based on adjacent leaves in L2 state Patricia trie
type StateLeafEvidence struct {
	// Leaf A (state trie leaf)
	LeafAKey   common.Hash // keccak256(address)
	LeafAValue []byte      // RLP(account)
	LeafAProof [][]byte    // Merkle proof

	// Leaf B (adjacent leaf in state trie)
	LeafBKey   common.Hash
	LeafBValue []byte
	LeafBProof [][]byte

	// State
	StateRoot   common.Hash // Deprecated: use OutputRootProof.StateRoot
	BlockNumber uint64

	// Output Root Proof (for rootClaim verification)
	OutputRootProof OutputRootProof // Proves stateRoot authenticity

	// Divergence Witness (perfect adjacency verification)
	DivergenceWitness DivergenceWitness // Proves no leaves between LeafA and LeafB
}

// NewStateLeafEvidence creates evidence from adjacent leaves
func NewStateLeafEvidence(leaves *l2sync.AdjacentLeaves) (*StateLeafEvidence, error) {
	if leaves == nil {
		return nil, fmt.Errorf("adjacent leaves cannot be nil")
	}

	if leaves.LeafA == nil || leaves.LeafB == nil {
		return nil, fmt.Errorf("leafA or leafB is nil")
	}

	// Verify keys are adjacent (lexicographically)
	// In Patricia trie, leaves are iterated in sorted order of keys
	if leaves.LeafA.Key.Big().Cmp(leaves.LeafB.Key.Big()) >= 0 {
		return nil, fmt.Errorf("leafA key must be < leafB key, got leafA=%s leafB=%s",
			leaves.LeafA.Key.Hex(), leaves.LeafB.Key.Hex())
	}

	// Generate divergence witness
	divergenceNode, indexA, indexB, depth, err := l2sync.FindDivergenceNode(
		leaves.LeafA.Key,
		leaves.LeafB.Key,
		leaves.ProofA,
		leaves.ProofB,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to find divergence node: %w", err)
	}

	return &StateLeafEvidence{
		LeafAKey:    leaves.LeafA.Key,
		LeafAValue:  leaves.LeafA.Value,
		LeafAProof:  leaves.ProofA,
		LeafBKey:    leaves.LeafB.Key,
		LeafBValue:  leaves.LeafB.Value,
		LeafBProof:  leaves.ProofB,
		StateRoot:   leaves.StateRoot,
		BlockNumber: leaves.BlockNumber,
		DivergenceWitness: DivergenceWitness{
			DivergenceNode:  divergenceNode,
			IndexA:          indexA,
			IndexB:          indexB,
			DivergenceDepth: depth,
		},
	}, nil
}

// Encode encodes the evidence as ABI-encoded bytes for contract submission
func (e *StateLeafEvidence) Encode() ([]byte, error) {
	// Define ABI arguments matching Solidity struct
	// struct StateLeafEvidence {
	//     bytes32 leafAKey;
	//     bytes leafAValue;
	//     bytes[] leafAProof;
	//     bytes32 leafBKey;
	//     bytes leafBValue;
	//     bytes[] leafBProof;
	//     bytes32 stateRoot;
	//     uint256 blockNumber;
	//     OutputRootProof outputRootProof;
	//     DivergenceWitness divergenceWitness;
	// }
	//
	// struct OutputRootProof {
	//     bytes32 version;
	//     bytes32 stateRoot;
	//     bytes32 messagePasserStorageRoot;
	//     bytes32 latestBlockhash;
	// }
	//
	// struct DivergenceWitness {
	//     bytes divergenceNode;
	//     uint8 indexA;
	//     uint8 indexB;
	//     uint256 divergenceDepth;
	// }

	// Define StateLeafEvidence tuple type (wrapping the entire struct)
	// This matches Solidity's abi.encode(StateLeafEvidence)
	stateLeafEvidenceTy, _ := abi.NewType("tuple", "", []abi.ArgumentMarshaling{
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
		{Name: "divergenceWitness", Type: "tuple", Components: []abi.ArgumentMarshaling{
			{Name: "divergenceNode", Type: "bytes"},
			{Name: "indexA", Type: "uint8"},
			{Name: "indexB", Type: "uint8"},
			{Name: "divergenceDepth", Type: "uint256"},
		}},
	})

	// Define OutputRootProof struct type for embedding
	type OutputRootProofStruct struct {
		Version                  [32]byte
		StateRoot                common.Hash
		MessagePasserStorageRoot common.Hash
		LatestBlockhash          common.Hash
	}

	// Define DivergenceWitness struct type for embedding
	type DivergenceWitnessStruct struct {
		DivergenceNode  []byte
		IndexA          uint8
		IndexB          uint8
		DivergenceDepth *big.Int
	}

	// Pack OutputRootProof as struct
	outputRootProofStruct := OutputRootProofStruct{
		Version:                  e.OutputRootProof.Version,
		StateRoot:                e.OutputRootProof.StateRoot,
		MessagePasserStorageRoot: e.OutputRootProof.MessagePasserStorageRoot,
		LatestBlockhash:          e.OutputRootProof.LatestBlockHash,
	}

	// Pack DivergenceWitness as struct
	divergenceWitnessStruct := DivergenceWitnessStruct{
		DivergenceNode:  e.DivergenceWitness.DivergenceNode,
		IndexA:          e.DivergenceWitness.IndexA,
		IndexB:          e.DivergenceWitness.IndexB,
		DivergenceDepth: new(big.Int).SetUint64(e.DivergenceWitness.DivergenceDepth),
	}

	// Pack the entire struct as a single tuple argument
	// This matches Solidity's abi.encode(StateLeafEvidence)
	stateLeafEvidenceStruct := struct {
		LeafAKey          common.Hash
		LeafAValue        []byte
		LeafAProof        [][]byte
		LeafBKey          common.Hash
		LeafBValue        []byte
		LeafBProof        [][]byte
		StateRoot         common.Hash
		BlockNumber       *big.Int
		OutputRootProof   OutputRootProofStruct
		DivergenceWitness DivergenceWitnessStruct
	}{
		LeafAKey:          e.LeafAKey,
		LeafAValue:        e.LeafAValue,
		LeafAProof:        e.LeafAProof,
		LeafBKey:          e.LeafBKey,
		LeafBValue:        e.LeafBValue,
		LeafBProof:        e.LeafBProof,
		StateRoot:         e.StateRoot,
		BlockNumber:       new(big.Int).SetUint64(e.BlockNumber),
		OutputRootProof:   outputRootProofStruct,
		DivergenceWitness: divergenceWitnessStruct,
	}

	// Create arguments with single tuple
	arguments := abi.Arguments{
		{Type: stateLeafEvidenceTy},
	}

	// Pack the struct as a single argument
	encoded, err := arguments.Pack(stateLeafEvidenceStruct)

	if err != nil {
		return nil, fmt.Errorf("failed to encode evidence: %w", err)
	}

	return encoded, nil
}

// Validate validates the evidence structure
func (e *StateLeafEvidence) Validate() error {
	// Check keys
	if e.LeafAKey == (common.Hash{}) {
		return fmt.Errorf("leafA key is zero")
	}

	if e.LeafBKey == (common.Hash{}) {
		return fmt.Errorf("leafB key is zero")
	}

	// Check key ordering
	if e.LeafAKey.Big().Cmp(e.LeafBKey.Big()) >= 0 {
		return fmt.Errorf("leafA key must be < leafB key")
	}

	// Check values exist
	if len(e.LeafAValue) == 0 {
		return fmt.Errorf("leafA value is empty")
	}

	if len(e.LeafBValue) == 0 {
		return fmt.Errorf("leafB value is empty")
	}

	// Check proofs exist
	if len(e.LeafAProof) == 0 {
		return fmt.Errorf("leafA proof is empty")
	}

	if len(e.LeafBProof) == 0 {
		return fmt.Errorf("leafB proof is empty")
	}

	// Check state root
	if e.StateRoot == (common.Hash{}) {
		return fmt.Errorf("state root is zero")
	}

	return nil
}

// String returns a string representation of the evidence
func (e *StateLeafEvidence) String() string {
	return fmt.Sprintf(
		"StateLeafEvidence{\n"+
			"  LeafA: {key: %s, value: %d bytes, proof: %d nodes}\n"+
			"  LeafB: {key: %s, value: %d bytes, proof: %d nodes}\n"+
			"  StateRoot: %s\n"+
			"  Block: %d\n"+
			"}",
		e.LeafAKey.Hex(),
		len(e.LeafAValue),
		len(e.LeafAProof),
		e.LeafBKey.Hex(),
		len(e.LeafBValue),
		len(e.LeafBProof),
		e.StateRoot.Hex(),
		e.BlockNumber,
	)
}

// VerifyRange verifies that a random value falls within the key range [leafA, leafB]
func (e *StateLeafEvidence) VerifyRange(randomValue *big.Int) bool {
	// Convert random value to hash
	randomHash := common.BigToHash(randomValue)

	// Check: leafA.key < randomHash <= leafB.key
	return e.LeafAKey.Big().Cmp(randomHash.Big()) < 0 &&
		randomHash.Big().Cmp(e.LeafBKey.Big()) <= 0
}

// Size returns the approximate size of the evidence in bytes
func (e *StateLeafEvidence) Size() int {
	// Keys: 32 bytes each = 64
	// Values: variable
	// Proofs: variable (each node ~32-544 bytes)
	// StateRoot: 32 bytes
	// BlockNumber: 32 bytes (when encoded)

	baseSize := 128 // keys + stateRoot + blockNumber
	valueSize := len(e.LeafAValue) + len(e.LeafBValue)

	proofSize := 0
	for _, node := range e.LeafAProof {
		proofSize += len(node)
	}
	for _, node := range e.LeafBProof {
		proofSize += len(node)
	}

	return baseSize + valueSize + proofSize
}
