package test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ethereum/go-ethereum/common"
	"github.com/stretchr/testify/require"
	"github.com/tokamak-network/ton-staking-v2/clients/rat-client-type3/pkg/verification"
)

// TestOutputRootProofIntegration tests the OutputRootProof flow with mock op-node
// This is a LIGHTWEIGHT integration test that doesn't require real infrastructure
func TestOutputRootProofIntegration(t *testing.T) {
	// Mock op-node server
	mockOpNode := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var req map[string]interface{}
		json.NewDecoder(r.Body).Decode(&req)

		method := req["method"].(string)

		switch method {
		case "optimism_outputAtBlock":
			// Return mock OutputResponse
			response := map[string]interface{}{
				"jsonrpc": "2.0",
				"id":      req["id"],
				"result": map[string]interface{}{
					"version": "0x0000000000000000000000000000000000000000000000000000000000000000",
					"stateRoot": "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
					"withdrawalStorageRoot": "0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
					"blockRef": map[string]interface{}{
						"hash":   "0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd",
						"number": "0x64",
					},
				},
			}
			json.NewEncoder(w).Encode(response)

		case "optimism_syncStatus":
			// Return mock sync status
			response := map[string]interface{}{
				"jsonrpc": "2.0",
				"id":      req["id"],
				"result": map[string]interface{}{
					"safe_l2": map[string]interface{}{
						"number": "0x64",
					},
				},
			}
			json.NewEncoder(w).Encode(response)

		default:
			w.WriteHeader(http.StatusNotFound)
		}
	}))
	defer mockOpNode.Close()

	t.Logf("Mock op-node server: %s", mockOpNode.URL)

	// Create OpNodeRollupClient
	client, err := verification.NewOpNodeRollupClient(mockOpNode.URL)
	require.NoError(t, err, "Failed to create op-node client")
	defer client.Close()

	// Test 1: Get OutputRootProof
	t.Run("GetOutputRootProof", func(t *testing.T) {
		ctx := context.Background()
		blockNum := uint64(100)

		proof, err := client.GetOutputRootProof(ctx, blockNum)
		require.NoError(t, err, "Failed to get OutputRootProof")
		require.NotNil(t, proof, "OutputRootProof should not be nil")

		t.Logf("✅ OutputRootProof fetched:")
		t.Logf("   Version: %x", proof.Version)
		t.Logf("   StateRoot: %s", proof.StateRoot.Hex())
		t.Logf("   MessagePasserStorageRoot: %s", proof.MessagePasserStorageRoot.Hex())
		t.Logf("   LatestBlockHash: %s", proof.LatestBlockHash.Hex())

		// Verify expected values
		expectedStateRoot := common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef")
		require.Equal(t, expectedStateRoot, proof.StateRoot, "StateRoot mismatch")
	})

	// Test 2: Hash OutputRootProof
	t.Run("HashOutputRootProof", func(t *testing.T) {
		proof := &verification.OutputRootProof{
			Version:                  [32]byte{},
			StateRoot:                common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"),
			MessagePasserStorageRoot: common.HexToHash("0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"),
			LatestBlockHash:          common.HexToHash("0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd"),
		}

		hash := verification.HashOutputRootProof(proof)
		require.NotEqual(t, common.Hash{}, hash, "Hash should not be zero")

		t.Logf("✅ OutputRootProof hash: %s", hash.Hex())
	})

	// Test 3: Verify OutputRootProof
	t.Run("VerifyOutputRootProof", func(t *testing.T) {
		proof := &verification.OutputRootProof{
			Version:                  [32]byte{},
			StateRoot:                common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"),
			MessagePasserStorageRoot: common.HexToHash("0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"),
			LatestBlockHash:          common.HexToHash("0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd"),
		}

		// Compute expected rootClaim
		expectedRootClaim := verification.HashOutputRootProof(proof)

		// Verify
		err := client.VerifyOutputRootProof(proof, expectedRootClaim)
		require.NoError(t, err, "OutputRootProof verification failed")

		t.Logf("✅ OutputRootProof verification passed")
	})

	// Test 4: Verify failure case
	t.Run("VerifyOutputRootProof_Mismatch", func(t *testing.T) {
		proof := &verification.OutputRootProof{
			Version:                  [32]byte{},
			StateRoot:                common.HexToHash("0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"),
			MessagePasserStorageRoot: common.HexToHash("0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321"),
			LatestBlockHash:          common.HexToHash("0xabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcdefabcd"),
		}

		// Use wrong rootClaim
		wrongRootClaim := common.HexToHash("0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef")

		// Verify should fail
		err := client.VerifyOutputRootProof(proof, wrongRootClaim)
		require.Error(t, err, "Verification should fail with wrong rootClaim")
		require.Contains(t, err.Error(), "hash mismatch", "Error should mention hash mismatch")

		t.Logf("✅ OutputRootProof verification correctly rejected mismatched rootClaim")
	})

	t.Log("=== Integration Test Summary ===")
	t.Log("✅ OutputRootProof 가져오기 성공")
	t.Log("✅ OutputRootProof 해싱 성공")
	t.Log("✅ OutputRootProof 검증 성공")
	t.Log("✅ 잘못된 rootClaim 거부 성공")
	t.Log("")
	t.Log("🎉 State Root as Target 플로우 동작 확인 완료!")
}
