# Slashing vs RAT E2E Test Analysis

본 문서는 `op-e2e` 폴더 내의 **Slashing 관련 테스트**와 **RAT(Reliability Available Token) 관련 테스트**의 차이점을 기술적으로 분석한 보고서입니다.

## 1. 분석 개요 (Analysis Overview)

Tokamak Network의 TON Staking V2 시스템에서 Slashing과 RAT은 보안 모델의 양축을 담당합니다. `op-e2e` 폴더의 테스트 코드들은 이 두 시스템이 실제 환경(L1/L2 연동)에서 어떻게 동작하는지 각각 다른 관점에서 검증합니다.

---

## 2. 테스트 목적 및 범위 비교 (Objective & Scope)

| 항목 | Slashing Tests (`op-e2e/slashing/`) | RAT Tests (`op-e2e/faultproofs/`) |
| :--- | :--- | :--- |
| **주요 목적** | **경제적 징벌 로직 검증** (Punitive Action) | **시스템 신뢰성 및 자산 보호 검증** (Reliability) |
| **핵심 시나리오** | 게임 종료 후 Operator의 지분을 실제로 삭감/소각 하는 과정 | 부정 클레임 발생 시 RAT이 정상적으로 트리거되고, 정직한 참여자가 보상을 받는지 확인 |
| **타겟 컨트랙트** | `Layer2Manager_Slashing`, `DepositManager_Slashing`, `SeigManager_Slashing` | `RAT`, `DisputeGameFactory`, `FaultDisputeGame` |
| **검증 데이터** | WTON 잔액 변동, `accStaked` 0 처리, 보상 비율(10%) 계산 | RAT Test ID 생성, Validator 활성화 상태, ETH Bond 반환 여부 |

---

## 3. 기술적 세부 차이점 (Technical Details)

### 3.1 Slashing Tests: "The Penalty Mechanism"
`slashing_test.go`는 Slashing 전용 V2 컨트랙트 아키텍처를 집중적으로 테스트합니다.
- **특이점**: `connectSlashingContracts`를 통해 별도의 Slashing 전용 바인딩 컨트랙트들을 연결합니다.
- **검증 흐름**: 
    1.  Operator 등록 및 스테이킹.
    2.  Dispute Game 완료 후 `Layer2Manager.slashingCandidate` 호출.
    3.  **내부 호출 트리거**: `Layer2Manager` -> `DepositManager` -> `SeigManager` 순서로 이어지는 Slashing 체인 검증.
    4.  **결과**: Operator의 스테이크가 0이 되고, Challenger에게 10%의 WTON 보상이 정확히 지급되는지 확인.

### 3.2 RAT Tests: "The Surveillance & Protection"
`rat_challenge_test.go` 및 `rat_system_test.go`는 RAT 시스템의 전반적인 라이프사이클을 테스트합니다.
- **특이점**: `DisputeGameFactory` 생성 시 `RAT` 컨트랙트가 확률적으로(또는 설정에 따라 100%로) 트리거되는 메커니즘에 집중합니다.
- **검증 흐름**: 
    1.  Validator의 RAT 등록 및 활성화 상태 확인.
    2.  Dispute Game 생성 시 `AttentionTestTriggered` 이벤트 발생 확인.
    3.  게임 승리 후 `RAT.resolveClaim`을 통해 **잠겼던 본드(Deposit)가 안전하게 복구**되는지 확인.
    4.  **결과**: 정직한 검증인이 시스템 감시(RAT)로 인해 손해를 보지 않고, 오히려 ETH 보상을 획득하는 안정성 확인.

---

## 4. 분석 결과 요약 (Summary)

- **Slashing 테스트**는 **"누가, 얼마나, 어떻게 뺏기는가?"**라는 경제적 파손 로직의 정확성을 검증합니다.
- **RAT 테스트**는 **"누가 감시받고, 정직한 자는 어떻게 보호받는가?"**라는 시스템 운영의 신뢰성과 무결성을 검증합니다.

따라서 Slashing 테스트는 **Staking 회계(Accounting)** 관점에서, RAT 테스트는 **보안 감시(Surveillance)** 관점에서 설계되었습니다.

---

**분석 모델 (Analysis Model)**:
이 분석은 **Google DeepMind의 Gemini 3 Flash (Experimental)** 모델을 사용하여 수행되었습니다. 소스 코드의 정적 분석과 더불어 E2E 시나리오 상의 트랜잭션 흐름을 대조 분석하였습니다.
