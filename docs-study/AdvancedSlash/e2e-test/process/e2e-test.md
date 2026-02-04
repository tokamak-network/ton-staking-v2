현재까지 진행한 작업을 요약하면 다음과 같습니다:
진행 상황 요약: TON 스테이킹 V3 마이그레이션 - 슬래싱 후 재등록
지금까지의 작업
- E2E 테스트 중 TestSlashing_ReRegistrationAfterSlashing 테스트가 실패하는 원인을 분석했습니다. 이 문제는 시스템이 여전히 V2 모드(v3Migrated = false)이기 때문에 V2DelegatecallFailedError가 발생하는 것으로 확인되었습니다.
- DeployV3WithSlashingForDevnet.s.sol 스크립트가 V3 마이그레이션 로직으로 업데이트되었는지 확인했습니다:
  - _setupV3ParameterSelectors(): SeigManagerProxy에 V3 파라미터 세터를 등록합니다.
  - _setV3Parameters(): V3 파라미터(예: halfSaturationPoint, minStakingRatio, daoDistributionRatio 등)를 설정합니다.
  - _migrateToV3(): migrateToV3()를 호출하여 V3 로직을 활성화하고 v3Migrated = true로 설정합니다.
- MockFaultDisputeGame3.sol 계약이 move(), step(), resolveClaim() 기능으로 현실적인 게임 시뮬레이션을 지원하도록 업데이트되었는지 확인했습니다.
- BaseAdvancedSlashingTest.sol과 파생된 테스트 파일들(SingleChallengerTest.t.sol, MultiChallengerEqualDistributionTest.t.sol 등)이 업데이트된 MockFaultDisputeGame3를 제대로 사용하고 있는지 검토했습니다.
현재 작업 중인 사항
- E2E 테스트가 MockFaultDisputeGame3 계약의 변경 사항을 반영하도록 업데이트하고 있는 중입니다. 구체적으로는 다음과 같은 작업을 진행하고 있습니다:
  - BaseAdvancedSlashingTest.sol과 파생된 테스트 파일들이 MockFaultDisputeGame3의 새로운 게임 플로우와 승리한 챌린저 추적 기능을 제대로 처리하고 있는지 확인합니다.
  - Layer2Manager_Slashing 계약이 getWinningChallengers() 함수를 사용해 MockFaultDisputeGame3에서 승리한 챌린저들을 올바르게 추출하는지 확인합니다.
  - DepositManager_Slashing 계약이 모든 승리한 챌린저들에게 보상을 올바르게 분배하는지 확인하고, 나머지 금액 분배도 제대로 처리되는지 점검합니다.
다음 단계
1. BaseAdvancedSlashingTest.sol 업데이트:
   - _setupMultiChallengerGame 함수가 winningChallengerTracker와 함께 MockFaultDisputeGame3를 올바르게 초기화하는지 확인합니다.
   - addWinningChallenger 함수가 여러 챌린저들을 올바르게 추가하는지 확인합니다.
   - resolveClaim 및 resolve 함수가 현실적인 게임 플로우를 시뮬레이션하기 위해 올바른 순서로 호출되는지 확인합니다.
2. 파생 테스트 파일 업데이트:
   - SingleChallengerTest.t.sol: 단일 챌린저 시나리오를 올바르게 처리하고 보상이 올바르게 분배되는지 확인합니다.
   - MultiChallengerEqualDistributionTest.t.sol: 다중 챌린저 시나리오와 동일한 분배를 올바르게 처리하고 있는지 확인합니다.
   - RealisticGameFlowTest.t.sol: 여러 이동, 단계, 해결이 있는 현실적인 게임 플로우를 올바르게 시뮬레이션하고 있는지 확인합니다.
3. DepositManager_Slashing.sol 검증:
   - _distributeRewards 함수가 모든 승리한 챌린저들에게 보상을 올바르게 분배하는지 확인합니다.
   - 각 챌린저에 대해 ChallengerRewarded 이벤트가 발생하는지 확인합니다.
4. Layer2Manager_Slashing.sol 검증:
   - slashingCandidate 함수가 MockFaultDisputeGame3의 getWinningChallengers 함수를 사용해 승리한 챌린저들을 올바르게 추출하는지 확인합니다.
   - slashedDisputeGames 매핑이 중복 슬래싱을 방지하기 위해 올바르게 업데이트되는지 확인합니다.
5. E2E 테스트 실행 및 검증:
   - make devnet-allocs-offline 명령을 사용하여 제네시스 파일을 재생성합니다.
   - cd op-e2e && GOWORK=off go test -v ./slashing/... -timeout 180s 명령을 사용하여 테스트를 실행하고 모든 테스트가 통과하는지 확인합니다.
이러한 단계를 따름으로써 TON 스테이킹 V3 마이그레이션이 완료되었고, E2E 테스트들이 새로운 로직을 반영하여 슬래싱 후 재등록 기능이 제대로 작동하는지 확인할 수 있습니다