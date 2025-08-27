# MultiSig 통합 프롬프트

## 프롬프트

```
EIP-1271 구현에서 MultiSig 지갑과의 통합을 위한 코드를 작성해주세요:

### 요구사항

1. **MultiSig 지갑 관리**
   - **MultiSig 지갑이 DAO의 Owner (DEFAULT_ADMIN_ROLE)**
   - MultiSig 지갑 주소 설정/변경 기능
   - 권한 기반 접근 제어 (onlyOwner)
   - 제로 주소 검증
   - 변경 이벤트 발생

2. **서명 검증 통합**
   - **단일 서명 검증: MultiSig 소유자 중 한 명의 서명만으로 충분**
   - MultiSig 소유자 확인 (`IMultiSigWallet.isOwner()` 사용)
   - 첫 번째 유효한 소유자 서명으로 검증 완료
   - 다중 서명 불필요 (가스 효율성 고려)

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

### 구현 방식

**단일 서명 검증 방식을 사용해주세요:**
- **요구사항**: MultiSig 소유자 중 한 명의 서명만으로 EIP-1271 검증 통과
- **이유**: 가스 효율성 및 사용성 향상
- **구현**: 첫 번째 유효한 소유자 서명 발견 시 즉시 검증 완료

```solidity
// 단일 서명 검증 예시
function _validateSignatures(bytes32 _hash, bytes memory _signature) internal view returns (bool) {
    if (_signature.length < 65) return false;
    
    // 65바이트 서명 추출
    bytes memory sigPart = _signature.slice(0, 65);
    address signer = _recoverSigner(_hash, sigPart);
    
    // MultiSig 소유자 중 한 명이면 검증 통과
    return IMultiSigWallet(multiSigWallet).isOwner(signer);
}
```

완전한 구현 코드와 함께 사용 예시도 제공해주세요.
```

## 추가 고려사항 프롬프트

```
### 단일 서명 검증 최적화

다음 최적화 사항들을 고려해주세요:

1. **가스 효율성**
   - 첫 번째 서명만 검증하여 가스 비용 최소화
   - 불필요한 루프 및 계산 제거
   - 조기 반환(early return) 패턴 사용

2. **보안 강화**
   - 서명 재사용 공격 방지
   - 올바른 서명 형식 검증
   - MultiSig 소유자 상태 실시간 확인

3. **사용성 개선**
   - 명확한 에러 메시지
   - 이벤트 로깅
   - 디버깅 정보 제공

4. **호환성**
   - 다양한 MultiSig 구현과 호환 (Gnosis Safe, 커스텀 MultiSig 등)
   - 표준 EIP-1271 인터페이스 준수
   - 업그레이드 가능한 구조

### 중요 제약사항
- **MultiSig의 required confirmations 수는 무시**
- **한 명의 소유자 서명만으로 충분**
- **DAO Owner는 반드시 MultiSig Contract**

구현 시 단일 서명 검증의 장점을 최대한 활용해주세요.
```