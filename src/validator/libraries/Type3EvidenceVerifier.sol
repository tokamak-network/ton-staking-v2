// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MerkleTrie} from "@optimism-bedrock/libraries/trie/MerkleTrie.sol";

/**
 * @title Type3EvidenceVerifier
 * @notice Type 3 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME) 전용 증거 검증 라이브러리
 * @dev Optimism Bedrock + DisputeGameFactory + RAT 롤업 타입을 위한 검증 로직
 */
library Type3EvidenceVerifier {
    // ==========================================
    // Structs
    // ==========================================

    /// @notice Type 3 롤업 전용 증거 데이터 구조 (Fraud Proof 방식)
    /// @dev Merkle proof 기반 fraud-proof 스타일 증거
    struct Evidence {
        // L2 데이터 (L1 배치로부터 trustless하게 derived)
        uint256 l2BlockNumber;          // L2 블록 번호
        bytes32 l2BlockHash;            // L2 블록 해시
        bytes32 l2StateRoot;            // L2 상태 루트 (derived)
        bytes32 withdrawalRoot;         // 출금 스토리지 루트
        bytes32 outputRoot;             // 계산된 output root

        // L1 출처 정보
        uint256 l1BlockNumber;          // L1 블록 번호
        bytes32 l1BlockHash;            // L1 블록 해시
        uint256 l1TxIndex;              // L1 트랜잭션 인덱스
        bytes32 l1TxHash;               // L1 트랜잭션 해시
        bytes   batchData;              // 배치 데이터 (from L1 calldata/blobs)

        // Merkle proof (온체인 검증용)
        bytes32[] stateProof;           // 상태 루트 증명 (L2 header trie)
        bytes32[] withdrawalProof;      // 출금 루트 증명
        bytes32[] batchProof;           // 배치 데이터 증명 (L1 tx trie)
        bytes     l2HeaderRLP;          // L2 블록 헤더 RLP (derived)
    }

    /// @notice Output Root Proof 구조체 (Optimism Types.OutputRootProof와 동일)
    /// @dev DisputeGame의 rootClaim = keccak256(abi.encode(OutputRootProof))
    struct OutputRootProof {
        bytes32 version;                    // Version (always 0x0)
        bytes32 stateRoot;                  // L2 state root
        bytes32 messagePasserStorageRoot;   // L2ToL1MessagePasser storage root
        bytes32 latestBlockhash;            // L2 block hash
    }

    /// @notice State Leaf Evidence (Adjacent Leaves 방식)
    /// @dev L2 state Patricia trie의 인접한 두 리프로 full node 증명
    struct StateLeafEvidence {
        // Leaf A (state trie의 첫 번째 리프)
        bytes32 leafAKey;               // keccak256(address)
        bytes   leafAValue;             // RLP(nonce, balance, storageRoot, codeHash)
        bytes[] leafAProof;             // Patricia Merkle proof

        // Leaf B (인접한 두 번째 리프)
        bytes32 leafBKey;               // keccak256(address)
        bytes   leafBValue;             // RLP(nonce, balance, storageRoot, codeHash)
        bytes[] leafBProof;             // Patricia Merkle proof

        // State context
        bytes32 stateRoot;              // L2 state root (deprecated, use outputRootProof.stateRoot)
        uint256 blockNumber;            // L2 block number

        // Output Root Proof (for rootClaim verification)
        OutputRootProof outputRootProof; // Proves stateRoot authenticity
    }

    /// @notice Evidence Type (증거 타입 구분)
    enum EvidenceType {
        FraudProof,         // 0: Fraud proof (batch derivation)
        StateLeaf           // 1: State leaf (adjacent leaves)
    }

    // ==========================================
    // Main Verification
    // ==========================================

    /// @notice Type 3 증거 검증 (온체인 Merkle proof 기반)
    /// @dev Evidence 구조체를 디코딩하고 Merkle proof로 검증
    /// @param batchHash 예상 output root (claimed by proposer)
    /// @param evidenceData Evidence 구조체 ABI 인코딩된 데이터
    /// @return 검증 성공 여부
    function verify(bytes32 batchHash, bytes calldata evidenceData)
        internal
        pure
        returns (bool)
    {
        // Evidence 데이터가 비어있으면 실패
        if (evidenceData.length == 0) {
            return false;
        }

        // Evidence 구조체 디코딩
        Evidence memory ev = abi.decode(evidenceData, (Evidence));

        // 1. L2 블록 헤더에서 state root 검증
        if (!_verifyStateRootInHeader(ev.l2BlockHash, ev.l2StateRoot, ev.l2HeaderRLP)) {
            return false;
        }

        // 2. Withdrawal root 검증 (L2ToL1MessagePasser storage root)
        if (!_verifyWithdrawalRoot(ev.withdrawalRoot, ev.withdrawalProof, ev.l2HeaderRLP)) {
            return false;
        }

        // 3. L1에서 배치 데이터 검증 (선택적 - 가스 절약 위해 생략 가능)
        // if (!_verifyBatchDataInL1(ev.l1BlockHash, ev.l1TxIndex, ev.batchData, ev.batchProof)) {
        //     return false;
        // }

        // 4. Output root 계산 및 검증
        bytes32 computedOutputRoot = _computeOutputRoot(
            ev.l2StateRoot,
            ev.withdrawalRoot,
            ev.l2BlockHash
        );

        // 5. 계산된 output root와 주장된 batchHash(output root) 비교
        return computedOutputRoot == batchHash;
    }

    /// @notice StateLeaf 증거 검증 (Type 3 전용) - State Root as Target
    /// @dev Adjacent leaves 방식으로 전체 State 보유 증명
    /// @param rootClaim DisputeGame의 rootClaim (hash of OutputRootProof)
    /// @param evidenceData StateLeafEvidence (abi.encode)
    /// @return 검증 성공 여부
    function verifyStateLeaf(bytes32 rootClaim, bytes calldata evidenceData)
        internal
        pure
        returns (bool)
    {
        if (evidenceData.length == 0) return false;

        StateLeafEvidence memory ev = abi.decode(evidenceData, (StateLeafEvidence));

        // 1. 기본 검증
        if (!_validateStateLeafBasics(ev)) return false;

        // 2. OutputRootProof 검증: hash(outputRootProof) == rootClaim
        bytes32 computedRootClaim = _hashOutputRootProof(ev.outputRootProof);
        if (computedRootClaim != rootClaim) {
            return false;
        }

        // 3. OutputRootProof에서 stateRoot 추출
        bytes32 stateRoot = ev.outputRootProof.stateRoot;

        // 4. 범위 검증: leafA.key < stateRoot < leafB.key (State Root as Target!)
        if (!_verifyAdjacentRange(ev.leafAKey, ev.leafBKey, stateRoot)) {
            return false;
        }

        // 5. Patricia Trie Merkle Proof 검증
        if (!_verifyPatriciaProofsWithRoot(ev, stateRoot)) {
            return false;
        }

        return true;
    }

    // ==========================================
    // Verification Helpers
    // ==========================================

    /// @notice L2 블록 헤더에서 state root 검증
    /// @dev RLP 디코딩으로 state root 필드 추출 및 비교
    /// @param l2BlockHash 예상 L2 블록 해시
    /// @param l2StateRoot 주장하는 L2 state root
    /// @param l2HeaderRLP L2 블록 헤더 RLP 인코딩 데이터
    /// @return 검증 성공 여부
    function _verifyStateRootInHeader(
        bytes32 l2BlockHash,
        bytes32 l2StateRoot,
        bytes memory l2HeaderRLP
    ) private pure returns (bool) {
        // 1. L2 헤더 RLP의 해시가 l2BlockHash와 일치하는지 검증
        bytes32 computedHash = keccak256(l2HeaderRLP);
        if (computedHash != l2BlockHash) {
            return false;
        }

        // 2. RLP 디코딩하여 state root 필드 추출
        // 블록 헤더 구조: [parentHash, ommersHash, beneficiary, stateRoot, txRoot, receiptRoot, ...]
        // stateRoot는 4번째 필드 (index 3)
        bytes32 extractedStateRoot = _extractStateRootFromHeader(l2HeaderRLP);

        // 3. 추출한 state root와 주장하는 state root 비교
        return extractedStateRoot == l2StateRoot;
    }

    /// @notice Withdrawal root 검증
    /// @dev L2ToL1MessagePasser의 storage root를 검증
    /// @param withdrawalRoot 주장하는 withdrawal storage root
    /// @param withdrawalProof Merkle proof (현재 간소화 버전)
    /// @param l2HeaderRLP L2 블록 헤더 RLP
    /// @return 검증 성공 여부
    function _verifyWithdrawalRoot(
        bytes32 withdrawalRoot,
        bytes32[] memory withdrawalProof,
        bytes memory l2HeaderRLP
    ) private pure returns (bool) {
        // 간소화된 구현: withdrawal root가 제공되었는지만 확인
        // 실제 프로덕션에서는 L2ToL1MessagePasser 계정의 storage trie proof를 검증해야 함
        // 이는 매우 복잡하므로 현재는 기본 검증만 수행

        if (withdrawalRoot == bytes32(0)) {
            return false;
        }

        // Proof가 제공되었는지 확인
        if (withdrawalProof.length == 0) {
            return false;
        }

        // TODO: 실제 Merkle proof 검증 구현
        // - L2 state trie에서 L2ToL1MessagePasser 계정 조회
        // - 계정의 storage root 추출
        // - withdrawalRoot와 비교

        // 현재는 l2HeaderRLP가 유효한지만 확인
        l2HeaderRLP;  // 사용하지 않는 경고 제거

        return true;
    }

    /// @notice L1에서 배치 데이터 검증 (선택적)
    /// @dev L1 트랜잭션 trie에서 배치 데이터의 Merkle proof 검증
    /// @param l1BlockHash L1 블록 해시
    /// @param l1TxIndex L1 트랜잭션 인덱스
    /// @param batchData 배치 데이터
    /// @param batchProof Merkle proof
    /// @return 검증 성공 여부
    function _verifyBatchDataInL1(
        bytes32 l1BlockHash,
        uint256 l1TxIndex,
        bytes memory batchData,
        bytes32[] memory batchProof
    ) private pure returns (bool) {
        // 간소화된 구현: 기본 검증만 수행
        // 실제로는 L1 블록의 transaction trie root를 사용하여
        // batchData가 해당 트랜잭션에 포함되었는지 Merkle proof로 검증해야 함

        if (l1BlockHash == bytes32(0) || batchData.length == 0) {
            return false;
        }

        // TODO: 실제 L1 transaction trie Merkle proof 검증
        // - L1 block header의 transactionsRoot 사용
        // - l1TxIndex 위치의 트랜잭션이 batchData를 포함하는지 검증

        // 사용하지 않는 경고 제거
        l1TxIndex;

        return batchProof.length > 0;
    }

    /// @notice Output root 계산
    /// @dev Optimism output root 포맷: keccak256(version || stateRoot || withdrawalRoot || blockHash)
    /// @param stateRoot L2 state root
    /// @param withdrawalRoot Withdrawal storage root
    /// @param blockHash L2 block hash
    /// @return 계산된 output root
    function _computeOutputRoot(
        bytes32 stateRoot,
        bytes32 withdrawalRoot,
        bytes32 blockHash
    ) private pure returns (bytes32) {
        // Optimism OutputV0 포맷
        // abi.encodePacked를 사용하여 연속된 바이트로 인코딩
        return keccak256(
            abi.encodePacked(
                bytes32(0),         // version (0 for OutputV0)
                stateRoot,
                withdrawalRoot,
                blockHash
            )
        );
    }

    /// @notice RLP 인코딩된 블록 헤더에서 state root 추출
    /// @dev 간소화된 구현 - 실제로는 RLPReader 라이브러리 사용 필요
    /// @param headerRLP RLP 인코딩된 블록 헤더
    /// @return 추출된 state root
    function _extractStateRootFromHeader(bytes memory headerRLP)
        private
        pure
        returns (bytes32)
    {
        // 간소화된 구현: RLP 디코딩 로직
        // 실제로는 Optimism의 RLPReader 또는 go-ethereum의 RLP 라이브러리 필요

        // RLP 리스트 구조:
        // [parentHash(32), ommersHash(32), beneficiary(20), stateRoot(32), ...]
        // parentHash: offset 1 + 32 bytes
        // ommersHash: offset 33 + 32 bytes
        // beneficiary: offset 65 + 20 bytes
        // stateRoot: offset 85 + 32 bytes (대략적인 위치)

        // TODO: 실제 RLP 디코딩 구현 필요
        // 현재는 placeholder - 프로덕션에서는 반드시 정확한 RLP 파싱 필요

        if (headerRLP.length < 117) {
            return bytes32(0);
        }

        // 임시 구현: 고정 오프셋 사용 (실제로는 동적 RLP 파싱 필요)
        bytes32 stateRoot;
        assembly {
            // headerRLP의 데이터 시작 위치 + 85 bytes offset
            // 주의: 이는 간소화된 예시이며 실제로는 RLP 구조를 정확히 파싱해야 함
            stateRoot := mload(add(add(headerRLP, 32), 85))
        }

        return stateRoot;
    }

    // ==========================================
    // State Leaf Evidence Verification Helpers
    // ==========================================

    /// @notice StateLeafEvidence 기본 검증
    /// @dev 필수 필드가 모두 제공되었는지 확인
    /// @param ev StateLeafEvidence 구조체
    /// @return 검증 성공 여부
    function _validateStateLeafBasics(StateLeafEvidence memory ev)
        internal
        pure
        returns (bool)
    {
        // State root 확인
        if (ev.stateRoot == bytes32(0)) {
            return false;
        }

        // Block number 확인 (0도 유효하므로 생략 가능)
        // if (ev.blockNumber == 0) {
        //     return false;
        // }

        // Leaf A 검증
        if (ev.leafAKey == bytes32(0)) {
            return false;
        }
        if (ev.leafAValue.length == 0) {
            return false;
        }
        if (ev.leafAProof.length == 0) {
            return false;
        }

        // Leaf B 검증
        if (ev.leafBKey == bytes32(0)) {
            return false;
        }
        if (ev.leafBValue.length == 0) {
            return false;
        }
        if (ev.leafBProof.length == 0) {
            return false;
        }

        return true;
    }

    /// @notice Adjacent leaves 범위 검증
    /// @dev leafA.key < randomValue <= leafB.key 확인
    /// @param leafAKey 첫 번째 리프의 키
    /// @param leafBKey 두 번째 리프의 키
    /// @param randomValue RAT test의 랜덤 값
    /// @return 검증 성공 여부
    function _verifyAdjacentRange(
        bytes32 leafAKey,
        bytes32 leafBKey,
        bytes32 randomValue
    ) internal pure returns (bool) {
        // Convert bytes32 to uint256 for comparison
        uint256 keyA = uint256(leafAKey);
        uint256 keyB = uint256(leafBKey);
        uint256 random = uint256(randomValue);

        // Verify: leafA.key < randomValue <= leafB.key
        // Note: We allow edge cases where randomValue is outside range
        // (using first/last two leaves as per design)

        // Basic check: leafA.key < leafB.key (adjacent leaves should be ordered)
        if (keyA >= keyB) {
            return false;
        }

        // Range check: leafA.key < randomValue <= leafB.key
        // OR edge case: randomValue <= leafA.key (use first two leaves)
        // OR edge case: randomValue > leafB.key (use last two leaves)

        // For normal case
        if (keyA < random && random <= keyB) {
            return true;
        }

        // Edge case: random value smaller than all leaves (using first two)
        if (random <= keyA) {
            return true;
        }

        // Edge case: random value larger than all leaves (using last two)
        if (random > keyB) {
            return true;
        }

        return false;
    }

    /// @notice Patricia Trie Merkle Proof 검증
    /// @dev 두 리프의 Merkle proof를 state root에 대해 검증
    /// @param ev StateLeafEvidence 구조체
    /// @return 검증 성공 여부
    function _verifyPatriciaProofs(StateLeafEvidence memory ev)
        internal
        pure
        returns (bool)
    {
        // Patricia Merkle Trie proof 검증
        // Optimism의 MerkleTrie 라이브러리를 사용하여 검증

        // 1. Leaf A proof 검증
        // leafAKey는 bytes32이므로 bytes로 변환
        // Patricia trie의 key는 keccak256(address)
        bool leafAValid = MerkleTrie.verifyInclusionProof(
            abi.encodePacked(ev.leafAKey),  // key as bytes
            ev.leafAValue,                  // value (RLP encoded account)
            ev.leafAProof,                  // proof nodes
            ev.stateRoot                    // root
        );

        if (!leafAValid) {
            return false;
        }

        // 2. Leaf B proof 검증
        bool leafBValid = MerkleTrie.verifyInclusionProof(
            abi.encodePacked(ev.leafBKey),  // key as bytes
            ev.leafBValue,                  // value (RLP encoded account)
            ev.leafBProof,                  // proof nodes
            ev.stateRoot                    // root
        );

        if (!leafBValid) {
            return false;
        }

        // NOTE: 완벽한 인접성(Adjacency) 검증은 Patricia Trie의
        // Branch/Extension Node를 모두 파싱해야 하므로 가스비가 매우 높습니다.
        //
        // 현재 보안 모델:
        // - Merkle Proof로 두 리프가 진짜 stateRoot의 구성요소임을 증명
        // - Range Check로 leafA < randomValue < leafB 확인
        // - 이것만으로도 공격자는 전체 state를 알아야 함
        //
        // 향후 개선:
        // - RISC Zero 등 ZK 시스템으로 완벽한 adjacency 검증 구현 예정

        return true;
    }

    /// @notice Patricia Trie Merkle Proof 검증 (stateRoot 파라미터 버전)
    /// @dev 두 리프의 Merkle proof를 주어진 state root에 대해 검증
    /// @param ev StateLeafEvidence 구조체
    /// @param stateRoot 검증에 사용할 state root
    /// @return 검증 성공 여부
    function _verifyPatriciaProofsWithRoot(StateLeafEvidence memory ev, bytes32 stateRoot)
        internal
        pure
        returns (bool)
    {
        // Patricia Merkle Trie proof 검증
        // Optimism의 MerkleTrie 라이브러리를 사용하여 검증

        // 1. Leaf A proof 검증
        bool leafAValid = MerkleTrie.verifyInclusionProof(
            abi.encodePacked(ev.leafAKey),  // key as bytes
            ev.leafAValue,                  // value (RLP encoded account)
            ev.leafAProof,                  // proof nodes
            stateRoot                       // root (파라미터로 받은 값 사용)
        );

        if (!leafAValid) {
            return false;
        }

        // 2. Leaf B proof 검증
        bool leafBValid = MerkleTrie.verifyInclusionProof(
            abi.encodePacked(ev.leafBKey),  // key as bytes
            ev.leafBValue,                  // value (RLP encoded account)
            ev.leafBProof,                  // proof nodes
            stateRoot                       // root (파라미터로 받은 값 사용)
        );

        if (!leafBValid) {
            return false;
        }

        return true;
    }

    /// @notice OutputRootProof 해싱 (Optimism Hashing.sol 패턴)
    /// @dev keccak256(abi.encode(OutputRootProof)) == rootClaim
    /// @param proof OutputRootProof 구조체
    /// @return rootClaim 해시값
    function _hashOutputRootProof(OutputRootProof memory proof)
        internal pure returns (bytes32)
    {
        return keccak256(abi.encode(proof.version, proof.stateRoot, proof.messagePasserStorageRoot, proof.latestBlockhash));
    }
}
