# 1. 프로젝트 개요

## 목적

Advanced Slash 시스템은 **Optimism Fault Proof 메커니즘**과 **TON Staking V3**를 통합하여, 잘못된 L2 Output Proposal을 제출한 Operator를 슬래싱하고, 이를 성공적으로 Challenge한 **모든 참여자에게 보상을 균등 분배**하는 시스템이다.

### 핵심 목표

1. **공정성**: 모든 승리한 Challenger에게 균등한 보상 제공
2. **투명성**: 온체인에서 모든 승자를 추적 가능
3. **효율성**: 최소한의 Gas 비용으로 다중 참여자 보상
4. **확장성**: 향후 가중치 기반 보상 시스템으로 확장 가능

---

## 기존 시스템의 문제

```
기존 구조 (단일 Challenger):

Layer2Manager_Slashing.slashingCandidate()
    ↓
_getWinningChallenger() → claimData(0).counteredBy  ← 첫 번째 counter만 기록
    ↓
DepositManager.slash(challenger) → 단일 보상

문제점:
- 첫 번째 counter만 기록됨
- 나머지 Challenger들은 보상 받지 못함
- 불공정한 인센티브 구조
```

---

## 해결 방안

외부 `WinningChallengerTracker` 컨트랙트를 도입하여:

- `resolveClaim()` 시점에 bond 수령자(= 승자)를 기록
- `gameCreator`(Proposer) 자동 필터링
- 중복 방지 메커니즘
- 슬래싱 시 기록된 모든 승자에게 WTON을 균등 분배

**EVM 24KB 제한 대응**: FaultDisputeGame 내부에 tracking 로직을 넣으면 24KB를 초과하므로, 별도 외부 컨트랙트(`WinningChallengerTracker`)로 분리하여 해결.

---

## 구현 진행 상태

| Phase | 내용 | 상태 |
|-------|------|------|
| **Phase 1**: Tracking Layer | WinningChallengerTracker 컨트랙트 구현 | ✅ 완료 |
| **Phase 2**: Integration Layer | DisputeGameFactory, FaultDisputeGame 통합 | ✅ 완료 |
| **Phase 3**: Slashing Layer | Layer2Manager, DepositManager 다중 challenger 지원 | ✅ 완료 |
| **Phase 4**: Foundry 단위 테스트 | 24개 AdvancedSlashing + 38개 BasicSlashing | ✅ 전체 통과 |
| **Phase 5**: E2E 테스트 (Mock) | 41개 슬래싱 로직 테스트 (Anvil 기반) | ✅ 전체 통과 |
| **Phase 6**: E2E 테스트 (Real) | 11개 실제 FaultDisputeGame + op-challenger | ✅ 전체 통과 |

---

## 향후 확장 가능성 (미구현)

| 확장 | 설명 |
|------|------|
| **가중치 기반 보상** | bond 투입량, move 횟수, 참여 시각에 따라 차등 분배 |
| **시간 기반 인센티브** | 조기 참여자에게 보너스 (1시간 내 +20%, 6시간 내 +10%) |
| **멀티체인 지원** | Cross-chain challenger tracking |
| **Analytics** | 게임 통계 조회 함수 (`getGameStatistics`) |

보상 분배 대안 옵션 검토 문서: `docs-study/AdvancedSlash/anotherOption/` 참조
- Option A: 고정 비율 (첫 번째 50%, 나머지 균등)
- Option B: 보너스 + 균등 (첫 번째 보너스 + 나머지 균등)
- Option C: 가중치 기반 (bond 크기에 따른 가중치)

---

다음: [02-architecture.md](./02-architecture.md)
