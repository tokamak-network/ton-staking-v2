# LotteryCandidate

`LotteryCandidate`는 사용자가 스테이킹한 자산을 활용하여 로터리에 참여하고 시뇨리지 보상을 받을 수 있는 Candidate 확장 모델입니다.

## 주요 특징

- **내부 잔액 관리**: 사용자의 예치금은 `LotteryCandidate` 내부 Storage에서 관리되며, 실제 자산은 `DepositManager`에 안전하게 스테이킹됩니다.
- **차감형 로터리**: 고정된 참여 비용(`entryFee`)을 지불하고 참여하며, 당첨자가 라운드의 모든 참여비를 독식하는 Winner-takes-all 방식입니다.
- **비례적 시뇨리지 분배**: 참여 여부와 관계없이 모든 예치자는 자신의 잔액 비율에 맞춰 시뇨리지 보상을 받습니다.
- **통합 출금 프로세스**: 로터리 참여 후 남은 잔액은 언제든지 출금 요청을 통해 회수할 수 있습니다.

## 문서 구성

- [`contracts.md`](contracts.md): 컨트랙트 구조 및 주요 함수 상세 설명
- [`scenario.md`](scenario.md): 사용 시나리오와 전체 플로우 가이드
- [`demo.md`](demo.md): 프론트엔드 데모 실행 및 사용 방법
