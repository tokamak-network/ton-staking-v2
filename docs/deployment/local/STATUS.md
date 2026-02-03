# TON Staking V3 로컬 배포 - 현재 상태 및 제한사항

> 최종 업데이트: 2026-02-03

## 현재 구축 상태

### ✅ 정상 작동

1. **Genesis 생성** ✓
   - `.devnet/genesis-l1-staking-v3.json` 생성 완료
   - 모든 TON Staking V3 컨트랙트 배포됨
   - Optimism L1 컨트랙트 포함
   - 테스트 계정에 ETH 및 TON 할당 완료

2. **L1 네트워크 (Anvil)** ✓
   - Chain ID: 900
   - Port: 8545
   - 블록 생성: 정상 (12초 간격)
   - 모든 컨트랙트 조회 가능

3. **L2 Execution (op-geth)** ✓
   - Chain ID: 901
   - Port: 9545
   - Genesis 초기화 완료
   - RPC 접근 가능

4. **컨트랙트 배포** ✓
   - TON, WTON: 정상 배포 및 조회 가능
   - SeigManagerV3_1: 배포됨, V3 마이그레이션 완료
   - DepositManagerV3: 배포됨
   - Layer2ManagerV3: 배포됨
   - RAT: 배포됨
   - SystemConfig: 배포됨

5. **문서화** ✓
   - README.md: 개요 및 빠른 참조
   - QUICKSTART.md: 단계별 가이드
   - IMPLEMENTATION.md: 기술 상세
   - VALIDATOR-SETUP.md: Validator 설정 가이드
   - STATUS.md: 현재 문서

### ⚠️ 부분적 작동 / 알려진 이슈

1. **op-node** ⚠️
   - 상태: 실행 실패
   - 원인: SystemConfig의 `unsafeBlockSigner` 미설정
   - 에러: `failed to fetch unsafe block signing address from system config`
   - 영향: L2 블록이 자동 생성되지 않음
   - 해결 방법: SystemConfig 초기화 필요 또는 Genesis에 스토리지 슬롯 추가

2. **cast 명령 호환성** ⚠️
   - 상태: 일부 명령 작동 안 함
   - 문제: `cast send` 명령이 Anvil과 호환되지 않음
   - 에러: `unknown field 'input'`
   - 영향: 스크립트 기반 자동화 어려움
   - 해결 방법: curl + RPC 직접 호출 사용

3. **L2 등록** ⚠️
   - 상태: SystemConfig가 Layer2로 미등록
   - 함수: `registerCandidateAddOn` (복잡한 파라미터 필요)
   - 영향: Validator 등록 전 L2 등록 필요
   - 해결 방법: Genesis에서 자동 등록 또는 별도 스크립트

4. **RAT 파라미터** ⚠️
   - 최소 담보금: ~60,000,000,000 TON (로컬 테스트용으로 너무 높음)
   - slashingPenalty: 10,000,000,000 TON
   - attentionCost: 1,000,000,000 TON
   - 영향: 로컬 테스트를 위해 많은 TON 필요
   - 해결 방법: Genesis에서 RAT 파라미터 조정 필요

### ❌ 현재 작동하지 않음

1. **RAT Challenge 생성** ❌
   - 원인: L2 블록이 생성되지 않음 (op-node 미작동)
   - 영향: RAT Client 테스트 불가
   - 해결: op-node 실행 후 테스트 가능

2. **Validator 자동 설정** ❌
   - 원인: cast send 호환성 문제
   - 영향: 수동 설정 스크립트 작동 안 함
   - 해결: Hardhat 스크립트 또는 curl 기반 스크립트 필요

3. **L2 → L1 메시지** ❌
   - 원인: op-node, batcher, proposer 미작동
   - 영향: 크로스 레이어 기능 테스트 불가

## 현재 가능한 테스트

### ✅ 실행 가능한 테스트

1. **TON/WTON 기본 기능**
   ```bash
   # TON 잔액 조회 (curl 사용)
   # WTON 스왑 조회
   # 컨트랙트 상태 조회
   ```

2. **컨트랙트 배포 확인**
   ```bash
   # 모든 컨트랙트 코드 확인
   # 컨트랙트 getter 함수 호출
   ```

3. **Genesis 검증**
   ```bash
   # Genesis 파일 구조 확인
   # 초기 배포 상태 확인
   ```

### ❌ 현재 불가능한 테스트

1. Validator 등록 및 관리
2. RAT Challenge 응답
3. L2 스테이킹
4. 크로스 레이어 메시징
5. Fault Proof 시스템

## 개선 우선순위

### P0 (Critical - 차단 요소)

1. **SystemConfig 초기화**
   - 작업: `unsafeBlockSigner` 스토리지 슬롯 설정
   - 방법: DeployAll 스크립트에 initialize 트랜잭션 추가
   - 영향: op-node 실행 가능 → L2 블록 생성 → RAT 테스트 가능

2. **RAT 파라미터 조정**
   - 작업: 로컬 테스트용 낮은 값 설정
   - 방법: DeployAll 스크립트에서 파라미터 조정
   - 예시:
     ```solidity
     slashingPenalty: 100 TON
     attentionCost: 10 TON
     minimumCollateral: 1,000 TON
     ```

3. **L2 자동 등록**
   - 작업: SystemConfig를 Layer2로 자동 등록
   - 방법: DeployAll 스크립트에 `registerCandidateAddOn` 호출 추가

### P1 (High - 편의성 향상)

4. **Hardhat 스크립트 작성**
   - cast 대신 Hardhat/ethers.js 사용
   - Validator 설정 자동화
   - 트랜잭션 전송 안정화

5. **테스트 계정 TON 배분**
   - Genesis에서 Validator 계정들에게 충분한 TON 할당
   - 수동 전송 불필요

### P2 (Medium - 기능 개선)

6. **Docker Compose 개선**
   - op-node 실행 조건 완화
   - 재시작 안정성 개선

7. **RAT Client 설정 템플릿**
   - 3개 Validator용 config 자동 생성
   - Docker 기반 RAT Client 실행

8. **모니터링 대시보드**
   - Grafana/Prometheus 통합
   - 웹 UI 개발

## 권장 사용 시나리오 (현재 상태)

### 시나리오 1: 컨트랙트 개발 및 테스트

```bash
# 1. Genesis 생성
make devnet-allocs-offline

# 2. L1 시작
docker-compose up -d l1

# 3. 컨트랙트 조회/테스트
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_call",...}' \
  http://localhost:8545
```

**가능한 작업**:
- 컨트랙트 함수 조회
- 상태 변수 확인
- 이벤트 로그 조회

### 시나리오 2: Genesis 수정 테스트

```bash
# 1. DeployAll.s.sol 수정
# 2. Genesis 재생성
rm -rf .devnet
make devnet-allocs-offline

# 3. 결과 확인
cat .devnet/addresses.json
```

**가능한 작업**:
- 새로운 컨트랙트 추가
- 초기 파라미터 변경
- 계정 설정 수정

### 시나리오 3: 문서 작성 및 검증

**가능한 작업**:
- 문서 정확성 확인
- 예제 코드 테스트
- 명령어 검증

## 개발 로드맵

### Phase 1: 핵심 기능 복구 (1-2주)
- [ ] SystemConfig 초기화
- [ ] RAT 파라미터 조정
- [ ] L2 자동 등록
- [ ] Hardhat 설정 스크립트

### Phase 2: 자동화 및 안정화 (2-3주)
- [ ] Validator 자동 설정
- [ ] RAT Client Docker 이미지
- [ ] E2E 테스트 스크립트
- [ ] 통합 테스트 환경

### Phase 3: 고급 기능 (4주+)
- [ ] 웹 UI
- [ ] 모니터링 대시보드
- [ ] 멀티 L2 지원
- [ ] 프로덕션 배포 가이드

## 알려진 버그 및 회피 방법

### Bug #1: cast send 실패
**증상**: `unknown field 'input'` 에러
**회피**: curl + RPC 직접 호출 사용

### Bug #2: op-node 시작 실패
**증상**: `unsafeBlockSigner not found` 에러
**회피**: op-node 없이 L1만 사용

### Bug #3: 높은 최소 담보금
**증상**: Validator 등록 시 `InsufficientCollateralError`
**회피**: 많은 TON 스테이킹 또는 RAT 파라미터 수정

## 참고 문서

- [빠른 시작](./QUICKSTART.md) - 로컬 환경 구축
- [구현 상세](./IMPLEMENTATION.md) - 기술 설명
- [Validator 설정](./VALIDATOR-SETUP.md) - Validator 가이드
- [메인 가이드](./README.md) - 개요 및 참조

## 문의 및 이슈 보고

- GitHub Issues: https://github.com/tokamak-network/ton-staking-v2/issues
- 브랜치: `ton-staking-v3/deploy-local`
