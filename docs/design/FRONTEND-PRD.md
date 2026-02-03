# Delegate Staking Frontend - Product Requirements Document (PRD)

> **Version**: 1.0
> **Status**: DRAFT
> **Related**: `DESIGN.md`, `FRONTEND-ARCHITECTURE.md`

## 1. 개요 (Overview)

Tokamak Network V3의 **Sequencer Delegate Staking** 시스템을 위한 웹 인터페이스입니다. 사용자는 이 서비스를 통해 Sequencer에게 TON을 위임하고, 스테이킹 보상을 수령할 수 있습니다.

### 1.1 목표
- 일반 사용자가 쉽고 직관적으로 위임(Staking)에 참여할 수 있는 UI 제공
- 복잡한 V3 시뇨리지 구조를 단순화하여 사용자에게 포트폴리오 성과(APY, 리워드) 시각화
- Sequencer를 위한 등록 및 관리 기능 제공

---

## 2. 사용자 페르소나 (User Personas)

### 2.1 Delegator (일반 사용자)
- **목표**: TON을 맡겨서 이자(WTON/TON)를 얻고 싶음.
- **주요 활동**: 좋은 Sequencer 탐색, 위임, 보상 청구, 출금.
- **Pain Point**: 복잡한 브릿징 과정, 긴 출금 대기 시간(DTD)에 대한 불안감.

### 2.2 Sequencer (운영자)
- **목표**: 많은 위임을 유치하여 커미션 수익 증대 및 L2 시뇨리지 자격 유지.
- **주요 활동**: Sequencer 등록, 홍보(수수료율 조정), 운용 현황 모니터링.

---

## 3. 핵심 기능 (Core Features)

### 3.1 대시보드 (Dashboard)
- **나의 자산 현황**:
  - 총 위임 금액 (Total Staked)
  - 출금 대기 중인 금액 (Pending Withdrawal)
  - 수령 가능한 보상 (Claimable Rewards)
  - 현재 APY (추정치)
- **활동 로그**: 최근 위임, 보상 수령 내역.

### 3.2 Sequencer 탐색기 (Explore)
- **리스트 뷰**:
  - Sequencer 이름/주소
  - 총 위임량 (TVL)
  - 수수료 (Commission Rate)
  - 참여자 수 (Delegators)
  - 상태 (Active/Inactive)
- **필터/정렬**: TVL 순, 수수료 낮은 순, APY 높은 순.

### 3.3 위임 (Delegate)
- **프로세스**:
  1. Sequencer 선택
  2. 위임할 TON 수량 입력
  3. `Permit` 또는 `Approve` 트랜잭션 서명
  4. `Delegate` 트랜잭션 전송
- **안내**: "위임 시 TON이 L2로 브릿징 되며, 출금 시 14일이 소요됩니다" 경고.

### 3.4 관리 및 출금 (Manage & Undelegate)
- **재위임 (Redelegate)**:
  - 현재 위임 중인 Sequencer에서 다른 Sequencer로 즉시 이동.
- **출금 요청 (Request Undelegate)**:
  - 일부 또는 전액 출금 요청.
  - DTD(14일) 카운트다운 시작 표시.
- **출금 완료 (Withdraw)**:
  - DTD 종료 후 L1으로 자산 수령 (`Claim`).

### 3.5 보상 청구 (Claim Rewards)
- Sequencer별 또는 일괄(Batch) 보상 수령 기능.

### 3.6 Sequencer Admin (Operator Only)
- Sequencer 등록 폼 (L2 Vault 주소 입력).
- 수수료율(Commission) 변경 기능.

---

## 4. 페이지 구조 (Sitemap)

| Path | Page Name | Description |
|------|-----------|-------------|
| `/` | **Home** | 서비스 소개 및 주요 Sequencer 하이라이트 |
| `/dashboard` | **My Dashboard** | 내 스테이킹 현황 및 포트폴리오 관리 |
| `/sequencers` | **Sequencer List** | 전체 Sequencer 목록 및 상세 정보 |
| `/sequencers/:id`| **Sequencer Detail** | 특정 Sequencer의 상세 성과 및 위임 모달 |
| `/admin` | **Sequencer Admin** | Sequencer 등록 및 관리 (운영자용) |

---

## 5. UI/UX 요구사항

### 5.1 디자인 원칙 (Design Principles)
- **Premium & Trustworthy**: 금융 애플리케이션으로서 신뢰감을 주는 디자인 (Glassmorphism, Clean lines).
- **Responsive**: 모바일 및 데스크톱 완벽 지원.
- **Dark Mode First**: 크립토 네이티브 사용자를 위한 다크 모드 기본 지원.

### 5.2 인터랙션
- **Wallet Connection**: RainbowKit 등을 사용하여 다양한 지갑 지원.
- **Feedback**: 모든 트랜잭션 단계(대기, 처리중, 성공, 실패)에 명확한 토스트 메시지 및 프로그레스 표시.
- **Loading State**: 데이터 로딩 시 스켈레톤 UI 사용.

---

## 6. 데이터 요구사항

- **Onchecker (Indexer)** 필요 여부:
  - Sequencer 목록 및 과거 APY 데이터는 온체인 순회로 가져오기 어려울 수 있음.
  - 초기 단계: RPC 직접 호출 (`multicall` 활용).
  - 추후: The Graph 또는 자체 인덱서 도입 고려.
