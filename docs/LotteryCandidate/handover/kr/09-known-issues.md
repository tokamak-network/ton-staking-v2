# 9. Known Issues / 기술 부채

[← 목차로 돌아가기](./README.md) | [← 이전: 보안 고려사항](./08-security.md)

---

## 9.1 확인된 이슈

### Issue #1: First-Call Trap

| 항목 | 내용 |
|------|------|
| **심각도** | 중간 |
| **상태** | 해결 (우회) |
| **위치** | `SeigManagerV3_2` (V2 모드) |
| **증상** | 첫 번째 `updateSeigniorage()` 호출 시 시뇨리지가 분배되지 않음 |
| **원인** | V2 모드에서 첫 호출은 `startBlock`만 설정하고 실제 보상 계산을 하지 않음 |
| **우회 방법** | `run-lottery-demo.sh`에서 배포 후 자동으로 `updateSeigniorage()` 1회 호출 |
| **근본 해결** | **아직 안 됨.** 컨트랙트 레벨에서 초기화 시 자동 호출하거나, 팩토리에서 처리하는 방안 검토 필요 |

### Issue #2: Same-Block Revert

| 항목 | 내용 |
|------|------|
| **심각도** | 낮음 |
| **상태** | 해결 (우회) |
| **위치** | `SeigManager` - `LastSeigBlockError` 체크 |
| **증상** | 배포와 `updateSeigniorage()`가 같은 블록에서 실행되면 revert |
| **우회 방법** | `run-lottery-demo.sh`에서 `sleep 2`로 블록 간격 확보 |
| **비고** | Anvil의 `--block-time 1` 설정에서만 발생. 메인넷에서는 자연스럽게 블록 간격 존재 |

### Issue #3: UI 정밀도 문제

| 항목 | 내용 |
|------|------|
| **심각도** | 낮음 |
| **상태** | 해결 |
| **위치** | `demo-frontend/src/components/SeignioragePanel.tsx` |
| **증상** | 매우 작은 시뇨리지 금액(~0.000000194 WTON)이 `toFixed(4)`로 표시 시 "0.0000"으로 보임 |
| **해결** | 과학적 표기법(`1.94e-7`) + nWTON 근사값(`~0.19 nWTON`) 이중 표시 구현 |

### Issue #4: 난수 생성 보안

| 항목 | 내용 |
|------|------|
| **심각도** | 높음 (메인넷) / 낮음 (데모) |
| **상태** | 미해결 |
| **위치** | `src/dao/LotteryCandidate.sol` - `drawWinner()` |
| **증상** | `block.prevrandao` 기반 의사 난수는 블록 생성자가 조작 가능 |
| **필요 조치** | 메인넷 배포 전 Chainlink VRF 통합 필수 |
| **상세** | [보안 고려사항 8.1](./08-security.md#81-난수-생성-취약점-심각도-높음---메인넷) 참조 |

### Issue #5: 출금 UI 미구현

| 항목 | 내용 |
|------|------|
| **심각도** | 중간 |
| **상태** | 미해결 |
| **위치** | `demo-frontend/` |
| **증상** | `requestWithdrawal`, `processWithdrawal` ABI는 `abi.ts`에 정의되어 있으나 UI 컴포넌트 없음 |
| **필요 조치** | 출금 요청/처리 컴포넌트 구현 |

### Issue #6: 프론트엔드 ABI 수동 관리

| 항목 | 내용 |
|------|------|
| **심각도** | 낮음 |
| **상태** | 미해결 |
| **위치** | `demo-frontend/src/contracts/abi.ts` |
| **증상** | ABI가 Solidity 소스에서 자동 생성되지 않고 수동으로 작성됨 |
| **리스크** | 컨트랙트 변경 시 ABI 동기화 누락 가능 |
| **필요 조치** | Forge 빌드 아티팩트(`out/`)에서 ABI를 자동 추출하는 스크립트 작성 |

---

## 9.2 기술 부채

| # | 항목 | 설명 | 영향 |
|---|------|------|------|
| 1 | **Solidity 버전 불일치** | 메인 프로젝트는 `0.8.19`, LotteryCandidate 관련 파일은 `0.8.4` | 컴파일 시 호환성 경고, 최신 기능 사용 불가 |
| 2 | **프록시 스토리지 주의점** | `LotteryCandidateStorage`가 `ProxyStorage` 이후에 상속됨. 스토리지 슬롯 순서 주의 필수 | 업그레이드 실수 시 데이터 손상 가능 |
| 3 | **_depositors 배열 비삭제** | 잔액이 0이 된 예치자도 `_depositors` 배열에서 제거되지 않음 | 대규모 예치자 시 시뇨리지 분배 가스 비용 폭증 |
| 4 | **totalDeposited/Coinage 불일치** | `_balances` 합계(`totalDeposited`)와 Coinage `totalSupply`가 시뇨리지 타이밍에 따라 일시적 불일치 | 정확한 지분 계산에 영향 가능 |
| 5 | **하드코딩된 로컬 체인** | `wagmi.ts`에 Anvil 체인(ID: 31337)만 설정됨 | 테스트넷/메인넷 배포 시 코드 수정 필요 |
| 6 | **SimpleMockDAOProxy** | 데모 배포에서 간략화된 DAO 프록시 사용 | 프로덕션에서는 정식 DAO 프록시로 교체 필요 |

---

## 9.3 시뇨리지 트러블슈팅 가이드

시뇨리지가 분배되지 않는 경우 4가지 원인을 순서대로 확인:

### 원인 1: 블록 간격 부족
- **증상:** `updateSeigniorage()` 트랜잭션 성공하지만 잔액 변화 없음
- **원인:** 마지막 호출 이후 충분한 블록이 생성되지 않음 (`span = currentBlock - lastSeigBlock`)
- **해결:** 블록이 더 지난 후 재시도 (데모에서는 Dev Tools의 "Advance Blocks" 사용)

### 원인 2: First-Call Trap
- **증상:** 최초 1회 호출 시 보상 0
- **원인:** V2 모드 첫 호출은 `startBlock`만 설정
- **해결:** 2번째 호출부터 정상 동작. `run-lottery-demo.sh`가 자동 처리

### 원인 3: 오퍼레이터 최소 스테이킹 미달
- **증상:** 트랜잭션 성공하지만 보상 0
- **원인:** 오퍼레이터(LotteryCandidate) 잔액이 `SeigManager.minimumAmount()` 미만
- **해결:** 충분한 금액 예치 확인 (데모: 1001 TON 이상)

### 원인 4: Silent Success
- **증상:** 트랜잭션 성공 = 보상 분배 성공이 아님
- **원인:** `SeigManager.updateSeigniorageV2()`는 보상이 0이어도 `true` 반환
- **해결:** 실제 잔액 변화를 확인해야 함

> **상세 문서:**
> - `docs/LotteryCandidate/seigniorage-troubleshooting.md`
> - `docs/LotteryCandidate/seigniorage-update-report.md`

---

[다음: 향후 개선 포인트 →](./10-future-improvements.md)
