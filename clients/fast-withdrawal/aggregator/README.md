# Fast Withdrawal Aggregator

Fast Withdrawal 시스템의 Aggregator Service 구현입니다.

## 개요

Aggregator는 다음 역할을 수행합니다:
- L1 FastWithdrawal 이벤트 모니터링
- libp2p로 Validator들에게 SignatureRequest 브로드캐스트
- Validator들의 BLS 서명 수집
- 만장일치(100%) 확인
- BLS 서명 집약
- L1에 집약된 서명 제출

## 아키텍처

```
┌─────────────────────────────────────────────┐
│         Aggregator Service                  │
├─────────────────────────────────────────────┤
│  L1 Event Monitor                           │
│  - FastWithdrawalRequested 감지             │
│  - WithdrawalRequested 이벤트 파싱          │
│                                             │
│  libp2p Network                             │
│  - SignatureRequest 브로드캐스트            │
│  - SignatureResponse 수신                   │
│                                             │
│  Signature Collector                        │
│  - Validator 서명 수집                      │
│  - 만장일치 (100%) 확인                     │
│  - 타임아웃 처리                            │
│                                             │
│  BLS Aggregator                             │
│  - BLS 서명 집약 (G2 addition)              │
│  - Validator bitmap 생성                    │
│                                             │
│  L1 Submitter                               │
│  - RAT.verifyAndExecuteFastWithdrawal()    │
│  - 가스 최적화, 재시도                      │
└─────────────────────────────────────────────┘
```

## 빌드

```bash
go build -o bin/aggregator ./cmd
```

## 실행

```bash
./bin/aggregator --config config.yaml
```

## 워크플로우

1. **L1 이벤트 감지**
   ```
   OptimismPortal2.proveAndRequestFastWithdrawal()
   → FastWithdrawalRequested 이벤트 발생
   ```

2. **서명 요청 브로드캐스트**
   ```
   Aggregator → libp2p pubsub → All Validators
   (SignatureRequest 메시지)
   ```

3. **서명 수집**
   ```
   Validators → Aggregator
   (각자 BLS 서명 응답)
   ```

4. **만장일치 확인**
   ```
   수집된 서명 수 == 활성 검증자 수 (100%)
   ```

5. **서명 집약**
   ```
   aggregatedSignature = BLS.aggregate(sig1, sig2, ...)
   validatorBitmap = 0b1111...1 (모두 1)
   ```

6. **L1 제출**
   ```
   RAT.verifyAndExecuteFastWithdrawal(
     tx,
     input,
     aggregatedSignature
   )
   ```

## 개발 상태

### ✅ 완료
- [x] Config 구조
- [x] README

### 🚧 작업 필요
- [ ] L1 Event Monitor
- [ ] libp2p Network (Validator와 동일한 코드 재사용)
- [ ] Signature Collector
- [ ] BLS Aggregator
- [ ] L1 Submitter
- [ ] main.go (CLI)

## 참고

- [Validator](../validator/README.md)
- [설계 문서](../../../docs/rat-fast-withdrawal/design.md)
