# Slashing Test Guide (Modular V3)

이 문서는 모듈화된 슬래싱 테스트(`test/v3/v3mode/BasicSlashing/`)의 구성과 실행 방법에 대해 설명합니다.

## 1. 테스트 목적
Tokamak Network V3의 슬래싱 메커니즘이 다양한 시나리오(기본 운영, 위임자 보호, 다중 운영자 환경, 보안 취약점 공격 등)에서 의도한 대로 동작하는지 검증합니다.

## 2. 테스트 환경 구성
기본적으로 `BaseSlashingTest.sol`을 상속받아 테스트 환경을 구축합니다.
- **BaseSlashingTest**: TON/WTON 배포, 레이어2 등록, 헬퍼 함수(슬래싱 실행, 시뇨리지 업데이트 등)를 포함하여 코드 중복을 최소화합니다.
- **Mocking**: `MockDisputeGameFactory`, `MockFaultDisputeGame2`를 사용하여 실제 Dispute Game 없이도 슬래싱 조건을 시뮬레이션합니다.

## 3. 테스트 파일별 상세 정리

| 파일명 | 주요 테스트 내용 |
|--------|----------------|
| **SlashingBasicTest.t.sol** | 후보자 등록, 기본 슬래싱 프로세스, 이벤트 발생 검증 |
| **SlashingDelegatorTest.t.sol** | 운영자 슬래싱 시 위임자의 스테이크 및 시뇨리지 보호, 슬래싱 후 출금 가능 여부 |
| **SlashingRewardRateTest.t.sol** | 다양한 보상 비율(0%, 10%, 50%, 100%)에 따른 챌린저 보상 및 소각량 검증 |
| **SlashingSeigniorageTest.t.sol** | 미수령 시뇨리지가 있는 상태에서의 슬래싱 및 원금/수익 전액 소각 로직 |
| **SlashingSecurityTest.t.sol** | 중복 슬래싱 방지, 승자 외 보상 금지, 비인가 접근 차단 |
| **SlashingAttackVectorTest.t.sol**| Reentrancy 취약점 및 악의적인 Dispute Game 상태를 이용한 공격 시뮬레이션 |
| **SlashingMultiOperatorTest.t.sol**| 여러 운영자가 존재하는 환경에서의 독립적인 슬래싱 및 선착순 보상 원칙 |
| **SlashingEdgeCaseTest.t.sol** | 최소 스테이크 미달, 부분 출금 후 슬래싱, 잘못된 게임 상태 등 엣지 케이스 |

## 4. 테스트 실행 방법

### 특정 파일 실행 (권장)
모듈화되어 있으므로 관심 있는 기능만 빠르게 테스트할 수 있습니다.
```bash
# 위임자 보호 테스트만 실행
forge test --match-path test/v3/v3mode/BasicSlashing/SlashingDelegatorTest.t.sol -vvv

# 보안 관련 테스트만 실행
forge test --match-path test/v3/v3mode/BasicSlashing/SlashingSecurityTest.t.sol -vvv
```

### 전체 슬래싱 테스트 실행
```bash
# BasicSlashing 폴더 내의 모든 테스트 실행
forge test --match-path "test/v3/v3mode/BasicSlashing/*.t.sol" -vvv
```


## 5. 시나리오 비교 및 변경 이력
상세한 시나리오 매핑과 변경 사항은 [Slashing Test Scenario Comparison](./slashing-test-scenario-comparison.md)를 참조하십시오.
