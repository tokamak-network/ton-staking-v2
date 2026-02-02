---
id: overview
title: 테스트 개요
sidebar_position: 1
---

# TON Staking V3 테스트 목록

> **최종 업데이트**: 2026-01-27

## 테스트 ID 네이밍 규칙

| Prefix | 대상 컨트랙트/기능 | 설명 |
|--------|-------------------|------|
| SM | SeigManager | 시뇨리지 매니저 관련 테스트 |
| DM | DepositManager | 예치/출금 매니저 관련 테스트 |
| LBR | L1BridgeRegistry | L1 브릿지 레지스트리 관련 테스트 |
| L2M | Layer2Manager | Layer2 매니저 관련 테스트 |
| RAT | RAT (Random Attention Test) | 검증자 어텐션 테스트 관련 |
| VR | ValidatorReward | 검증자 보상 컨트랙트 관련 테스트 |
| MIG | Migration | V2→V3 마이그레이션 관련 테스트 |
| INT | Integration | 컨트랙트 간 통합 테스트 |
| SEC | Security | 보안/권한 관련 테스트 |
| SD | Seigniorage Distribution | 시뇨리지 분배 공식 검증 |
| INV | Invariant | 불변성 테스트 |
| E2E | End-to-End | 전체 시나리오 테스트 |
| EDGE | Edge Case | 경계값/엣지 케이스 테스트 |
| SCENSEQ | Scenario Sequencer | 시퀀서 시나리오 테스트 |
| SCENVAL | Scenario Validator | 검증자 시나리오 테스트 |
| GAS | Gas Measurement | 가스 비용 측정 테스트 |

**Suffix 규칙:**
- `-V2` / `-V3`: V2/V3 모드 구분
- `-Type2` / `-Type3`: rollupType 2/3 구분
- 숫자: 순차적 테스트 번호 (예: SM-001, SM-002)

## 전체 테스트 통계

### Solidity 테스트
- **총 테스트**: 526개 통과
- **커버리지**:
  - V3 실효 커버리지: 88.5% (lines)
  - 전체 시스템: 54.12% (lines, infrastructure 포함)
- **실행 시간**: ~2분

### Go 테스트
- **op-e2e 테스트**: 7개 (시스템 3개 + RAT 시나리오 3개 + RAT Client E2E 1개)
- **RAT Client 유닛 테스트**: 60개
- **총 Go 테스트**: 67개
- **실행 시간**:
  - op-e2e: ~80초
  - RAT Client 유닛: ~5초

### 총계
- **Solidity**: 526개
- **Go E2E**: 7개
- **Go Unit**: 60개
- **전체**: **593개 테스트**

---

## 다음 단계

상세한 테스트 내역은 각 카테고리별 문서를 참조하세요:

- [V2 모드 테스트](v2-mode-tests.md) - 44개 테스트
- [V3 모드 테스트](v3-mode-tests.md) - 493개 테스트
- [시나리오 테스트](scenario-tests.md) - 18개 테스트
- [Go E2E 테스트](e2e-tests.md) - 7개 테스트
- [RAT Client 유닛 테스트](rat-client-unit-tests.md) - 60개 테스트
