# Tokamak Economics Whitepaper V2: Slashing 메커니즘 정리 (추가 개발사항)

이 문서는 `Tokamak_Economics_Whitepape_V2_(121025).pdf` 백서에 기술된 **Slashing(슬래싱)** 관련 내용을 중점적으로 정리한 것입니다. Slashing은 네트워크의 보안을 위협하거나 의무를 다하지 않은 참여자의 스테이킹된 자산(TON)을 몰수하는 핵심 경제적 처벌 장치입니다.

## 1. 개요
Tokamak Network의 모든 Slashing은 **TON 토큰**으로 집행됩니다. 시퀀서(Sequencer)와 검증자(Validator)는 네트워크 참여를 위해 TON을 담보(Bond/Deposit)로 예치해야 하며, 부정행위 적발 시 이 담보가 삭감됩니다.

## 2. Sequencer Slashing (시퀀서 슬래싱)
시퀀서는 L2의 상태를 업데이트하고 블록을 생성하는 주체입니다.

### 2.1 발동 조건
*   **유효하지 않은 상태 전이(Invalid State Transition)**: 시퀀서가 제출한 상태 루트(State Root)에 대해 **사기 증명(Fraud Proof)**이 제출되고, 챌린지 기간 동안 이것이 참으로 판명될 경우 발동합니다.

### 2.2 처벌 내용 (Penalty)
*   **전액 몰수 (Full Slashing)**: 시퀀서가 예치한 보증금($D_{sequencer}$) **전액**이 슬래싱됩니다.
*   **즉시 정지 (Immediate Suspension)**: 슬래싱된 시퀀서는 즉시 시퀀싱 권한을 상실하고 정지됩니다.

### 2.3 보상 분배 (Distribution)
몰수된 보증금은 다음과 같이 분배됩니다.
1.  **챌린저 보상 ($R_{challenger}$)**: 유효한 사기 증명을 제출한 챌린저(들)에게 지급됩니다.
    *   수식: $R_{challenger} = C_{max} + \Delta_{sequencer}$
    *   ($C_{max}$: 사기 증명 실행 비용, $\Delta_{sequencer}$: 추가 보상)
    *   **Multi-Challenger 지원**: 만약 $n$명의 챌린저가 동시에 유효한 증명을 제출했다면, 보상은 이들에게 분배됩니다.
2.  **프로토콜 트레저리**: 챌린저 보상을 제외한 나머지 금액은 프로토콜 트레저리로 귀속됩니다.

### 2.4 복구 및 영구 퇴출
*   **재예치 (Re-bonding)**: 시퀀서가 다시 활동하려면 정해진 기간 내에 보증금을 다시 채워 넣어야 합니다.
*   **영구 퇴출**: 기간 내에 보증금을 복구하지 못하면 활성 시퀀서 세트에서 **영구적으로 제거(Permanent Removal)**됩니다.

---

## 3. Validator Slashing (검증자 슬래싱)
검증자는 L2 상태를 모니터링하고 RAT(Randomized Attention Test)에 응답해야 하는 주체입니다.

### 3.1 발동 조건 (RAT)
검증자 슬래싱은 주로 **RAT(Randomized Attention Test)** 문맥에서 발생합니다.
*   **무응답 (Failure to Respond)**: 시스템이 무작위로 검증 요청(Attention Test)을 보냈을 때, 정해진 시간 내에 응답하지 않은 경우.
*   **거짓 증명 (Dishonest Attestation)**: 잘못된 검증 결과를 제출한 경우.

### 3.2 처벌 내용 (Penalty)
*   **부분 차감 ($C_{off}$)**: 보증금($D_{validator}$)에서 정해진 페널티 금액($C_{off}$)이 차감됩니다.
    *   페널티 금액($C_{off}$)은 검증자가 검증 비용($c_m$)을 아끼기 위해 '오프라인' 전략을 취하는 것이 손해가 되도록 설정됩니다. ($C_{off} \ge \frac{c_m \cdot N}{\pi_a}$)

### 3.3 복구 및 퇴출
*   **최소 보증금 유지**: 슬래싱 후 남은 보증금이 최소 요구량($D_{min}$) 미만으로 떨어지면, 정해진 기간 내에 이를 보충해야 합니다.
*   **퇴출**: 보충하지 못할 경우 활성 검증자 세트에서 제거됩니다.

---

## 4. 요약 비교

| 구분 | Sequencer (시퀀서) | Validator (검증자) |
| :--- | :--- | :--- |
| **주요 위반** | 사기(Fraud) - 잘못된 상태 제출 | 태만(Inattentiveness) - RAT 무응답 |
| **슬래싱 규모** | **보증금 전액 (Full Bond)** | **페널티 금액 ($C_{off}$)** |
| **결과** | 즉시 정지 및 영구 퇴출 위험 | 보증금 차감 (재충전 필요) |
| **목적** | 치명적인 악의적 공격 방지 | 상시 모니터링 상태(Liveness) 유지 |
