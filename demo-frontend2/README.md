# demo-frontend2 - Interactive Challenger Demo Frontend

**Option 1: 선택형 Challenger** 프론트엔드

## 📦 설치

bash
cd demo-frontend2
npm install


## 🚀 실행

bash
npm run dev

브라우저에서 http://localhost:3002 접속

## 🎮 사용 방법

1. 지갑 연결: MetaMask 연결
2. 게임 생성: Root Block Number 입력 후 게임 생성
3. Move 선택: 유효한 move들 중 하나 선택
4. Move 제출: 선택한 move 제출
5. 게임 종료: 승리 후 게임 종료 및 보상 분배
6. 새 게임: 새로운 게임 시작

## 📡 API 연동

demo-backend2 (port 3001)와 연동

bash
# 터미널 1: devnet
bash scripts/demo/devnet-up.sh

# 터미널 2: backend2
cd demo-backend2
npm run dev

# 터미널 3: frontend2
cd demo-frontend2
npm run dev


## 🎨 기술 스택

- Next.js 14
- React 18
- TypeScript
- Tailwind CSS
- ethers.js 6