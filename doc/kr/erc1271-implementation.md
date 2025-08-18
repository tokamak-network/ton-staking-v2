# DAOCommittee_V2의 ERC-1271 구현

## 개요

DAOCommittee_V2 컨트랙트가 **ERC-1271 표준 서명 검증 방법**을 지원하도록 업그레이드되었습니다. 이를 통해 스마트 컨트랙트 서명 검증이 가능해지며, Safe Global 생태계를 포함한 최신 Web3 인프라와의 호환성이 크게 향상되었습니다.

## ERC-1271이란?

ERC-1271은 스마트 컨트랙트가 자체적으로 서명을 검증할 수 있도록 하는 이더리움 표준입니다. 이를 통해 다음이 가능해집니다:

- **스마트 컨트랙트 지갑**: 컨트랙트가 서명자 역할 수행
- **다중 서명 검증**: 복잡한 서명 체계 지원
- **크로스 플랫폼 호환성**: Safe Global, MetaMask 등 Web3 도구와 연동
- **유연한 인증**: 단순한 EOA(외부 소유 계정) 서명을 넘어선 인증

## 구현 세부사항

### 핵심 함수

```solidity
function isValidSignature(
    bytes32 _hash,
    bytes memory _signature
) external view returns (bytes4 magicValue)
```

### 주요 기능

#### 1. **MultiSigWallet 통합**
- MultiSigWallet의 모든 owner 서명 검증
- 단일 서명 검증 (효율적인 가스 사용)
- `IMultiSigWallet.isOwner()`를 통한 자동 owner 확인

#### 2. **보안 기능**
- **EIP-2 가변성 방지**: 서명 가변성 공격 차단
- **접근 제어**: admin 승인된 MultiSigWallet만 사용 가능
- **입력 검증**: 포괄적인 서명 형식 검증

#### 3. **Safe Global 호환성**
- Safe Protocol Kit과 완전 호환
- 문자열 메시지 및 EIP-712 타입 데이터 지원
- Safe Transaction Service와 연동

## 아키텍처

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Safe SDK      │───▶│  DAOCommittee_V2 │───▶│  MultiSigWallet │
│  Protocol Kit   │    │   (ERC-1271)     │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │                          │
                              ▼                          ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  서명 검증        │    │  Owner EOAs     │
                       │                  │    │                 │
                       └──────────────────┘    └─────────────────┘
```

## 사용 예제

### 1. 기본 서명 검증

```javascript
// ethers.js 사용
const message = "DAO 거버넌스 제안";
const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(message));

// MultiSigWallet owner가 메시지 서명
const signature = await owner.signMessage(ethers.utils.arrayify(hash));

// DAOCommittee_V2를 통한 서명 검증
const isValid = await daoCommittee.isValidSignature(hash, signature);
// 반환값: 유효하면 0x1626ba7e (MAGICVALUE), 무효하면 0xffffffff
```

### 2. Safe Global 통합

```javascript
// Safe Protocol Kit 사용
const protocolKit = await Safe.create({
  ethAdapter,
  safeAddress: DAO_COMMITTEE_ADDRESS
});

// 메시지 생성 및 서명
const safeMessage = protocolKit.createMessage("테스트 메시지");
const signedMessage = await protocolKit.signMessage(
  safeMessage,
  SigningMethod.ETH_SIGN_TYPED_DATA_V4
);

// ERC-1271을 통한 자동 서명 검증
const isValid = await protocolKit.isValidSignature(messageHash, signature);
```

### 3. MultiSigWallet 설정

```solidity
// 컨트랙트 owner만 MultiSigWallet 설정 가능
function setMultiSigWallet(address _multiSigWallet) external onlyOwner {
    // MultiSigWallet이 admin 역할을 가지고 있는지 검증
    require(hasRole(DEFAULT_ADMIN_ROLE, _multiSigWallet), "Not an admin");
    multiSigWallet = _multiSigWallet;
    emit MultiSigWalletSet(oldWallet, _multiSigWallet);
}
```

## 보안 고려사항

### ✅ 구현된 보안 기능

1. **서명 가변성 방지**
   - EIP-2 준수 `s` 값 검증
   - 적절한 `v` 값 확인 (27/28만 허용)

2. **접근 제어**
   - MultiSigWallet은 `DEFAULT_ADMIN_ROLE` 필수
   - 컨트랙트 owner만 MultiSigWallet 설정 가능

3. **입력 검증**
   - 서명 길이 검증 (65바이트)
   - 영 주소 확인

### ⚠️ 중요 사항

- MultiSigWallet owner 중 **한 명의 서명**만으로 검증 완료
- ethers.js와의 호환성을 위해 **Ethereum Signed Message** 형식 사용
- 가스 효율적인 단일 서명 처리로 DoS 공격 방지

## 테스트

다음 항목들을 포괄하는 종합적인 테스트가 포함되어 있습니다:

- ✅ 유효한 서명 검증
- ✅ 무효한 서명 거부
- ✅ MultiSigWallet owner 확인
- ✅ 보안 엣지 케이스
- ✅ 접근 제어 메커니즘
- ✅ EIP-2 가변성 방지

```bash
# ERC-1271 테스트 실행
npx hardhat test test/erc1271-test.ts
```

## 통합 가이드

### DApp 개발자용

```javascript
// 컨트랙트가 ERC-1271을 지원하는지 확인
const supportsERC1271 = await contract.supportsInterface("0x1626ba7e");

// 서명 검증
if (supportsERC1271) {
  const isValid = await contract.isValidSignature(hash, signature);
  if (isValid === "0x1626ba7e") {
    // 서명이 유효함
  }
}
```

### Safe Global 사용자용

DAOCommittee_V2 컨트랙트는 다음과 완전히 호환됩니다:
- **Safe{Wallet}**: 직접 통합 지원
- **Safe Protocol Kit**: 메시지 서명 및 검증
- **Safe Transaction Service**: 오프체인 메시지 저장
- **Safe API Kit**: 트랜잭션 및 메시지 관리

## 배포 정보

### 컨트랙트 주소
- **메인넷**: `TBD`
- **세폴리아**: `TBD`

### ABI 업데이트
컨트랙트 ABI에 다음이 추가되었습니다:
- `isValidSignature(bytes32,bytes)` - ERC-1271 검증
- `setMultiSigWallet(address)` - MultiSigWallet 설정
- `MultiSigWalletSet(address,address)` - 지갑 변경 이벤트

## 마이그레이션 가이드

### 이전 버전으로부터

1. **새 컨트랙트 배포**: ERC-1271 지원하는 DAOCommittee_V2 배포
2. **MultiSigWallet 설정**: `setMultiSigWallet()`을 사용하여 MultiSigWallet 주소 설정
3. **통합 검증**: MultiSigWallet owner들과 서명 검증 테스트
4. **프론트엔드 업데이트**: DApp에 ERC-1271 서명 검증 통합

### 하위 호환성

- 기존 DAOCommittee 기능은 모두 그대로 유지
- ERC-1271은 기존 동작에 영향을 주지 않는 추가 기능
- 기존 접근 제어 및 거버넌스 메커니즘 보존

## 참고 자료

- [EIP-1271: 컨트랙트용 표준 서명 검증 방법](https://eips.ethereum.org/EIPS/eip-1271)
- [Safe Global 문서](https://docs.safe.global/)
- [Safe Protocol Kit 서명 가이드](https://docs.safe.global/sdk/protocol-kit/guides/signatures)
- [EIP-2: Homestead 하드포크 변경사항](https://eips.ethereum.org/EIPS/eip-2)

## 지원

기술 지원 및 문의사항:
- **GitHub Issues**: [저장소 이슈](https://github.com/your-repo/issues)
- **문서**: [개발자 가이드](../developer-guide/)
- **커뮤니티**: [Discord/Telegram 채널]

## 버전 히스토리

### v2.5.0 (2024년 12월)
- ✅ ERC-1271 표준 서명 검증 구현
- ✅ MultiSigWallet 통합
- ✅ Safe Global 생태계 호환성
- ✅ 포괄적인 보안 기능 및 테스트

### 이전 버전
- v2.4.x: 기본 DAO 거버넌스 기능
- v2.3.x: 초기 MultiSig 지원

---

**최종 업데이트**: 2024년 12월  
**버전**: 2.5.0  
**호환성**: Safe Global SDK, ethers.js v5+, Hardhat
