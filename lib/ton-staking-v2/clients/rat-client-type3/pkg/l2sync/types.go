package l2sync

import (
	"math/big"

	"github.com/ethereum/go-ethereum/common"
)

// ValidatorState represents a validator's state at a specific block
type ValidatorState struct {
	Address     common.Address
	Stake       *big.Int
	Index       uint64 // Position in sorted list
	IsActive    bool
	LastUpdated uint64 // Block number
}

// ValidatorEvent represents a state change event from L2
type ValidatorEvent struct {
	Type        EventType
	Validator   common.Address
	Stake       *big.Int
	BlockNumber uint64
	TxHash      common.Hash
}

// EventType defines the type of validator state change
type EventType int

const (
	EventTypeStaked EventType = iota
	EventTypeUnstaked
	EventTypeStakeChanged
)

// MerkleProof represents a Merkle proof for a leaf
type MerkleProof struct {
	Leaf     []byte
	Index    uint64
	Siblings []common.Hash
}

// SyncStatus represents the synchronization status
type SyncStatus struct {
	LatestBlock   uint64
	IsSynced      bool
	StateDBPath   string
	EstimatedSize int
}
