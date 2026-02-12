# 68020 명령어 세트 체크리스트

**목표**: Motorola 68020 전체 스펙 100% 구현

이 파일은 구현 진행 상황을 추적합니다.

---

## 데이터 이동 (Data Movement) - 0/18

- [ ] MOVE - Move data
- [ ] MOVEA - Move address
- [ ] MOVEQ - Move quick (immediate)
- [ ] MOVEM - Move multiple registers
- [ ] MOVEP - Move peripheral data
- [ ] LEA - Load effective address
- [ ] PEA - Push effective address
- [ ] EXG - Exchange registers
- [ ] SWAP - Swap register halves
- [ ] EXT - Sign extend
- [ ] EXTB - Sign extend byte to long (68020)
- [ ] LINK - Link and allocate
- [ ] UNLK - Unlink

---

## 산술 연산 (Integer Arithmetic) - 0/25

- [ ] ADD - Add
- [ ] ADDA - Add address
- [ ] ADDI - Add immediate
- [ ] ADDQ - Add quick
- [ ] ADDX - Add extended
- [ ] SUB - Subtract
- [ ] SUBA - Subtract address
- [ ] SUBI - Subtract immediate
- [ ] SUBQ - Subtract quick
- [ ] SUBX - Subtract extended
- [ ] MULS - Signed multiply (16/32-bit)
- [ ] MULU - Unsigned multiply (16/32-bit)
- [ ] DIVS - Signed divide
- [ ] DIVU - Unsigned divide
- [ ] DIVSL - Signed divide long (68020)
- [ ] DIVUL - Unsigned divide long (68020)
- [ ] NEG - Negate
- [ ] NEGX - Negate with extend
- [ ] CLR - Clear
- [ ] CMP - Compare
- [ ] CMPA - Compare address
- [ ] CMPI - Compare immediate
- [ ] CMPM - Compare memory
- [ ] TST - Test

---

## 논리 연산 (Logical) - 0/8

- [ ] AND - Logical AND
- [ ] ANDI - AND immediate
- [ ] OR - Logical OR
- [ ] ORI - OR immediate
- [ ] EOR - Logical exclusive OR
- [ ] EORI - EOR immediate
- [ ] NOT - Logical complement

---

## 시프트/로테이트 (Shift and Rotate) - 0/8

- [ ] ASL - Arithmetic shift left
- [ ] ASR - Arithmetic shift right
- [ ] LSL - Logical shift left
- [ ] LSR - Logical shift right
- [ ] ROL - Rotate left
- [ ] ROR - Rotate right
- [ ] ROXL - Rotate left with extend
- [ ] ROXR - Rotate right with extend

---

## 비트 조작 (Bit Manipulation) - 0/13

### 기본 (68000)
- [ ] BTST - Test bit
- [ ] BSET - Set bit
- [ ] BCLR - Clear bit
- [ ] BCHG - Change bit

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
- [ ] TAS - Test and set

---

## 프로그램 제어 (Program Control) - 1/35

### 분기 (Branch)
- [x] BRA - Branch always (구현됨)
- [ ] BSR - Branch to subroutine
- [ ] Bcc - Branch conditionally (16 conditions)
  - [ ] BHI, BLS, BCC, BCS
  - [ ] BNE, BEQ, BVC, BVS
  - [ ] BPL, BMI, BGE, BLT
  - [ ] BGT, BLE

### 조건 (Conditional)
- [ ] DBcc - Decrement and branch
- [ ] Scc - Set according to condition

### 점프 (Jump)
- [ ] JMP - Jump
- [ ] JSR - Jump to subroutine
- [ ] RTS - Return from subroutine
- [ ] RTR - Return and restore
- [ ] RTE - Return from exception

### 기타
- [x] NOP - No operation (구현됨)

---

## 시스템 제어 (System Control) - 0/15

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

## 68020 전용 명령어 - 0/12

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
- [ ] EXTB - Extend byte to long
- [ ] DIVSL, DIVUL - 64-bit divide
- [ ] MULS.L, MULU.L - 32×32→64-bit multiply
- [ ] CALLM, RTM - Module call/return

---

## 어드레싱 모드 (Addressing Modes) - 5/18

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

## 예외 처리 (Exception Processing) - 0/14

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

## 시스템 레지스터 - 0/10

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

| 카테고리 | 완료 | 전체 | 진행률 |
|---------|------|------|--------|
| 데이터 이동 | 0 | 18 | 0% |
| 산술 연산 | 0 | 25 | 0% |
| 논리 연산 | 0 | 8 | 0% |
| 시프트/로테이트 | 0 | 8 | 0% |
| 비트 조작 | 0 | 13 | 0% |
| 프로그램 제어 | 1 | 35 | 3% |
| 시스템 제어 | 0 | 15 | 0% |
| 어드레싱 모드 | 5 | 18 | 28% |
| 예외 처리 | 0 | 14 | 0% |
| 시스템 레지스터 | 0 | 10 | 0% |
| **전체** | **6** | **164** | **4%** |

---

**목표**: 164개 항목 모두 체크 = 68020 완전 구현!

**현재**: Phase 1-2 완료, Phase 3 시작 전

**작성일**: 2026-02-12
