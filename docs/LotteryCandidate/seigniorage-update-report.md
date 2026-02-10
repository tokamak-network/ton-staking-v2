# LotteryCandidate 시뇨리지 업데이트 개선 보고서

본 문서는 `LotteryCandidate` 데모 환경에서 발생한 시뇨리지 업데이트 미작동 현상에 대한 기술적 분석과 해결 내용을 기록합니다.

## 1. 발생한 문제 (Issue)

### A. First-Call Trap (첫 호출 함정)
`SeigManagerV3_2` (V2 모드)의 설계상, 특정 Candidate에 대해 `updateSeigniorage()`를 처음 호출할 때는 보상을 분배하지 않고 **시작 블록(`startBlock`)을 설정**하는 역할만 수행합니다. 이로 인해 사용자가 데모 시작 후 처음 버튼을 눌렀을 때 아무런 변화가 없는 것처럼 보이는 현상이 발생했습니다.

### B. Same-Block Revert (동일 블록 실행 오류)
배포 스크립트(`DeployLotteryDemo.s.sol`) 내에서 `SeigManager` 초기화(`initialize`)와 `updateSeigniorage()` 호출이 동일한 블록 내에서 발생할 경우, `SeigManager`의 `LastSeigBlockError` (현재 블록이 마지막 업데이트 블록보다 커야 함)에 의해 트랜잭션이 revert 되었습니다.

### C. UI 표시 한계 (Precision Issue)
시뇨리지 발생량이 매우 적을 경우(예: 0.000000194 WTON), 프론트엔드의 `toFixed(4)` 포맷팅에 의해 `2000.0000`에서 값이 변하지 않는 것처럼 표시되었습니다.

---

## 2. 해결 내용 (Solutions)

### A. 자동 초기화 프로세스 도입 (`run-lottery-demo.sh`)
데모 실행 스크립트에 초기화 단계를 추가하여 사용자가 버튼을 누르기 전에 이미 `startBlock`이 설정되도록 수정했습니다.
- 배포 완료 후 `sleep 2`를 통해 Anvil에서 새로운 블록이 생성되도록 대기합니다.
- `cast send`를 사용하여 별도의 트랜잭션으로 `updateSeigniorage()`를 호출, 초기 설정을 완료합니다.

### B. 프론트엔드 UI/UX 개선 (`SeignioragePanel.tsx`)
사용자가 시뇨리지의 미세한 변화를 실시간으로 확인할 수 있도록 개선했습니다.
- **자동 Refetch**: 트랜잭션 성공(`updateSuccess`) 시 자동으로 데이터를 다시 불러오도록 `useEffect` 로직을 추가했습니다.
- **가변 소수점 표시**: 값이 매우 작을 경우 과학적 표기법(Scientific Notation)으로 표시하고, 나노 WTON(`nWTON`) 단위의 근사치를 함께 보여주어 아주 작은 변화도 감지할 수 있게 했습니다.
- **Raw Data 노출**: 디버깅 및 검증을 위해 `totalDeposited`의 원본 BigInt 값을 화면에 표시했습니다.
- **상태 안내**: 시뇨리지 증가분이 0인 경우(동일 블록에서 다시 호출 등), "블록을 더 생성한 후 시도하라"는 안내 메시지를 추가했습니다.

---

## 3. 검증 결과

- **컨트랙트 레벨**: `updateSeigniorage()` 호출 시 `totalDeposited`와 `balanceOf(operator)`가 약 `1.94e20` (0.000000194 WTON) 만큼 증가하는 것을 확인했습니다.
- **UI 레벨**: 업데이트 후 "You received: +1.9405e-7 (~0.19 nWTON)" 형태의 메시지가 정상적으로 표시되며, Raw 값이 즉시 갱신됩니다.

## 4. 향후 권장 사항
- 로컬 테스트 시에는 `SeignioragePanel` 하단의 **"Dev Tools: Advance Blocks"** 기능을 사용하여 충분한 블록(최소 100개 권장)을 생성한 후 시뇨리지를 청구하면 더욱 뚜렷한 숫자 변화를 확인할 수 있습니다.
