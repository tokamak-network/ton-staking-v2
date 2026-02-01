# 슬래싱 E2E 테스트 아키텍처

## 🎯 핵심: Mock이 아닌 실제 Optimism 환경 테스트

슬래싱 E2E 테스트는 **실제 Optimism DisputeGameFactory와 FaultDisputeGame**을 사용하여 전체 슬래싱 프로세스를 검증합니다.

---

## 📊 테스트 환경 비교

### Forge 테스트 (Solidity) - 단위 테스트
**위치**: `test/Slashing/SlashingTest.t.sol`

```solidity
// Mock 컨트랙트 사용
MockDisputeGameFactory mockDGF;
MockFaultDisputeGame2 mockGame;

// 시뮬레이션된 환경
mockGame.setStatus(GameStatus.CHALLENGER_WINS);
```

**특징**:
- ✅ 빠른 실행 속도
- ✅ 단위 테스트에 적합
- ✅ 슬래싱 로직 검증
- ❌ 실제 Optimism 통합 검증 불가
- ❌ DisputeGame 생성/해결 프로세스 생략

---

### E2E 테스트 (Go) - 통합 테스트 ⭐
**위치**: `op-e2e/slashing/slashing_test.go`

```go
// 실제 Optimism 컨트랙트 사용
dgf := bindings.NewDisputeGameFactory(
    sys.Addresses.DisputeGameFactory,  // Genesis에서 배포된 실제 주소
    sys.L1Client                        // 실제 Anvil L1 클라이언트
)

// 실제 트랜잭션 실행
createGameTx, err := dgf.Create(
    proposerAuth,
    gameType,      // 0 = FaultDisputeGame
    rootClaim,     // 잘못된 root claim
    extraData      // L2 block number
)
```

**특징**:
- ✅ **실제 Optimism 환경**
- ✅ **실제 DisputeGameFactory 사용**
- ✅ **실제 FaultDisputeGame 생성**
- ✅ **실제 RAT 트리거 메커니즘**
- ✅ **프로덕션과 동일한 플로우**
- ❌ 느린 실행 속도 (Anvil 노드 시작 필요)

---

## 🏗️ E2E 테스트 아키텍처

### 1. Genesis 기반 테스트 환경

```
┌─────────────────────────────────────────────────────────┐
│ Genesis File (.devnet/genesis-l1-staking-v3.json)      │
├─────────────────────────────────────────────────────────┤
│ Optimism L1 Contracts (104개)                          │
│  ├─ DisputeGameFactory                                 │
│  ├─ FaultDisputeGame (implementation)                  │
│  ├─ DelayedWETH                                        │
│  └─ SystemConfig                                       │
│                                                         │
│ TON Staking Contracts (15개)                           │
│  ├─ RAT (Rollup Attention Test)                       │
│  ├─ SeigManager (+ Slashing)                          │
│  ├─ DepositManager (+ Slashing)                       │
│  ├─ Layer2Manager (+ Slashing)                        │
│  └─ DAOCommittee                                       │
└─────────────────────────────────────────────────────────┘
                        ↓
            ┌───────────────────────┐
            │   Anvil L1 Node       │
            │  (isolated per test)  │
            └───────────────────────┘
                        ↓
            ┌───────────────────────┐
            │   E2E Test (Go)       │
            │  - Real transactions  │
            │  - Real contracts     │
            └───────────────────────┘
```

### 2. 실제 슬래싱 플로우

```
Step 1: Operator 등록
  └─ Layer2Manager.registerCandidateAddOn()
  └─ DepositManager.deposit(50,000 WTON)

Step 2: DisputeGame 생성 (실제!)
  └─ DisputeGameFactory.create(wrongRootClaim)
  └─ FaultDisputeGame 컨트랙트 배포
  └─ RAT.onDisputeGameCreated() 자동 호출

Step 3: RAT 트리거 (실제!)
  └─ RAT이 Validator 선택
  └─ Validator bond 잠금
  └─ AttentionTestTriggered 이벤트 발생

Step 4: Challenger 공격 (실제!)
  └─ FaultDisputeGame.attack(correctClaim)
  └─ Game 상태 변경

Step 5: Game 해결 (실제!)
  └─ 시간 경과 (7일)
  └─ FaultDisputeGame.resolveClaim()
  └─ Game status = CHALLENGER_WINS

Step 6: 슬래싱 실행 (실제!)
  └─ Layer2Manager.slashingCandidate()
  └─ DepositManager.slash()
  └─ SeigManager.onSlash()
  └─ Operator 스테이크 소각
  └─ Challenger 보상 (10%)
```

---

## 🔍 실제 컨트랙트 사용 증거

### Genesis 주소 (실제 배포됨)
```json
{
  "chainId": 900,
  "disputeGameFactory": "0xb606Ad4a2Ba58ba7cE88fe50A2b7991EB0e1d4F3",
  "systemConfig": "0xe705b6429e79D1a2Ce8E84df065c27b9c4Eed3C4",
  "ratProxy": "0x49FcbCC4E425add3a45AFC82F4dD0E5c227A0Ff8",
  "seigManagerProxy": "0x0f5D1ef48f12b6f691401bfe88c2037c690a6afe",
  "depositManagerProxy": "0x90118d110B07ABB82Ba8980D1c5cC96EeA810d2C",
  "layer2ManagerProxy": "0xcA03Dc4665A8C3603cb4Fd5Ce71Af9649dC00d44"
}
```

### 코드 증거: `createDisputeGameWithWrongClaim()`
```go
// op-e2e/e2eutils/rat/helpers.go (or local helpers)

func createDisputeGameWithWrongClaim(...) {
    // 실제 DisputeGameFactory 연결
    dgf, err := bindings.NewDisputeGameFactory(
        sys.Addresses.DisputeGameFactory,  // ← 실제 주소!
        sys.L1Client                        // ← 실제 클라이언트!
    )
    
    // 실제 initBond 조회
    initBond, err := dgf.InitBonds(callOpts, gameType)
    
    // 실제 트랜잭션 전송
    createGameTx, err := dgf.Create(
        proposerAuth,
        gameType,
        rootClaim,
        extraData
    )
    
    // 실제 트랜잭션 대기
    receipt, err := bind.WaitMined(sys.Ctx, sys.L1Client, createGameTx)
    
    // 실제 이벤트 파싱
    for _, log := range receipt.Logs {
        if log.Topics[0].Hex() == eventDisputeGameCreated {
            gameAddress = common.HexToAddress(log.Topics[1].Hex())
        }
    }
}
```

---

## 💡 왜 E2E 테스트가 중요한가?

### Forge 테스트로는 검증할 수 없는 것들:

1. **DisputeGameFactory 통합**
   - ✅ E2E: 실제 게임 생성 프로세스
   - ❌ Forge: Mock으로 시뮬레이션

2. **RAT 자동 트리거**
   - ✅ E2E: DisputeGameFactory → RAT 이벤트 체인
   - ❌ Forge: 수동으로 RAT 호출

3. **FaultDisputeGame 상태 관리**
   - ✅ E2E: 실제 게임 로직 (attack, resolve)
   - ❌ Forge: Mock 상태 설정

4. **크로스 컨트랙트 상호작용**
   - ✅ E2E: RAT ↔ DisputeGame ↔ Layer2Manager ↔ DepositManager
   - ❌ Forge: 개별 컨트랙트 테스트

5. **이벤트 체인**
   - ✅ E2E: 실제 이벤트 발생 및 파싱
   - ❌ Forge: 이벤트 시뮬레이션

---

## 🎯 테스트 전략

### 계층적 테스트 접근

```
┌─────────────────────────────────────────┐
│ E2E Tests (Go)                          │
│ - 실제 Optimism 환경                     │
│ - 전체 슬래싱 플로우                      │
│ - 통합 검증                              │
└─────────────────────────────────────────┘
                 ↑ 통합
┌─────────────────────────────────────────┐
│ Integration Tests (Solidity)            │
│ - 여러 컨트랙트 상호작용                  │
│ - 시나리오 테스트                         │
└─────────────────────────────────────────┘
                 ↑ 통합
┌─────────────────────────────────────────┐
│ Unit Tests (Solidity)                   │
│ - Mock 사용                              │
│ - 개별 함수 테스트                        │
│ - 빠른 피드백                             │
└─────────────────────────────────────────┘
```

**각 레벨이 서로 보완합니다!**

---

## 📝 E2E 테스트 실행 방법

### 1. Genesis 생성 (한 번만)
```bash
make devnet-allocs-offline
```

### 2. E2E 테스트 실행
```bash
# 전체 실행
make test-e2e

# 슬래싱 테스트만
cd op-e2e
GOWORK=off go test -v ./slashing/...
```

### 3. 테스트 플로우
```
1. StartTONStakingSystem()
   └─ Genesis 로드
   └─ Anvil 노드 시작 (독립적인 포트)
   └─ 모든 컨트랙트 배포 완료 상태

2. 실제 트랜잭션 실행
   └─ Operator 등록
   └─ DisputeGame 생성
   └─ Challenger 공격
   └─ 슬래싱 실행

3. 결과 검증
   └─ Operator 스테이크 = 0
   └─ Challenger 보상 = 10%
   └─ 소각 = 90%

4. 노드 종료 (자동)
```

---

## 🔒 신뢰성 보장

### E2E 테스트가 보장하는 것:

1. ✅ **실제 Optimism 호환성**
   - DisputeGameFactory 인터페이스
   - FaultDisputeGame 프로토콜
   - 이벤트 형식

2. ✅ **전체 시스템 통합**
   - RAT ↔ Optimism 통합
   - 슬래싱 메커니즘 전체 플로우
   - 크로스 컨트랙트 호출 체인

3. ✅ **프로덕션 준비도**
   - 실제 환경과 동일한 조건
   - 실제 트랜잭션 가스 비용
   - 실제 이벤트 처리

---

## 📚 참고 자료

### 관련 파일
- **E2E 테스트**: `op-e2e/slashing/slashing_test.go`
- **헬퍼 함수**: `op-e2e/slashing/slashing_helpers.go`
- **공통 헬퍼**: `op-e2e/e2eutils/rat/helpers.go`
- **Genesis 스크립트**: `script/DeployV3SlashForDevnet.s.sol`

### 기존 E2E 테스트 예시
- `op-e2e/faultproofs/rat_challenge_test.go:TestSimpleRAT_ChallengerWins`
  - 실제 DisputeGame 생성 및 해결
  - RAT 트리거 및 bond 처리
  - 전체 Challenger wins 플로우

---

## 🎉 결론

**슬래싱 E2E 테스트는 Mock이 아닌 실제 Optimism 환경에서 전체 슬래싱 프로세스를 검증합니다.**

이를 통해:
- ✅ Optimism 통합 검증
- ✅ 프로덕션 준비도 확인
- ✅ 실제 환경에서의 동작 보장

**E2E 테스트 = 실제 환경 시뮬레이션 = 최종 품질 보증** 🚀
