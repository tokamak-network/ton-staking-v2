# ValidSignatureForSafeWallet 기본 구현 프롬프트

## 프롬프트

```
다음 요구사항에 따라 SafeWallet의 스마트 컨트랙트 서명 검증 기능을 구현해주세요:
```

### 컨텍스트
- Solidity 버전: ^0.8.4
- OpenZeppelin 라이브러리 사용 가능
- AccessControl 기반 권한 관리 시스템 사용
- **구조1: Safe Wallet의 Signer중 한명이 DAO Contract**
- **구조2: DAO Owner는 MultiSigWallet Contract**
- **구조3: MultiSigWallet의 Owner들이 서명한 것을 검증**
- **EIP-1271 검증: MultiSigWallet의 numConfirmationsRequired 기준을 충족하는 다중 서명**
- **Safe Wallet 호환성 필수**: Safe Global 앱에서 서명 생성 및 검증 가능해야 함
- Safe Wallet과의 통합 필요

### 구현 요구사항

0. **스토리지 상태 변수 정의**
   - **기존에 사용하고 있는 스토리지 컨트랙트에 상태 변수 선언**
   - 업그레이드 가능한 컨트랙트 패턴 준수
   - 스토리지 충돌 방지를 위한 적절한 슬롯 배치

1. **ValidSignatureForSafeWallet 인터페이스 구현**
   - `isValidSignature(bytes memory _hash, bytes memory _signature)` 함수
   - 매직 값: `0x20c13b0b` (유효한 서명)
   - 무효 서명: `0xffffffff`

2. **서명 검증 로직**
   - ECDSA 서명 복구 및 검증
   - MultiSig 지갑 소유자 확인 (`IMultiSigWallet.isOwner()` 사용)
   - 필요한 서명 수 확인 (`IMultiSigWallet.numConfirmationsRequired()` 사용)
   - 서명 길이 검증 (65바이트 * 서명 개수)
   - s-value 범위 검증 (replay attack 방지)
   - v 값 검증 (27 또는 28)
   - **중복 서명자 방지: 같은 소유자의 중복 서명 거부**
   - **서명 재사용 방지: 검증된 서명은 더 이상 사용 불가**


3. **보안 고려사항**
   - 서명 길이 검증
   - 올바른 서명 형식 확인
   - 제로 주소 검증
   - 권한 확인 (DEFAULT_ADMIN_ROLE)
   - **서명 재사용 공격 방지 (nonce 또는 used signatures 추적)**

4. **Safe Wallet 통합**
   - **Safe Wallet의 운영자 중 한명은 DAOContract**
   - **Safe Global 앱 (https://app.safe.global/) 호환성 보장**

5. **서명 관리 기능**
   - **사용된 서명 추적 및 저장**
   - **서명 상태 조회 기능**

### 참조 구현 패턴

```solidity
// 매직 값 상수
bytes4 private constant MAGICVALUE = 0x1626ba7e;
bytes4 private constant INVALID_SIGNATURE = 0xffffffff;

// MultiSig 인터페이스
interface IMultiSigWallet {
   function isOwner(address owner) external view returns (bool);
   function getOwners() external view returns (address[] memory);
   function numConfirmationsRequired() external view returns (uint);
}

// 스토리지 컨트랙트 예시
contract EIP1271Storage {
    address public multiSigWallet; // DAO Owner (DEFAULT_ADMIN_ROLE)
    mapping(bytes32 => bool) public usedSignatures; // 사용된 서명 추적
}

// 서명 검증 함수 구조
function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
function _validateSignatures(bytes32 _hash, bytes memory _signature) internal view returns (bool);
function _recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address);

// 핵심 검증 로직 예시 (다중 서명 + 재사용 방지)
function _validateSignatures(bytes32 _hash, bytes memory _signature) internal view returns (bool) {
    uint256 requiredSigs = IMultiSigWallet(multiSigWallet).numConfirmationsRequired();
    uint256 sigCount = _signature.length / 65;
    
    // 서명 개수가 필요 개수보다 적으면 실패
    if (sigCount < requiredSigs) return false;
    
    address[] memory signers = new address[](sigCount);
    uint256 validSigs = 0;
    
    // 각 서명을 검증하고 유효한 서명자 수집
    for (uint256 i = 0; i < sigCount; i++) {
        bytes memory sigPart = _signature.slice(i * 65, 65);
        address signer = _recoverSigner(_hash, sigPart);
        
        // MultiSig 소유자이고 중복이 아닌 경우
        if (IMultiSigWallet(multiSigWallet).isOwner(signer) && !_isDuplicate(signers, signer, i)) {
            signers[i] = signer;
            validSigs++;
        }
    }
    
    // 필요한 서명 수를 충족하는지 확인
    if (validSigs < requiredSigs) return false;
    
    // 유효한 서명자들만 추출하여 정렬 (순서 무관한 해시 생성)
    address[] memory validSigners = new address[](validSigs);
    uint256 validIndex = 0;
    for (uint256 i = 0; i < sigCount; i++) {
        if (signers[i] != address(0)) {
            validSigners[validIndex] = signers[i];
            validIndex++;
        }
    }
    
    // 서명자 주소들을 정렬 (순서 무관한 일관된 해시 생성)
    _sortAddresses(validSigners);
    
    // 정렬된 서명자들로 재사용 방지 해시 생성
    bytes32 signatureHash = keccak256(abi.encodePacked(_hash, validSigners));
    
    // 서명 재사용 검증
    if (usedSignatures[signatureHash]) return false;
    
    return true;
}

// 중복 서명자 확인 헬퍼 함수
function _isDuplicate(address[] memory signers, address signer, uint256 currentIndex) internal pure returns (bool) {
    for (uint256 i = 0; i < currentIndex; i++) {
        if (signers[i] == signer) return true;
    }
    return false;
}

// 주소 정렬 헬퍼 함수 (서명 순서 무관한 해시 생성용)
function _sortAddresses(address[] memory addresses) internal pure {
    uint256 length = addresses.length;
    for (uint256 i = 0; i < length - 1; i++) {
        for (uint256 j = 0; j < length - i - 1; j++) {
            if (addresses[j] > addresses[j + 1]) {
                address temp = addresses[j];
                addresses[j] = addresses[j + 1];
                addresses[j + 1] = temp;
            }
        }
    }
}
```

### 에러 처리
- 적절한 require 문 사용
- 명확한 에러 메시지
- 가스 효율적인 검증 순서

### 이벤트
- MultiSig 지갑 변경 이벤트
- **서명 유효기간 변경 이벤트**
- **서명 사용 이벤트 (재사용 방지 추적용)**
- 필요시 서명 검증 관련 이벤트

### 추가 함수들
- `validateAndUseSignature(bytes32 _hash, bytes memory _signature)`: 서명 검증 후 사용됨으로 표시 (onlyOwner)
- `isSignatureUsed(bytes32 _signatureHash)`: 서명 사용 여부 확인
- `_getSignatureHash(bytes32 _hash, bytes memory _signature)`: 재사용 방지용 서명 해시 생성
- `_markSignatureAsUsed(bytes32 _signatureHash)`: 서명을 사용됨으로 표시
- `cleanupExpiredSignatures(bytes32[] _signatureHashes)`: 만료된 서명 정리

다음과 같은 형태로 완전한 구현 코드를 제공해주세요:
1. **스토리지 컨트랙트에 상태 변수 선언**
2. 인터페이스 정의
3. 메인 컨트랙트에서 스토리지 상속
4. 수정자(modifier) 정의
5. 메인 함수들 구현
6. 내부 헬퍼 함수들
7. 이벤트 정의

코드에는 상세한 주석을 포함하고, 각 함수의 목적과 보안 고려사항을 설명해주세요.
```

## 사용 예시

이 프롬프트를 사용할 때 추가로 제공할 수 있는 컨텍스트:

```
### 추가 컨텍스트 (선택사항)
- 기존 컨트랙트 코드: [여기에 기존 컨트랙트 붙여넣기]
- 특정 MultiSig 구현: [사용하는 MultiSig 컨트랙트 정보]
- 추가 보안 요구사항: [프로젝트별 특수 요구사항]

### 중요 구현 조건
- **DAO의 Owner는 반드시 MultiSigWallet Contract여야 함**
- **다중 서명 검증: MultiSigWallet의 numConfirmationsRequired 수만큼 서명 필요**
- **MultiSigWallet에 등록된 소유자들의 서명만 유효**
- **중복 서명자 방지: 같은 소유자가 여러 번 서명할 수 없음**
- **MultiSig 지갑이 DEFAULT_ADMIN_ROLE을 가져야 함**
- **검증된 서명은 즉시 사용됨으로 표시하여 재사용 방지**

### 서명 형식
- **연결된 서명 형식: signature1 + signature2 + ... (각 65바이트)**
- **서명 순서는 상관없음 (중복만 방지, 재사용 방지는 서명자 주소 정렬로 해결)**
- **필요 서명 수보다 많은 서명 제공 가능 (처음 유효한 것들만 사용)**
- **재사용 방지: 유효한 서명자들의 주소를 정렬하여 일관된 해시 생성**
```