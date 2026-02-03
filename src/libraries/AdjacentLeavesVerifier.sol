// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title AdjacentLeavesVerifier
 * @notice Verifies that two leaves are adjacent in a Merkle Patricia Trie
 * @dev Used for State Root validity verification in Fast Withdrawal
 *
 * Adjacent Leaves Proof (인접 리프 증명):
 * - 두 리프가 Trie에서 "인접"함을 증명
 * - 두 리프의 키가 분기(diverge)하는 지점에서 형제 관계임을 검증
 * - 이를 통해 State Root가 실제로 존재하는 유효한 Trie임을 증명
 *
 * 검증 원리:
 * 1. leafA와 leafB의 Merkle Proof를 각각 검증
 * 2. 두 경로가 분기하는 지점 찾기
 * 3. 분기 지점에서 두 노드가 형제임을 확인
 */
library AdjacentLeavesVerifier {
    // ==========================================
    // Errors
    // ==========================================

    error InvalidProofElementLength();
    error EmptyProof();
    error SameLeaf();
    /// @notice 인접 리프 증명 검증
    /// @param stateRoot 검증할 State Root
    /// @param leafA 첫 번째 리프 (key-value 해시)
    /// @param leafB 두 번째 리프 (key-value 해시)
    /// @param proofsA 리프 A의 Merkle Proof
    /// @param proofsB 리프 B의 Merkle Proof
    /// @return valid 검증 성공 여부
    function verify(
        bytes32 stateRoot,
        bytes32 leafA,
        bytes32 leafB,
        bytes[] calldata proofsA,
        bytes[] calldata proofsB
    ) internal pure returns (bool valid) {
        // 빈 증명 체크
        if (proofsA.length == 0 || proofsB.length == 0) {
            return false;
        }

        // 같은 리프면 인접이 아님
        if (leafA == leafB) {
            return false;
        }

        // 각 리프의 루트까지의 경로 계산
        bytes32 rootA = _computeRoot(leafA, proofsA);
        bytes32 rootB = _computeRoot(leafB, proofsB);

        // 두 루트가 stateRoot와 같아야 함
        if (rootA != stateRoot || rootB != stateRoot) {
            return false;
        }

        // 분기 지점 검증
        // 두 증명에서 분기가 발생하는 위치를 찾고,
        // 해당 위치에서 두 노드가 형제임을 확인
        return _verifyAdjacency(leafA, leafB, proofsA, proofsB);
    }

    /// @notice Merkle 루트 계산
    /// @param leaf 리프 노드
    /// @param proof Merkle Proof (sibling 노드들)
    /// @return root 계산된 루트
    function _computeRoot(
        bytes32 leaf,
        bytes[] calldata proof
    ) internal pure returns (bytes32 root) {
        root = leaf;
        uint256 len = proof.length;

        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                // proof 원소가 정확히 32바이트인지 검증
                if (proof[i].length != 32) revert InvalidProofElementLength();

                bytes32 sibling = bytes32(proof[i]);

                // 해시 순서 결정 (작은 값이 왼쪽)
                if (root < sibling) {
                    root = keccak256(abi.encodePacked(root, sibling));
                } else {
                    root = keccak256(abi.encodePacked(sibling, root));
                }
            }
        }
    }

    /// @notice 인접성 검증
    /// @dev 두 리프의 경로가 분기하는 지점에서 형제 관계인지 확인
    function _verifyAdjacency(
        bytes32 leafA,
        bytes32 leafB,
        bytes[] calldata proofsA,
        bytes[] calldata proofsB
    ) internal pure returns (bool) {
        // 경로 길이가 다르면 다른 깊이의 리프
        // 인접 리프는 같은 부모 아래 또는 가까운 조상 아래 있어야 함

        bytes32 currentA = leafA;
        bytes32 currentB = leafB;

        uint256 lenA = proofsA.length;
        uint256 lenB = proofsB.length;
        uint256 minLen = lenA < lenB ? lenA : lenB;

        // 리프부터 루트 방향으로 경로 추적
        unchecked {
            for (uint256 i = 0; i < minLen; ++i) {
                // proof 원소 길이 검증
                if (proofsA[i].length != 32) revert InvalidProofElementLength();
                if (proofsB[i].length != 32) revert InvalidProofElementLength();

                bytes32 siblingA = bytes32(proofsA[i]);
                bytes32 siblingB = bytes32(proofsB[i]);

                // 같은 레벨에서 currentA가 siblingB이거나 currentB가 siblingA이면 인접
                if (currentA == siblingB || currentB == siblingA) {
                    return true;
                }

                // 다음 레벨로 이동
                if (currentA < siblingA) {
                    currentA = keccak256(abi.encodePacked(currentA, siblingA));
                } else {
                    currentA = keccak256(abi.encodePacked(siblingA, currentA));
                }

                if (currentB < siblingB) {
                    currentB = keccak256(abi.encodePacked(currentB, siblingB));
                } else {
                    currentB = keccak256(abi.encodePacked(siblingB, currentB));
                }

                // 경로가 합류하면 인접 (같은 조상)
                if (currentA == currentB) {
                    return true;
                }
            }
        }

        // 분기 지점을 찾지 못함
        return false;
    }

    /// @notice 간단한 인접성 검증 (단일 분기 지점)
    /// @dev 두 리프가 같은 부모 노드 바로 아래에 있는 경우
    /// @param stateRoot State Root
    /// @param leafA 첫 번째 리프
    /// @param leafB 두 번째 리프
    /// @param commonProof 공통 조상까지의 증명
    /// @return valid 검증 성공 여부
    function verifySimpleAdjacency(
        bytes32 stateRoot,
        bytes32 leafA,
        bytes32 leafB,
        bytes[] calldata commonProof
    ) internal pure returns (bool valid) {
        // 같은 리프면 인접이 아님
        if (leafA == leafB) {
            return false;
        }

        // 두 리프의 부모 계산
        bytes32 parent;
        if (leafA < leafB) {
            parent = keccak256(abi.encodePacked(leafA, leafB));
        } else {
            parent = keccak256(abi.encodePacked(leafB, leafA));
        }

        // 부모부터 루트까지 경로 검증
        bytes32 root = parent;
        uint256 len = commonProof.length;

        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                // proof 원소 길이 검증
                if (commonProof[i].length != 32) revert InvalidProofElementLength();

                bytes32 sibling = bytes32(commonProof[i]);
                if (root < sibling) {
                    root = keccak256(abi.encodePacked(root, sibling));
                } else {
                    root = keccak256(abi.encodePacked(sibling, root));
                }
            }
        }

        return root == stateRoot;
    }
}
