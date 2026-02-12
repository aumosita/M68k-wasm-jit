# TODO - 68020 JIT 에뮬레이터

**현재 진행도**: 17/164 (10%)

---

## 🔥 최우선 (이번 주)

### Phase 3.3: 데이터 이동 완성 (11개 남음)
- [ ] MOVEA - Move to address register
- [ ] MOVEM - Move multiple registers
- [ ] MOVEP - Move peripheral
- [ ] LINK - Link and allocate
- [ ] UNLK - Unlink

**목표**: 데이터 이동 18개 완성 → 18/18 (100%)

---

## 📋 Phase 3.4: 산술 연산 (23개 남음)

### 즉시값 명령어
- [ ] ADDI - Add immediate
- [ ] ADDQ - Add quick (부분 구현됨)
- [ ] ADDX - Add extended
- [ ] SUBI - Subtract immediate
- [ ] SUBQ - Subtract quick (부분 구현됨)
- [ ] SUBX - Subtract extended

### 곱셈/나눗셈
- [ ] MULS - Signed multiply (16/32-bit)
- [ ] MULU - Unsigned multiply (16/32-bit)
- [ ] DIVS - Signed divide
- [ ] DIVU - Unsigned divide
- [ ] DIVSL - Signed divide long (68020)
- [ ] DIVUL - Unsigned divide long (68020)

### 단항 연산
- [ ] NEG - Negate
- [ ] NEGX - Negate with extend
- [ ] CLR - Clear

### 비교
- [ ] CMP - Compare (부분 구현됨)
- [ ] CMPA - Compare address
- [ ] CMPI - Compare immediate
- [ ] CMPM - Compare memory
- [ ] TST - Test

**목표**: 산술 25개 완성 → 25/25 (100%)

---

## 📋 Phase 3.5: 논리 연산 (5개 남음)

- [ ] ANDI - AND immediate
- [ ] ORI - OR immediate
- [ ] EORI - EOR immediate
- [ ] NOT - Logical complement

**목표**: 논리 8개 완성 → 8/8 (100%)

---

## 📋 Phase 3.6: 시프트/로테이트 (8개)

현재: 0/8 (ASL, ASR, LSL, LSR, ROL, ROR 일부 디코딩만)

- [ ] ASL, ASR - Arithmetic shift
- [ ] LSL, LSR - Logical shift
- [ ] ROL, ROR - Rotate
- [ ] ROXL, ROXR - Rotate with extend

**목표**: 시프트 8개 완성 → 8/8 (100%)

---

## 📋 Phase 3.7: 비트 조작 (13개)

### 기본
- [ ] BTST - Test bit (부분 디코딩만)
- [ ] BSET - Set bit
- [ ] BCLR - Clear bit
- [ ] BCHG - Change bit

### 68020 비트 필드
- [ ] BFCHG - Bit field change
- [ ] BFCLR - Bit field clear
- [ ] BFEXTS - Bit field extract signed
- [ ] BFEXTU - Bit field extract unsigned
- [ ] BFFFO - Bit field find first one
- [ ] BFINS - Bit field insert
- [ ] BFSET - Bit field set
- [ ] BFTST - Bit field test

### 특수
- [ ] TAS - Test and set

**목표**: 비트 조작 13개 완성 → 13/13 (100%)

---

## 📋 Phase 3.8: 프로그램 제어 (32개 남음)

### 분기
- [ ] BSR - Branch to subroutine
- [ ] Bcc - All 16 conditions (BHI, BLS, BCC, BCS, BNE, BEQ, BVC, BVS, BPL, BMI, BGE, BLT, BGT, BLE)

### 조건부
- [ ] DBcc - Decrement and branch
- [ ] Scc - Set according to condition

### 점프
- [ ] JMP - Jump
- [ ] RTR - Return and restore

**목표**: 프로그램 제어 35개 완성 → 35/35 (100%)

---

## 📋 Phase 3.9: 시스템 제어 (13개 남음)

- [ ] TRAP - Trap
- [ ] TRAPV - Trap on overflow
- [ ] CHK - Check register
- [ ] CHK2 - Check register (68020)
- [ ] CAS - Compare and swap (68020)
- [ ] CAS2 - Compare and swap dual (68020)
- [ ] CMP2 - Compare register (68020)
- [ ] CALLM - Call module (68020)
- [ ] RTM - Return from module (68020)
- [ ] PACK - Pack BCD (68020)
- [ ] UNPK - Unpack BCD (68020)
- [ ] STOP - Stop
- [ ] RESET - Reset

**목표**: 시스템 15개 완성 → 15/15 (100%)

---

## 🔧 기술 부채 & 개선

### Translator 개선
- [ ] EA 모드 완전 구현
  - [ ] AddrRegDisp - displacement 읽기
  - [ ] AddrRegIndex - index 계산
  - [ ] AbsShort, AbsLong - 절대 주소
  - [ ] PCDisp, PCIndex - PC 상대
  - [ ] MemoryIndirect, PCMemoryIndirect (68020)

### 메모리 접근
- [ ] i32.load8_u, i32.load16_s 올바른 구현
- [ ] i32.store8, i32.store16 올바른 구현
- [ ] 메모리 정렬 처리

### 플래그 계산
- [ ] C (Carry) 플래그 정확한 계산
- [ ] V (Overflow) 플래그 정확한 계산
- [ ] X (Extend) 플래그 구현

### 제어 흐름
- [ ] BRA/Bcc - 실제 분기 구현 (block/loop 필요)
- [ ] JSR/RTS - 스택 기반 호출
- [ ] DBcc - 루프 카운터

---

## 📚 문서화

- [ ] WASM 바이트코드 포맷 문서
- [ ] 각 명령어 변환 예제
- [ ] 성능 벤치마크 결과
- [ ] JavaScript API 사용 가이드

---

## 🎯 마일스톤

### 🏁 Milestone 1: 데이터 이동 + 산술 완성 (이번 주 목표)
- 데이터 이동: 18/18 ✅
- 산술 연산: 25/25 ✅
- **진행도**: 43/164 (26%)

### 🏁 Milestone 2: 기본 명령어 완성 (2주 후)
- + 논리: 8/8 ✅
- + 시프트: 8/8 ✅
- **진행도**: 59/164 (36%)

### 🏁 Milestone 3: 전체 명령어 완성 (4주 후)
- + 비트: 13/13 ✅
- + 제어: 35/35 ✅
- + 시스템: 15/15 ✅
- **진행도**: 122/164 (74%)

### 🏁 Milestone 4: 68020 완전 구현 (6주 후)
- + EA 모드: 18/18 ✅
- + 예외: 14/14 ✅
- + 레지스터: 10/10 ✅
- **진행도**: 164/164 (100%) 🎉

---

## ✅ 완료된 항목

### Phase 1: 기초 구조 ✅
- [x] WASM Builder
- [x] 68k Decoder (기본)
- [x] Translator (기본)
- [x] JIT Compiler

### Phase 2: 사이클 정확도 ✅
- [x] CycleData (68020 사이클 데이터베이스)
- [x] 사이클 카운팅 시스템
- [x] Translator 사이클 통합

### Phase 3.1-3.2: 첫 명령어들 ✅
- [x] MOVEQ, MOVE
- [x] LEA, PEA
- [x] EXG, SWAP, EXT
- [x] ADD, SUB
- [x] AND, OR, EOR
- [x] BRA, Bcc, NOP
- [x] JSR, RTS

---

**마지막 업데이트**: 2026-02-12 16:30
**현재 진행도**: 17/164 (10%)
**다음 작업**: Phase 3.3 - 데이터 이동 완성
