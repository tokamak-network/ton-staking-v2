# Demo Configuration

이 디렉토리는 **Front 데모에서 사용하는 설정 파일**을 모아둡니다.

## Files

### `challengers.json`
- 데모에서 관찰할 챌린저 주소 목록
- 리워드 토큰 정보(WTON 등)

### `networks.json`
- L1/L2 RPC, op-node, batcher 주소
- devnet 연결 정보

### `scenarios.json`
- 데모 시나리오 리스트
- backend가 script 실행시 이 설정을 사용

---

## Update Guide

1. **Challenger 주소 수정**
   - `challengers.json`의 `challengers` 항목을 실제 devnet 계정으로 변경하세요.

2. **RPC 주소 수정**
   - `networks.json`에서 L1/L2 RPC URL을 devnet에 맞게 수정하세요.

3. **Scenario 추가**
   - `scenarios.json`에 script 경로 및 테스트명을 추가하면 UI에 자동 반영됩니다.
