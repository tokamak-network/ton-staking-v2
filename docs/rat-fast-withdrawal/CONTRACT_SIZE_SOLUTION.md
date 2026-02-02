# RAT 컨트랙트 크기 문제 및 해결방안

## 문제 상황

### 컨트랙트 크기 제한 초과

```
컨트랙트 크기 제한: 24,576 bytes (24KB)
현재 RAT 크기:      27,273 bytes
초과:              2,697 bytes (약 11% 초과)
```

**원인:**
- RAT 컨트랙트가 1,540줄로 매우 큼
- Fast Withdrawal 기능 추가로 약 400줄 증가
- BLS 공개키 관리 기능 추가로 약 200줄 증가

---

## 해결 방안

### Option 1: RatFastWithdrawal 분리 (권장)

RAT의 Fast Withdrawal 기능을 별도 컨트랙트로 분리

**구조:**
```
┌─────────────────────────────┐
│          RAT                │
│  - 검증자 등록/탈퇴          │
│  - RAT 트리거               │
│  - 증거 검증                │
│  - 슬래싱                   │
│  - BLS 공개키 저장          │ ← 여기는 남김 (다른 기능도 사용)
└──────────┬──────────────────┘
           │ 위임 (delegate call)
           ↓
┌─────────────────────────────┐
│   RatFastWithdrawal         │
│  - BLS 서명 검증            │
│  - 인접 리프 검증           │
│  - Portal 호출              │
│  - 수수료 분배              │
└─────────────────────────────┘
```

**장점:**
- RAT 크기 약 2,000-3,000 bytes 감소
- 기능적 분리로 유지보수 용이
- Fast Withdrawal 업그레이드 시 RAT 영향 없음

**단점:**
- 컨트랙트 간 호출로 약간의 가스 증가 (~5,000 gas)
- 배포 시 2개 컨트랙트 관리 필요

---

### Option 2: 라이브러리 분리

BLS 검증 로직을 라이브러리로 분리

**Before:**
```solidity
contract RAT {
    function _verifyBLSSignature(...) internal view { ... }
    function _aggregatePublicKeys(...) internal view { ... }
    function _countSetBits(...) internal pure { ... }
}
```

**After:**
```solidity
library RatBLSVerifier {
    function verifyBLSSignature(...) internal view { ... }
    function aggregatePublicKeys(...) internal view { ... }
    function countSetBits(...) internal pure { ... }
}

contract RAT {
    using RatBLSVerifier for *;
}
```

**문제점:**
- 라이브러리도 배포 코드에 포함되어 크기 감소 효과 제한적
- internal view 함수는 라이브러리로 분리해도 인라인됨

---

### Option 3: 프록시 패턴 + 모듈화

RAT을 RatCore와 RatExtension으로 분리

**구조:**
```
┌─────────────────┐
│   RATProxy      │ ← 사용자 진입점
└────────┬────────┘
         │
    ┌────┴────┐
    ↓         ↓
┌────────┐ ┌──────────────┐
│RatCore │ │RatExtension  │
│(핵심)  │ │(Fast WD 등)  │
└────────┘ └──────────────┘
```

**문제점:**
- 복잡도 증가
- 상태 공유 어려움
- delegatecall 가스 비용

---

## 권장 솔루션: RatFastWithdrawal 분리

### 1. 파일 구조

```
src/validator/
├── RAT.sol                    (핵심 기능만)
├── RatFastWithdrawal.sol      (Fast Withdrawal 전용)
├── RATStorage.sol
├── IRAT.sol
└── RATTypes.sol
```

### 2. RAT.sol 수정

```solidity
contract RAT is RATStorage, IRAT {
    /// @notice Fast Withdrawal 컨트랙트 주소
    address public ratFastWithdrawal;

    /// @notice Fast Withdrawal 컨트랙트 설정
    function setRatFastWithdrawal(address _ratFastWithdrawal) external onlyOwner {
        ratFastWithdrawal = _ratFastWithdrawal;
    }

    // Fast Withdrawal 관련 모든 코드 제거:
    // - verifyAndExecuteFastWithdrawal
    // - _verifyBLSSignature
    // - _verifyAdjacentLeaves
    // - _executeFastWithdrawal
    // - _aggregatePublicKeys
    // - _countSetBits
    // - _distributeFastWithdrawalFees
    // - Fast Withdrawal 이벤트
    // - Fast Withdrawal 에러
    
    // BLS 공개키 관리는 남김 (다른 용도로도 사용 가능)
    function getValidatorBLSPubKey(...) external view returns (bytes memory) {
        return validatorRegistrations[systemConfig][validator].blsPublicKey;
    }
}
```

### 3. RatFastWithdrawal.sol 구조

```solidity
contract RatFastWithdrawal {
    address public immutable RAT_CONTRACT;
    address public immutable LAYER2_MANAGER;
    
    // Fast Withdrawal 전용 상태
    mapping(bytes32 => bool) public processedWithdrawals;
    uint256 public aggregatorFeeRate;
    bool public fastWithdrawalEnabled;
    
    function verifyAndExecuteFastWithdrawal(
        Types.WithdrawalTransaction calldata _tx,
        FastWithdrawalInput calldata input,
        bytes calldata _aggregatedSignature
    ) external {
        // 1. RAT에서 검증자 정보 조회
        address[] memory validators = IRAT(RAT_CONTRACT).getL2Validators(input.systemConfig);
        
        // 2. BLS 서명 검증
        _verifyBLSSignature(...);
        
        // 3. Portal 호출
        _executeFastWithdrawal(...);
    }
}
```

### 4. 배포 순서

```solidity
// 1. RAT 배포 (Fast Withdrawal 코드 제거)
RAT rat = new RAT();

// 2. RatFastWithdrawal 배포
RatFastWithdrawal fastWithdrawal = new RatFastWithdrawal(
    address(rat),
    layer2Manager,
    validatorReward,
    1e26  // 10% aggregator fee
);

// 3. RAT에 RatFastWithdrawal 주소 설정
rat.setRatFastWithdrawal(address(fastWithdrawal));

// 4. RatFastWithdrawal 활성화
fastWithdrawal.setFastWithdrawalEnabled(true);
```

### 5. 사용자 호출 흐름

```
사용자 (Aggregator)
    ↓
RatFastWithdrawal.verifyAndExecuteFastWithdrawal()
    ↓
RAT.getL2Validators()          (검증자 목록 조회)
RAT.getActiveValidatorCount()  (검증자 수 조회)
RAT.getValidatorBLSPubKey()    (BLS 공개키 조회)
    ↓
OptimismPortal2.setWithdrawalVerified()
OptimismPortal2.fastWithdrawalFinalize()
```

---

## 예상 결과

### 크기 감소

| 컨트랙트 | Before | After | 감소량 |
|---------|--------|-------|--------|
| RAT | 27,273 bytes | ~22,000 bytes | ~5,273 bytes |
| RatFastWithdrawal | - | ~6,000 bytes | - |

**RAT 크기 감소 내역:**
- Fast Withdrawal 함수들 제거: ~2,500 bytes
- Fast Withdrawal 이벤트/에러 제거: ~500 bytes
- Fast Withdrawal helper 함수 제거: ~2,000 bytes
- 총 감소: ~5,000 bytes

### 가스 비용 변화

| 작업 | Before (통합) | After (분리) | 차이 |
|-----|--------------|-------------|------|
| Fast Withdrawal | ~200,000 gas | ~205,000 gas | +5,000 gas (+2.5%) |

**가스 증가 원인:**
- 외부 컨트랙트 호출 (CALL opcode)
- 약 5회 외부 view 호출 (각 ~1,000 gas)

**트레이드오프:**
- 가스: +2.5% 증가
- 배포: 24KB 제한 준수 가능
- 유지보수: 기능별 분리로 개선
- 업그레이드: Fast Withdrawal만 독립적으로 가능

---

## 대안: 코드 최적화

Fast Withdrawal 분리가 어려운 경우, 다음 최적화를 고려:

### 1. 함수 인라인 제거

```solidity
// Before (더 많은 bytecode)
function _validateX() internal view { ... }
function _validateY() internal view { ... }
function _validateZ() internal view { ... }

// After (함수 통합)
function _validate() internal view {
    // 모든 검증 로직 하나로 통합
}
```

**절약: ~500 bytes**

### 2. 에러 메시지 제거

```solidity
// Before
require(condition, "detailed error message");

// After
if (!condition) revert CustomError();
```

**절약: ~1,000 bytes**

### 3. 불필요한 함수 제거

- getter 함수 중 외부에서 사용하지 않는 것 제거
- internal 함수 중 한 번만 사용되는 것 인라인화

**절약: ~500 bytes**

### 4. 최적화 설정

```toml
# foundry.toml
[profile.default]
optimizer = true
optimizer_runs = 200  # 기본값
via_ir = true         # IR 기반 최적화
```

**절약: ~1,000-2,000 bytes**

---

## 결론

### 권장 방안: RatFastWithdrawal 분리

**이유:**
1. ✅ **크기 문제 해결**: RAT을 24KB 이하로 감소
2. ✅ **기능 분리**: Fast Withdrawal 독립적 업그레이드 가능
3. ✅ **유지보수성**: 코드 구조 개선
4. ⚠️ **가스 비용**: +2.5% 증가 (허용 가능)
5. ✅ **보안**: 각 컨트랙트의 책임 명확화

### 구현 우선순위

1. **Phase 1**: RatFastWithdrawal 컨트랙트 작성 및 테스트
2. **Phase 2**: RAT에서 Fast Withdrawal 코드 제거
3. **Phase 3**: 통합 테스트 및 가스 벤치마크
4. **Phase 4**: 배포 스크립트 작성
5. **Phase 5**: 문서 업데이트

---

*Last Updated: 2026-02-02*
