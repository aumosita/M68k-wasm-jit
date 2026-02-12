# 68k → WASM JIT 컴파일러 기술 명세서

**버전**: 1.0  
**작성일**: 2026-02-12  
**작성자**: 김서방  

---

## 1. 프로젝트 개요

### 1.1 목적
Motorola 68000/68020 바이너리를 런타임에 WebAssembly로 JIT 변환하여 즉시 실행

### 1.2 배경
- **문제**: Zig 컴파일 타임 병목 (68k → 네이티브 컴파일 느림)
- **해결**: 68k → WASM 런타임 변환 (컴파일 시간 제거)

### 1.3 핵심 아이디어
```
기존: 68k 소스 → Zig 컴파일 (느림) → 네이티브
신규: 68k 바이너리 → JIT 변환 (즉시) → WASM → 브라우저 JIT → 네이티브
```

---

## 2. 아키텍처

### 2.1 전체 구조
```
┌─────────────────────────────────────────────────┐
│  68k Binary (ROM/Executable)                    │
│  예: Atari ST, Amiga, Macintosh 프로그램         │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  JIT Compiler (Zig/JavaScript)                  │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ 68k Decoder  │→│ WASM Builder │            │
│  │ (Zig)        │  │ (Zig)        │            │
│  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  WASM Module (동적 생성)                         │
│  - Linear memory (68k 메모리)                   │
│  - Local variables (D0-D7, A0-A7, SR)          │
│  - Functions (변환된 68k 코드)                  │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│  Browser WASM Engine (V8/SpiderMonkey)          │
│  - WASM → Native JIT compilation               │
│  - Execution                                    │
└─────────────────────────────────────────────────┘
```

### 2.2 컴포넌트

#### 2.2.1 68k Decoder (Zig)
- **입력**: 68k 바이너리 (opcode stream)
- **출력**: 명령어 구조체
- **기능**:
  - Opcode 파싱
  - EA 모드 디코딩
  - 명령어 크기 계산

#### 2.2.2 WASM Builder (Zig)
- **입력**: 명령어 구조체
- **출력**: WASM bytecode
- **기능**:
  - WASM 모듈 생성
  - 함수 코드 생성
  - 레지스터 매핑
  - 메모리 설정

#### 2.2.3 JIT Compiler (JavaScript)
- **입력**: 68k 바이너리
- **출력**: 실행 가능한 WASM 모듈
- **기능**:
  - 전체 변환 오케스트레이션
  - 브라우저 인터페이스
  - 디버깅 지원

---

## 3. 68k → WASM 변환 규칙

### 3.1 레지스터 매핑

#### 68k 레지스터
```
D0-D7: Data registers (32-bit)
A0-A7: Address registers (32-bit)
PC:    Program counter (32-bit)
SR:    Status register (16-bit)
```

#### WASM 매핑
```wasm
(local $d0 i32)  ;; D0
(local $d1 i32)  ;; D1
...
(local $d7 i32)  ;; D7

(local $a0 i32)  ;; A0
(local $a1 i32)  ;; A1
...
(local $a7 i32)  ;; A7 (Stack Pointer)

(local $pc i32)  ;; Program Counter
(local $sr i32)  ;; Status Register

;; Flags (SR bits를 개별 변수로)
(local $flag_c i32)  ;; Carry
(local $flag_v i32)  ;; Overflow
(local $flag_z i32)  ;; Zero
(local $flag_n i32)  ;; Negative
(local $flag_x i32)  ;; Extend
```

### 3.2 메모리

#### Linear Memory
```wasm
(memory 256)  ;; 256 pages = 16MB (68020 최대 주소 공간)
```

#### 접근
```wasm
;; Read long
(i32.load (local.get $addr))

;; Write long
(i32.store (local.get $addr) (local.get $value))

;; Read word (sign-extend)
(i32.load16_s (local.get $addr))

;; Read byte
(i32.load8_u (local.get $addr))
```

### 3.3 명령어 변환 규칙

#### 3.3.1 데이터 이동

##### MOVEQ #imm8, Dn
```
68k:  MOVEQ #42, D0
Hex:  0x7042

WASM:
(local.set $d0 (i32.const 42))
(local.set $flag_n (i32.const 0))
(local.set $flag_z (i32.eqz (local.get $d0)))
(local.set $flag_v (i32.const 0))
(local.set $flag_c (i32.const 0))
```

##### MOVE.L Dn, Dm
```
68k:  MOVE.L D0, D1
Hex:  0x2200

WASM:
(local.set $d1 (local.get $d0))
(local.set $flag_n (i32.lt_s (local.get $d1) (i32.const 0)))
(local.set $flag_z (i32.eqz (local.get $d1)))
(local.set $flag_v (i32.const 0))
(local.set $flag_c (i32.const 0))
```

##### MOVE.L (An), Dm
```
68k:  MOVE.L (A0), D0
Hex:  0x2010

WASM:
(local.set $d0 (i32.load (local.get $a0)))
(local.set $flag_n (i32.lt_s (local.get $d0) (i32.const 0)))
(local.set $flag_z (i32.eqz (local.get $d0)))
(local.set $flag_v (i32.const 0))
(local.set $flag_c (i32.const 0))
```

#### 3.3.2 산술 연산

##### ADD.L Dn, Dm
```
68k:  ADD.L D1, D0
Hex:  0xD081

WASM:
(local.set $d0 (i32.add (local.get $d0) (local.get $d1)))
;; Flags 계산
(local.set $flag_c (i32.gt_u 
  (i32.add (local.get $d0) (local.get $d1))
  (i32.const 0xFFFFFFFF)))
(local.set $flag_n (i32.lt_s (local.get $d0) (i32.const 0)))
(local.set $flag_z (i32.eqz (local.get $d0)))
;; V flag: overflow 검출 (부호가 같은데 결과가 다를 때)
```

##### SUB.L Dn, Dm
```
68k:  SUB.L D1, D0
Hex:  0x9081

WASM:
(local.set $d0 (i32.sub (local.get $d0) (local.get $d1)))
;; Flags 계산 (ADD와 유사)
```

##### MULS.W Dn, Dm
```
68k:  MULS.W D1, D0
Hex:  0xC1C1

WASM:
(local.set $d0 
  (i32.mul 
    (i32.extend16_s (local.get $d0))  ;; Sign-extend word
    (i32.extend16_s (local.get $d1))))
```

#### 3.3.3 논리 연산

##### AND.L Dn, Dm
```
68k:  AND.L D1, D0

WASM:
(local.set $d0 (i32.and (local.get $d0) (local.get $d1)))
(local.set $flag_n (i32.lt_s (local.get $d0) (i32.const 0)))
(local.set $flag_z (i32.eqz (local.get $d0)))
(local.set $flag_v (i32.const 0))
(local.set $flag_c (i32.const 0))
```

##### OR.L Dn, Dm
```
WASM:
(local.set $d0 (i32.or (local.get $d0) (local.get $d1)))
;; Flags...
```

##### EOR.L Dn, Dm
```
WASM:
(local.set $d0 (i32.xor (local.get $d0) (local.get $d1)))
;; Flags...
```

##### NOT.L Dn
```
WASM:
(local.set $d0 (i32.xor (local.get $d0) (i32.const 0xFFFFFFFF)))
;; Flags...
```

#### 3.3.4 제어 흐름

##### JMP (An)
```
68k:  JMP (A0)

WASM:
;; PC 업데이트 후 함수 종료, 다음 블록으로 점프
(local.set $pc (local.get $a0))
(br $exit)
```

##### JSR (An)
```
68k:  JSR (A0)

WASM:
;; Push return address
(local.set $a7 (i32.sub (local.get $a7) (i32.const 4)))
(i32.store (local.get $a7) (local.get $pc))

;; Jump
(local.set $pc (local.get $a0))
(br $exit)
```

##### RTS
```
68k:  RTS

WASM:
;; Pop return address
(local.set $pc (i32.load (local.get $a7)))
(local.set $a7 (i32.add (local.get $a7) (i32.const 4)))
(br $exit)
```

##### BRA label
```
68k:  BRA +10

WASM:
(local.set $pc (i32.add (local.get $pc) (i32.const 10)))
(br $exit)
```

##### BEQ label (Branch if Equal)
```
68k:  BEQ +10

WASM:
(if (local.get $flag_z)
  (then
    (local.set $pc (i32.add (local.get $pc) (i32.const 10)))
    (br $exit)))
```

##### Bcc (16개 조건)
```
BEQ: Z
BNE: !Z
BGT: !Z && !(N^V)
BLE: Z || (N^V)
BGE: !(N^V)
BLT: N^V
BHI: !C && !Z
BLS: C || Z
BCC: !C
BCS: C
BPL: !N
BMI: N
BVC: !V
BVS: V
```

---

## 4. WASM 모듈 구조

### 4.1 모듈 레이아웃
```wasm
(module
  ;; Memory (16MB)
  (memory (export "memory") 256)
  
  ;; Main function
  (func $main (export "main") (result i32)
    ;; Local variables (registers)
    (local $d0 i32) (local $d1 i32) ... (local $d7 i32)
    (local $a0 i32) (local $a1 i32) ... (local $a7 i32)
    (local $pc i32) (local $sr i32)
    (local $flag_c i32) (local $flag_v i32) 
    (local $flag_z i32) (local $flag_n i32) (local $flag_x i32)
    
    ;; Initialize
    (local.set $a7 (i32.const 0x10000))  ;; Stack pointer
    (local.set $pc (i32.const 0x1000))    ;; Start address
    
    ;; Translated 68k code
    (block $exit
      (loop $main_loop
        ;; Instruction 1
        ;; Instruction 2
        ;; ...
        
        ;; PC increment
        (local.set $pc (i32.add (local.get $pc) (i32.const 2)))
        
        ;; Continue loop
        (br $main_loop)
      )
    )
    
    ;; Return exit code
    (local.get $d0)
  )
)
```

### 4.2 Basic Block 구조
```wasm
;; 기본 블록 단위로 변환
(block $block_0x1000
  ;; Instructions @ 0x1000
  ;; ...
  (br $block_0x1010)  ;; Jump to next block
)

(block $block_0x1010
  ;; Instructions @ 0x1010
  ;; ...
)
```

---

## 5. API 명세

### 5.1 Zig API (WASM 컴파일러)

```zig
/// WASM 모듈 빌더
pub const ModuleBuilder = struct {
    pub fn init(allocator: Allocator) ModuleBuilder;
    pub fn writeHeader(self: *ModuleBuilder) !void;
    pub fn addFunction(self: *ModuleBuilder, func: Function) !void;
    pub fn build(self: *ModuleBuilder) ![]u8;
};

/// 함수 빌더
pub const FunctionBuilder = struct {
    pub fn init(allocator: Allocator) FunctionBuilder;
    pub fn addLocal(self: *FunctionBuilder, type: ValType) !u32;
    pub fn emitI32Const(self: *FunctionBuilder, value: i32) !void;
    pub fn emitLocalGet(self: *FunctionBuilder, index: u32) !void;
    pub fn emitLocalSet(self: *FunctionBuilder, index: u32) !void;
    pub fn emit(self: *FunctionBuilder, opcode: Opcode) !void;
    pub fn finalize(self: *FunctionBuilder) ![]u8;
};

/// 68k → WASM Translator
pub const Translator = struct {
    pub fn translate68kToWasm(m68k_binary: []const u8) ![]u8;
    pub fn translateInstruction(opcode: u16) ![]const Opcode;
};
```

### 5.2 JavaScript API

```javascript
class M68kJIT {
    /**
     * JIT 컴파일러 초기화
     */
    constructor();
    
    /**
     * 68k 바이너리를 WASM으로 컴파일
     * @param {Uint8Array} binary - 68k 바이너리
     * @param {number} startAddr - 시작 주소 (기본: 0x1000)
     * @returns {WebAssembly.Module} WASM 모듈
     */
    async compile(binary, startAddr = 0x1000);
    
    /**
     * 컴파일된 모듈 실행
     * @param {WebAssembly.Module} module
     * @returns {number} 종료 코드 (D0 값)
     */
    async run(module);
    
    /**
     * 레지스터 상태 조회
     * @returns {Object} { d0-d7, a0-a7, pc, sr, flags }
     */
    getRegisters();
    
    /**
     * 메모리 읽기
     * @param {number} addr
     * @param {number} size - 1/2/4 bytes
     * @returns {number}
     */
    readMemory(addr, size);
}
```

### 5.3 사용 예제

```javascript
// JIT 컴파일러 생성
const jit = new M68kJIT();

// 68k 프로그램
const program = new Uint8Array([
    0x70, 0x42,  // MOVEQ #42, D0
    0x72, 0x14,  // MOVEQ #20, D1
    0xD0, 0x81,  // ADD.L D1, D0
    0x4E, 0x75   // RTS
]);

// 컴파일
const module = await jit.compile(program);

// 실행
const exitCode = await jit.run(module);

console.log('Exit code:', exitCode);  // 62 (42 + 20)
console.log('D0:', jit.getRegisters().d0);  // 62
```

---

## 6. 성능 목표

### 6.1 컴파일 속도
- **목표**: < 0.1초 / 1MB 68k 바이너리
- **방법**: 단순 1:N 매핑 (최적화 최소화)

### 6.2 실행 속도
- **목표**: 네이티브의 80-95%
- **WASM JIT**: V8/SpiderMonkey 최적화 활용
- **비교 대상**: 네이티브 Zig 컴파일 결과

### 6.3 메모리
- **목표**: 원본 68k 바이너리의 2-3배
- **WASM 코드**: 68k의 약 2배 크기 예상

---

## 7. 제약사항

### 7.1 지원하지 않는 기능
- **예외 처리**: TRAP, exception vector (Phase 1)
- **특권 명령어**: RESET, STOP, RTE (Phase 1)
- **MMU**: 페이징, 보호 (전체 기간)
- **FPU**: 부동소수점 연산 (선택)

### 7.2 지원 범위
- **68000 기본 명령어**: 100%
- **68020 확장**: 일부 (32-bit 연산, bit field 제외)
- **EA 모드**: 기본 8가지

---

## 8. 개발 일정

### Phase 1: 기초 (1주)
- WASM Builder ✅
- 68k Decoder
- MOVEQ 변환

### Phase 2: 핵심 명령어 (1주)
- MOVE, MOVEA
- ADD, SUB, AND, OR

### Phase 3: 제어 흐름 (1주)
- JMP, JSR, RTS
- Bcc, DBcc

**총 3주** (집중 작업 시)

---

## 9. 참고 자료

### 9.1 68k 명령어
- M68000 Family Programmer's Reference Manual
- 68020 User's Manual

### 9.2 WASM
- WebAssembly Specification
- WASM Binary Format
- MDN WebAssembly Documentation

### 9.3 유사 프로젝트
- Emscripten (C/C++ → WASM)
- wasm-micro-runtime
- QEMU user-mode (다른 아키텍처이지만 참고)

---

**문서 버전**: 1.0  
**최종 수정**: 2026-02-12  
**작성자**: 김서방  
**승인**: 대감
