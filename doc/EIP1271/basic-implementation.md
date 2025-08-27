# EIP-1271 기본 구현 프롬프트

## 프롬프트

```
다음 요구사항에 따라 EIP-1271 스마트 컨트랙트 서명 검증 기능을 구현해주세요:

### 컨텍스트
- Solidity 버전: ^0.8.4
- OpenZeppelin 라이브러리 사용 가능
- AccessControl 기반 권한 관리 시스템 사용
- MultiSig 지갑과의 통합 필요

### 구현 요구사항

1. **EIP-1271 인터페이스 구현**
   - `isValidSignature(bytes32 _hash, bytes memory _signature)` 함수
   - 매직 값: `0x1626ba7e` (유효한 서명)
   - 무효 서명: `0xffffffff`

2. **서명 검증 로직**
   - ECDSA 서명 복구 및 검증
   - MultiSig 지갑 소유자 확인
   - 서명 길이 검증 (65바이트)
   - s-value 범위 검증 (replay attack 방지)
   - v 값 검증 (27 또는 28)

3. **보안 고려사항**
   - 서명 길이 검증
   - 올바른 서명 형식 확인
   - 제로 주소 검증
   - 권한 확인 (DEFAULT_ADMIN_ROLE)

4. **MultiSig 통합**
   - MultiSig 지갑 주소 설정 기능
   - 소유자 확인 인터페이스
   - 권한 기반 접근 제어

### 참조 구현 패턴

```solidity
// 매직 값 상수
bytes4 private constant MAGICVALUE = 0x1626ba7e;
bytes4 private constant INVALID_SIGNATURE = 0xffffffff;

// MultiSig 인터페이스
interface IMultiSigWallet {
    function isOwner(address owner) external view returns (bool);
    function getOwners() external view returns (address[] memory);
}

// 서명 검증 함수 구조
function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
function _validateSignatures(bytes32 _hash, bytes memory _signature) internal view returns (bool);
function _recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address);
```

### 에러 처리
- 적절한 require 문 사용
- 명확한 에러 메시지
- 가스 효율적인 검증 순서

### 이벤트
- MultiSig 지갑 변경 이벤트
- 필요시 서명 검증 관련 이벤트

다음과 같은 형태로 완전한 구현 코드를 제공해주세요:
1. 인터페이스 정의
2. 상태 변수 선언
3. 수정자(modifier) 정의
4. 메인 함수들 구현
5. 내부 헬퍼 함수들
6. 이벤트 정의

코드에는 상세한 주석을 포함하고, 각 함수의 목적과 보안 고려사항을 설명해주세요.
```

## 사용 예시

이 프롬프트를 사용할 때 추가로 제공할 수 있는 컨텍스트:

```
### 추가 컨텍스트 (선택사항)
- 기존 컨트랙트 코드: [여기에 기존 컨트랙트 붙여넣기]
- 특정 MultiSig 구현: [사용하는 MultiSig 컨트랙트 정보]
- 추가 보안 요구사항: [프로젝트별 특수 요구사항]
```