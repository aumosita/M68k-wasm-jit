# TODO - 68020 JIT 에뮬레이터

**현재 진행도**: 42/164 (26%)

---

## 🎉 최근 완료 (2026-02-12 17:25)

### ✅ 시프트/로테이트 완성! (8/8 = 100%)
- [x] ASL, ASR - Arithmetic shift left/right
- [x] LSL, LSR - Logical shift left/right
- [x] ROL, ROR - Rotate left/right
- [x] ROXL, ROXR - Rotate with extend
- **두 번째 명령어 그룹 100% 완성!** 🎊

### ✅ 논리 연산 완성! (8/8 = 100%)
- [x] AND, ANDI, OR, ORI, EOR, EORI, NOT

### 진행 중
- 🔄 데이터 이동 11/18 (61%)
- 🔄 산술 연산 10/25 (40%)

**이번 세션 성과**: 17개 → 42개 (+25개 추가, 147% 증가!)

---

## 🔥 최우선 (다음 작업)

### Phase 3.6: 비트 조작 (0/13)

#### 기본 비트 명령어 (68000)
- [ ] BTST - Test bit
- [ ] BSET - Set bit
- [ ] BCLR - Clear bit
- [ ] BCHG - Change bit

#### 68020 비트 필드 명령어
- [ ] BFCHG - Bit field change
- [ ] BFCLR - Bit field clear
- [ ] BFEXTS - Bit field extract signed
- [ ] BFEXTU - Bit field extract unsigned
- [ ] BFFFO - Bit field find first one
- [ ] BFINS - Bit field insert
- [ ] BFSET - Bit field set
- [ ] BFTST - Bit field test

#### 특수
- [ ] TAS - Test and set

**목표**: 기본 비트 명령어 4개 먼저 완성

---

## 📋 남은 데이터 이동 (7개)

- [ ] MOVEM - Move multiple registers (중요, 복잡)
- [ ] MOVEP - Move peripheral (덜 중요)
- [ ] ADDA - Add address
- [ ] SUBA - Subtract address
- [ ] CMPA - Compare address
- [ ] ADDX - Add extended
- [ ] SUBX - Subtract extended
- [ ] NEGX - Negate with extend
- [ ] CMPM - Compare memory

---

## 📋 남은 산술 연산 (15개)

### 곱셈/나눗셈
- [ ] MULS - Signed multiply (16/32-bit)
- [ ] MULU - Unsigned multiply (16/32-bit)
- [ ] DIVS - Signed divide
- [ ] DIVU - Unsigned divide
- [ ] DIVSL - Signed divide long (68020)
- [ ] DIVUL - Unsigned divide long (68020)

---

## 📋 프로그램 제어 (32개 남음)

### 분기
- [ ] BSR - Branch to subroutine
- [ ] Bcc 16가지 조건 (현재 기본 구조만 있음)

### 조건부
- [ ] DBcc - Decrement and branch
- [ ] Scc - Set according to condition

### 점프
- [ ] JMP - Jump
- [ ] RTR - Return and restore

---

## 📋 시스템 제어 (13개 남음)

- [ ] TRAP, TRAPV
- [ ] CHK, CHK2
- [ ] CAS, CAS2 (68020)
- [ ] CMP2 (68020)
- [ ] CALLM, RTM (68020)
- [ ] PACK, UNPK (68020)
- [ ] STOP, RESET
- [ ] ILLEGAL

---

## 🔧 기술 부채 & 개선

### 플래그 구현 필요
- [ ] C (Carry) 플래그 - 시프트/산술 연산
- [ ] V (Overflow) 플래그 - 산술 연산
- [ ] X (Extend) 플래그 - ROXL/ROXR, ADDX/SUBX

### EA 모드 완전 구현
- [ ] AddrRegDisp - displacement 읽기
- [ ] AddrRegIndex - index 계산
- [ ] AbsShort, AbsLong - 절대 주소
- [ ] PCDisp, PCIndex - PC 상대
- [ ] MemoryIndirect, PCMemoryIndirect (68020)

### 메모리 접근
- [ ] i32.load8_u, i32.load16_s 올바른 인코딩
- [ ] i32.store8, i32.store16 올바른 인코딩
- [ ] 메모리 정렬 처리

### 제어 흐름
- [ ] BRA/Bcc - 실제 분기 구현 (block/loop)
- [ ] DBcc - 루프 카운터

---

## 🎯 마일스톤

### 🏁 Milestone 1: 기본 명령어 완성 (진행 중)
- ✅ 논리 연산: 8/8 (100%)
- ✅ 시프트/로테이트: 8/8 (100%)
- 🔄 데이터 이동: 11/18 (61%)
- 🔄 산술 연산: 10/25 (40%)
- **현재 진행도**: 42/164 (26%)
- **목표 진행도**: 59/164 (36%)

### 🏁 Milestone 2: 비트 & 제어 완성 (다음 목표)
- + 비트: 13/13 ✅
- + 제어: 35/35 ✅
- **목표 진행도**: 107/164 (65%)

### 🏁 Milestone 3: 전체 명령어 완성
- + 시스템: 15/15 ✅
- **목표 진행도**: 122/164 (74%)

### 🏁 Milestone 4: 68020 완전 구현
- + EA 모드: 18/18 ✅
- + 예외: 14/14 ✅
- + 레지스터: 10/10 ✅
- **최종 목표**: 164/164 (100%) 🎉

---

## ✅ 완료된 항목

### Phase 1: 기초 구조 ✅
- [x] WASM Builder
- [x] 68k Decoder
- [x] Translator
- [x] JIT Compiler

### Phase 2: 사이클 정확도 ✅
- [x] CycleData (68020 사이클 데이터베이스)
- [x] 사이클 카운팅 시스템
- [x] Translator 사이클 통합

### Phase 3: 명령어 구현 진행 중

**완성된 그룹 (2개):**
- ✅ 논리 연산 (8/8): AND, ANDI, OR, ORI, EOR, EORI, NOT
- ✅ 시프트/로테이트 (8/8): ASL, ASR, LSL, LSR, ROL, ROR, ROXL, ROXR

**진행 중:**
- 🔄 데이터 이동 (11/18): MOVEQ, MOVE, MOVEA, LEA, PEA, EXG, SWAP, EXT, EXTB, LINK, UNLK
- 🔄 산술 연산 (10/25): ADD, ADDI, ADDQ, SUB, SUBI, SUBQ, CLR, NEG, TST, CMP, CMPI
- 🔄 제어 흐름 (5/35): BRA, Bcc, NOP, JSR, RTS

---

**마지막 업데이트**: 2026-02-12 17:25
**현재 진행도**: 42/164 (26%)
**다음 작업**: Phase 3.6 - 비트 조작 기본 4개 (BTST, BSET, BCLR, BCHG)
