# TON Staking V3 로컬 배포 - 현재 상태

> 최종 업데이트: 2026-02-03

## 전체 상태 요약

✅ **L1 + L2 네트워크 정상 작동**  
✅ **모든 TON Staking 컨트랙트 배포 완료**  
⚠️ **일부 고급 기능 미구현 (Validator 등록, RAT)**

---

## ✅ 정상 작동 중인 기능

### 1. L1 네트워크 (Geth with Clique PoA)
- Chain ID: 900
- Port: 8545
- 블록 생성: 정상 (~1초 간격)
- 상태: ✅ 완전 작동

### 2. L2 네트워크 (Optimism Stack)
- **L2 Execution (op-geth)**
  - Chain ID: 901
  - Port: 9545
  - Debug API: ✅ 활성화 (`debug_accountRange` 지원)
  - 상태: ✅ 정상 작동
  
- **op-node**
  - Port: 7545
  - L2 블록 생성: ✅ 정상 작동
  - L1 연동: ✅ 정상
  
- **Batcher & Proposer**
  - 상태: ✅ 실행 중

### 3. 컨트랙트 배포
모든 TON Staking V3 컨트랙트가 Genesis를 통해 사전 배포되어 있습니다:

- ✅ TON, WTON 토큰
- ✅ SeigManagerV3_1 (시뇨리지 관리)
- ✅ DepositManagerV3 (스테이킹 관리)
- ✅ Layer2ManagerV3 (L2 관리)
- ✅ L1BridgeRegistryV1_2 (브리지 TVL)
- ✅ RAT (Validator 테스트)
- ✅ ValidatorRewardV1 (보상 풀)
- ✅ Optimism L1 컨트랙트 (SystemConfig, OptimismPortal 등)

### 4. 기본 기능
- ✅ TON/WTON 잔액 조회
- ✅ 컨트랙트 함수 호출 (view functions)
- ✅ 트랜잭션 전송 (curl 또는 `--legacy` 플래그 사용)
- ✅ 이벤트 로그 조회
- ✅ L1 ↔ L2 통신

---

## ⚠️ 알려진 제한사항

### 1. cast 명령 호환성 이슈
**문제**: 일부 `cast send` 명령에서 경고 발생  
**해결 방법**: 
- `--legacy` 플래그 사용
- 또는 curl + RPC 직접 호출

**예시**:
```bash
# cast 사용 시
cast send $CONTRACT "function()" --legacy --private-key $KEY --rpc-url $RPC

# curl 사용 시 (권장)
DATA=$(cast calldata "function()")
curl -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_sendTransaction\",...}" \
  $RPC_URL
```

### 2. L2 등록 미완료
**문제**: SystemConfig가 Layer2로 자동 등록되지 않음  
**영향**: Validator 등록 전 수동으로 L2 등록 필요  
**해결**: `registerCandidateAddOn` 함수 호출 (복잡한 파라미터 필요)

### 3. RAT 파라미터 (프로덕션 값)
**문제**: 로컬 테스트용으로 너무 높은 담보금 요구  
**현재 값**:
- 최소 담보금: ~60,000,000,000 TON
- slashingPenalty: 10,000,000,000 TON
- attentionCost: 1,000,000,000 TON

**영향**: 로컬 테스트 시 많은 TON 필요  
**권장**: Genesis 생성 시 파라미터 조정

---

## ❌ 현재 미구현 기능

1. **Validator 자동 등록**
   - Genesis에서 자동 등록 미지원
   - 수동 스크립트 필요

2. **RAT Client 통합 테스트**
   - RAT 파라미터 조정 필요
   - L2 등록 필요

3. **웹 UI**
   - 개발 예정

---

## 테스트 가능 범위

### ✅ 현재 테스트 가능
- L1/L2 네트워크 연결
- TON/WTON 토큰 조회 및 전송
- 컨트랙트 상태 확인
- Genesis 파일 검증
- 기본 트랜잭션 실행

### ⚠️ 추가 설정 필요
- Validator 등록 (수동 스크립트)
- L2 스테이킹 (L2 등록 후)
- RAT Challenge (파라미터 조정 후)

### ❌ 현재 불가능
- 자동 Validator 설정
- RAT Client 완전 통합 테스트

---

## 권장 사용 방법

### 기본 테스트
```bash
# 1. 환경 시작
make devnet-allocs-offline
make devnet-start

# 2. 상태 확인
make devnet-info

# 3. 컨트랙트 조회
export RPC_URL="http://localhost:8545"
export TON=$(jq -r '.ton' .devnet/addresses.json)
cast call $TON "name()(string)" --rpc-url $RPC_URL

# 4. 잔액 확인 (curl 권장)
DEPLOYER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
DATA=$(cast calldata "balanceOf(address)" $DEPLOYER)
curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"method\":\"eth_call\",\"params\":[{\"to\":\"$TON\",\"data\":\"$DATA\"},\"latest\"],\"id\":1}" \
  $RPC_URL | jq -r '.result' | xargs cast --to-dec | xargs cast from-wei
```

### 환경 관리
```bash
# 중지 (데이터 유지)
make devnet-stop

# 완전 초기화
docker-compose down -v
rm -rf .devnet

# 재시작
make devnet-allocs-offline
make devnet-start
```

---

## 개선 계획

### Phase 1: 편의성 개선 (단기)
- [ ] RAT 파라미터 조정 (로컬 테스트용 낮은 값)
- [ ] L2 자동 등록 스크립트
- [ ] test-local-devnet.sh 타임아웃 개선

### Phase 2: 자동화 (중기)
- [ ] Validator 자동 설정 스크립트
- [ ] Hardhat 기반 트랜잭션 스크립트
- [ ] E2E 테스트 자동화

### Phase 3: 고급 기능 (장기)
- [ ] 웹 UI 개발
- [ ] 모니터링 대시보드
- [ ] 멀티 Validator 지원

---

## 참고 문서

- **[빠른 시작](./QUICKSTART.md)** - 5분 안에 환경 구축
- **[구현 상세](./IMPLEMENTATION.md)** - 기술적 세부사항
- **[Validator 설정](./VALIDATOR-SETUP.md)** - Validator 등록 가이드
- **[메인 가이드](./README.md)** - 문서 목록

---

## 문의 및 이슈

- GitHub Issues: https://github.com/tokamak-network/ton-staking-v2/issues
- 브랜치: `ton-staking-v3/deploy-local`
