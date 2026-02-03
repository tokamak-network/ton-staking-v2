# 프론트 데모

경로: `frontend/`

## 실행

```bash
cd frontend
npm install
npm run dev
```

## 준비 사항

- LotteryCandidate 주소
- DepositManager 주소
- TON/WTON 주소

## 로컬 데모 (테스트용)

로컬에서 바로 띄워서 주소를 생성해 사용해도 됩니다.

### 1. 로컬 노드 실행

```bash
# 터미널 1: Anvil 실행
anvil
```

### 2. 컨트랙트 배포

```bash
# 터미널 2: 전체 배포 (devnet용 스크립트)
forge script script/DeployV3FullForDevnet.s.sol:DeployV3FullForDevnet \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast -vvvv
```

배포 로그에서 다음 주소들을 확인하세요:
- `daoCommitteeProxy`
- `ton`
- `wton`
- `depositManagerProxy`

### 3. LotteryCandidate 생성

```bash
# operator 주소 (anvil의 첫 번째 계정 사용)
OPERATOR=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# LotteryCandidate 생성
cast send $DAO_COMMITTEE_PROXY \
  "createLotteryCandidate(string)" "lottery-candidate" \
  --rpc-url http://127.0.0.1:8545 --private-key $PK

# LotteryCandidate 주소 확인
cast call $DAO_COMMITTEE_PROXY \
  "candidateInfos(address)(address,uint256,uint128,uint128,uint128)" $OPERATOR \
  --rpc-url http://127.0.0.1:8545
```

첫 번째 반환값이 LotteryCandidate 주소입니다.

### 4. 프론트엔드에서 사용

1. **MetaMask에 로컬 네트워크 추가:**
   - MetaMask → 네트워크 추가
   - RPC URL: `http://127.0.0.1:8545`
   - Chain ID: `31337`
   - Currency Symbol: `ETH`

2. **Anvil 계정을 MetaMask에 가져오기:**
   - Anvil 실행 시 출력되는 Private Key를 MetaMask에 Import

3. **프론트엔드 실행:**
   ```bash
   cd frontend
   npm install
   npm run dev
   ```

4. **주소 입력:**
   - 배포 로그에서 확인한 주소들을 프론트엔드에 입력
   - 또는 `frontend/src/App.tsx`의 `loadLocalAddresses()` 함수에 주소를 하드코딩 후 "Load Local Addresses" 버튼 클릭
   - "Save Addresses" 버튼으로 localStorage에 저장 가능

## 기능

- TON/WTON 스테이킹
- Lottery 참여/추첨
- 시뇨리지 적립/분배
- 언스테이킹 요청/처리 (DepositManager 직접 호출)
