// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "forge-std/Test.sol";
import {AdjacentLeavesVerifier} from "../../src/libraries/AdjacentLeavesVerifier.sol";

/**
 * @title AdjacentLeavesVerifierWrapper
 * @notice Wrapper contract to call library functions with calldata
 */
contract AdjacentLeavesVerifierWrapper {
    function verify(
        bytes32 stateRoot,
        bytes32 leafA,
        bytes32 leafB,
        bytes[] calldata proofsA,
        bytes[] calldata proofsB
    ) external pure returns (bool) {
        return AdjacentLeavesVerifier.verify(stateRoot, leafA, leafB, proofsA, proofsB);
    }

    function verifySimpleAdjacency(
        bytes32 stateRoot,
        bytes32 leafA,
        bytes32 leafB,
        bytes[] calldata commonProof
    ) external pure returns (bool) {
        return AdjacentLeavesVerifier.verifySimpleAdjacency(stateRoot, leafA, leafB, commonProof);
    }
}

/**
 * @title AdjacentLeavesVerifierTest
 * @notice AdjacentLeavesVerifier 라이브러리 테스트
 */
contract AdjacentLeavesVerifierTest is Test {
    AdjacentLeavesVerifierWrapper public wrapper;

    // ==========================================
    // Test Data
    // ==========================================

    bytes32 constant LEAF_A = keccak256("leafA");
    bytes32 constant LEAF_B = keccak256("leafB");
    bytes32 constant LEAF_C = keccak256("leafC");
    bytes32 constant LEAF_D = keccak256("leafD");

    function setUp() public {
        wrapper = new AdjacentLeavesVerifierWrapper();
    }

    // ==========================================
    // Helper Functions
    // ==========================================

    function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encodePacked(a, b));
        } else {
            return keccak256(abi.encodePacked(b, a));
        }
    }

    function _buildSimpleTree() internal pure returns (
        bytes32 root,
        bytes32 nodeAB,
        bytes32 nodeCD
    ) {
        nodeAB = _hash(LEAF_A, LEAF_B);
        nodeCD = _hash(LEAF_C, LEAF_D);
        root = _hash(nodeAB, nodeCD);
    }

    // ==========================================
    // verifySimpleAdjacency Tests
    // ==========================================

    function test_verifySimpleAdjacency_siblings() public view {
        (bytes32 root, , bytes32 nodeCD) = _buildSimpleTree();

        bytes[] memory commonProof = new bytes[](1);
        commonProof[0] = abi.encodePacked(nodeCD);

        bool valid = wrapper.verifySimpleAdjacency(root, LEAF_A, LEAF_B, commonProof);
        assertTrue(valid, "A and B should be adjacent siblings");
    }

    function test_verifySimpleAdjacency_siblings_reversed() public view {
        (bytes32 root, , bytes32 nodeCD) = _buildSimpleTree();

        bytes[] memory commonProof = new bytes[](1);
        commonProof[0] = abi.encodePacked(nodeCD);

        bool valid = wrapper.verifySimpleAdjacency(root, LEAF_B, LEAF_A, commonProof);
        assertTrue(valid, "B and A (reversed) should be adjacent siblings");
    }

    function test_verifySimpleAdjacency_sameLeaf_fails() public view {
        (bytes32 root, , bytes32 nodeCD) = _buildSimpleTree();

        bytes[] memory commonProof = new bytes[](1);
        commonProof[0] = abi.encodePacked(nodeCD);

        bool valid = wrapper.verifySimpleAdjacency(root, LEAF_A, LEAF_A, commonProof);
        assertFalse(valid, "Same leaf should not be adjacent");
    }

    function test_verifySimpleAdjacency_wrongRoot_fails() public view {
        (, , bytes32 nodeCD) = _buildSimpleTree();
        bytes32 wrongRoot = keccak256("wrong root");

        bytes[] memory commonProof = new bytes[](1);
        commonProof[0] = abi.encodePacked(nodeCD);

        bool valid = wrapper.verifySimpleAdjacency(wrongRoot, LEAF_A, LEAF_B, commonProof);
        assertFalse(valid, "Wrong root should fail");
    }

    function test_verifySimpleAdjacency_noCommonProof() public view {
        bytes32 root = _hash(LEAF_A, LEAF_B);
        bytes[] memory emptyProof = new bytes[](0);

        bool valid = wrapper.verifySimpleAdjacency(root, LEAF_A, LEAF_B, emptyProof);
        assertTrue(valid, "Direct children of root should be adjacent");
    }

    // ==========================================
    // verify (Full) Tests
    // ==========================================

    function test_verify_siblings() public view {
        (bytes32 root, , bytes32 nodeCD) = _buildSimpleTree();

        bytes[] memory proofsA = new bytes[](2);
        proofsA[0] = abi.encodePacked(LEAF_B);
        proofsA[1] = abi.encodePacked(nodeCD);

        bytes[] memory proofsB = new bytes[](2);
        proofsB[0] = abi.encodePacked(LEAF_A);
        proofsB[1] = abi.encodePacked(nodeCD);

        bool valid = wrapper.verify(root, LEAF_A, LEAF_B, proofsA, proofsB);
        assertTrue(valid, "A and B should be verified as adjacent");
    }

    function test_verify_cousins() public view {
        (bytes32 root, bytes32 nodeAB, bytes32 nodeCD) = _buildSimpleTree();

        bytes[] memory proofsA = new bytes[](2);
        proofsA[0] = abi.encodePacked(LEAF_B);
        proofsA[1] = abi.encodePacked(nodeCD);

        bytes[] memory proofsC = new bytes[](2);
        proofsC[0] = abi.encodePacked(LEAF_D);
        proofsC[1] = abi.encodePacked(nodeAB);

        bool valid = wrapper.verify(root, LEAF_A, LEAF_C, proofsA, proofsC);
        assertTrue(valid, "A and C should be adjacent (share root)");
    }

    function test_verify_emptyProof_fails() public view {
        bytes32 root = keccak256("root");

        bytes[] memory emptyProof = new bytes[](0);
        bytes[] memory validProof = new bytes[](1);
        validProof[0] = abi.encodePacked(keccak256("sibling"));

        bool valid1 = wrapper.verify(root, LEAF_A, LEAF_B, emptyProof, validProof);
        bool valid2 = wrapper.verify(root, LEAF_A, LEAF_B, validProof, emptyProof);

        assertFalse(valid1, "Empty proofA should fail");
        assertFalse(valid2, "Empty proofB should fail");
    }

    function test_verify_sameLeaf_fails() public view {
        (bytes32 root, , bytes32 nodeCD) = _buildSimpleTree();

        bytes[] memory proofsA = new bytes[](2);
        proofsA[0] = abi.encodePacked(LEAF_B);
        proofsA[1] = abi.encodePacked(nodeCD);

        bool valid = wrapper.verify(root, LEAF_A, LEAF_A, proofsA, proofsA);
        assertFalse(valid, "Same leaf should fail");
    }

    function test_verify_wrongRoot_fails() public view {
        (, , bytes32 nodeCD) = _buildSimpleTree();
        bytes32 wrongRoot = keccak256("wrong");

        bytes[] memory proofsA = new bytes[](2);
        proofsA[0] = abi.encodePacked(LEAF_B);
        proofsA[1] = abi.encodePacked(nodeCD);

        bytes[] memory proofsB = new bytes[](2);
        proofsB[0] = abi.encodePacked(LEAF_A);
        proofsB[1] = abi.encodePacked(nodeCD);

        bool valid = wrapper.verify(wrongRoot, LEAF_A, LEAF_B, proofsA, proofsB);
        assertFalse(valid, "Wrong root should fail");
    }

    // ==========================================
    // Edge Cases
    // ==========================================

    function test_verify_differentProofLengths_notSupported() public view {
        // Note: Current implementation doesn't support unbalanced trees
        // where leaves are at different depths
        bytes32 nodeAB = _hash(LEAF_A, LEAF_B);
        bytes32 root = _hash(nodeAB, LEAF_C);

        bytes[] memory proofsA = new bytes[](2);
        proofsA[0] = abi.encodePacked(LEAF_B);
        proofsA[1] = abi.encodePacked(LEAF_C);

        bytes[] memory proofsC = new bytes[](1);
        proofsC[0] = abi.encodePacked(nodeAB);

        bool valid = wrapper.verify(root, LEAF_A, LEAF_C, proofsA, proofsC);
        // This returns false because the algorithm expects same-depth leaves
        assertFalse(valid, "Different depth leaves not supported by current implementation");
    }

    function test_verify_deepTree() public view {
        // Build a deeper balanced tree
        //              root
        //            /      \
        //        node1       node2
        //        /   \       /   \
        //       A     B     C     D

        bytes32 node1 = _hash(LEAF_A, LEAF_B);
        bytes32 node2 = _hash(LEAF_C, LEAF_D);
        bytes32 root = _hash(node1, node2);

        // Proof for A: [B, node2]
        bytes[] memory proofsA = new bytes[](2);
        proofsA[0] = abi.encodePacked(LEAF_B);
        proofsA[1] = abi.encodePacked(node2);

        // Proof for D: [C, node1]
        bytes[] memory proofsD = new bytes[](2);
        proofsD[0] = abi.encodePacked(LEAF_C);
        proofsD[1] = abi.encodePacked(node1);

        bool valid = wrapper.verify(root, LEAF_A, LEAF_D, proofsA, proofsD);
        assertTrue(valid, "A and D should be adjacent (share root)");
    }

    // ==========================================
    // Fuzz Tests
    // ==========================================

    function testFuzz_verifySimpleAdjacency_randomLeaves(
        bytes32 leafA,
        bytes32 leafB,
        bytes32 sibling
    ) public view {
        vm.assume(leafA != leafB);
        vm.assume(leafA != bytes32(0) && leafB != bytes32(0));

        bytes32 parent = _hash(leafA, leafB);
        bytes32 root = _hash(parent, sibling);

        bytes[] memory commonProof = new bytes[](1);
        commonProof[0] = abi.encodePacked(sibling);

        bool valid = wrapper.verifySimpleAdjacency(root, leafA, leafB, commonProof);
        assertTrue(valid, "Random adjacent leaves should verify");
    }

    function testFuzz_verify_sameLeaf_alwaysFails(bytes32 leaf) public view {
        vm.assume(leaf != bytes32(0));

        bytes[] memory proof = new bytes[](1);
        proof[0] = abi.encodePacked(keccak256("sibling"));

        bool valid = wrapper.verify(keccak256("root"), leaf, leaf, proof, proof);
        assertFalse(valid, "Same leaf should always fail");
    }
}
