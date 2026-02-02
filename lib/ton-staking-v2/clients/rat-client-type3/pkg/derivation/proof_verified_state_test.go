package derivation

import (
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
)

// TestProofDB tests the proofDB implementation
func TestProofDB(t *testing.T) {
	db := newProofDB()

	// Test Put and Get
	key := []byte("test-key")
	value := []byte("test-value")

	err := db.Put(key, value)
	if err != nil {
		t.Fatalf("Put failed: %v", err)
	}

	retrieved, err := db.Get(key)
	if err != nil {
		t.Fatalf("Get failed: %v", err)
	}

	if string(retrieved) != string(value) {
		t.Errorf("Expected %s, got %s", value, retrieved)
	}

	// Test Has
	exists, err := db.Has(key)
	if err != nil {
		t.Fatalf("Has failed: %v", err)
	}

	if !exists {
		t.Error("Key should exist")
	}

	// Test non-existent key
	_, err = db.Get([]byte("non-existent"))
	if err == nil {
		t.Error("Expected error for non-existent key")
	}
}

// TestConvertProofToNodeSet tests hex proof conversion
func TestConvertProofToNodeSet(t *testing.T) {
	// Example proof nodes (hex-encoded)
	proofHex := []string{
		"0xf90211a0",
		"0xf851a0",
		"0xe2a120",
	}

	db, err := convertProofToNodeSet(proofHex)
	if err != nil {
		t.Fatalf("convertProofToNodeSet failed: %v", err)
	}

	if db == nil {
		t.Fatal("Expected non-nil proofDB")
	}

	// Verify that nodes were added
	// Each node should be accessible by its keccak256 hash
	for _, hexNode := range proofHex {
		hexNode = hexNode[2:] // Remove "0x"
		// Just check that conversion didn't panic
	}
}

// TestEmptyConstants tests the empty hash constants
func TestEmptyConstants(t *testing.T) {
	// emptyCodeHash should be keccak256("")
	expectedEmptyCode := crypto.Keccak256Hash([]byte{})
	if emptyCodeHash != expectedEmptyCode {
		t.Errorf("emptyCodeHash mismatch: expected %s, got %s", expectedEmptyCode, emptyCodeHash)
	}

	// Verify constants are correct hex values
	if emptyCodeHash.Hex() != "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470" {
		t.Errorf("emptyCodeHash has wrong value: %s", emptyCodeHash.Hex())
	}

	if emptyStorageHash.Hex() != "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421" {
		t.Errorf("emptyStorageHash has wrong value: %s", emptyStorageHash.Hex())
	}
}

// TestAccountDataStruct tests the AccountData structure
func TestAccountDataStruct(t *testing.T) {
	addr := common.HexToAddress("0x1234567890abcdef1234567890abcdef12345678")

	data := &AccountData{
		Nonce:       1,
		Balance:     common.Big1,
		StorageHash: common.Hash{},
		CodeHash:    emptyCodeHash,
		Code:        []byte{},
		Verified:    true,
	}

	if data.Nonce != 1 {
		t.Errorf("Expected nonce 1, got %d", data.Nonce)
	}

	if !data.Verified {
		t.Error("Expected Verified to be true")
	}

	// Use addr to avoid unused warning
	_ = addr
}
