# RAT Client Tests

이 디렉토리의 테스트들은 rat-client 브랜치에서 가져온 것으로, dev 브랜치의 V3 API에 맞게 수정되었습니다.

## 수정 내용

1. **V3TestBase 상속** - dev 브랜치의 통합 테스트 환경 사용
2. **registerValidator(systemConfig)** - coinage 기반 담보금 (인자 1개)
3. **addDeposit() 제거** - depositManager.deposit()로 대체
4. **getValidatorRegistration()** - 반환값 3개 (collateral, validatorIndex, isActive)

## 테스트 목록

- `RATClient.t.sol` - 33개 RAT 단위 테스트 (증거 검증 포함)
- `RATClientIntegration.t.sol` - 3개 RAT 통합 테스트

## 실행 방법

```bash
forge test --match-path "test/v3/rat-client/*.t.sol"
```
