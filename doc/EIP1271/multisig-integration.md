# MultiSig 통합 프롬프트

## 프롬프트

```
EIP-1271 구현에서 MultiSig 지갑과의 통합을 위한 코드를 작성해주세요:

### 요구사항

1. **MultiSig 지갑 관리**
   - MultiSig 지갑 주소 설정/변경 기능
   - 권한 기반 접근 제어 (onlyOwner)
   - 제로 주소 검증
   - 변경 이벤트 발생

2. **서명 검증 통합**
   - MultiSig 소유자 확인
   - 단일 서명으로 검증 (첫 번째 유효한 소유자 서명)
   - 또는 다중 서명 검증 (요구사항에 따라)

3. **인터페이스 정의**
```solidity
interface IMultiSigWallet {
    function isOwner(address owner) external view returns (bool);
    function getOwners() external view returns (address[] memory);
    function numConfirmationsRequired() external view returns (uint256);
}
```

4. **구현할 함수들**
   - `setMultiSigWallet(address _multiSigWallet)`: MultiSig 지갑 설정
   - `_validateSignatures()`: 서명 검증 로직
   - 필요시 다중 서명 검증 로직

5. **보안 고려사항**
   - MultiSig 지갑이 admin 권한을 가지고 있는지 확인
   - 서명자가 실제 MultiSig 소유자인지 검증
   - 재진입 공격 방지

6. **이벤트**
```solidity
event MultiSigWalletSet(address indexed oldWallet, address indexed newWallet);
```

### 참조 패턴

DAOCommittee_V2에서 사용된 패턴을 참조하여:
- 단일 서명 검증 방식 (첫 번째 유효한 소유자)
- AccessControl 기반 권한 관리
- 적절한 에러 처리

### 선택 옵션

다음 중 하나를 선택하여 구현해주세요:
A) 단일 서명 검증: 하나의 유효한 소유자 서명으로 충분
B) 다중 서명 검증: MultiSig의 required confirmations만큼 서명 필요
C) 하이브리드: 설정 가능한 검증 방식

선택한 방식에 대한 이유와 장단점도 함께 설명해주세요.

완전한 구현 코드와 함께 사용 예시도 제공해주세요.
```

## 고급 옵션 프롬프트

```
### 고급 MultiSig 통합 (선택사항)

다음 고급 기능들도 함께 구현해주세요:

1. **동적 서명 요구사항**
   - MultiSig의 required confirmations 수에 따른 동적 검증
   - 서명 개수 확인 로직

2. **서명 순서 검증**
   - 서명자 주소 순서 확인
   - 중복 서명 방지

3. **가스 최적화**
   - 효율적인 서명 검증 순서
   - 불필요한 계산 최소화

4. **확장성**
   - 다른 MultiSig 구현과의 호환성
   - 플러그인 방식의 검증 로직

구현 시 각 기능의 가스 비용과 보안 트레이드오프를 고려해주세요.
```