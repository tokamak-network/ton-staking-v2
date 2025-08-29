# EIP-1271 기본 구현 프롬프트

## 프롬프트

```
다음 요구사항에 따라 EIP-1271 스마트 컨트랙트 서명 검증 기능을 구현해주세요:

### 컨텍스트
- Solidity 버전: ^0.8.4
- OpenZeppelin 라이브러리 사용 가능
- AccessControl 기반 권한 관리 시스템 사용
- **DAO Owner는 MultiSigWallet Contract**
- **EIP-1271 검증: MultiSigWallet의 numConfirmationsRequired 기준을 충족하는 다중 서명**
- MultiSig 지갑과의 통합 필요

### 구현 요구사항

1. **EIP-1271 인터페이스 구현**
   - `isValidSignature(bytes32 _hash, bytes memory _signature)` 함수
   - 매직 값: `0x1626ba7e` (유효한 서명)
   - 무효 서명: `0xffffffff`

2. **서명 검증 로직**
   - ECDSA 서명 복구 및 검증
   - **다중 서명 검증: MultiSigWallet의 numConfirmationsRequired 수만큼 유효한 서명 필요**
   - MultiSig 지갑 소유자 확인 (`IMultiSigWallet.isOwner()` 사용)
   - 필요한 서명 수 확인 (`IMultiSigWallet.numConfirmationsRequired()` 사용)
   - 서명 길이 검증 (65바이트 * 서명 개수)
   - s-value 범위 검증 (replay attack 방지)
   - v 값 검증 (27 또는 28)
   - **중복 서명자 방지: 같은 소유자의 중복 서명 거부**
   - **서명 재사용 방지: 검증된 서명은 더 이상 사용 불가**
   - **서명 유효기간 검증: Owner가 설정한 기간 내에서만 유효**

3. **보안 고려사항**
   - 서명 길이 검증
   - 올바른 서명 형식 확인
   - 제로 주소 검증
   - 권한 확인 (DEFAULT_ADMIN_ROLE)
   - **서명 재사용 공격 방지 (nonce 또는 used signatures 추적)**
   - **타임스탬프 기반 유효기간 검증**

4. **MultiSig 통합**
   - **MultiSig 지갑이 DAO의 Owner (DEFAULT_ADMIN_ROLE)**
   - MultiSig 지갑 주소 설정 기능
   - **다중 서명 방식: numConfirmationsRequired 수만큼의 유효한 서명 필요**
   - 소유자 확인 인터페이스 (`isOwner()` 메서드)
   - 필요 서명 수 확인 인터페이스 (`numConfirmationsRequired()` 메서드)
   - 권한 기반 접근 제어

5. **서명 관리 기능**
   - **서명 유효기간 설정 함수 (Owner만 가능)**
   - **사용된 서명 추적 및 저장**
   - **서명 만료 시간 검증**
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

// 상태 변수
address public multiSigWallet; // DAO Owner (DEFAULT_ADMIN_ROLE)
uint256 public signatureValidityPeriod; // 서명 유효기간 (초 단위)
mapping(bytes32 => bool) public usedSignatures; // 사용된 서명 추적
mapping(bytes32 => uint256) public signatureTimestamps; // 서명 생성 시간

// 서명 검증 함수 구조
function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4);
function _validateSignatures(bytes32 _hash, bytes memory _signature) internal view returns (bool);
function _recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address);
function setSignatureValidityPeriod(uint256 _period) external onlyOwner;
function _isSignatureExpired(bytes32 _signatureHash) internal view returns (bool);

// 핵심 검증 로직 예시 (다중 서명 + 재사용 방지 + 유효기간)
function _validateSignatures(bytes32 _hash, bytes memory _signature) internal returns (bool) {
    uint256 requiredSigs = IMultiSigWallet(multiSigWallet).numConfirmationsRequired();
    uint256 sigCount = _signature.length / 65;
    
    // 서명 개수가 필요 개수보다 적으면 실패
    if (sigCount < requiredSigs) return false;
    
    // 서명 해시 생성 (재사용 방지용)
    bytes32 signatureHash = keccak256(abi.encodePacked(_hash, _signature));
    
    // 서명 재사용 검증
    if (usedSignatures[signatureHash]) return false;
    
    // 서명 유효기간 검증
    if (_isSignatureExpired(signatureHash)) return false;
    
    address[] memory signers = new address[](sigCount);
    uint256 validSigs = 0;
    
    // 각 서명을 검증
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
    if (validSigs >= requiredSigs) {
        // 서명을 사용됨으로 표시
        usedSignatures[signatureHash] = true;
        return true;
    }
    
    return false;
}

// 중복 서명자 확인 헬퍼 함수
function _isDuplicate(address[] memory signers, address signer, uint256 currentIndex) internal pure returns (bool) {
    for (uint256 i = 0; i < currentIndex; i++) {
        if (signers[i] == signer) return true;
    }
    return false;
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
- `setSignatureValidityPeriod(uint256 _period)`: 서명 유효기간 설정
- `isSignatureUsed(bytes32 _signatureHash)`: 서명 사용 여부 확인
- `getSignatureTimestamp(bytes32 _signatureHash)`: 서명 생성 시간 조회
- `cleanupExpiredSignatures(bytes32[] _signatureHashes)`: 만료된 서명 정리

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

### 중요 구현 조건
- **DAO의 Owner는 반드시 MultiSigWallet Contract여야 함**
- **다중 서명 검증: MultiSigWallet의 numConfirmationsRequired 수만큼 서명 필요**
- **MultiSigWallet에 등록된 소유자들의 서명만 유효**
- **중복 서명자 방지: 같은 소유자가 여러 번 서명할 수 없음**
- **MultiSig 지갑이 DEFAULT_ADMIN_ROLE을 가져야 함**
- **검증된 서명은 즉시 사용됨으로 표시하여 재사용 방지**
- **서명 유효기간은 Owner만 설정 가능하며, 기본값 권장 (예: 1시간)**
- **만료된 서명은 자동으로 무효 처리**

### 서명 형식
- **연결된 서명 형식: signature1 + signature2 + ... (각 65바이트)**
- **서명 순서는 상관없음 (중복만 방지)**
- **필요 서명 수보다 많은 서명 제공 가능 (처음 유효한 것들만 사용)**
```