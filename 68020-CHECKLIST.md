# 68020 명령어 세트 체크리스트

**목표**: Motorola 68020 전체 스펙 100% 구현 (정수 연산 CPU 코어)

**제외**: FPU (68881/68882 코프로세서) - 별도 확장 가능

이 파일은 구현 진행 상황을 추적합니다.

---

## 데이터 이동 (Data Movement) - 11/18 (61%)

- [x] MOVE - Move data
- [x] MOVEA - Move address
- [x] MOVEQ - Move quick (immediate)
- [ ] MOVEM - Move multiple registers
- [ ] MOVEP - Move peripheral data
- [x] LEA - Load effective address
- [x] PEA - Push effective address
- [x] EXG - Exchange registers
- [x] SWAP - Swap register halves
- [x] EXT - Sign extend
- [x] EXTB - Sign extend byte to long (68020)
- [x] LINK - Link and allocate
- [x] UNLK - Unlink

**구현**: 11개 | **디코딩**: 11/11 ✅

---

## 산술 연산 (Integer Arithmetic) - 23/25 (92%) ✅

- [x] ADD - Add
- [x] ADDA - Add address
- [x] ADDI - Add immediate
- [x] ADDQ - Add quick
- [x] ADDX - Add extended
- [x] SUB - Subtract
- [x] SUBA - Subtract address
- [x] SUBI - Subtract immediate
- [x] SUBQ - Subtract quick
- [x] SUBX - Subtract extended
- [x] MULS - Signed multiply (16/32-bit)
- [x] MULU - Unsigned multiply (16/32-bit)
- [x] DIVS - Signed divide
- [x] DIVU - Unsigned divide
- [x] DIVSL - Signed divide long (68020) *simplified*
- [x] DIVUL - Unsigned divide long (68020) *simplified*
- [x] NEG - Negate
- [x] NEGX - Negate with extend
- [x] CLR - Clear
- [x] CMP - Compare
- [x] CMPA - Compare address
- [x] CMPI - Compare immediate
- [ ] CMPM - Compare memory
- [x] TST - Test

**구현**: 23개 | **디코딩**: 23/23 ✅

**Note**: DIVSL/DIVUL은 32÷32 버전으로 구현됨 (64÷32는 TODO)

---

## 논리 연산 (Logical) - 7/8 (88%) ✅

- [x] AND - Logical AND
- [x] ANDI - AND immediate
- [x] OR - Logical OR
- [x] ORI - OR immediate
- [x] EOR - Logical exclusive OR
- [x] EORI - EOR immediate
- [x] NOT - Logical complement

**구현**: 7개 | **디코딩**: 7/7 ✅

---

## 시프트/로테이트 (Shift and Rotate) - 6/8 (75%)

- [x] ASL - Arithmetic shift left
- [x] ASR - Arithmetic shift right
- [x] LSL - Logical shift left
- [x] LSR - Logical shift right
- [ ] ROL - Rotate left *opcode needs verification*
- [x] ROR - Rotate right
- [ ] ROXL - Rotate left with extend *opcode needs verification*
- [ ] ROXR - Rotate right with extend *opcode needs verification*

**구현**: 6개 | **디코딩**: 6/6 ✅

**Note**: ROL/ROXL/ROXR 구현은 완료, opcode 생성 검증 필요

---

## 비트 조작 (Bit Manipulation) - 5/13 (38%)

### 기본 (68000)
- [x] BTST - Test bit
- [x] BSET - Set bit
- [x] BCLR - Clear bit
- [x] BCHG - Change bit

### 비트 필드 (68020)
- [ ] BFCHG - Bit field change
- [ ] BFCLR - Bit field clear
- [ ] BFEXTS - Bit field extract signed
- [ ] BFEXTU - Bit field extract unsigned
- [ ] BFFFO - Bit field find first one
- [ ] BFINS - Bit field insert
- [ ] BFSET - Bit field set
- [ ] BFTST - Bit field test

### 특수
- [x] TAS - Test and set

**구현**: 5개 | **디코딩**: 5/5 ✅

---

## 프로그램 제어 (Program Control) - 20/35 (57%)

### 분기 (Branch)
- [x] BRA - Branch always
- [x] BSR - Branch to subroutine
- [x] Bcc - Branch conditionally (14 conditions)
  - [x] BHI, BLS, BCC, BCS
  - [x] BNE, BEQ, BVC, BVS
  - [x] BPL, BMI, BGE, BLT
  - [x] BGT, BLE

### 조건 (Conditional)
- [ ] DBcc - Decrement and branch
- [ ] Scc - Set according to condition

### 점프 (Jump)
- [x] JMP - Jump
- [x] JSR - Jump to subroutine
- [x] RTS - Return from subroutine
- [ ] RTR - Return and restore
- [ ] RTE - Return from exception

### 기타
- [x] NOP - No operation

**구현**: 20개 | **디코딩**: 20/20 ✅

**완성 항목**:
- BRA, BSR (분기)
- Bcc 14개 조건 (HI, LS, CC, CS, NE, EQ, VC, VS, PL, MI, GE, LT, GT, LE)
- JMP, JSR, RTS (점프/서브루틴)
- NOP

**남은 항목**:
- DBcc, Scc
- RTR, RTE

---

## 시스템 제어 (System Control) - 0/15 (0%)

### 특권 명령어 (Privileged)
- [ ] ANDI to SR - AND immediate to SR
- [ ] EORI to SR - EOR immediate to SR
- [ ] ORI to SR - OR immediate to SR
- [ ] MOVE to/from SR - Move to/from SR
- [ ] MOVE USP - Move user stack pointer
- [ ] STOP - Stop
- [ ] RESET - Reset external devices
- [ ] RTE - Return from exception

### 예외/트랩 (Exception and Trap)
- [ ] TRAP - Trap
- [ ] TRAPV - Trap on overflow
- [ ] CHK - Check register against bounds
- [ ] CHK2 - Check register against bounds (68020)
- [ ] ILLEGAL - Illegal instruction

### 68020 전용
- [ ] CALLM - Call module (68020)
- [ ] RTM - Return from module (68020)

---

## 68020 전용 명령어 - 0/12 (0%)

### 비트 필드 (위에서 중복)
- Bit field 명령어 참조

### 팩/언팩 (Pack/Unpack)
- [ ] PACK - Pack BCD
- [ ] UNPK - Unpack BCD

### Compare-And-Swap
- [ ] CAS - Compare and swap operands
- [ ] CAS2 - Compare and swap dual operands

### 기타
- [ ] CMP2 - Compare register against bounds
- [x] EXTB - Extend byte to long ✅
- [x] DIVSL, DIVUL - 64-bit divide ✅ *simplified*
- [ ] MULS.L, MULU.L - 32×32→64-bit multiply
- [ ] CALLM, RTM - Module call/return

---

## 어드레싱 모드 (Addressing Modes) - 5/18 (28%)

### 레지스터
- [x] Dn - Data register direct
- [x] An - Address register direct

### 레지스터 간접
- [x] (An) - Address register indirect
- [x] (An)+ - Postincrement
- [x] -(An) - Predecrement
- [ ] d16(An) - Displacement
- [ ] d8(An,Xn) - Indexed
- [ ] (bd,An,Xn) - Memory indirect (68020)

### 절대
- [ ] (xxx).W - Absolute short
- [ ] (xxx).L - Absolute long

### PC 상대
- [ ] d16(PC) - PC displacement
- [ ] d8(PC,Xn) - PC indexed
- [ ] (bd,PC,Xn) - PC memory indirect (68020)

### 즉시값
- [x] #<data> - Immediate

### 특수
- [ ] SR - Status register
- [ ] CCR - Condition code register
- [ ] USP - User stack pointer

---

## 예외 처리 (Exception Processing) - 0/14 (0%)

- [ ] Reset
- [ ] Bus Error
- [ ] Address Error
- [ ] Illegal Instruction
- [ ] Zero Divide
- [ ] CHK Instruction
- [ ] TRAPV Instruction
- [ ] Privilege Violation
- [ ] Trace
- [ ] Line A Emulator
- [ ] Line F Emulator
- [ ] Uninitialized Interrupt
- [ ] Spurious Interrupt
- [ ] Interrupt Autovectors (7 levels)
- [ ] TRAP Instructions (16 vectors)

---

## 시스템 레지스터 - 0/10 (0%)

- [ ] PC - Program Counter
- [ ] SR - Status Register
- [ ] CCR - Condition Code Register
- [ ] USP - User Stack Pointer
- [ ] SSP - Supervisor Stack Pointer
- [ ] VBR - Vector Base Register (68020)
- [ ] SFC - Source Function Code (68020)
- [ ] DFC - Destination Function Code (68020)
- [ ] CACR - Cache Control Register (68020)
- [ ] CAAR - Cache Address Register (68020)

---

## 진행 상황 요약

| 카테고리 | 구현 | 디코딩 | 전체 | 진행률 | 상태 |
|---------|------|--------|------|--------|------|
| 데이터 이동 | 11 | 11/11 ✅ | 18 | 61% | 🔄 |
| 산술 연산 | 23 | 23/23 ✅ | 25 | **92%** | ✅ |
| 논리 연산 | 7 | 7/7 ✅ | 8 | **88%** | ✅ |
| 시프트/로테이트 | 6 | 6/6 ✅ | 8 | **75%** | ✅ |
| 비트 조작 | 5 | 5/5 ✅ | 13 | 38% | 🔄 |
| 프로그램 제어 | 20 | 20/20 ✅ | 35 | **57%** | 🔄 |
| 시스템 제어 | 0 | 0/0 | 15 | 0% | 📝 |
| 어드레싱 모드 | 5 | - | 18 | 28% | 📝 |
| 예외 처리 | 0 | - | 14 | 0% | 📝 |
| 시스템 레지스터 | 0 | - | 10 | 0% | 📝 |
| **전체** | **58** | **58/58** ✅ | **164** | **35%** | 🔄 |

**범례**: ✅ 완료/거의완료 | 🔄 진행중 | 📝 미시작

---

## 🎉 최근 성과 (2026-02-12)

### ✅ 프로그램 제어 구현 완료!
- **BRA, BSR** - 무조건 분기 및 서브루틴 호출 ✅
- **Bcc (14개)** - 모든 조건 분기 ✅
  - HI, LS, CC, CS, NE, EQ, VC, VS, PL, MI, GE, LT, GT, LE
- **JMP, JSR, RTS** - 점프 및 서브루틴 완전 구현 ✅

### ✅ 테스트 확장
- 46개 → **65개 명령어 자동 테스트**
- **65/65 전부 통과** ✅
- 프로그램 제어 완전 검증

### ✅ Decoder 대폭 개선 (오전)
- **19/60 (31%) → 58/58 (100%)** 디코딩 성공률 달성!
- 모든 구현된 명령어가 정상 디코딩 ✅

### ✅ 빌드 시스템 완성 (오전)
- Zig 0.13.0 호환성 확보
- 자동 빌드 + 테스트 파이프라인

---

## 📊 다음 작업 우선순위

### 1️⃣ **데이터 이동 완성**
나머지 7개 구현으로 61% → 100%
- [ ] MOVEM - 다중 레지스터 이동
- [ ] MOVEP - 주변장치 데이터 이동
- [ ] LINK/UNLK 완전 구현

### 2️⃣ **비트 필드 명령어**
68020 고유 기능
- [ ] 8개 비트 필드 명령어

### 3️⃣ **조건 설정 명령어**
- [ ] DBcc - Decrement and branch
- [ ] Scc - Set condition code
나머지 7개 구현으로 61% → 100%
- [ ] MOVEM - 다중 레지스터 이동
- [ ] LINK/UNLK 완전 구현

### 3️⃣ **비트 필드 명령어**
68020 고유 기능
- [ ] 8개 비트 필드 명령어

---

**작성일**: 2026-02-09
**마지막 업데이트**: 2026-02-12 18:15

**GitHub**: https://github.com/aumosita/M68k-wasm-jit
**최신 커밋**: 2d7c80b - "Implement JMP, JSR, RTS (jump and subroutine)"
