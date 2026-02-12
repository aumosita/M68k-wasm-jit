# PROJECT.md - 프로젝트 정의

## 핵심 목표

**고정밀 사이클 정확도의 고성능 68020 에뮬레이터**

A cycle-accurate, high-performance Motorola 68020 emulator using WebAssembly JIT compilation.

**중요**: 68000이 아닌 **68020 전체 스펙 완전 구현**이 목표

---

## 목표의 세 축

### 1. 사이클 정확도 (Cycle Accuracy)

**정의**: 모든 명령어가 실제 68020 하드웨어와 동일한 사이클 수로 실행

**구현**:
- 각 명령어의 정확한 사이클 카운트 추적
- EA(Effective Address) 계산 사이클 포함
- 메모리 접근 대기 시간 시뮬레이션
- 68020 공식 스펙 준수

**왜 중요한가**:
- 타이밍에 민감한 68k 소프트웨어 정확히 에뮬레이션
- 사운드, 비디오 동기화 정확도
- 원본 하드웨어 동작 완벽 재현

### 2. 68020 완전 구현 (Complete 68020 Specification)

**정의**: Motorola 68020 프로세서의 모든 기능 100% 구현

**범위**:
- ✅ 모든 명령어 (100개+ 명령어, 모든 변형)
- ✅ 모든 어드레싱 모드 (18가지 EA 모드)
- ✅ 모든 데이터 크기 (Byte, Word, Long)
- ✅ 예외 처리 (모든 벡터)
- ✅ 특권 모드 (Supervisor/User)
- ✅ 시스템 레지스터 (SR, USP, SSP 등)
- ✅ 68020 고유 기능 (32비트 확장, 새 명령어)

**68020 vs 68000 차이**:
- 32비트 주소/데이터 버스
- 추가 명령어 (BFEXTU, BFINS, CAS, CHK2, PACK, UNPK 등)
- 강화된 EA 모드
- 명령어 캐시
- 향상된 성능

**왜 68020인가**:
- 68000보다 완전한 32비트 프로세서
- Amiga, Macintosh II, Atari TT 등에서 사용
- 더 강력하고 현대적인 명령어 세트

### 3. 고성능 (High Performance)

**정의**: 네이티브 실행 속도의 80-95% 달성

**구현**:
- 68k → WASM JIT 변환 (런타임)
- 브라우저 WASM 엔진의 네이티브 코드 생성 활용
- 최소 오버헤드, 직접 변환

**왜 JIT인가**:
- ❌ 인터프리터: 너무 느림 (fetch-decode-execute 반복)
- ❌ 정적 컴파일: Zig 컴파일 타임 병목
- ✅ 런타임 JIT: 즉시 변환 + 브라우저 최적화

---

## 대상 CPU: Motorola 68020 (완전 구현)

**목표**: 68020 명령어 세트 100% 구현

### 구현할 모든 명령어 그룹

#### 데이터 이동 (18개)
- MOVE, MOVEA, MOVEQ, MOVEM, MOVEP
- LEA, PEA
- EXG, SWAP
- EXT, EXTB (68020)
- LINK, UNLK

#### 산술 연산 (25개)
- ADD, ADDA, ADDI, ADDQ, ADDX
- SUB, SUBA, SUBI, SUBQ, SUBX
- MULS, MULU (16/32비트)
- DIVS, DIVU, DIVSL, DIVUL (68020)
- NEG, NEGX
- CLR
- CMP, CMPA, CMPI, CMPM
- TST

#### 논리 연산 (8개)
- AND, ANDI
- OR, ORI
- EOR, EORI
- NOT

#### 시프트/로테이트 (8개)
- ASL, ASR
- LSL, LSR
- ROL, ROR
- ROXL, ROXR

#### 비트 조작 (13개 - 68020 확장)
- BTST, BSET, BCLR, BCHG
- BFCHG, BFCLR, BFEXTS, BFEXTU (68020)
- BFFFO, BFINS, BFSET, BFTST (68020)
- TAS

#### 조건/분기 (12개)
- BRA, BSR
- Bcc (16가지 조건)
- DBcc
- Scc

#### 점프 (6개)
- JMP, JSR
- RTS, RTR, RTE
- NOP

#### 시스템/제어 (15개)
- TRAP, TRAPV
- CHK, CHK2 (68020)
- CAS, CAS2 (68020)
- CMP2 (68020)
- CALLM, RTM (68020)
- PACK, UNPK (68020)
- STOP, RESET
- ILLEGAL

### 모든 어드레싱 모드 (18가지)

1. **레지스터 직접**
   - Dn (데이터 레지스터)
   - An (주소 레지스터)

2. **레지스터 간접**
   - (An)
   - (An)+
   - -(An)
   - d16(An)
   - d8(An,Xn)
   - (bd,An,Xn) (68020)

3. **메모리**
   - (xxx).W
   - (xxx).L
   - d16(PC)
   - d8(PC,Xn)
   - (bd,PC,Xn) (68020)

4. **즉시값**
   - #<data>

5. **특수**
   - SR, CCR, USP

### 모든 데이터 크기

- Byte (.B) - 8비트
- Word (.W) - 16비트
- Long (.L) - 32비트

### 예외 처리 (모든 벡터)

- Reset
- Bus Error, Address Error
- Illegal Instruction, Privilege Violation
- Trace
- Line A, Line F Emulator
- Interrupt (8 levels)
- TRAP (16 vectors)
- 기타 예외

### 시스템 레지스터

- PC (Program Counter)
- SR (Status Register)
- CCR (Condition Code Register)
- USP (User Stack Pointer)
- SSP (Supervisor Stack Pointer)
- VBR (Vector Base Register - 68020)
- CACR, CAAR (Cache Control - 68020)

---

## 구현 범위 명확화

### ✅ 구현 대상

**68020 CPU 코어 (정수 연산)**:
- 모든 정수 명령어 (100개+)
- 모든 어드레싱 모드 (18가지)
- 모든 예외 처리
- 특권/사용자 모드
- 시스템 레지스터

### ❌ 구현 제외

**FPU (Floating Point Unit)**:
- 68881/68882 코프로세서 명령어 제외
- 부동소수점 연산 제외
- 부동소수점 레지스터 (FP0-FP7) 제외
- F-Line 에뮬레이션은 예외 처리로만

**이유**:
- 68020 CPU 자체는 FPU를 내장하지 않음 (별도 코프로세서)
- 정수 연산만으로도 대부분의 68k 소프트웨어 실행 가능
- 프로젝트 범위 집중 (CPU 완전 구현 우선)

**향후 확장 가능**: FPU는 별도 모듈로 추가 가능

---

## 비교: 기존 에뮬레이터들

| 에뮬레이터 | 사이클 정확도 | 성능 | 방식 |
|-----------|-------------|------|------|
| **UAE** | 중간 | 높음 | 인터프리터 + 최적화 |
| **Musashi** | 낮음 | 매우 높음 | 인터프리터 |
| **Generator** | 중간 | 높음 | JIT (x86) |
| **이 프로젝트** | **높음** | **높음** | **WASM JIT** |

**차별점**:
- 사이클 정확도 + 고성능 **동시 달성**
- WASM 기반 → 플랫폼 독립적
- 브라우저 실행 가능

---

## 설계 원칙

### 1. 완전성 우선 (Completeness First)
- 68020 스펙 100% 구현 - 타협 없음
- 모든 명령어, 모든 EA 모드, 모든 예외
- "거의 완전" 또는 "주요 기능만"은 목표가 아님

### 2. 사이클 정확도 우선 (Cycle Accuracy First)
- 성능을 위해 사이클 정확도를 희생하지 않음
- 모든 최적화는 사이클 정확도 유지 하에 수행

### 3. 명확한 변환 (Clear Translation)
- 68k 명령어 → WASM 1:1 매핑 (가능한 한)
- 복잡한 최적화보다 정확성 우선

### 4. 검증 가능 (Verifiable)
- 각 명령어의 사이클 카운트 문서화
- 테스트 케이스로 검증 가능
- 68020 공식 문서 대조

---

## 성능 목표 상세

### 컴파일 속도
- **목표**: <0.1초/MB
- **현실적**: 0.05초/MB (20MB/초)
- **이유**: 로딩 시간 최소화

### 실행 속도
- **목표**: 네이티브의 80-95%
- **측정**: 벤치마크 프로그램 (Dhrystone 등)
- **이유**: 실시간 에뮬레이션 가능

### 메모리
- **목표**: 2-3배
- **구성**: 
  - 원본 68k 바이너리: 1x
  - WASM 코드: 1-2x
  - 메모리 공간: 16MB (고정)

### 사이클 정확도
- **목표**: 100% (68020 스펙 준수)
- **검증**: 공식 문서 대조
- **허용 오차**: 0 사이클 (정확해야 함)

---

## 우선순위

1. **68020 완전 구현** (최최우선)
2. **사이클 정확도** (최우선)
3. **실행 성능** (중요)
4. **컴파일 속도** (중요)
5. **메모리 효율** (보통)

완전하지 않은 에뮬레이터는 목표 달성이 아님!

---

## 완료 기준

프로젝트는 다음을 모두 만족할 때 완료:

✅ **68020 명령어 세트 100% 구현**
- 모든 명령어 그룹 (100개+ 명령어)
- 모든 어드레싱 모드 (18가지)
- 모든 데이터 크기 (Byte, Word, Long)

✅ **사이클 정확도 100%**
- 68020 공식 스펙 대조
- 모든 명령어의 정확한 사이클
- EA 모드 사이클 포함

✅ **완전한 시스템 구현**
- 모든 예외 처리
- 특권/사용자 모드
- 모든 시스템 레지스터

✅ **성능 목표 달성**
- 네이티브의 80-95%
- 사이클 정확도 유지하면서

✅ **검증 완료**
- 68020 테스트 롬 통과
- 실제 68k 소프트웨어 실행
- 사이클 카운트 검증

**타협 없는 완전 구현이 목표!**

---

**작성일**: 2026-02-12  
**목적**: 프로젝트 목표 명문화
