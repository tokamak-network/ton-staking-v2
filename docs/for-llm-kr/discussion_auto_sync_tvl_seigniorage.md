# TVL 변경 시 시뇨리지 자동 동기화 검토

## 개요

이 문서는 L2의 TVL(Total Value Locked) 변경 시 시뇨리지 분배 값을 자동으로 동기화할지 여부를 결정하기 위한 검토 문서입니다.

---

## 현재 구현

### 관련 플래그
```solidity
// SeigManagerV1_4Storage.sol
bool public autoSyncEffectiveTVL;
```

### 동작 방식

| `autoSyncEffectiveTVL` | 동작 |
|:----------------------:|------|
| **false (기본값)** | `onBridgedTONChange`에서 `currentBridgedTON`과 `isEligible`만 업데이트. `effectiveBridgedTON`은 시뇨리지 계산 시점에만 동기화 |
| **true** | `onBridgedTONChange`에서 `effectiveBridgedTON`과 `totalEffectiveBridgedTON`도 즉시 동기화 |

### 어드민 설정
```solidity
function setAutoSyncEffectiveTVL(bool enabled) external onlyOwner;
```

---

## 비교 분석

### Option A: 자동 동기화 OFF (기본값, `autoSyncEffectiveTVL = false`)

```
onBridgedTONChange(layer2, newTVL)
  ├── currentBridgedTON = newTVL        ✅ 업데이트
  ├── isEligible = checkEligibility()   ✅ 업데이트
  ├── effectiveBridgedTON              ❌ 변경 없음
  └── totalEffectiveBridgedTON         ❌ 변경 없음

updateSeigniorage() 호출 시점에만:
  └── _syncEffectiveBridgedTON(layer2)  → effectiveBridgedTON 동기화
```

**장점:**
- 브릿지 트랜잭션 가스비 절감
- TVL 조작을 통한 시뇨리지 게이밍 방지 (스냅샷 기반)
- 사용자 경험 유지

**단점:**
- 시뇨리지 분배가 실시간 TVL을 반영하지 않음
- 별도의 `updateSeigniorage` 호출 필요

### Option B: 자동 동기화 ON (`autoSyncEffectiveTVL = true`)

```
onBridgedTONChange(layer2, newTVL)
  ├── currentBridgedTON = newTVL        ✅ 업데이트
  ├── isEligible = checkEligibility()   ✅ 업데이트
  ├── effectiveBridgedTON              ✅ 즉시 동기화
  └── totalEffectiveBridgedTON         ✅ 즉시 동기화
```

**장점:**
- 시뇨리지 분배가 실시간 TVL 반영
- 별도 동기화 호출 불필요

**단점:**
- 브릿지 트랜잭션 가스비 증가 (~50k gas 추가)
- TVL 조작을 통한 시뇨리지 게이밍 가능성

---

## 가스비 비교

| 시나리오 | Option A (OFF) | Option B (ON) |
|---------|----------------|---------------|
| `onBridgedTONChange` | ~30k gas | ~80k gas |
| 브릿지 deposit/withdraw | 영향 없음 | +50k gas |

---

## 보안 고려사항

### TVL 조작 공격 시나리오 (Option B 활성화 시)

1. 공격자가 대량의 TON을 브릿지에 입금
2. `onBridgedTONChange` → `effectiveBridgedTON` 즉시 증가
3. 높은 TVL 기준으로 시뇨리지 분배
4. 즉시 TON 출금
5. 불공정한 시뇨리지 획득

**완화 방안:**
- Time-weighted average TVL 사용 (구현 복잡)
- 최소 락업 기간 적용
- Option A 유지 (스냅샷 기반)

---

## 권장 사항

| 항목 | 권장 |
|------|------|
| **초기 설정** | `autoSyncEffectiveTVL = false` |
| **이유** | 가스비 절감, 보안성, 기존 시스템 호환성 |
| **변경 시점** | 충분한 테스트 및 경제적 분석 후 |

---

## 결정 체크리스트

- [ ] 브릿지 사용자 가스비 증가 허용 가능한가?
- [ ] TVL 조작 공격에 대한 대응책이 있는가?
- [ ] 실시간 TVL 반영이 경제적으로 필요한가?
- [ ] Keeper/Bot 기반 주기적 동기화가 대안인가?

---

## 관련 코드

- `SeigManagerV1_4Storage.sol`: `autoSyncEffectiveTVL` 플래그
- `SeigManagerV1_4.sol`:
  - `setAutoSyncEffectiveTVL()`: 어드민 설정 함수
  - `onBridgedTONChange()`: 조건부 동기화 로직
  - `_syncEffectiveBridgedTON()`: 동기화 내부 함수
