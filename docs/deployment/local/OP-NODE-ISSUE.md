# op-node 실행 불가 문제 - 근본 원인 및 해결 방안

## 문제 요약

op-node가 초기화 중 크래시하여 L2 블록 생성이 불가능합니다.

```
Error: failed to fetch unsafe block signing address from system config: 
       Invalid string length
```

## 근본 원인 분석

### 1. op-node의 동작 방식

op-node는 SystemConfig 컨트랙트에서 `unsafeBlockSigner`를 읽을 때:

1. **블록 해시를 blockTag로 사용**하여 RPC 호출
2. `--l1.trustrpc` 사용 시: `eth_getStorageAt(address, slot, blockHash)`
3. `--l1.trustrpc` 미사용 시: `eth_getProof(address, [slot], blockHash)`

### 2. Anvil의 제한사항

**Anvil은 blockTag로 블록 해시를 지원하지 않습니다.**

지원하는 blockTag:
- ✅ `"latest"`
- ✅ `"earliest"`  
- ✅ `"pending"`
- ✅ 블록 번호 (hex): `"0x1"`, `"0x64"` 등
- ❌ 블록 해시: `"0x6c7925..."`

### 3. 실제 테스트 결과

```bash
# ❌ 블록 해시 사용 - 실패
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getStorageAt","params":["0x577...","0x65a7...","0x6c79..."],"id":1}' \
  http://localhost:8545

# Response: {"error":{"code":-32602,"message":"Invalid string length"}}

# ✅ "latest" 사용 - 성공
curl -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getStorageAt","params":["0x577...","0x65a7...","latest"],"id":1}' \
  http://localhost:8545

# Response: {"result":"0x00000000000000000000000015d34aaf..."}
```

### 4. op-node 소스 코드 확인

`op-service/sources/eth_client.go`:

```go
func (s *EthClient) ReadStorageAt(ctx context.Context, address common.Address, 
    storageSlot common.Hash, blockHash common.Hash) (common.Hash, error) {
    if s.trustRPC {
        // blockHash를 문자열로 변환하여 사용
        return s.GetStorageAt(ctx, address, storageSlot, blockHash.String())
    }
    // ...
    result, err := s.GetProof(ctx, address, []common.Hash{storageSlot}, blockHash.String())
    // ...
}
```

**문제**: `blockHash.String()`은 "0x6c7925..."을 반환하지만, Anvil은 이를 지원하지 않음

## 시도한 해결 방법

### ✅ 1. SystemConfig의 unsafeBlockSigner 설정

```bash
cast send $SYSTEM_CONFIG \
  --legacy \
  --private-key $OWNER_KEY \
  --rpc-url $RPC_URL \
  "setUnsafeBlockSigner(address)" \
  $PROPOSER
```

**결과**: 
- ✅ 트랜잭션 성공
- ✅ unsafeBlockSigner() 함수 호출 시 정상 반환
- ✅ 스토리지 슬롯에 값 저장됨
- ❌ op-node는 여전히 블록 해시로 조회하므로 실패

### ❌ 2. --l1.trustrpc 플래그 제거

docker-compose.yml에서 `--l1.trustrpc` 제거 → `eth_getProof` 사용

**결과**:
- Anvil은 `eth_getProof`도 블록 해시를 blockTag로 받지 못함
- 같은 "Invalid string length" 에러 발생

### ❌ 3. op-node 버전 변경

- v1.7.7 → v1.7.0
- 더 낮은 버전 시도

**결과**: 
- 모든 버전이 블록 해시를 사용하므로 동일한 문제 발생

## 해결 방안

### Option 1: Anvil을 Geth로 교체 ⭐ (권장)

**장점**:
- Geth는 블록 해시를 blockTag로 완벽 지원
- 프로덕션 환경과 동일한 동작
- op-node와 완벽 호환

**단점**:
- Genesis 생성 방식 변경 필요
- Geth 초기화 및 설정 복잡
- 리소스 사용량 증가

**구현**:
```yaml
# docker-compose.yml
l1:
  image: ethereum/client-go:latest
  command:
    - --dev
    - --http
    - --http.api=eth,net,web3,debug
    - --init=/genesis/genesis.json
    # ...
```

### Option 2: op-node 코드 패치

op-node를 수정하여 blockHash 대신 블록 번호 사용

**단점**:
- 코드 수정 및 빌드 필요
- 업스트림 변경 시 충돌
- 유지보수 부담

### Option 3: L1만 사용 (현재 상태)

op-node 없이 L1 기능만 테스트

**사용 가능**:
- ✅ TON/WTON 컨트랙트
- ✅ SeigManager, DepositManager
- ✅ L1 기반 기능 테스트

**사용 불가**:
- ❌ L2 블록 생성
- ❌ RAT Challenge (L2 상태 변화 필요)
- ❌ L1↔L2 브릿지

### Option 4: Hardhat Network 사용

Anvil 대신 Hardhat Network 사용

**장점**:
- JavaScript/TypeScript 기반
- 디버깅 도구 풍부

**단점**:
- 블록 해시 지원 확인 필요
- 성능이 Anvil보다 낮음

## 권장 해결책

### 단기 (현재)

**Option 3 유지**: L1만 사용하여 TON Staking 컨트랙트 테스트

**이유**:
- Genesis 생성 및 컨트랙트 배포는 정상 작동
- L1 기반 기능 개발 및 테스트 가능
- 빠른 이터레이션 가능

### 중기 (1-2주 내)

**Option 1 구현**: Geth로 마이그레이션

**단계**:
1. Geth genesis 포맷으로 변환 스크립트 작성
2. Docker Compose에서 Anvil → Geth 교체
3. Geth 설정 최적화 (dev 모드, mining 간격 등)
4. op-node 연동 테스트

### 장기

**프로덕션 준비**: 전체 L1+L2 스택 완성

- Geth L1
- op-geth L2
- op-node
- op-batcher
- op-proposer
- RAT Client 통합

## 상세 기술 정보

### Anvil RPC 제한사항

Anvil이 **지원하지 않는** 기능:
1. blockTag로 블록 해시 사용
   - `eth_getStorageAt(..., blockHash)`
   - `eth_getProof(..., blockHash)`
   - `eth_getBalance(..., blockHash)`
   - `eth_call(..., blockHash)`

2. 일부 debug API
   - `debug_traceTransaction` 일부 옵션

### op-node 의존성

op-node가 **반드시** 필요한 이유:
1. L1 트랜잭션을 L2 블록으로 derivation
2. unsafe blocks 생성 지시
3. L2 상태 안전성 보장
4. batcher, proposer 조정

**op-node 없이는 L2가 완전히 멈춥니다.**

## 참고 자료

- Anvil 이슈: https://github.com/foundry-rs/foundry/issues/
- op-node 소스: `/lib/optimism/op-node/node/runcfg/runtime_config.go`
- Geth JSON-RPC: https://geth.ethereum.org/docs/interacting-with-geth/rpc

## 업데이트 이력

- 2026-02-03: 근본 원인 파악 (Anvil 블록 해시 미지원)
- 2026-02-03: unsafeBlockSigner 설정 성공 (하지만 op-node 여전히 실패)
- 2026-02-03: --l1.trustrpc 제거 시도 (실패)
- 2026-02-03: op-node v1.7.0 시도 (실패)
