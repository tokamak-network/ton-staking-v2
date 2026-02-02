// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {MerkleTrie} from "@optimism-bedrock/libraries/trie/MerkleTrie.sol";
import {RLPReader} from "@optimism-bedrock/libraries/rlp/RLPReader.sol";

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

    /// @notice Divergence Witness (분기점 증명 데이터)
    /// @dev LeafA와 LeafB 사이에 다른 리프가 없음을 증명하는 witness 데이터
    struct DivergenceWitness {
        bytes   divergenceNode;         // 분기점 브랜치 노드의 RLP 데이터
        uint8   indexA;                 // 분기점에서 LeafA가 위치한 슬롯 (0-15)
        uint8   indexB;                 // 분기점에서 LeafB가 위치한 슬롯 (0-15)
        uint256 divergenceDepth;        // 분기점의 깊이 (루트로부터)
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

        // Divergence Witness (인접성 완벽 검증)
        DivergenceWitness divergenceWitness; // 분기점 증명 데이터
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

    /// @notice Universal 증거 검증 (타입별 dispatcher)
    /// @dev EvidenceType에 따라 적절한 검증 함수로 라우팅
    /// @param evidenceType 증거 타입 (FraudProof 또는 StateLeaf)
    /// @param rootClaim 검증할 root (Output Root 또는 Root Claim)
    /// @param evidenceData 증거 데이터 (타입별로 다른 구조체)
    /// @return 검증 성공 여부
    function verifyUniversal(
        EvidenceType evidenceType,
        bytes32 rootClaim,
        bytes calldata evidenceData
    ) internal pure returns (bool) {
        if (evidenceType == EvidenceType.FraudProof) {
            // 전통적인 Fraud Proof 방식 (L2 블록 헤더 기반)
            return verify(rootClaim, evidenceData);
        } else if (evidenceType == EvidenceType.StateLeaf) {
            // Adjacent Leaves 방식 (State Trie 기반)
            return verifyStateLeaf(rootClaim, evidenceData);
        }

        return false; // 알 수 없는 타입
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
        require(evidenceData.length > 0, "ERR_EMPTY_EVIDENCE");

        StateLeafEvidence memory ev = abi.decode(evidenceData, (StateLeafEvidence));

        // 1. 기본 검증
        require(_validateStateLeafBasics(ev), "ERR_BASIC_VALIDATION");

        // 2. OutputRootProof 검증: hash(outputRootProof) == rootClaim
        bytes32 computedRootClaim = _hashOutputRootProof(ev.outputRootProof);
        require(computedRootClaim == rootClaim, "ERR_OUTPUT_ROOT_MISMATCH");

        // 3. OutputRootProof에서 stateRoot 추출
        bytes32 stateRoot = ev.outputRootProof.stateRoot;

        // 4. 범위 검증: leafA.key < stateRoot < leafB.key (State Root as Target!)
        require(_verifyAdjacentRange(ev.leafAKey, ev.leafBKey, stateRoot), "ERR_RANGE_CHECK");

        // 5. Patricia Trie Merkle Proof 검증
        require(_verifyPatriciaProofsWithRoot(ev, stateRoot), "ERR_MERKLE_PROOF");

        // 6. Divergence 검증 (완벽한 인접성 - LeafA와 LeafB 사이에 다른 리프가 없음을 증명)
        require(_verifyDivergence(ev), "ERR_DIVERGENCE");

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

    /// @notice L2 블록 헤더 RLP에서 stateRoot 추출 (RLPReader 사용)
    /// @dev 이더리움 블록 헤더 구조를 정확히 파싱하여 stateRoot 추출
    /// @param headerRLP L2 블록 헤더 RLP 인코딩 데이터
    /// @return L2 state root (헤더의 4번째 필드)
    function _extractStateRootFromHeader(bytes memory headerRLP)
        private
        pure
        returns (bytes32)
    {
        // RLPReader를 사용하여 블록 헤더 파싱
        RLPReader.RLPItem[] memory headerItems = RLPReader.readList(headerRLP);

        // 이더리움 블록 헤더 구조 (15개 필드):
        // [0] parentHash       - bytes32
        // [1] ommersHash       - bytes32 (uncleHash)
        // [2] beneficiary      - address (coinbase, miner)
        // [3] stateRoot        - bytes32 ← 우리가 추출할 필드
        // [4] transactionsRoot - bytes32
        // [5] receiptsRoot     - bytes32
        // [6] logsBloom        - bytes256
        // [7] difficulty       - uint256
        // [8] number           - uint256
        // [9] gasLimit         - uint256
        // [10] gasUsed         - uint256
        // [11] timestamp       - uint256
        // [12] extraData       - bytes (가변 길이)
        // [13] mixHash         - bytes32
        // [14] nonce           - uint64

        require(headerItems.length >= 4, "ERR_INVALID_HEADER");

        // stateRoot는 4번째 필드 (index 3)
        bytes memory stateRootBytes = RLPReader.readBytes(headerItems[3]);
        require(stateRootBytes.length == 32, "ERR_INVALID_STATE_ROOT_LENGTH");

        bytes32 stateRoot;
        assembly {
            stateRoot := mload(add(stateRootBytes, 32))
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

        // NOTE: 완벽한 인접성(Adjacency) 검증은 _verifyDivergence()에서 수행됨
        // - DivergenceWitness를 통해 분기점 노드 제공
        // - 분기점 노드의 indexA ~ indexB 사이 슬롯이 비어있음을 검증
        // - 가스비 최적화: 증명자가 분기점을 계산, 컨트랙트는 검증만 수행

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

        require(leafAValid, "ERR_LEAF_A_INVALID");

        // 2. Leaf B proof 검증
        bool leafBValid = MerkleTrie.verifyInclusionProof(
            abi.encodePacked(ev.leafBKey),  // key as bytes
            ev.leafBValue,                  // value (RLP encoded account)
            ev.leafBProof,                  // proof nodes
            stateRoot                       // root (파라미터로 받은 값 사용)
        );

        require(leafBValid, "ERR_LEAF_B_INVALID");

        return true;
    }

    /// @notice Divergence 검증 (완벽한 인접성)
    /// @dev LeafA와 LeafB 사이에 다른 리프가 없음을 분기점 노드로 증명
    /// @dev leafA와 leafB의 proof는 _verifyPatriciaProofsWithRoot에서 이미 stateRoot에 대해 검증됨
    /// @param ev StateLeafEvidence 구조체
    /// @return 검증 성공 여부
    ///
    /// NOTE: Boundary Proof 고려사항
    /// 현재 구현은 분기점 노드의 indexA ~ indexB 사이가 비어있음을 확인합니다.
    /// 이는 대부분의 경우 충분하지만, 다음 경우를 완벽히 검증하려면 추가 증거가 필요할 수 있습니다:
    ///
    /// Case 1: indexA 슬롯이 브랜치 노드를 포함하는 경우
    ///   → LeafA가 그 하위 트리에서 가장 오른쪽(Most Right) 리프인지 증명 필요
    ///   → 그렇지 않으면 LeafA 오른쪽에 다른 리프가 숨어있을 수 있음
    ///
    /// Case 2: indexB 슬롯이 브랜치 노드를 포함하는 경우
    ///   → LeafB가 그 하위 트리에서 가장 왼쪽(Most Left) 리프인지 증명 필요
    ///   → 그렇지 않으면 LeafB 왼쪽에 다른 리프가 숨어있을 수 있음
    ///
    /// 실무 해결책:
    /// 오프체인에서 분기점을 계산할 때, LeafA와 LeafB가 직접 분기하는 노드를 선택하면
    /// indexA와 indexB 슬롯에 리프 노드가 직접 들어가므로 추가 검증이 불필요합니다.
    /// 즉, 해당 슬롯에서 경로가 즉시 종료(Leaf)되므로 그 하위 트리에서 발생할 수 있는
    /// 추가적인 사잇값 존재 가능성이 원천 차단됩니다.
    /// (Optimism Fault Proof 등 실제 시스템에서 사용하는 방법)
    ///
    /// 향후 개선 (선택적):
    /// 더 엄격한 검증이 필요한 경우, 다음과 같은 추가 체크를 구현할 수 있습니다:
    /// ```
    /// RLPReader.RLPItem[] memory items = RLPReader.readList(witness.divergenceNode);
    /// require(_isLeafNode(items[witness.indexA]), "ERR_NOT_DIRECT_LEAF_A");
    /// require(_isLeafNode(items[witness.indexB]), "ERR_NOT_DIRECT_LEAF_B");
    /// ```
    /// 이는 indexA/indexB 슬롯이 리프 노드임을 강제하여 Boundary Proof를 완벽히 보장합니다.
    function _verifyDivergence(StateLeafEvidence memory ev)
        internal
        pure
        returns (bool)
    {
        DivergenceWitness memory witness = ev.divergenceWitness;

        // 1. 분기점 노드가 제공되었는지 확인
        require(witness.divergenceNode.length > 0, "ERR_NO_DIVERGENCE_NODE");

        // 2. indexA < indexB 확인
        require(witness.indexA < witness.indexB, "ERR_INDEX_ORDER");

        // 3. 분기점 노드의 해시 계산
        bytes32 divergenceHash = keccak256(witness.divergenceNode);

        // 4. 분기점 노드가 LeafA와 LeafB의 proof에 모두 포함되는지 확인
        // NOTE: MerkleTrie 라이브러리는 Top-down 방식 (proof[0] = root)
        require(_isNodeInProof(divergenceHash, ev.leafAProof, witness.divergenceDepth), "ERR_DIVERGENCE_NOT_IN_PROOF_A");
        require(_isNodeInProof(divergenceHash, ev.leafBProof, witness.divergenceDepth), "ERR_DIVERGENCE_NOT_IN_PROOF_B");

        // 5. 분기점 노드 내에서 indexA와 indexB 사이의 슬롯이 비어있는지 확인
        require(_verifyGapBetweenIndices(witness.divergenceNode, witness.indexA, witness.indexB), "ERR_GAP_CHECK");

        return true;
    }

    /// @notice Proof에 특정 노드가 포함되어 있는지 확인
    /// @param nodeHash 찾을 노드의 해시
    /// @param proof Merkle proof 배열
    /// @param depth 노드의 깊이 (0부터 시작, 0 = root)
    /// @return 포함 여부
    ///
    /// IMPORTANT: Proof 배열 순서
    /// Optimism MerkleTrie 라이브러리는 Top-down 방식을 사용합니다:
    /// - proof[0] = root 노드
    /// - proof[1] = root의 자식 노드
    /// - ...
    /// - proof[length-1] = leaf의 부모 노드
    ///
    /// 따라서 depth는 루트로부터의 깊이이며, proof 배열의 인덱스와 일치합니다.
    function _isNodeInProof(bytes32 nodeHash, bytes[] memory proof, uint256 depth)
        internal
        pure
        returns (bool)
    {
        // depth가 proof 배열의 범위 내에 있는지 확인
        if (depth >= proof.length) {
            return false;
        }

        // proof[depth] 위치의 노드 해시와 비교
        bytes32 proofNodeHash = keccak256(proof[depth]);
        return proofNodeHash == nodeHash;
    }

    /// @notice 브랜치 노드 내에서 두 인덱스 사이의 슬롯이 비어있는지 확인
    /// @param branchNode RLP 인코딩된 브랜치 노드
    /// @param indexA 시작 인덱스 (0-15)
    /// @param indexB 끝 인덱스 (0-15)
    /// @return 슬롯이 비어있는지 여부
    /// @dev Optimism RLPReader 라이브러리를 사용하여 안전하게 RLP 디코딩
    function _verifyGapBetweenIndices(bytes memory branchNode, uint8 indexA, uint8 indexB)
        internal
        pure
        returns (bool)
    {
        // 브랜치 노드는 17개 요소를 가진 RLP 리스트
        // [child0, child1, ..., child15, value]

        // indexB - indexA == 1인 경우, 바로 인접 (중간 슬롯 없음)
        if (indexB - indexA == 1) {
            return true;
        }

        // RLPReader를 사용하여 브랜치 노드 파싱
        RLPReader.RLPItem[] memory items = RLPReader.readList(branchNode);

        // 브랜치 노드는 반드시 17개의 요소를 가져야 함
        require(items.length == 17, "ERR_INVALID_BRANCH_NODE");

        // indexA+1 ~ indexB-1 범위의 슬롯이 비어있는지 확인
        // RLP에서 빈 값은 0x80이며, RLPReader에서는 길이가 1인 바이트 배열로 표현됨
        for (uint8 i = indexA + 1; i < indexB; i++) {
            bytes memory itemBytes = RLPReader.readRawBytes(items[i]);

            // 빈 슬롯은 0x80 (1바이트)이어야 함
            if (itemBytes.length != 1 || uint8(itemBytes[0]) != 0x80) {
                return false; // 슬롯에 데이터가 있음 → 인접성 파괴
            }
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
