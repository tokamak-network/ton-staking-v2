# Web UI 검증 가이드 - 전체 개요

TON Staking V3 Web UI를 검증하기 위한 완전한 가이드입니다.

---

## 📚 문서 구성

### 1. 빠른 점검 (5분) ⭐ **시작하기 좋음**
**파일**: [WEB-UI-QUICK-CHECK.md](./WEB-UI-QUICK-CHECK.md)

**누구에게**: 처음 Web UI를 확인하는 사람, 빠른 동작 확인 필요

**내용**:
- 환경 실행 확인
- Config 검증
- Web UI 실행
- 핵심 기능 5가지 점검 (지갑 연결, Overview, Operator, Balances, L2 Info)

**사용 시점**: 
- Web UI를 처음 설치한 후
- 변경 사항 후 기본 동작 확인
- 빠른 헬스 체크

---

### 2. 상세 점검 (30-60분) 📋 **완전한 검증**
**파일**: [WEB-UI-DETAILED-CHECKLIST.md](./WEB-UI-DETAILED-CHECKLIST.md)

**누구에게**: 개발자, QA, 상세 검증이 필요한 경우

**내용**:
- **9개 탭 전체** 상세 검증
- **모든 데이터 필드** (100개 이상)
- **모든 UI 요소** (버튼, 입력, 상태)
- **인터랙션 테스트** (트랜잭션, 에러 핸들링)
- **데이터 정확성** (CLI와 비교)
- **UI/UX** (반응형, 로딩, 피드백)

**목차**:
1. 사전 준비 체크리스트
2. 빌드 & 설치 체크리스트
3. 설정 파일 검증
4. 페이지별 상세 검증 (9개 탭)
   - 4.1 Overview 탭
   - 4.2 Operator 탭
   - 4.3 Validators 탭
   - 4.4 TON Staking 탭
   - 4.5 Seigniorage 탭
   - 4.6 L2 Information 탭
   - 4.7 Bridge to L2 탭
   - 4.8 Dispute Games 탭
   - 4.9 Balances 탭
5. 인터랙션 테스트
6. 데이터 정확성 검증
7. 에러 핸들링 테스트
8. UI/UX 검증

**사용 시점**:
- 프로덕션 배포 전
- 주요 변경 사항 후
- 전체 기능 검증 필요 시

---

### 3. 기본 검증 (15분)
**파일**: [WEB-UI-VERIFICATION-CHECKLIST.md](./WEB-UI-VERIFICATION-CHECKLIST.md)

**누구에게**: 기본적인 검증이 필요한 경우

**내용**:
- 주요 탭별 데이터 항목 나열
- CLI 검증 명령어 제공
- 기본적인 데이터 표시 확인

---

## 🛠️ 자동화 도구

### Config 검증 스크립트
```bash
./scripts/verify-webui-config.sh
```

**검증 내용**:
- 11개 컨트랙트 주소 일치 (config.ts ↔ addresses.json)
- 네트워크 설정 (chainId, rpcUrl, l2RpcUrl)
- 테스트 계정 설정

**출력 예시**:
```
✓ TON Token
  Devnet: 0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E
  Config: 0xd55b55304b5cf7607B6dEd6DA6EeB487918AaD2E

✓ WTON Token
  Devnet: 0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a
  Config: 0x2B2fE3204CcB8282ac6bC31d485cB6aa010d193a

...

✅ ALL VERIFICATIONS PASSED!
```

---

## 📊 검증 레벨 비교

| 항목 | 빠른 점검 | 기본 검증 | 상세 점검 |
|------|---------|---------|---------|
| **소요 시간** | 5분 | 15분 | 30-60분 |
| **검증 항목** | 5개 핵심 | 주요 데이터 | 전체 (100개+) |
| **자동화** | 부분 | 부분 | 수동 |
| **사용 시점** | 매번 | 정기적 | 배포 전 |
| **문서 파일** | QUICK-CHECK | VERIFICATION-CHECKLIST | DETAILED-CHECKLIST |

---

## 🚀 시작하기

### 처음 사용자
1. [WEB-UI-QUICK-CHECK.md](./WEB-UI-QUICK-CHECK.md) 읽기
2. 5분 빠른 점검 실행
3. 문제 없으면 사용 시작

### 개발자/QA
1. `./scripts/verify-webui-config.sh` 실행
2. [WEB-UI-DETAILED-CHECKLIST.md](./WEB-UI-DETAILED-CHECKLIST.md) 따라 전체 검증
3. 모든 항목 체크 완료

---

## 🎯 각 탭별 주요 검증 항목

### 📊 Overview
- [ ] L1/L2 노드 상태
- [ ] 블록 번호 (실시간 증가)
- [ ] Rollup 정보
- [ ] V3 Migration 상태
- [ ] 컨트랙트 주소 11개

### 👤 Operator
- [ ] Operator 주소
- [ ] OperatorManager 주소
- [ ] CandidateAddOn 주소
- [ ] Sequencer Collateral 금액
- [ ] Layer2Registry 등록 상태
- [ ] Add Collateral 기능

### 👥 Validators
- [ ] Validator 목록 (주소, Deposit, Available)
- [ ] RAT 등록 상태
- [ ] Active 상태

### 💎 TON Staking
- [ ] Deposit (Stake)
- [ ] Request Withdrawal
- [ ] Process Withdrawal
- [ ] Staked Amount
- [ ] Pending Unstaked

### 💰 Seigniorage
- [ ] Layer2 주소 입력 및 조회
- [ ] Layer2 등록 상태
- [ ] Operator Manager 정보
- [ ] Seigniorage Issuance Factors (8개 파라미터)
- [ ] Update History
- [ ] Reward Per Unit
- [ ] Bridged TON & Required Stake
- [ ] Eligibility Checklist (5개 조건)
- [ ] Update Seigniorage 기능

### 🌐 L2 Information
- [ ] L2 Chain ID (901)
- [ ] L2 Block Number
- [ ] Proposer & Batcher 정보
- [ ] System Configuration (Gas Limit 등)
- [ ] Bridge & Portal 주소
- [ ] Portal 상태 & 잔액

### 🌉 Bridge to L2
- [ ] Bridge ETH to L2
- [ ] Bridge TON to L2
- [ ] Withdraw ETH from L2
- [ ] Withdraw TON from L2
- [ ] Finalize Withdrawal (Advanced)

### 🎮 Dispute Games
- [ ] 게임 목록 테이블
- [ ] 게임 타입, 주소, 생성 시간

### 💰 Balances
- [ ] 잔액 카드 4개 (ETH, TON, WTON, Staked)
- [ ] Faucet (ETH, TON, WTON 받기)
- [ ] Token Swap (TON ↔ WTON)
- [ ] 계정 정보

---

## ⚠️ 주의사항

### 검증 전 확인
- [ ] 로컬 환경 실행 중 (L1 + L2 노드)
- [ ] `.devnet/addresses.json` 존재
- [ ] `web-ui/node_modules` 설치됨

### 검증 중 유의사항
- [ ] 트랜잭션 테스트 시 충분한 ETH/TON 필요
- [ ] 일부 기능은 Operator/Validator 등록 후 사용 가능
- [ ] 브라우저 개발자 도구 콘솔 열어두고 에러 확인

### 검증 후 조치
- [ ] 실패 항목 기록 및 이슈 생성
- [ ] 성공 시 검증 보고서 작성
- [ ] 다음 검증 일정 계획

---

## 📝 검증 보고서 템플릿

```markdown
## Web UI 검증 보고서

**날짜**: YYYY-MM-DD
**검증자**: [이름]
**환경**: [OS], [브라우저]
**검증 레벨**: 빠른 점검 / 기본 검증 / 상세 점검

### 검증 결과
- 총 항목: [숫자]
- 통과: [숫자]
- 실패: [숫자]

### 실패 항목
1. [항목명]: [원인] - [해결 방법]

### 주요 발견사항
- [발견사항 1]
- [발견사항 2]

### 권장사항
- [권장사항 1]

### 결론
✅ 검증 통과 - 사용 가능
또는
❌ [N]개 항목 실패 - 수정 필요
```

---

## 🔗 관련 문서

- [QUICKSTART.md](./QUICKSTART.md) - 로컬 환경 빠른 시작
- [STATUS.md](./STATUS.md) - 현재 상태 및 알려진 이슈
- [VERIFICATION-CHECKLIST.md](./VERIFICATION-CHECKLIST.md) - 전체 시스템 검증

---

## 📞 문의 및 지원

- **GitHub Issues**: https://github.com/tokamak-network/ton-staking-v2/issues
- **문서 위치**: `/docs/deployment/local/`

---

**최종 업데이트**: 2026-02-03
