# Instant Withdrawal Non-Responder RAT Targeting

## TODO: 확인 필요

빠른 출금 요청에 응답하지 않은 검증자는 다음 번 RAT(Randomized Attention Test)의 대상이 된다.

---

## 개요

빠른 출금(Instant Withdrawal) 요청 시, 전체 검증자 풀에 서명을 요청합니다. 이 때 **응답하지 않은 검증자**는 다음 번 확률적 RAT의 **필수 대상자**가 됩니다.

---

## 메커니즘

```
빠른 출금 요청 (T+0)
├─ 전체 검증자 풀 100명에게 서명 요청
├─ 타임아웃: 10분
│
├─ T+10분: 결과
│  ├─ 응답한 검증자: 95명 ✅
│  └─ 미응답 검증자: 5명 ❌
│
└─ 미응답 검증자 처리:
   ├─ 1. 현재 빠른 출금: 수수료 못 받음 (Bond Slashing 없음)
   └─ 2. 다음 RAT: 필수 대상자로 지정 (Bond 선차감됨)
```

---

## 다음 RAT 대상 선정

```
일반 RAT (확률적 선택):
├─ 기본: 랜덤하게 K명 선택
│
└─ 미응답자 포함 로직:
   ├─ 1. 미응답자 목록에서 전원 선택 (필수)
   ├─ 2. 나머지 슬롯: 일반 검증자 풀에서 랜덤 선택
   └─ 3. 최종 대상: 미응답자 + 랜덤 선택자
```

### 예시

```
기존 RAT 선택: K = 10명

Case 1: 미응답자 5명 존재
├─ 필수 선택: 5명 (미응답자)
├─ 랜덤 선택: 5명 (일반 풀)
└─ 총 대상: 10명

Case 2: 미응답자 15명 존재
├─ 필수 선택: 15명 (미응답자 전원)
├─ 랜덤 선택: 0명
└─ 총 대상: 15명 (K 초과 가능)
```

---

## 확인해야 할 사항

### 1. 컨트랙트 구현

- [ ] 미응답자 목록 저장 구조
  - `mapping(address => bool) public instantWithdrawalNonResponders;`
  - 또는 `address[] public nonResponderQueue;`

- [ ] 미응답자 등록 시점
  - 빠른 출금 타임아웃 시 자동 등록?
  - 별도 트랜잭션으로 등록?

- [ ] 미응답자 해제 조건
  - 다음 RAT 응답 시 목록에서 제거?
  - N번 연속 응답 시 해제?

### 2. RAT 선택 로직 수정

- [ ] `triggerAttentionTest` 함수 수정
  - 미응답자 우선 포함 로직 추가
  - 랜덤 선택 로직과 결합

```solidity
function selectValidatorsForRAT(uint256 k) internal returns (address[] memory) {
    // 1. 미응답자 전원 포함
    address[] memory nonResponders = getNonResponders();
    
    // 2. 나머지 슬롯은 랜덤 선택
    uint256 remainingSlots = k > nonResponders.length ? k - nonResponders.length : 0;
    address[] memory randomValidators = selectRandomValidators(remainingSlots);
    
    // 3. 병합
    return merge(nonResponders, randomValidators);
}
```

### 3. 경제적 인센티브

- [ ] 미응답 페널티 크기 결정
  - 빠른 출금 실패 시: 수수료 못 받음 (Bond Slashing 없음)
  - 다음 RAT 강제 참여 시: 일반 RAT처럼 Bond 선차감됨

- [ ] 검증자 회복 경로
  - 얼마나 많은 RAT에 응답해야 정상 복귀?
  - 연속 미응답 시 추가 페널티?

### 4. 보안 고려사항

- [ ] 미응답자 목록 조작 방지
- [ ] 네트워크 장애로 인한 false positive 처리
- [ ] 의도적 미응답과 기술적 실패 구분

---

## 예상 구현 위치

```
RAT Contract 수정:
└─ /ton-staking-v2/src/validator/RAT.sol
   ├─ nonResponderQueue 상태 변수 추가
   ├─ recordNonResponder() 함수 추가
   ├─ selectValidatorsForRAT() 함수 수정
   └─ clearNonResponder() 함수 추가
```

---

## 플로우 다이어그램

```
[빠른 출금 요청]
       │
       ▼
[전체 검증자 서명 요청] ─────► [타임아웃]
       │                           │
       ▼                           ▼
[서명 수집]                  [미응답자 식별]
       │                           │
       ▼                           ▼
[성공: 100명 서명]          [5명 미응답]
       │                           │
       ▼                           ▼
[즉시 출금]                 [미응답자 큐에 등록]
                                   │
                                   ▼
                           [다음 RAT 발생 시]
                                   │
                                   ▼
                           [미응답자 필수 포함]
                                   │
                                   ▼
                           [RAT 응답 완료 시]
                                   │
                                   ▼
                           [미응답자 큐에서 제거]
```

---

## 관련 문서

- [INSTANT_WITHDRAWAL_WITH_RAT.md](./INSTANT_WITHDRAWAL_WITH_RAT.md) - 빠른 출금 전체 설계
- [RAT_INTEGRATION.md](./RAT_INTEGRATION.md) - RAT 통합 개요
