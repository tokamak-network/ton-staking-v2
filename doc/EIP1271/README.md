# EIP-1271 Implementation Prompts

이 폴더는 EIP-1271 스마트 컨트랙트 서명 검증 기능을 구현하기 위한 LLM 프롬프트들을 포함합니다.

## 파일 구조

- `basic-implementation.md`: EIP-1271 + MultiSig 통합 구현 프롬프트
- `security-checklist.md`: 보안 검토 체크리스트
- `testing-prompts.md`: 테스트 코드 생성 프롬프트
- `upgrade-guide.md`: 기존 컨트랙트 업그레이드 가이드

## 사용 방법

1. 해당하는 프롬프트 파일을 선택
2. 프롬프트 내용을 LLM에 입력
3. 필요에 따라 컨텍스트 정보 추가
4. 생성된 코드를 검토 및 테스트

## 주의사항

- 생성된 코드는 반드시 보안 검토를 거쳐야 합니다
- 테스트 코드를 함께 작성하여 검증하세요
- 프로덕션 배포 전 감사를 받으시기 바랍니다