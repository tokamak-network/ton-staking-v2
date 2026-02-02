# TON Staking V3 시스템 명세서

> Tokamak Economics Whitepaper V2 (December 2025) 기반

## 문서 목록

| 문서 | 설명 |
|------|------|
| [01-system-overview.md](./01-system-overview.md) | 시스템 소개, V3 변경사항, 핵심 개념, 주요 흐름, 파라미터 |
| [02-system-architecture.md](./02-system-architecture.md) | 전체 아키텍처, 컨트랙트 의존성, 프록시 패턴, 롤업 타입, 데이터 흐름 |
| [03-contract-structure.md](./03-contract-structure.md) | 디렉토리 구조, 컨트랙트 상세, 스토리지 구조, 인터페이스, 상속 관계 |
| [04-contract-roles.md](./04-contract-roles.md) | 컨트랙트별 역할, 책임, 상호작용 (SeigManager, DepositManager, RAT 등) |
| [05-actors.md](./05-actors.md) | 액터 정의, 시퀀서/검증자 여정 가이드, 상호작용 |
| [06-function-specs.md](./06-function-specs.md) | 함수별 상세 설명, 파라미터, 동작 흐름, 이벤트 |
| [07-economics-whitepaper-summary.md](./07-economics-whitepaper-summary.md) | Tokamak Economics Whitepaper V2 요약 |
| [08-v2-to-v3-upgrade-guide.md](./08-v2-to-v3-upgrade-guide.md) | V2에서 V3로 업그레이드 가이드 |
| [09-layer2-registration-guide.md](./09-layer2-registration-guide.md) | Layer2 등록 가이드 |
| [10-v3-test-lists.md](./10-v3-test-lists.md) | V3 테스트 목록 |
| [11-seigniorage-update-cases.md](./11-seigniorage-update-cases.md) | 시뇨리지 업데이트 케이스 상세 분석 |
| [12-optimism-integration.md](./12-optimism-integration.md) | Optimism L2 통합 (RAT, SeigManager 연동) |
| [13-rat-client-specification.md](./13-rat-client-specification.md) | RAT Client 구현 및 운영 스펙 (통합 문서: 개요, 구현, 배포, 운영) |

## 핵심 컨트랙트

| 컨트랙트 | 역할 |
|---------|------|
| **SeigManagerV3_1** | 시뇨리지 계산 및 분배 (V3 핵심) |
| **DepositManagerV3** | TON/WTON 스테이킹 관리 |
| **Layer2ManagerV3** | L2 등록 및 Bridged TON 조회 |
| **L1BridgeRegistryV1_2** | 브릿지/포탈 등록, TVL 조회 |
| **RAT** | 검증자 등록, RAT 테스트, C_off 페널티 |
| **ValidatorRewardV1** | 검증자 보상 분배 |

## V3 핵심 변경사항

| 항목 | V2 | V3 |
|------|-----|-----|
| 시뇨리지 분배 기준 | L2 TVL | Bridged TON |
| 분배 함수 | 선형 | 쌍곡선 `y(x) = L·(x/(k+x))` |
| 자격 조건 | 최소 예치금 | `T_i ≥ max(θ·B_i, D_seq)` |
| 스테이커 시뇨리지 | 제공 | 미제공 |
| 검증자 보상 | 없음 | `α·S_i / |V_i|` |

## 핵심 파라미터

| 파라미터 | 기호 | 설명 |
|---------|------|------|
| `daoDistributionRatio` | d | DAO 분배 비율 |
| `minStakingRatio` | θ | 최소 스테이킹 비율 |
| `validatorDistributionRatio` | α | 검증자 분배 비율 |
| `halfSaturationPoint` | k | 반포화점 |
| `ratTriggerProbability` | π_a | RAT 트리거 확률 |
| `slashingPenalty` | C_off | 검증자 슬래싱 페널티 |
| `evidenceSubmissionPeriod` | - | 증거 제출 기간 |

## 관련 문서

- [deployment-guide.md](../deployment-guide.md): 배포 가이드
- [for-llm-kr/](../for-llm-kr/): LLM용 상세 명세서
