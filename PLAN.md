# 프로젝트 계획

**최종 목표**: 고정밀 사이클 정확도의 고성능 68020 에뮬레이터

## 핵심 원칙

1. **사이클 정확도 최우선** - 성능을 위해 정확도 희생 금지
2. **68020 완전 구현** - 전체 명령어 세트 + 어드레싱 모드
3. **검증 가능** - 각 명령어의 사이클 카운트 문서화 + 테스트

---

## Phase 1: 기초 구조 ✅ (완료)

### 1.1 WASM Bytecode Generator ✅
- [x] WASM 바이너리 포맷 구조
- [x] 기본 명령어 생성 (i32.const, local.get, local.set 등)
- [x] 모듈 빌더 (header, type section, function section 등)

### 1.2 68k Decoder ✅
- [x] Pipeline 프로젝트에서 decoder 이식
- [x] 기본 명령어 디코딩

### 1.3 기본 Translator ✅
- [x] MOVEQ 변환
- [x] 레지스터 매핑 (D0-D7, A0-A7 → local 변수)
- [x] 산술/논리 연산
- [x] 메모리 접근
- [x] 제어 흐름 (BRA, Bcc, JSR/RTS)

### 1.4 완전한 WASM 모듈 생성 ✅
- [x] JITCompiler 고수준 API
- [x] 모든 WASM 섹션 (Type, Function, Memory, Export, Code)
- [x] 68k 바이너리 → WASM 모듈 변환 성공!

---

## Phase 2: 사이클 정확도 구현 (진행 예정)

### 2.1 사이클 카운팅 시스템
- [ ] CycleCounter 구조체
- [ ] 각 명령어의 기본 사이클 수
- [ ] EA 모드별 추가 사이클
- [ ] 메모리 접근 사이클

### 2.2 68020 사이클 데이터베이스
- [ ] 공식 68020 스펙 문서화
- [ ] 명령어별 사이클 테이블
- [ ] EA 모드 사이클 테이블
- [ ] 테스트 케이스 작성

### 2.3 Translator에 사이클 통합
- [ ] 각 WASM 변환에 사이클 카운트 추가
- [ ] 누적 사이클 추적
- [ ] 사이클 정확도 검증

**목표**: 모든 명령어의 정확한 사이클 카운트

---

## Phase 3: 68020 전체 명령어 세트 (3주)

### 3.1 데이터 이동
- [ ] MOVE (모든 EA 모드)
- [ ] MOVEA, MOVEQ
- [ ] MOVEM (다중 레지스터)
- [ ] MOVEP (주변장치)
- [ ] LEA, PEA

### 3.2 산술 연산
- [ ] ADD, SUB (모든 변형)
- [ ] MULS, MULU, DIVS, DIVU
- [ ] ADDX, SUBX (확장)
- [ ] NEG, NEGX, CLR

### 3.3 논리 연산
- [ ] AND, OR, EOR, NOT
- [ ] 모든 EA 모드 지원

### 3.4 시프트/로테이트
- [ ] ASL, ASR, LSL, LSR
- [ ] ROL, ROR, ROXL, ROXR
- [ ] 레지스터/메모리 변형

### 3.5 비트 조작
- [ ] BTST, BSET, BCLR, BCHG
- [ ] 즉시/레지스터 모드

### 3.6 제어 흐름
- [x] BRA, BSR
- [x] Bcc (모든 조건)
- [ ] DBcc (루프)
- [ ] JMP, JSR, RTS
- [ ] RTR, RTE

### 3.7 시스템
- [ ] LINK, UNLK
- [ ] TRAP, TRAPV
- [ ] CHK, CHK2
- [ ] STOP, RESET

**목표**: 68020 전체 명령어 세트 완전 구현 + 사이클 정확

---

## Phase 4: 고급 기능 (2주)

### 4.1 예외 처리
- [ ] 주소 오류
- [ ] 불법 명령어
- [ ] 0 나누기
- [ ] TRAP 핸들러

### 4.2 특권 모드
- [ ] Supervisor/User 모드
- [ ] SR(Status Register) 관리
- [ ] 특권 명령어

### 4.3 메모리 관리
- [ ] MMU 시뮬레이션 (선택적)
- [ ] 캐시 동작 (사이클 영향)

**목표**: 완전한 68020 에뮬레이션

---

## Phase 5: 최적화 & 검증 (2주)

### 5.1 성능 최적화
- [ ] WASM 코드 크기 최소화
- [ ] 불필요한 플래그 계산 제거
- [ ] 핫패스 최적화
- [ ] 목표: 네이티브의 85%+

### 5.2 사이클 정확도 검증
- [ ] 68020 테스트 롬
- [ ] 각 명령어 사이클 검증
- [ ] 벤치마크 프로그램
- [ ] 목표: 100% 정확도

### 5.3 JavaScript API
- [ ] M68kEmulator 클래스
- [ ] run(), step(), reset()
- [ ] getRegisters(), setRegisters()
- [ ] 메모리 I/O
- [ ] 사이클 카운터 노출

**목표**: 사이클 정확 + 고성능 달성

---

## Phase 6: 문서화 & 배포 (1주)

### 6.1 문서
- [ ] API 레퍼런스
- [ ] 사이클 카운트 테이블
- [ ] 사용 예제
- [ ] 성능 벤치마크 결과

### 6.2 테스트 & 예제
- [ ] 68k 프로그램 예제
- [ ] 브라우저 데모
- [ ] 성능 비교

### 6.3 배포
- [ ] npm 패키지
- [ ] 웹 데모 사이트
- [ ] GitHub 릴리스

---

## 타임라인

- **Week 1**: Phase 1 (기초) ✅
- **Week 2**: Phase 2 (사이클 정확도)
- **Week 3-5**: Phase 3 (전체 명령어)
- **Week 6-7**: Phase 4 (고급 기능)
- **Week 8-9**: Phase 5 (최적화 & 검증)
- **Week 10**: Phase 6 (문서화 & 배포)

**총 예상 기간**: 10주

---

## 현재 상태

✅ **Phase 1 완료** (2026-02-12)
- WASM Builder
- 68k Decoder
- Translator (기본 명령어)
- JIT Compiler
- 완전한 WASM 모듈 생성

⏳ **다음**: Phase 2 (사이클 정확도 구현)

---

**핵심**: 사이클 정확도를 유지하면서 고성능을 달성하는 것이 목표!
