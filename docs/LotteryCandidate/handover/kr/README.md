# LotteryCandidate 프로젝트 인수인계서

**작성일:** 2026-03-03
**작성자:** 기존 담당 개발자
**대상:** 후임 개발자
**프로젝트 브랜치:** `lotteryCandidate` (base: `ton-staking-v2`)
**최종 커밋:** `2ab17fa1` (Fixed seigniorage distribution error)

---

## 문서 구성

> 각 섹션은 독립적인 문서로 분리되어 있습니다.
> 처음 읽는 분은 1번부터 순서대로, 특정 주제가 필요하면 해당 문서만 참조하세요.

| # | 문서 | 설명 | 대상 |
|---|------|------|------|
| 1 | [프로젝트 개요](./01-project-overview.md) | 목적, 타겟 사용자, 핵심 기능 | 전체 |
| 2 | [시스템 아키텍처](./02-system-architecture.md) | 전체 구조도, 기술 스택, 외부 의존성 | 전체 |
| 3 | [디렉토리 구조](./03-directory-structure.md) | 폴더/파일 구조 및 역할 설명 | 전체 |
| 4 | [핵심 비즈니스 로직](./04-business-logic.md) | 예치/복권/시뇨리지/출금 데이터 흐름 | 백엔드 개발자 |
| 5 | [데이터 구조](./05-data-structure.md) | 스토리지 스키마, 상태 관리 방식 | 백엔드 개발자 |
| 6 | [API 명세](./06-api-specification.md) | 컨트랙트 함수/이벤트 전체 명세 | 백엔드 + 프론트 |
| 7 | [배포 및 운영](./07-deployment-operations.md) | 실행 방법, 환경 변수, 테스트 방법 | 운영/DevOps |
| 8 | [보안 고려사항](./08-security.md) | 보안 취약점 및 접근 제어 | 전체 |
| 9 | [Known Issues / 기술 부채](./09-known-issues.md) | 확인된 이슈, 기술 부채, 트러블슈팅 | 전체 |
| 10 | [향후 개선 포인트](./10-future-improvements.md) | 우선순위별 개선 항목 | PM/리드 |

---

## 온보딩 체크리스트 (3~7일 플랜)

### Day 1-2: 환경 설정 및 데모 실행
- [ ] 리포지토리 클론 (`git clone --recurse-submodules`)
- [ ] Foundry 설치 (`curl -L https://foundry.paradigm.xyz | bash && foundryup`)
- [ ] Node.js v18+ 설치
- [ ] `./run-lottery-demo.sh` 실행하여 전체 데모 동작 확인
- [ ] MetaMask에 Anvil 네트워크 추가 및 테스트 계정 import
- [ ] 예치 → 복권 참가 → 시뇨리지 클레임 → 추첨 플로우 직접 체험

### Day 3-4: 핵심 코드 이해
- [ ] [데이터 구조](./05-data-structure.md) → `LotteryCandidateStorage.sol` 스토리지 파악
- [ ] [비즈니스 로직](./04-business-logic.md) → `LotteryCandidate.sol` 핵심 흐름 분석
- [ ] `src/dao/factory/LotteryCandidateFactory.sol` 팩토리 패턴 이해
- [ ] `src/dao/DAOCommittee_V1.sol`의 `createLotteryCandidate()` 흐름 추적
- [ ] `test/v3/scenarios/LotteryCandidate.t.sol` 테스트 실행 및 분석
- [ ] 프록시 패턴 (`LotteryCandidateProxy` → `LotteryCandidate`) 이해

### Day 5-6: 시스템 연동 이해
- [ ] `DepositManager`와의 예치/출금 흐름 추적
- [ ] `SeigManager`와의 시뇨리지 생성/분배 메커니즘 이해
- [ ] [Known Issues](./09-known-issues.md) → 시뇨리지 트러블슈팅 가이드 숙지
- [ ] 프론트엔드 코드 (`demo-frontend/`) 구조 파악
- [ ] `script/DeployLotteryDemo.s.sol` 배포 순서 이해

### Day 7: 실습 및 확인
- [ ] 기존 테스트 전체 실행 (`forge test`) 및 통과 확인
- [ ] 간단한 테스트 케이스 추가해보기 (예: 3명 이상 참가자 복권)
- [ ] Known Issues 목록 확인 및 재현
- [ ] 질문 사항 정리

---

## 참고 문서

| 문서 | 경로 | 설명 |
|------|------|------|
| 프로젝트 README | `README.md` / `README_kr.md` | TON Staking V3 전체 개요 |
| LotteryCandidate 개요 | `docs/LotteryCandidate/en/README.md` | LotteryCandidate 소개 |
| 컨트랙트 구조 | `docs/LotteryCandidate/en/contracts.md` | 컨트랙트 상세 설명 |
| 시나리오 문서 | `docs/LotteryCandidate/en/scenario.md` | 사용 시나리오 |
| 데모 가이드 (상세) | `docs/LotteryCandidate/kr/demo.md` | 가장 상세한 데모 가이드 |
| 시뇨리지 이슈 리포트 | `docs/LotteryCandidate/seigniorage-update-report.md` | 시뇨리지 버그 해결 기록 |
| 시뇨리지 트러블슈팅 | `docs/LotteryCandidate/seigniorage-troubleshooting.md` | 시뇨리지 문제 해결 가이드 |
| V3 시스템 사양서 | `docs/specs-kr/` | 전체 시스템 사양 (12개 파일) |
| 테스트 문서 | `docs/test/` | 테스트 가이드 (8개 파일) |
| 배포 가이드 | `docs/deployment/` | 배포 상세 가이드 |
| 화이트페이퍼 | `docs/*.pdf` | Tokamak Economics V1~V3 |

---

*이 문서는 2026-03-03 기준으로 작성되었으며, 코드 변경 시 업데이트가 필요합니다.*
