# Solidity 계약 구현

## 3.1 Type3EvidenceVerifier 라이브러리

### 3.1.1 핵심 구조체

**StateLeafEvidence**: Adjacent Leaves 방식의 증거 구조
**OutputRootProof**: Optimism의 Output Root 포맷
**DivergenceWitness**: 분기점 노드 증명 (인접성 완벽 보장)

자세한 구조체 정의는 `src/validator/libraries/Type3EvidenceVerifier.sol` 참고.

### 3.1.2 검증 로직 단계

1. **기본 검증**: 필드 존재성, 타입 체크
2. **OutputRootProof 검증**: `hash(outputRootProof) == rootClaim`
3. **범위 검증**: `leafA.key < stateRoot < leafB.key`
4. **Merkle Proof 검증**: leafA와 leafB가 stateRoot에 실제로 존재
5. **Divergence 검증**: leafA와 leafB 사이에 다른 리프가 없음을 증명

## 3.2 RAT 계약 통합

### 증거 타입별 디스패처

- **Evidence Type 0**: FraudProof (batch derivation)
- **Evidence Type 1**: StateLeaf (adjacent leaves) ← **현재 사용**

`_verifyEvidenceWithType()` 함수에서 롤업 타입과 증거 타입에 따라 적절한 검증 로직 호출.

## 3.3 가스 최적화 전략

### 오프체인 vs 온체인 분업

| 작업 | 위치 | 복잡도 | 비고 |
|------|------|--------|------|
| Divergence node 계산 | 오프체인 | O(n) | 클라이언트가 계산 |
| IndexA, IndexB 추출 | 오프체인 | O(1) | 클라이언트가 계산 |
| Gap 사전 검증 | 오프체인 | O(k) | 실패 시 제출하지 않음 |
| Merkle proof 검증 | 온체인 | O(depth) | 필수 온체인 작업 |
| Divergence 검증 | 온체인 | O(k) | k = indexB - indexA |
| OutputRootProof 해싱 | 온체인 | O(1) | keccak256 1회 |

### 예상 가스 비용

- Merkle proof 검증 (x2): ~100,000 gas
- Divergence 검증: ~20,000 gas
- 기타 (range check, hashing): ~30,000 gas
- **Total: ~150,000 gas**

**기존 fraud proof 대비 1/3 수준의 가스 비용** 달성.

### 최적화 기법

1. **오프체인 사전 검증**: Gap이 유효하지 않으면 제출하지 않음
2. **Direct Divergence 권장**: indexA, indexB 슬롯이 직접 leaf로 가면 Gap 검증 불필요 (O(1))
3. **Storage SLOAD 최소화**: 필요한 데이터만 읽기

---

**다음**: [Go Client 구현](./04-go-client-implementation.md)
