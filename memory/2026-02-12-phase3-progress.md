# Phase 3.1 진행 상황

## 목표
데이터 이동 명령어 완전 구현 (18개)

## 완료 사항

### 1. EA 모드 확장 ✅
```zig
// 기존 8개 → 17개로 확장
- DataRegDirect, AddrRegDirect
- AddrRegIndirect, Post, Pre, Disp, Index
- AbsShort, AbsLong  // NEW
- PCDisp, PCIndex     // NEW
- Immediate
- MemoryIndirect      // NEW - 68020
- PCMemoryIndirect    // NEW - 68020
- StatusReg, CCR, USP // NEW
```

### 2. Operation enum 확장 ✅
```zig
// 데이터 이동: 13개 추가
MOVEM, MOVEP, EXG, SWAP, EXT, EXTB

// 산술: 11개 추가  
ADDX, SUBX, DIVSL, DIVUL, NEGX, CMPA, CMPM

// 논리: 변경 없음

// 시프트: 2개 추가
ROXL, ROXR

// 비트: 9개 추가
BFCHG, BFCLR, BFEXTS, BFEXTU, BFFFO, BFINS, BFSET, BFTST, TAS

// 제어: 2개 추가
Scc, RTR, RTE

// 시스템: 11개 추가
TRAP, TRAPV, CHK, CHK2, CAS, CAS2, CMP2, CALLM, RTM, PACK, UNPK, STOP, RESET

총: 49개 명령어 추가!
```

### 3. Instruction 구조체 확장 ✅
```zig
struct Instruction {
    // 기존 필드
    dst_imm: ?i32,      // NEW - dual operand
    reg_mask: u16,      // NEW - MOVEM용
    bf_offset: u5,      // NEW - 비트 필드
    bf_width: u5,       // NEW - 비트 필드
}
```

### 4. Decoder 확장 시작 ✅
```zig
decodeGroup4() 확장:
  - LEA ✅
  - PEA ✅  
  - SWAP ✅
  - EXT ✅
  - EXG ✅
  - RTS ✅ (기존)
```

## 다음 작업

### Decoder 완성
- [ ] decodeMOVE() - 모든 EA 모드
- [ ] decodeMOVEM() - 레지스터 마스크
- [ ] decodeMOVEP() - 주변장치
- [ ] 나머지 Group4 명령어들

### Translator 구현
- [ ] translateEXG()
- [ ] translateSWAP()
- [ ] translateEXT()
- [ ] translateMOVEM()
- [ ] EA 모드 핸들러 확장

### Cycles 업데이트
- [ ] 새 명령어 사이클 데이터

---

**진행**: Decoder 기초 확장 완료
**다음**: 모든 decoder 함수 업데이트
