# EIP-1271 테스트 코드 생성 프롬프트

## 기본 테스트 프롬프트

```
다음 EIP-1271 구현에 대한 포괄적인 테스트 코드를 작성해주세요:

[여기에 구현 코드 붙여넣기]

### 테스트 프레임워크
- Hardhat + Ethers.js
- Chai assertion 라이브러리
- TypeScript 지원

### 테스트 카테고리

#### 1. 기본 기능 테스트
```javascript
describe("EIP-1271 Basic Functionality", () => {
  // 정상적인 서명 검증
  // 잘못된 서명 검증
  // 매직 값 반환 확인
});
```

#### 2. MultiSig 통합 테스트
```javascript
describe("MultiSig Integration", () => {
  // MultiSig 지갑 설정
  // 소유자 서명 검증
  // 비소유자 서명 거부
});
```

#### 3. 보안 테스트
```javascript
describe("Security Tests", () => {
  // 잘못된 서명 길이
  // 무효한 v 값
  // s-value 범위 초과
  // 제로 주소 검증
});
```

#### 4. 권한 테스트
```javascript
describe("Access Control", () => {
  // admin 권한 확인
  // 권한 없는 접근 차단
  // MultiSig 권한 검증
});
```

#### 5. 엣지 케이스 테스트
```javascript
describe("Edge Cases", () => {
  // 경계값 테스트
  // 예외 상황 처리
  // 가스 한도 테스트
});
```

### 테스트 헬퍼 함수

다음 헬퍼 함수들을 포함해주세요:
- 서명 생성 함수
- MultiSig 지갑 모킹
- 테스트 데이터 생성
- 어설션 헬퍼

### 테스트 데이터

실제적인 테스트 시나리오를 위한:
- 유효한 서명 예시
- 무효한 서명 예시
- 다양한 해시 값
- MultiSig 소유자 주소들

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
- MultiSig 지갑 컨트랙트
- 외부 의존성들
- 네트워크 호출

### 테스트 유틸리티

편의를 위한 유틸리티 함수들:
- 서명 생성 및 검증
- 테스트 데이터 팩토리
- 어설션 매처
- 테스트 환경 설정
```

## 보안 테스트 프롬프트

```
### 보안 중심 테스트

보안 취약점을 찾기 위한 테스트 코드를 작성해주세요:

#### 1. 공격 시나리오 테스트
```javascript
describe("Attack Scenarios", () => {
  it("should prevent signature replay attacks", async () => {
    // 서명 재사용 공격 테스트
  });
  
  it("should prevent signature malleability", async () => {
    // 서명 변조 공격 테스트
  });
  
  it("should prevent unauthorized access", async () => {
    // 권한 없는 접근 테스트
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
    // 서명 검증 가스 사용량 측정
  });
  
  it("should compare gas usage with different signature types", async () => {
    // 다양한 서명 타입별 가스 비교
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