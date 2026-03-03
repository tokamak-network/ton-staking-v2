# Advanced Slashing 인수인계서

> **작성일**: 2026-03-03
> **프로젝트**: ton-staking-v2 / Advanced Slashing
> **브랜치**: `ton-staking-3/dev-slash-front2` (개발), `ton-staking-v2` (메인)

---

## 문서 구조

이 인수인계서는 주제별로 분리되어 있습니다. 처음 읽는 경우 번호 순서대로 읽는 것을 권장합니다.

| # | 문서 | 설명 | 대상 |
|---|------|------|------|
| 1 | [01-overview.md](./01-overview.md) | 프로젝트 개요, 목적, 기존 문제와 해결 방안 | 모든 사람 |
| 2 | [02-architecture.md](./02-architecture.md) | 시스템 아키텍처, 전체 흐름, 레이어 구조 | 모든 사람 |
| 3 | [03-contracts.md](./03-contracts.md) | 핵심 컨트랙트 변경 상세 (6개 컴포넌트) | 개발자 |
| 4 | [04-reward-logic.md](./04-reward-logic.md) | 승자 판정 기준, 보상 분배 공식, 보안 설계 | 개발자 |
| 5 | [05-build-deploy.md](./05-build-deploy.md) | 빌드, 배포 파이프라인, Go 파이프라인 | 개발자 / DevOps |
| 6 | [06-testing.md](./06-testing.md) | 테스트 가이드 (Foundry 62개, E2E 52개) | 개발자 / QA |
| 7 | [07-issues.md](./07-issues.md) | 해결된 주요 이슈, 제약사항, 주의사항 | 개발자 |
| 8 | [08-file-map.md](./08-file-map.md) | 전체 파일 경로 맵 (컨트랙트, 테스트, 배포) | 개발자 |
| 9 | [09-quickstart.md](./09-quickstart.md) | 새로운 담당자를 위한 빠른 시작 가이드 | 새 담당자 |

---

## 한 줄 요약

**Optimism Fault Proof에서 승리한 모든 Challenger에게 슬래싱 보상을 균등 분배하는 시스템.**

기존에는 첫 번째 counter만 보상을 받았으나, `WinningChallengerTracker` 외부 컨트랙트를 도입하여 모든 승리한 Challenger를 추적하고 WTON을 균등 분배한다.

---

## 구현 현황

| Phase | 상태 |
|-------|------|
| Tracking Layer (WinningChallengerTracker) | ✅ 완료 |
| Integration Layer (Factory, Game 통합) | ✅ 완료 |
| Slashing Layer (다중 challenger 보상 분배) | ✅ 완료 |
| Foundry 단위 테스트 (62개) | ✅ 전체 통과 |
| E2E 테스트 - Mock 기반 (41개) | ✅ 전체 통과 |
| E2E 테스트 - Real FaultDisputeGame (11개) | ✅ 전체 통과 |

---

## 상세 문서 참조

원본 설계/구현 문서는 `docs-study/AdvancedSlash/` 에 있음.
