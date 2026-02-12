# 68020 명령어 세트 체크리스트

**목표**: Motorola 68020 전체 스펙 100% 구현 (정수 연산 CPU 코어)

**제외**: FPU (68881/68882 코프로세서) - 별도 확장 가능

이 파일은 구현 진행 상황을 추적합니다.

---

## 데이터 이동 (Data Movement) - 11/18

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

---

## 산술 연산 (Integer Arithmetic) - 21/25

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
- [ ] DIVSL - Signed divide long (68020)
- [ ] DIVUL - Unsigned divide long (68020)
- [x] NEG - Negate
- [x] NEGX - Negate with extend
- [x] CLR - Clear
- [x] CMP - Compare
- [x] CMPA - Compare address
- [x] CMPI - Compare immediate
- [x] CMPM - Compare memory
- [x] TST - Test

---

## 논리 연산 (Logical) - 8/8 ✅

- [x] AND - Logical AND
- [x] ANDI - AND immediate
- [x] OR - Logical OR
- [x] ORI - OR immediate
- [x] EOR - Logical exclusive OR
- [x] EORI - EOR immediate
- [x] NOT - Logical complement

---

## 시프트/로테이트 (Shift and Rotate) - 8/8 ✅

- [x] ASL - Arithmetic shift left
- [x] ASR - Arithmetic shift right
- [x] LSL - Logical shift left
- [x] LSR - Logical shift right
- [x] ROL - Rotate left
- [x] ROR - Rotate right
- [x] ROXL - Rotate left with extend
- [x] ROXR - Rotate right with extend

---

## 비트 조작 (Bit Manipulation) - 5/13

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

---

## 프로그램 제어 (Program Control) - 3/35

### 분기 (Branch)
- [x] BRA - Branch always
- [ ] BSR - Branch to subroutine
- [x] Bcc - Branch conditionally (16 conditions)
  - [ ] BHI, BLS, BCC, BCS
  - [ ] BNE, BEQ, BVC, BVS
  - [ ] BPL, BMI, BGE, BLT
  - [ ] BGT, BLE

### 조건 (Conditional)
- [ ] DBcc - Decrement and branch
- [ ] Scc - Set according to condition

### 점프 (Jump)
- [ ] JMP - Jump
- [x] JSR - Jump to subroutine
- [x] RTS - Return from subroutine
- [ ] RTR - Return and restore
- [ ] RTE - Return from exception

### 기타
- [x] NOP - No operation

---

## 시스템 제어 (System Control) - 2/15

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
| 데이터 이동 | 11 | 18 | 61% |
| 산술 연산 | 21 | 25 | 84% |
| 논리 연산 | 8 | 8 | **100%** ✅ |
| 시프트/로테이트 | 8 | 8 | **100%** ✅ |
| 비트 조작 | 5 | 13 | 38% |
| 프로그램 제어 | 3 | 35 | 9% |
| 시스템 제어 | 2 | 15 | 13% |
| 어드레싱 모드 | 5 | 18 | 28% |
| 예외 처리 | 0 | 14 | 0% |
| 시스템 레지스터 | 0 | 10 | 0% |
| **전체** | **58** | **164** | **35%** |

---

**목표**: 164개 항목 모두 체크 = 68020 완전 구현!

**현재**: Phase 3 진행 중
**완료**: 
- ✅ 논리 연산 8/8 (100%)
- ✅ 시프트/로테이트 8/8 (100%)
- 🔄 산술 연산 21/25 (84% - 거의 완성!)
- 🔄 데이터 이동 11/18 (61%)
- 🔄 비트 조작 5/13 (38%)

**다음**: 68020 전용 곱셈/나눗셈 (DIVSL, DIVUL) 또는 다른 그룹

**작성일**: 2026-02-12
**마지막 업데이트**: 2026-02-12 17:40






