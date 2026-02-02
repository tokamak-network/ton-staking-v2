package verification

import (
	"fmt"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

// OutputV0 represents an L2 output root (OutputV0 format)
type OutputV0 struct {
	Version                  [32]byte    // Version (0x0000...0000)
	StateRoot                common.Hash // L2 state root
	MessagePasserStorageRoot common.Hash // L2ToL1MessagePasser storage root
	BlockHash                common.Hash // L2 block hash
}

// OutputRootComputer computes output roots for L2 blocks
type OutputRootComputer struct {
	l2ToL1MessagePasser common.Address
}

// NewOutputRootComputer creates a new output root computer
func NewOutputRootComputer(l2ToL1MessagePasser common.Address) *OutputRootComputer {
	return &OutputRootComputer{
		l2ToL1MessagePasser: l2ToL1MessagePasser,
	}
}

// ComputeOutputRoot computes the output root for an L2 block
func (c *OutputRootComputer) ComputeOutputRoot(
	stateRoot common.Hash,
	withdrawalStorageRoot common.Hash,
	blockHash common.Hash,
) (common.Hash, error) {
	output := OutputV0{
		Version:                  [32]byte{}, // Version 0
		StateRoot:                stateRoot,
		MessagePasserStorageRoot: withdrawalStorageRoot,
		BlockHash:                blockHash,
	}

	return c.HashOutputV0(output), nil
}

// HashOutputV0 computes the hash of an OutputV0 struct
// Hash = keccak256(version || stateRoot || messagePasserStorageRoot || blockHash)
func (c *OutputRootComputer) HashOutputV0(output OutputV0) common.Hash {
	// Concatenate: version (32) + stateRoot (32) + messagePasserStorageRoot (32) + blockHash (32) = 128 bytes
	data := make([]byte, 0, 128)
	data = append(data, output.Version[:]...)
	data = append(data, output.StateRoot[:]...)
	data = append(data, output.MessagePasserStorageRoot[:]...)
	data = append(data, output.BlockHash[:]...)

	return crypto.Keccak256Hash(data)
}

// GetWithdrawalStorageRoot gets the withdrawal storage root for an L2 block
// This requires querying the L2ToL1MessagePasser contract storage root
func (c *OutputRootComputer) GetWithdrawalStorageRoot(
	stateRoot common.Hash,
	// TODO: Add state trie access to query storage root
) (common.Hash, error) {
	// TODO: Implement storage root extraction from state trie
	// This requires:
	// 1. Access to state trie at stateRoot
	// 2. Query account at l2ToL1MessagePasser address
	// 3. Extract storageRoot from account

	return common.Hash{}, fmt.Errorf("withdrawal storage root extraction not yet implemented")
}
