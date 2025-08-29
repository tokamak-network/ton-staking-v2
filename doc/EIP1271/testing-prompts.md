# EIP-1271 테스트 코드 생성 프롬프트

## 기본 테스트 프롬프트

```
다음 EIP-1271 구현에 대한 포괄적인 테스트 코드를 작성해주세요:

[여기에 구현 코드 붙여넣기]
```

### 컨텍스트
- **구조**: Safe Wallet의 Signer 중 한명이 DAO Contract
- **DAO Owner**: MultiSigWallet Contract (별도의 MultiSig)
- **EIP-1271 검증**: DAO Contract가 자신의 Owner인 MultiSigWallet 소유자들의 서명 검증
- **Safe Wallet 호환성**: Safe Global 앱에서 DAO Contract 서명 시 EIP-1271 검증 가능

### 배포 환경 정보
- **네트워크**: Sepolia Testnet
- **DAO 구조**: DAOCommitteeProxy → DAOCommitteeProxy2 → DAOCommittee_V2
- **DAOCommitteeProxy 주소**: `0xA2101482b28E3D99ff6ced517bA41EFf4971a386`
- **업그레이드 방식**: DAOCommittee_V2 배포 후 DAOCommitteeProxy2의 `upgradeTo2()` 함수로 지정
- **MultiSigWallet ABI**: `test/abi/MultiSigWallet.json`
- **DAOCommitteeProxy2 ABI**: `test/abi/DAOCommitteeProxy2.json`

### 테스트 프레임워크
- Hardhat + Ethers.js
- Chai assertion 라이브러리
- TypeScript 지원
- Sepolia 테스트넷 연동 지원
- 실제 배포된 컨트랙트와의 통합 테스트

### 테스트 카테고리

#### 1. 기본 기능 테스트
```javascript
describe("EIP-1271 Basic Functionality", () => {
  // 정상적인 서명 검증 (MultiSigWallet 소유자들)
  // 잘못된 서명 검증
  // 매직 값 반환 확인 (0x1626ba7e)
  // 무효한 서명 반환 확인 (0xffffffff)
});
```

#### 2. MultiSigWallet 통합 테스트
```javascript
describe("MultiSigWallet Integration", () => {
  // MultiSigWallet이 DAO Owner인지 확인
  // MultiSigWallet 소유자들의 서명 검증
  // 비소유자 서명 거부
  // numConfirmationsRequired 기준 충족 확인
  // MultiSigWallet 소유자 변경 시 동작 확인
  // threshold 변경 시 동작 확인
});
```

#### 3. 다중 서명 검증 테스트
```javascript
describe("Multi-Signature Validation", () => {
  // 필요 서명 수 충족 시 성공
  // 필요 서명 수 미달 시 실패
  // 중복 서명자 방지
  // 서명 순서 무관성 확인
  // 초과 서명 제공 시 처리
});
```

#### 4. 보안 테스트
```javascript
describe("Security Tests", () => {
  // 서명 재사용 방지
  // 잘못된 서명 길이 거부
  // 무효한 v 값 거부 (27, 28 외)
  // s-value 범위 초과 거부
  // 제로 주소 검증
  // 서명 변조 감지
});
```

#### 5. 권한 테스트
```javascript
describe("Access Control", () => {
  // MultiSigWallet admin 권한 확인
  // 권한 없는 접근 차단
  // onlyOwner 함수 접근 제어
  // MultiSigWallet 설정 권한 검증
});
```

#### 6. Safe Wallet 호환성 테스트
```javascript
describe("Safe Wallet Compatibility", () => {
  // Safe Wallet에서 DAO Contract 서명 시나리오
  // EIP-1271 표준 준수 확인
  // Safe Global 앱 호환성 검증
});
```

#### 7. 실제 배포 환경 통합 테스트
```javascript
describe("Sepolia Integration Tests", () => {
  // Sepolia 네트워크 연결 테스트
  // 실제 DAOCommitteeProxy 주소로 연결
  // DAOCommittee_V2 배포 및 업그레이드 테스트
  // 업그레이드 후 EIP-1271 기능 검증
  // 실제 MultiSigWallet과의 통합 테스트
});
```

#### 8. 프록시 패턴 테스트
```javascript
describe("Proxy Pattern Tests", () => {
  // DAOCommitteeProxy → DAOCommitteeProxy2 → DAOCommittee_V2 구조 검증
  // upgradeTo2 함수 테스트
  // 업그레이드 전후 상태 보존 확인
  // 프록시를 통한 EIP-1271 호출 테스트
});
```

### 테스트 헬퍼 함수

다음 헬퍼 함수들을 포함해주세요:
- **MultiSigWallet 소유자들의 서명 생성 함수**
- **numConfirmationsRequired 수만큼 서명 생성**
- **연결된 서명 형식 생성 헬퍼 (signature1 + signature2 + ...)**
- **중복 서명자 테스트 헬퍼**
- **서명 재사용 테스트 헬퍼**
- **서명 순서 변경 테스트 헬퍼**
- **DAOCommitteeProxy2 연동 헬퍼** (upgradeTo2 함수 호출)
- **Sepolia 네트워크 연결 헬퍼**
- **실제 배포된 컨트랙트 인스턴스 생성**
- **ABI 파일 로드 헬퍼** (MultiSigWallet.json, DAOCommitteeProxy2.json)
- 테스트 데이터 생성
- 어설션 헬퍼

### 테스트 데이터

실제적인 테스트 시나리오를 위한:
- **MultiSigWallet 소유자들의 유효한 서명 예시**
- **비소유자의 무효한 서명 예시**
- **DAO Owner로 설정된 MultiSigWallet 주소**
- **Sepolia 네트워크 설정**
  - DAOCommitteeProxy 주소: `0xA2101482b28E3D99ff6ced517bA41EFf4971a386`
  - RPC URL 및 네트워크 설정
- **실제 배포 시나리오**
  - DAOCommittee_V2 새 배포
  - DAOCommitteeProxy2.upgradeTo2() 호출
  - 업그레이드 후 EIP-1271 기능 테스트
- 다양한 해시 값
- MultiSigWallet 소유자 주소들 (3-5개)
- numConfirmationsRequired 설정 (예: 2/3, 3/5)

### 실제 환경 설정 예시

```javascript
// hardhat.config.ts 설정 예시
const config: HardhatUserConfig = {
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};

// 테스트 설정 예시
describe("EIP-1271 Sepolia Integration", () => {
  const DAO_COMMITTEE_PROXY = "0xA2101482b28E3D99ff6ced517bA41EFf4971a386";
  
  beforeEach(async () => {
    // ABI 파일 로드
    const multiSigABI = require("../test/abi/MultiSigWallet.json");
    const proxyABI = require("../test/abi/DAOCommitteeProxy2.json");
    
    // 실제 배포된 컨트랙트 연결
    const daoProxy = new ethers.Contract(DAO_COMMITTEE_PROXY, proxyABI.abi, signer);
    
    // DAOCommittee_V2 새로 배포
    const DAOCommitteeV2 = await ethers.getContractFactory("DAOCommittee_V2");
    const newImplementation = await DAOCommitteeV2.deploy();
    
    // 업그레이드 실행
    await daoProxy.upgradeTo2(newImplementation.address);
  });
});
```

각 테스트에 대해 상세한 설명과 함께 완전한 테스트 코드를 제공해주세요.
```

## 고급 테스트 프롬프트

```
### 고급 테스트 시나리오

다음 고급 테스트 시나리오들을 구현해주세요:

#### 1. Fuzzing 테스트
```javascript
describe("Fuzzing Tests", () => {
  // 랜덤 서명 데이터 테스트
  // 랜덤 해시 값 테스트
  // 경계값 주변 테스트
});
```

#### 2. 가스 효율성 테스트
```javascript
describe("Gas Efficiency", () => {
  // 가스 사용량 측정
  // 최적화 전후 비교
  // 가스 한도 테스트
});
```

#### 3. 통합 테스트
```javascript
describe("Integration Tests", () => {
  // 실제 MultiSig와 통합
  // 다른 컨트랙트와의 상호작용
  // 메타 트랜잭션 테스트
});
```

#### 4. 성능 테스트
```javascript
describe("Performance Tests", () => {
  // 대량 서명 처리
  // 동시 접근 테스트
  // 메모리 사용량 테스트
});
```

### 모킹 및 스텁

다음 컴포넌트들의 모킹 코드를 제공해주세요:
- **MultiSigWallet 컨트랙트** (DAO Owner 역할)
  - `isOwner()` 함수 모킹
  - `getOwners()` 함수 모킹  
  - `numConfirmationsRequired()` 함수 모킹
- **Safe Wallet 시뮬레이션** (DAO Contract를 서명 대상으로)
- AccessControl 권한 시스템
- 외부 의존성들
- 네트워크 호출

### 테스트 유틸리티

편의를 위한 유틸리티 함수들:
- **MultiSigWallet 소유자들의 서명 생성 및 검증**
- **연결된 서명 데이터 생성** (signature1 + signature2 + ...)
- **서명 해시 계산** (재사용 방지용)
- 테스트 데이터 팩토리
- 어설션 매처
- 테스트 환경 설정
- **MultiSigWallet 배포 및 설정 헬퍼**
```

## 보안 테스트 프롬프트

```
### 보안 중심 테스트

보안 취약점을 찾기 위한 테스트 코드를 작성해주세요:

#### 1. 공격 시나리오 테스트
```javascript
describe("Attack Scenarios", () => {
  it("should prevent signature replay attacks", async () => {
    // 서명 재사용 공격 테스트 (usedSignatures 매핑 활용)
  });
  
  it("should prevent signature malleability", async () => {
    // 서명 변조 공격 테스트 (s-value 범위 검증)
  });
  
  it("should prevent unauthorized access", async () => {
    // 권한 없는 접근 테스트 (onlyOwner 검증)
  });
  
  it("should reject non-multisig owner signatures", async () => {
    // MultiSigWallet 소유자가 아닌 서명 거부 테스트
  });
  
  it("should enforce MultiSigWallet signature standards", async () => {
    // MultiSigWallet 서명 기준 준수 테스트 (numConfirmationsRequired)
  });
  
  it("should validate multiple owner signatures correctly", async () => {
    // 다중 소유자 서명 검증 테스트 (threshold 충족)
  });
  
  it("should reject insufficient signatures", async () => {
    // 필요 서명 수보다 적은 서명 거부 테스트
  });
  
  it("should prevent duplicate signers", async () => {
    // 중복 서명자 방지 테스트 (_isDuplicate 함수)
  });
  
  it("should prevent signature reuse", async () => {
    // 서명 재사용 방지 테스트 (signatureHash 추적)
  });
  
  it("should handle signature order independence", async () => {
    // 서명 순서 무관성 테스트 (정렬된 해시 생성)
  });
  
  it("should reject signatures from non-admin MultiSigWallet", async () => {
    // DEFAULT_ADMIN_ROLE이 없는 MultiSigWallet 거부
  });

});
```

#### 2. 암호학적 보안 테스트
```javascript
describe("Cryptographic Security", () => {
  it("should validate ECDSA signatures correctly", async () => {
    // ECDSA 검증 정확성 테스트
  });
  
  it("should reject invalid signature formats", async () => {
    // 잘못된 서명 형식 거부 테스트
  });
});
```


### 자동화된 보안 테스트

다음을 포함한 자동화 스크립트:
- 정적 분석 도구 실행
- 보안 테스트 자동 실행
- 취약점 리포트 생성

각 테스트에 대해 예상 결과와 실패 시나리오도 함께 설명해주세요.
```

## 성능 테스트 프롬프트

```
### 성능 및 가스 최적화 테스트

#### 1. 가스 사용량 분석
```javascript
describe("Gas Usage Analysis", () => {
  it("should measure gas consumption for signature verification", async () => {
    // isValidSignature 함수 가스 사용량 측정
  });
  
  it("should compare gas usage with different signature counts", async () => {
    // 서명 개수별 가스 비교 (2개, 3개, 5개 등)
  });
  
  it("should measure gas for validateAndUseSignature", async () => {
    // 서명 사용 표시 포함 가스 측정
  });
  
  it("should analyze gas efficiency of signature sorting", async () => {
    // 서명자 정렬 알고리즘 가스 효율성
  });
});
```

#### 2. 벤치마크 테스트
```javascript
describe("Benchmark Tests", () => {
  // 처리 속도 측정
  // 메모리 사용량 분석
  // 네트워크 호출 최적화
});
```

#### 3. 스케일링 테스트
```javascript
describe("Scaling Tests", () => {
  // 대량 트랜잭션 처리
  // 동시 사용자 시뮬레이션
  // 부하 테스트
});
```

성능 메트릭 수집 및 리포팅 기능도 함께 구현해주세요.
```