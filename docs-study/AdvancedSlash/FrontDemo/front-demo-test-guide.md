# Front Demo Test Guide (Multi-Challenger Slashing)

이 문서는 **Front 데모 테스트 방법**을 단계별로 상세 설명합니다.  
멀티 챌린저 시나리오(보상 분배 포함)를 UI에서 검증하는 것을 목표로 합니다.

---

## ✅ 0. 사전 요구사항

- Full Optimism devnet 실행 필요
- Hardhat compile + ABI 추출 필요
- Backend/Frontend 각각 실행 필요

---

## ✅ 1. Devnet 실행
# repo root (ton-staking-v2/)
# 처음 실행 시 (최초 1회)
make devnet-allocs-offline

# repo root (Devnet 계속 실행 (백그라운드))
bash scripts/demo/devnet-up.sh

- devnet 실행 로그: .devnet/devnet.log
- devnet 종료:
bash scripts/demo/devnet-down.sh


---

## ✅ 2. ABI 준비bash
# 처음 실행 시 (최초 1회)
npm install 

# repo root (ton-staking-v2/)
npx hardhat compile

bash scripts/demo/extract-abis.sh 
or 
chmod +x scripts/demo/extract-abis.sh
./scripts/demo/extract-abis.sh


확인해야 할 ABI:
demo-config/abis/DisputeGameFactory.json
demo-config/abis/FaultDisputeGame.json
demo-config/abis/SeigManager.json

---

## ✅ 3. Backend 실행bash
cd demo-backend

# 처음 실행 시 (최초 1회)
npm install 

# 매번
npm run dev


---

## ✅ 4. Front 실행bash
cd demo-frontend

# 처음 실행 시 (최초 1회)
npm install

# 매번
npm run dev

접속: http://localhost:3000

---

## ✅ 5. UI에서 테스트
1. Scenario 선택  
2. Start Demo 클릭  
3. 아래 항목 확인  

### ✅ 확인 포인트
- RPC Status: L1/L2 OK 확인  
- Event Config Warnings: 이벤트 설정 오류 없음  
- Stepper: 이벤트 발생 시 단계 이동  
- Logs: backend 스크립트 로그 출력  
- Balances: 챌린저 WTON 잔액 변화 확인