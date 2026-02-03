# Fast Withdrawal Validator

Fast Withdrawal 시스템의 Validator Node 구현입니다.

## 개요

Validator Node는 다음 역할을 수행합니다:
- libp2p 네트워크에서 Fast Withdrawal 요청 수신
- 출금 요청의 유효성 검증 (L2 state 확인)
- BLS 서명 생성 및 Aggregator에게 전송

## 아키텍처

```
┌─────────────────────────────────────────────┐
│         Validator Node                      │
├─────────────────────────────────────────────┤
│  libp2p Node                                │
│  - PeerID 생성                              │
│  - DHT discovery                            │
│  - GossipSub pubsub                         │
│                                             │
│  Request Handler                            │
│  - SignatureRequest 수신                    │
│  - 출금 검증 (Type3Verifier)                │
│  - BLS 서명 생성                            │
│  - SignatureResponse 발행                   │
│                                             │
│  BLS Signer                                 │
│  - BLS12-381 서명                           │
│  - Proof of Possession                      │
└─────────────────────────────────────────────┘
```

## 빌드

```bash
go build -o bin/validator ./cmd
```

## 설정

`config.yaml` 파일을 생성하세요:

```yaml
validator:
  address: "0x1234567890123456789012345678901234567890"
  bls_private_key: "0xabcdef..." # 32 bytes hex

l1:
  rpc: "https://ethereum-rpc.example.com"
  rat_contract: "0xRAT_CONTRACT_ADDRESS"

l2:
  rpc: "http://localhost:8545"  # op-geth with debug API
  opnode_rpc: "http://localhost:9545"  # optional

p2p:
  listen_addr: "/ip4/0.0.0.0/tcp/9000"
  bootstrap_peers:
    - "/ip4/1.2.3.4/tcp/9000/p2p/QmBootstrapPeer1"
  dht_namespace: "/tokamak-rat-validators"
  withdrawal_topic: "/tokamak/rat/withdrawal/1.0.0"

log:
  level: "info"
  format: "text"
```

## 실행

```bash
./bin/validator --config config.yaml
```

## BLS 키 생성

새로운 BLS 키 쌍을 생성하려면:

```go
package main

import (
	"fmt"
	"github.com/tokamak-network/ton-staking-v2/clients/fast-withdrawal/validator/pkg/signer"
)

func main() {
	s, _ := signer.GenerateKey()
	fmt.Printf("Private Key: 0x%s\n", s.PrivateKeyHex())
	fmt.Printf("Public Key: 0x%x\n", s.PublicKey())
}
```

## 테스트

```bash
# 모든 테스트 실행
go test ./...

# 특정 패키지 테스트
go test ./pkg/signer/... -v
go test ./pkg/p2p/... -v
go test ./pkg/handler/... -v
```

## 개발 상태

### ✅ 완료
- [x] Config 로딩 (YAML)
- [x] BLS Signer (서명 생성/검증)
- [x] libp2p Node (P2P 통신)
- [x] Request Handler (요청 처리)
- [x] Mock Verifier (테스트용)
- [x] CLI (main.go)

### 🚧 작업 필요
- [ ] Type3 Verifier (rat-client-type3 재사용)
- [ ] L2 state 검증 (OutputRootProof)
- [ ] DisputeGame 상태 확인
- [ ] 프로덕션 배포 및 테스트

## 참고

- [설계 문서](../../../docs/rat-fast-withdrawal/design.md)
- [개발 계획](../../../docs/rat-fast-withdrawal/plan.md)
- [다음 작업](../../../docs/rat-fast-withdrawal/NEXT_STEPS.md)
