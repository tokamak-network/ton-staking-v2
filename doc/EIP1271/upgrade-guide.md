# EIP-1271 업그레이드 가이드 프롬프트

## 기존 컨트랙트 업그레이드 프롬프트

```
기존 스마트 컨트랙트에 EIP-1271 기능을 추가하는 업그레이드를 도와주세요:

### 현재 컨트랙트 정보
[여기에 기존 컨트랙트 코드 붙여넣기]

### 업그레이드 요구사항

#### 1. 호환성 유지
- 기존 함수들의 동작 변경 없음
- 스토리지 레이아웃 충돌 방지
- 기존 인터페이스 유지

#### 2. 새로운 기능 추가
- EIP-1271 `isValidSignature` 함수
- **단일 서명 검증 로직**
- **MultiSig 지갑을 DAO Owner로 설정**
- MultiSig 지갑 관리 기능
- 관련 이벤트 및 에러 정의

#### 3. 보안 강화
- **MultiSig Owner 권한 체계 통합**
- 기존 보안 모델과의 조화
- 업그레이드 과정에서의 보안 유지
- **단일 서명 검증의 보안 고려사항**

### 업그레이드 전략

다음 중 적절한 전략을 선택하고 구현해주세요:

#### A) 직접 업그레이드
- 기존 컨트랙트에 직접 기능 추가
- 스토리지 변수 추가
- 새로운 함수 구현

#### B) 프록시 패턴 업그레이드
- 새로운 구현 컨트랙트 작성
- 프록시를 통한 업그레이드
- 스토리지 호환성 보장

#### C) 모듈러 업그레이드
- EIP-1271 기능을 별도 모듈로 분리
- 기존 컨트랙트와 연동
- 느슨한 결합 유지

### 마이그레이션 계획

#### 1. 사전 준비
```solidity
// 업그레이드 전 체크리스트
- [ ] 기존 상태 백업
- [ ] 테스트넷 검증
- [ ] 가스 비용 분석
- [ ] 보안 감사
```

#### 2. 업그레이드 실행
```solidity
// 업그레이드 스크립트
- [ ] 컨트랙트 배포
- [ ] 상태 마이그레이션
- [ ] 권한 이전
- [ ] 검증 테스트
```

#### 3. 사후 검증
```solidity
// 업그레이드 후 확인사항
- [ ] 기존 기능 정상 동작
- [ ] 새 기능 테스트
- [ ] 성능 확인
- [ ] 보안 재검토
```

### 구현 가이드

다음 순서로 구현 코드를 제공해주세요:

1. **스토리지 변수 추가**
   - **MultiSig 지갑 주소 저장 변수**
   - 새로운 상태 변수 정의
   - 기존 스토리지와의 충돌 방지
   - 초기화 로직

2. **인터페이스 구현**
   - EIP-1271 인터페이스 추가
   - **IMultiSigWallet 인터페이스 정의**
   - 기존 인터페이스와의 통합
   - 버전 관리

3. **핵심 로직 구현**
   - **단일 서명 검증 함수**
   - **MultiSig 소유자 확인 로직**
   - MultiSig 통합 로직
   - 에러 처리

4. **권한 관리 통합**
   - **MultiSig를 DEFAULT_ADMIN_ROLE로 설정**
   - 기존 AccessControl과 연동
   - 새로운 권한 정의
   - 권한 검증 로직

5. **이벤트 및 에러**
   - **MultiSig 지갑 변경 이벤트**
   - 새로운 이벤트 정의
   - 커스텀 에러 추가
   - 로깅 개선

### 테스트 전략

업그레이드 검증을 위한 테스트:
- 기존 기능 회귀 테스트
- 새 기능 단위 테스트
- 통합 테스트
- 성능 테스트

각 단계별로 상세한 구현 코드와 설명을 제공해주세요.
```

## 버전 관리 프롬프트

```
### 컨트랙트 버전 관리

EIP-1271 업그레이드에 따른 버전 관리 시스템을 구현해주세요:

#### 1. 버전 정보 관리
```solidity
function version() public pure returns (string memory);
function getFeatures() public pure returns (string[] memory);
function isFeatureSupported(bytes4 interfaceId) public view returns (bool);
```

#### 2. 호환성 체크
```solidity
function isCompatibleWith(string memory requiredVersion) public pure returns (bool);
function getMigrationPath(string memory fromVersion) public pure returns (bytes memory);
```

#### 3. 기능 플래그
```solidity
mapping(bytes4 => bool) public supportedFeatures;
function enableFeature(bytes4 featureId) external onlyOwner;
function disableFeature(bytes4 featureId) external onlyOwner;
```

### 업그레이드 스크립트

자동화된 업그레이드를 위한 스크립트:
- 배포 스크립트
- 마이그레이션 스크립트
- 검증 스크립트
- 롤백 스크립트

TypeScript/JavaScript로 구현해주세요.
```

## 롤백 계획 프롬프트

```
### 업그레이드 롤백 계획

EIP-1271 업그레이드 실패 시 롤백 전략을 수립해주세요:

#### 1. 롤백 조건
- 치명적 버그 발견
- 성능 저하
- 보안 취약점
- 사용자 피드백

#### 2. 롤백 메커니즘
```solidity
contract UpgradeManager {
    address public previousImplementation;
    bool public emergencyMode;
    
    function emergencyRollback() external onlyEmergencyAdmin;
    function pauseNewFeatures() external onlyOwner;
}
```

#### 3. 데이터 보존
- 상태 변수 백업
- 이벤트 로그 보존
- 사용자 데이터 무결성

#### 4. 커뮤니케이션 계획
- 사용자 공지
- 개발자 알림
- 문서 업데이트

구체적인 롤백 절차와 코드를 제공해주세요.
```