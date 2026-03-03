# 3. 디렉토리 구조 설명

[← 목차로 돌아가기](./README.md) | [← 이전: 시스템 아키텍처](./02-system-architecture.md)

---

> ★ 표시는 LotteryCandidate 기능의 핵심 파일입니다.

```
ton-staking-v2/
│
├── src/                              # Solidity 소스 코드 (180개 파일)
│   │
│   ├── dao/                          # ★ DAO 거버넌스 (52개 파일) - LotteryCandidate 핵심
│   │   ├── LotteryCandidate.sol          # ★ 핵심 구현 컨트랙트 (복권+스테이킹)
│   │   ├── LotteryCandidateProxy.sol     # ★ 프록시 컨트랙트
│   │   ├── LotteryCandidateStorage.sol   # ★ 스토리지 레이아웃 정의
│   │   ├── Candidate.sol                 # 기존 후보 컨트랙트 (비교 참조)
│   │   ├── CandidateAddOnV1_1.sol        # 애드온 후보
│   │   ├── DAOCommittee_V1.sol           # ★ DAO 위원회 (createLotteryCandidate 포함)
│   │   ├── DAOCommitteeOwner.sol         # DAO 위원회 Owner 함수
│   │   ├── StorageStateCommittee.sol     # 위원회 스토리지 V1
│   │   ├── StorageStateCommitteeV2.sol   # ★ 위원회 스토리지 V2 (lotteryCandidateFactory 포함)
│   │   │
│   │   ├── factory/                      # 팩토리 컨트랙트
│   │   │   ├── LotteryCandidateFactory.sol   # ★ 복권 후보 팩토리
│   │   │   ├── CandidateFactory.sol          # 기존 후보 팩토리
│   │   │   └── CandidateAddOnFactory.sol     # 애드온 후보 팩토리
│   │   │
│   │   ├── interfaces/                   # DAO 인터페이스 (17개 파일)
│   │   │   ├── ICandidate.sol
│   │   │   ├── IDAOCommittee.sol
│   │   │   ├── IDAOAgendaManager.sol
│   │   │   ├── IDAOVault.sol
│   │   │   └── ... (기타)
│   │   │
│   │   └── lib/                          # 유틸리티
│   │       ├── Agenda.sol
│   │       └── BytesLib.sol
│   │
│   ├── stake/                        # 스테이킹 시스템 (50개 파일)
│   │   ├── managers/
│   │   │   ├── SeigManagerV3_1.sol       # V3 시뇨리지 코어 (쌍곡선 포화 함수)
│   │   │   ├── SeigManagerV3_2.sol       # V3 delegatecall (V2 호환 모드)
│   │   │   ├── SeigManagerV1_2.sol       # V1.2 베이스 구현
│   │   │   ├── DepositManagerV3.sol      # V3 예치/출금 관리
│   │   │   └── Storage*.sol              # 스토리지 정의 파일들
│   │   ├── tokens/
│   │   │   ├── AutoRefactorCoinage.sol   # 리팩터링 코인지 토큰
│   │   │   └── RefactorCoinageSnapshot.sol # 스냅샷 기능
│   │   ├── factory/
│   │   │   └── CoinageFactory.sol        # 코인지 토큰 팩토리
│   │   └── Layer2Registry.sol            # L2 레지스트리 (코인지 배포)
│   │
│   ├── layer2/                       # L2 관리 (38개 파일)
│   │   ├── Layer2ManagerV3.sol           # V3 L2 매니저
│   │   ├── L1BridgeRegistryV1_2.sol      # L1 브릿지 레지스트리
│   │   └── OperatorManagerV1_2.sol       # 오퍼레이터 매니저
│   │
│   ├── validator/                    # 밸리데이터 시스템 (8개 파일)
│   │   ├── RAT.sol                       # Randomized Attention Test
│   │   └── ValidatorRewardV1.sol         # 밸리데이터 보상
│   │
│   ├── proxy/                        # 프록시 패턴 (8개 파일)
│   │   ├── Proxy.sol                     # 범용 프록시
│   │   ├── ProxyStorage.sol              # 프록시 스토리지 베이스
│   │   └── DAOCommitteeProxy2.sol        # DAO 위원회 프록시
│   │
│   ├── common/                       # 공통 유틸 (6개 파일)
│   │   ├── AccessibleCommon.sol          # 접근 제어 공통
│   │   └── AuthRole.sol                  # 역할 정의
│   │
│   ├── accessControl/                # 접근 제어 (6개 파일)
│   ├── libraries/                    # 유틸리티 라이브러리 (5개 파일)
│   │   ├── DSMath.sol, FullMath.sol, SafeERC20.sol, Create2.sol
│   │
│   └── mocks/                        # 테스트 목 컨트랙트 (11개 파일)
│       ├── MockTON.sol, MockWTON.sol
│       ├── MockDisputeGameFactory.sol
│       └── ... (기타)
│
├── test/                             # 테스트 스위트 (36개 파일)
│   └── v3/
│       ├── scenarios/
│       │   ├── LotteryCandidate.t.sol    # ★ LotteryCandidate 시나리오 테스트
│       │   ├── SequencerJourney.t.sol
│       │   └── ValidatorJourney.t.sol
│       ├── v3mode/                       # V3 모드 테스트
│       │   ├── RAT.t.sol
│       │   ├── ValidatorRewardV1.t.sol
│       │   └── BasicSlashing/            # 슬래싱 테스트 (8개)
│       ├── v2mode/                       # V2 호환성 테스트
│       ├── invariants/                   # 불변성 테스트
│       └── helpers/                      # 테스트 헬퍼
│
├── script/                           # 배포 스크립트 (9개 파일)
│   ├── DeployLotteryDemo.s.sol           # ★ 복권 데모 배포 (459줄)
│   ├── DeployV3Full.s.sol                # V3 전체 배포
│   ├── DeployV3FullSlash.s.sol           # V3 슬래싱 포함 배포
│   └── VerifyGenesisSetup.s.sol          # 제네시스 검증
│
├── demo-frontend/                    # ★ React 프론트엔드
│   ├── src/
│   │   ├── App.tsx                       # 메인 앱 (설정 관리 + 레이아웃)
│   │   ├── main.tsx                      # 엔트리포인트
│   │   ├── wagmi.ts                      # Web3 설정 (Anvil 전용)
│   │   ├── contracts/
│   │   │   └── abi.ts                    # ★ 컨트랙트 ABI 정의 (수동 관리)
│   │   └── components/
│   │       ├── ConnectWallet.tsx          # 지갑 연결/해제
│   │       ├── LotteryInfo.tsx           # 복권 현황 대시보드
│   │       ├── LotteryActions.tsx        # 복권 참여/추첨 버튼
│   │       ├── DepositForm.tsx           # TON 예치 (approve → deposit)
│   │       ├── UserBalance.tsx           # 잔액 표시 (TON/WTON/예치)
│   │       ├── SeignioragePanel.tsx      # 시뇨리지 분배 + 블록 마이닝 도구
│   │       └── PastRounds.tsx            # 과거 라운드 결과 이력
│   ├── package.json                      # React 18 + Vite + wagmi + Tailwind
│   └── vite.config.ts
│
├── docs/LotteryCandidate/            # ★ LotteryCandidate 문서
│   ├── en/                               # 영문 (README, contracts, scenario, demo)
│   ├── kr/                               # 한글 (동일 구조, demo가 더 상세)
│   ├── handover/                         # ★ 인수인계서 (본 문서들)
│   ├── seigniorage-update-report.md      # 시뇨리지 이슈 해결 리포트
│   └── seigniorage-troubleshooting.md    # 시뇨리지 트러블슈팅 가이드
│
├── docs/                             # 전체 프로젝트 문서
│   ├── specs-kr/                         # 한글 사양서 (12개 파일)
│   ├── test/                             # 테스트 문서 (8개 파일)
│   ├── deployment/                       # 배포 가이드
│   └── *.pdf                             # 화이트페이퍼 (V1~V3)
│
├── lib/                              # Git Submodules
│   ├── forge-std/                        # Foundry 표준 라이브러리
│   ├── openzeppelin-contracts/           # OpenZeppelin
│   ├── optimism/                         # Optimism (Tokamak fork)
│   └── tokamak-dao-contracts/            # Tokamak DAO
│
├── op-e2e/                           # Go E2E 테스트 (27개 바인딩)
│
├── run-lottery-demo.sh               # ★ 원클릭 데모 실행 스크립트
├── Makefile                          # 빌드/테스트/배포 자동화
├── foundry.toml                      # Foundry 설정
├── hardhat.config.ts                 # Hardhat 설정
├── .env.example                      # 환경변수 예시
├── README.md                         # 프로젝트 README (영문)
└── README_kr.md                      # 프로젝트 README (한글)
```

---

[다음: 핵심 비즈니스 로직 →](./04-business-logic.md)
