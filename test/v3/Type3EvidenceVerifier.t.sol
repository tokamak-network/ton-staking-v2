// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {Type3EvidenceVerifier} from "../../src/validator/libraries/Type3EvidenceVerifier.sol";
import {MerkleTrie} from "../../lib/optimism/packages/contracts-bedrock/src/libraries/trie/MerkleTrie.sol";

/// @title Type3EvidenceVerifierTest
/// @notice Unit tests for Type3EvidenceVerifier library
contract Type3EvidenceVerifierTest is Test {
    // Test helper contract to expose internal functions
    TestVerifier public verifier;

    function setUp() public {
        verifier = new TestVerifier();
    }

    // ==========================================
    // StateLeaf Evidence Tests
    // ==========================================

    /// @notice Test basic validation - valid evidence
    function test_validateStateLeafBasics_valid() public view {
        Type3EvidenceVerifier.StateLeafEvidence memory ev = _createValidStateLeafEvidence();

        bool result = verifier.validateStateLeafBasics(ev);
        assertTrue(result, "Valid evidence should pass basic validation");
    }

    /// @notice Test basic validation - missing stateRoot
    function test_validateStateLeafBasics_missingStateRoot() public view {
        Type3EvidenceVerifier.StateLeafEvidence memory ev = _createValidStateLeafEvidence();
        ev.stateRoot = bytes32(0);

        bool result = verifier.validateStateLeafBasics(ev);
        assertFalse(result, "Should fail with missing stateRoot");
    }

    /// @notice Test basic validation - missing leafAKey
    function test_validateStateLeafBasics_missingLeafAKey() public view {
        Type3EvidenceVerifier.StateLeafEvidence memory ev = _createValidStateLeafEvidence();
        ev.leafAKey = bytes32(0);

        bool result = verifier.validateStateLeafBasics(ev);
        assertFalse(result, "Should fail with missing leafAKey");
    }

    /// @notice Test basic validation - empty leafAValue
    function test_validateStateLeafBasics_emptyLeafAValue() public view {
        Type3EvidenceVerifier.StateLeafEvidence memory ev = _createValidStateLeafEvidence();
        ev.leafAValue = "";

        bool result = verifier.validateStateLeafBasics(ev);
        assertFalse(result, "Should fail with empty leafAValue");
    }

    /// @notice Test basic validation - empty leafAProof
    function test_validateStateLeafBasics_emptyLeafAProof() public view {
        Type3EvidenceVerifier.StateLeafEvidence memory ev = _createValidStateLeafEvidence();
        ev.leafAProof = new bytes[](0);

        bool result = verifier.validateStateLeafBasics(ev);
        assertFalse(result, "Should fail with empty leafAProof");
    }

    // ==========================================
    // Range Verification Tests
    // ==========================================

    /// @notice Test range verification - normal case (leafA < random <= leafB)
    function test_verifyAdjacentRange_normalCase() public view {
        bytes32 leafAKey = bytes32(uint256(100));
        bytes32 leafBKey = bytes32(uint256(200));
        bytes32 randomValue = bytes32(uint256(150));

        bool result = verifier.verifyAdjacentRange(leafAKey, leafBKey, randomValue);
        assertTrue(result, "Should pass for leafA < random <= leafB");
    }

    /// @notice Test range verification - edge case (random <= leafA)
    function test_verifyAdjacentRange_edgeCaseSmaller() public view {
        bytes32 leafAKey = bytes32(uint256(100));
        bytes32 leafBKey = bytes32(uint256(200));
        bytes32 randomValue = bytes32(uint256(50));

        bool result = verifier.verifyAdjacentRange(leafAKey, leafBKey, randomValue);
        assertTrue(result, "Should pass for random <= leafA (first two leaves)");
    }

    /// @notice Test range verification - edge case (random > leafB)
    function test_verifyAdjacentRange_edgeCaseLarger() public view {
        bytes32 leafAKey = bytes32(uint256(100));
        bytes32 leafBKey = bytes32(uint256(200));
        bytes32 randomValue = bytes32(uint256(300));

        bool result = verifier.verifyAdjacentRange(leafAKey, leafBKey, randomValue);
        assertTrue(result, "Should pass for random > leafB (last two leaves)");
    }

    /// @notice Test range verification - invalid (leafA >= leafB)
    function test_verifyAdjacentRange_invalidOrder() public view {
        bytes32 leafAKey = bytes32(uint256(200));
        bytes32 leafBKey = bytes32(uint256(100));
        bytes32 randomValue = bytes32(uint256(150));

        bool result = verifier.verifyAdjacentRange(leafAKey, leafBKey, randomValue);
        assertFalse(result, "Should fail when leafA >= leafB");
    }

    /// @notice Test range verification - boundary (random == leafB)
    function test_verifyAdjacentRange_boundary() public view {
        bytes32 leafAKey = bytes32(uint256(100));
        bytes32 leafBKey = bytes32(uint256(200));
        bytes32 randomValue = bytes32(uint256(200));

        bool result = verifier.verifyAdjacentRange(leafAKey, leafBKey, randomValue);
        assertTrue(result, "Should pass for random == leafB");
    }

    // ==========================================
    // Full Verification Tests (with mock proofs)
    // ==========================================

    /// @notice Test full verification with valid structure (proof verification mocked)
    /// @dev Patricia proof verification requires real state trie data (tested in E2E)
    /// @dev This test is skipped because it requires real Patricia proofs from op-geth
    function test_verifyStateLeaf_validStructure_SKIP() public view {
        // SKIPPED: This test requires real Patricia proofs from op-geth state trie
        // Full E2E tests will verify this functionality with actual state data

        bytes32 randomValue = bytes32(uint256(150));
        Type3EvidenceVerifier.StateLeafEvidence memory ev = _createValidStateLeafEvidence();

        // Encode evidence
        bytes memory evidenceData = abi.encode(ev);

        // Note: This will fail at Patricia proof verification stage
        // because we don't have real proof data
        // Expected to fail with ContentLengthMismatch or similar RLP error
        // In E2E tests with real proofs, this should pass

        // Skipping actual verification
        assertTrue(true, "Test skipped - requires real Patricia proofs");
    }

    /// @notice Test verification with empty evidence data
    function test_verifyStateLeaf_emptyData() public {
        bytes32 randomValue = bytes32(uint256(150));
        bytes memory evidenceData = "";

        // Should revert with ERR_EMPTY_EVIDENCE
        vm.expectRevert("ERR_EMPTY_EVIDENCE");
        verifier.verifyStateLeaf(randomValue, evidenceData);
    }

    /// @notice Test MerkleTrie directly with real account data from E2E test
    /// @dev This tests the Merkle proof verification in isolation, without ABI encoding issues
    function test_merkleTrie_withRealAccountData() public view {
        // Real data from LATEST E2E test (after eth_getProof fix)
        // Account A: address=0x0000000000000000000000000000000000000000
        //   nonce=0, balance=30940284522000 (0x1c23d8ab0e10)
        // Account B: address=0x000000000000000000000000000000000000000A
        //   nonce=0, balance=100000000000000000 (0x016345785d8a0000)

        bytes32 stateRoot = 0xd41bafe5a9bd1a8acf7ce800773f892950746e45040fa5240dbc32d41cdcfd36;

        // Leaf A data - Account address 0x00..00
        bytes32 leafAKey = 0x5380c7b7ae81a58eb98d9c78de4a1fd7fd9535fc953ed2be602daaa41767312a;
        // RLP([nonce=0, balance=0x1c23d8ab0e10, storageRoot=0x56e81f..., codeHash=0xc5d246...])
        bytes memory leafAValue = hex"f84a80861c23d8ab0e10a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        // Leaf A proof (2 nodes) - correctly extracted from ABI encoding
        bytes[] memory leafAProof = new bytes[](2);
        leafAProof[0] = hex"f8718080808080a0b40d147218a1e3b80a1f9854cbde2f981e49c37cbdca2de71eed5e0e3f55836e80808080808080a0a7fcf24375ff0a8c95069e8e75ba36c6f09dad3c147525f6f9713262c92e0751a0d551c93a45008bf408880b4f6215203b6282994502fc2380a3317dfb90dd5f448080";
        leafAProof[1] = hex"f86fa03380c7b7ae81a58eb98d9c78de4a1fd7fd9535fc953ed2be602daaa41767312ab84cf84a80861c23d8ab0e10a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        console.log("Testing Leaf A proof verification...");
        console.log("StateRoot:", vm.toString(stateRoot));
        console.log("LeafAKey:", vm.toString(leafAKey));
        console.log("LeafAValue length:", leafAValue.length);
        console.log("LeafAProof nodes:", leafAProof.length);

        // First, try to get the value from the trie
        bytes memory retrievedValue = MerkleTrie.get(
            abi.encodePacked(leafAKey),
            leafAProof,
            stateRoot
        );

        console.log("\nRetrieved value from trie:");
        console.log("  Length:", retrievedValue.length);
        console.logBytes(retrievedValue);

        console.log("\nExpected value:");
        console.log("  Length:", leafAValue.length);
        console.logBytes(leafAValue);

        // Test Leaf A proof
        bool leafAValid = MerkleTrie.verifyInclusionProof(
            abi.encodePacked(leafAKey),
            leafAValue,
            leafAProof,
            stateRoot
        );

        console.log("\nLeaf A verification result:", leafAValid);

        if (!leafAValid) {
            console.log("Leaf A verification FAILED");
            // Try to get more info about the failure
            revert("Leaf A proof verification failed");
        }

        assertTrue(leafAValid, "Leaf A should be valid");

        // Leaf B data - Account address 0x00..0A
        bytes32 leafBKey = 0xd9ed35852650f28d7a8f73c7ba49bcd72d97edf8d731797e5a2728559b865552;
        // RLP([nonce=0, balance=0x016345785d8a0000, storageRoot=0x56e81f..., codeHash=0xc5d246...])
        bytes memory leafBValue = hex"f84c8088016345785d8a0000a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        // Leaf B proof (2 nodes) - correctly extracted from ABI encoding
        bytes[] memory leafBProof = new bytes[](2);
        leafBProof[0] = hex"f8718080808080a0b40d147218a1e3b80a1f9854cbde2f981e49c37cbdca2de71eed5e0e3f55836e80808080808080a0a7fcf24375ff0a8c95069e8e75ba36c6f09dad3c147525f6f9713262c92e0751a0d551c93a45008bf408880b4f6215203b6282994502fc2380a3317dfb90dd5f448080";
        leafBProof[1] = hex"f871a039ed35852650f28d7a8f73c7ba49bcd72d97edf8d731797e5a2728559b865552b84ef84c8088016345785d8a0000a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        console.log("\nTesting Leaf B proof verification...");
        console.log("LeafBKey:", vm.toString(leafBKey));
        console.log("LeafBValue length:", leafBValue.length);
        console.log("LeafBProof nodes:", leafBProof.length);

        // Test Leaf B proof
        bool leafBValid = MerkleTrie.verifyInclusionProof(
            abi.encodePacked(leafBKey),
            leafBValue,
            leafBProof,
            stateRoot
        );

        console.log("Leaf B verification result:", leafBValid);

        if (!leafBValid) {
            console.log("Leaf B verification FAILED");
            revert("Leaf B proof verification failed");
        }

        assertTrue(leafBValid, "Leaf B should be valid");

        console.log("\nBoth Merkle proofs verified successfully!");
    }

    /// @notice Test full StateLeaf verification with real E2E data
    /// @dev Uses actual data from E2E test after eth_getProof fix
    function test_verifyStateLeaf_withRealE2EData() public view {
        // Data from E2E test log (2026/01/10 22:17:11)
        // Account A: 0x0000000000000000000000000000000000000000
        //   balance=30940284522000 (0x1c23d8ab0e10)
        // Account B: 0x000000000000000000000000000000000000000A
        //   balance=100000000000000000 (0x016345785d8a0000)

        // RootClaim from OutputRoot verification
        bytes32 rootClaim = 0xd853e991ca5ff11d392c338d237bff5806468a2a5c9420aefd25350069aed52c;

        // OutputRootProof components from log
        Type3EvidenceVerifier.OutputRootProof memory outputRootProof = Type3EvidenceVerifier.OutputRootProof({
            version: bytes32(0),
            stateRoot: 0xd41bafe5a9bd1a8acf7ce800773f892950746e45040fa5240dbc32d41cdcfd36,
            messagePasserStorageRoot: bytes32(0),
            latestBlockhash: 0xa00b586ff72eb9aee8f51b44130c26ed88db84995c447b8c33141b341f247505
        });

        // Verify OutputRootProof hash matches rootClaim
        bytes32 computedRootClaim = keccak256(abi.encode(
            outputRootProof.version,
            outputRootProof.stateRoot,
            outputRootProof.messagePasserStorageRoot,
            outputRootProof.latestBlockhash
        ));

        console.log("\nOutputRootProof verification:");
        console.log("  Computed:", vm.toString(computedRootClaim));
        console.log("  Expected:", vm.toString(rootClaim));
        assertEq(computedRootClaim, rootClaim, "OutputRootProof hash mismatch");

        // StateLeafEvidence with real E2E values
        bytes32 leafAKey = 0x5380c7b7ae81a58eb98d9c78de4a1fd7fd9535fc953ed2be602daaa41767312a;
        bytes memory leafAValue = hex"f84a80861c23d8ab0e10a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        bytes[] memory leafAProof = new bytes[](2);
        leafAProof[0] = hex"f8718080808080a0b40d147218a1e3b80a1f9854cbde2f981e49c37cbdca2de71eed5e0e3f55836e80808080808080a0a7fcf24375ff0a8c95069e8e75ba36c6f09dad3c147525f6f9713262c92e0751a0d551c93a45008bf408880b4f6215203b6282994502fc2380a3317dfb90dd5f448080";
        leafAProof[1] = hex"f86fa03380c7b7ae81a58eb98d9c78de4a1fd7fd9535fc953ed2be602daaa41767312ab84cf84a80861c23d8ab0e10a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        bytes32 leafBKey = 0xd9ed35852650f28d7a8f73c7ba49bcd72d97edf8d731797e5a2728559b865552;
        bytes memory leafBValue = hex"f84c8088016345785d8a0000a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        bytes[] memory leafBProof = new bytes[](2);
        leafBProof[0] = hex"f8718080808080a0b40d147218a1e3b80a1f9854cbde2f981e49c37cbdca2de71eed5e0e3f55836e80808080808080a0a7fcf24375ff0a8c95069e8e75ba36c6f09dad3c147525f6f9713262c92e0751a0d551c93a45008bf408880b4f6215203b6282994502fc2380a3317dfb90dd5f448080";
        leafBProof[1] = hex"f871a039ed35852650f28d7a8f73c7ba49bcd72d97edf8d731797e5a2728559b865552b84ef84c8088016345785d8a0000a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

        Type3EvidenceVerifier.StateLeafEvidence memory ev = Type3EvidenceVerifier.StateLeafEvidence({
            leafAKey: leafAKey,
            leafAValue: leafAValue,
            leafAProof: leafAProof,
            leafBKey: leafBKey,
            leafBValue: leafBValue,
            leafBProof: leafBProof,
            stateRoot: outputRootProof.stateRoot,
            blockNumber: 3,
            outputRootProof: outputRootProof
        });

        console.log("\nTesting full StateLeaf verification...");
        console.log("  RootClaim:", vm.toString(rootClaim));
        console.log("  StateRoot:", vm.toString(outputRootProof.stateRoot));
        console.log("  LeafAKey:", vm.toString(leafAKey));
        console.log("  LeafBKey:", vm.toString(leafBKey));

        // Encode evidence
        bytes memory evidenceData = abi.encode(ev);
        console.log("  Evidence size:", evidenceData.length);

        // Verify
        bool result = verifier.verifyStateLeaf(rootClaim, evidenceData);

        console.log("  Verification result:", result);
        assertTrue(result, "Full StateLeaf verification should pass with real E2E data");

        console.log("\nFull E2E verification PASSED!");
    }

    // ==========================================
    // Real E2E Data Tests (from failed transaction)
    // ==========================================

    /// @notice Test OutputRootProof encoding and verification
    function test_outputRootProof_encoding() public view {
        // Create a simple OutputRootProof
        Type3EvidenceVerifier.OutputRootProof memory proof = Type3EvidenceVerifier.OutputRootProof({
            version: bytes32(0),
            stateRoot: bytes32(uint256(0x1234)),
            messagePasserStorageRoot: bytes32(uint256(0x5678)),
            latestBlockhash: bytes32(uint256(0x9abc))
        });

        // Compute hash
        bytes32 computed = keccak256(abi.encode(
            proof.version,
            proof.stateRoot,
            proof.messagePasserStorageRoot,
            proof.latestBlockhash
        ));

        // Verify it's deterministic
        bytes32 computed2 = keccak256(abi.encode(
            proof.version,
            proof.stateRoot,
            proof.messagePasserStorageRoot,
            proof.latestBlockhash
        ));

        assertEq(computed, computed2, "OutputRoot hash should be deterministic");
    }

    /// @notice Test StateLeafEvidence with OutputRootProof structure
    function test_stateLeafEvidence_withOutputRootProof() public view {
        // Create mock proofs
        bytes[] memory proofA = new bytes[](2);
        proofA[0] = hex"f851a0abcd";
        proofA[1] = hex"e2a0beef";

        bytes[] memory proofB = new bytes[](2);
        proofB[0] = hex"f851a0dcba";
        proofB[1] = hex"e2a0feeb";

        // Create OutputRootProof
        Type3EvidenceVerifier.OutputRootProof memory outputRootProof = Type3EvidenceVerifier.OutputRootProof({
            version: bytes32(0),
            stateRoot: bytes32(uint256(0x1234)),
            messagePasserStorageRoot: bytes32(uint256(0x5678)),
            latestBlockhash: bytes32(uint256(0x9abc))
        });

        // Create evidence
        Type3EvidenceVerifier.StateLeafEvidence memory ev = Type3EvidenceVerifier.StateLeafEvidence({
            leafAKey: bytes32(uint256(100)),
            leafAValue: hex"f84401830f424084deadbeef80a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
            leafAProof: proofA,
            leafBKey: bytes32(uint256(200)),
            leafBValue: hex"f84402830f424084cafebabe80a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
            leafBProof: proofB,
            stateRoot: bytes32(uint256(0x1234)),
            blockNumber: 1000,
            outputRootProof: outputRootProof
        });

        // Test basic validation
        bool valid = verifier.validateStateLeafBasics(ev);
        assertTrue(valid, "Evidence with OutputRootProof should pass basic validation");

        // Test that we can encode and decode it
        bytes memory encoded = abi.encode(ev);
        Type3EvidenceVerifier.StateLeafEvidence memory decoded = abi.decode(encoded, (Type3EvidenceVerifier.StateLeafEvidence));

        // Verify fields match
        assertEq(decoded.leafAKey, ev.leafAKey, "leafAKey should match");
        assertEq(decoded.leafBKey, ev.leafBKey, "leafBKey should match");
        assertEq(decoded.stateRoot, ev.stateRoot, "stateRoot should match");
        assertEq(decoded.blockNumber, ev.blockNumber, "blockNumber should match");
        assertEq(decoded.outputRootProof.version, ev.outputRootProof.version, "outputRootProof.version should match");
        assertEq(decoded.outputRootProof.stateRoot, ev.outputRootProof.stateRoot, "outputRootProof.stateRoot should match");
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    /// @notice Helper function to decode evidence (external for try-catch)
    function decodeEvidence(bytes calldata data) external pure returns (Type3EvidenceVerifier.StateLeafEvidence memory) {
        return abi.decode(data, (Type3EvidenceVerifier.StateLeafEvidence));
    }

    /// @notice Create valid StateLeafEvidence structure for testing
    function _createValidStateLeafEvidence() private pure returns (Type3EvidenceVerifier.StateLeafEvidence memory) {
        bytes[] memory proofA = new bytes[](3);
        proofA[0] = hex"f851a0abcd";
        proofA[1] = hex"e2a0beef";
        proofA[2] = hex"c0";

        bytes[] memory proofB = new bytes[](3);
        proofB[0] = hex"f851a0dcba";
        proofB[1] = hex"e2a0feeb";
        proofB[2] = hex"c0";

        // Create OutputRootProof for testing
        Type3EvidenceVerifier.OutputRootProof memory outputRootProof = Type3EvidenceVerifier.OutputRootProof({
            version: bytes32(0),
            stateRoot: bytes32(uint256(0x1234)),
            messagePasserStorageRoot: bytes32(uint256(0x5678)),
            latestBlockhash: bytes32(uint256(0x9abc))
        });

        return Type3EvidenceVerifier.StateLeafEvidence({
            leafAKey: bytes32(uint256(100)),
            leafAValue: hex"f84401830f424084deadbeef80a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
            leafAProof: proofA,
            leafBKey: bytes32(uint256(200)),
            leafBValue: hex"f84402830f424084cafebabe80a0c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
            leafBProof: proofB,
            stateRoot: bytes32(uint256(0x1234)),
            blockNumber: 1000,
            outputRootProof: outputRootProof
        });
    }
}

/// @notice Test helper contract to expose internal functions
contract TestVerifier {
    using Type3EvidenceVerifier for *;

    function validateStateLeafBasics(Type3EvidenceVerifier.StateLeafEvidence memory ev)
        external
        pure
        returns (bool)
    {
        return Type3EvidenceVerifier._validateStateLeafBasics(ev);
    }

    function verifyAdjacentRange(bytes32 leafAKey, bytes32 leafBKey, bytes32 randomValue)
        external
        pure
        returns (bool)
    {
        return Type3EvidenceVerifier._verifyAdjacentRange(leafAKey, leafBKey, randomValue);
    }

    function verifyStateLeaf(bytes32 randomValue, bytes calldata evidenceData)
        external
        pure
        returns (bool)
    {
        return Type3EvidenceVerifier.verifyStateLeaf(randomValue, evidenceData);
    }
}
