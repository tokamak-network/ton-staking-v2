# 개요

**작성일**: 2026-01-30
**버전**: 4.0
**대상**: Type 3 롤업 (OPTIMISM_BEDROCK_WITH_DISPUTE_GAME)
**상태**: 통합 스펙 문서 (구현 + 운영)

## 1.1 RAT Client란?

RAT (Randomized Attention Test) Client는 **RollupType 3 롤업(Optimism Bedrock with Dispute Game)** 에서 검증자가 **full node를 운영하고 있음을 증명**하기 위한 오프체인 클라이언트입니다.

**핵심 목적**:
- **Liveness 검증**: 검증자가 L2 full archive node를 직접 운영 중임을 증명
- **Full State 보유 증명**: 전체 state trie 접근 능력 증명
- **Public RPC 사용 불가**: Self-hosted node with debug API 필수

**DisputeGame과의 차이**:
| 항목 | RAT Client | DisputeGame (Optimism) |
|------|-----------|------------------------|
| 검증 시간 | 즉시 ~ 수분 | 7일 |
| 복잡도 | 낮음 | 높음 |
| 비용 | 낮음 (1-2 tx) | 높음 (수십 tx) |
| 요구사항 | Full op-geth + debug API | L1만 사용 |
| 검증 내용 | Liveness (node 보유 + 모니터링) | Correctness (state 정확성) |
| 목적 | Fast path (99% 케이스) | Final safety (1% 의심 케이스) |

## 1.2 핵심 메커니즘: State Leaf Evidence

**State Root as Target** 방식:
- L2 state root를 랜덤값으로 사용
- State trie에서 **인접한 두 개의 account (leafA, leafB)** 를 찾아서 제출
- `leafA.key < stateRoot < leafB.key` 관계를 증명
- 두 리프 사이에 다른 리프가 없음을 **Divergence Witness**로 증명

**왜 State Root를 Target으로 사용하는가?**:
```
일반적인 방식 (예측 가능):
  - 특정 주소 지정 → validator가 미리 proof 준비 가능
  - Public RPC로도 가능
  - Full node 불필요

StateRoot 방식 (예측 불가능):
  - StateRoot = 32 bytes random hash
  - State trie에서 임의의 위치
  - 어떤 계정 쌍이 선택될지 사전에 알 수 없음
  - debug_accountRange로 전체 trie 순회 필요
  - Self-hosted archive node 필수!
```

## 1.3 왜 Adjacent Leaves인가?

| 기존 방식 (Single Merkle Proof) | Adjacent Leaves 방식 |
|-------------------------------|---------------------|
| ❌ Light node도 속일 수 있음 | ✅ Full state 필요 |
| ❌ 랜덤값에 해당하는 주소만 조회 | ✅ Trie 전체 스캔 필요 |
| ❌ 인접성 보장 없음 | ✅ Divergence witness로 완벽 증명 |

**결론**: Adjacent Leaves 방식은 검증자가 **전체 state trie를 보유**하고 있어야만 제출 가능한 증거입니다.

---

**다음**: [Adjacent Leaves 증명](./02-adjacent-leaves-proof.md)
