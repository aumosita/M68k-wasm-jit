# 다음 수순 - Phase 3.2

## 완료 사항 ✅
- Phase 1: 기초 구조
- Phase 2: 사이클 정확도
- Phase 3.1: 구조 확장
- Git 커밋: a4af1a3

---

## 다음 작업: Phase 3.2 - Decoder 완성

### 1. 모든 decoder 함수 업데이트
```zig
// 모든 함수에 새 필드 추가
- decodeMOVE()
- decodeBranch()
- decodeMOVEQ()
- decodeOR()
- decodeSUBADD()
- decodeCMPEOR()
- decodeAND()
- decodeShift()
- makeIllegal()
- makeNOP()

새 필드:
.dst_imm = null,
.reg_mask = 0,
.bf_offset = 0,
.bf_width = 0,
```

### 2. 새 명령어 디코딩 추가
```zig
// 데이터 이동
- MOVEM (레지스터 마스크)
- MOVEP (주변장치)
- LINK, UNLK

// 산술
- ADDX, SUBX (확장)
- NEGX, CMPA, CMPM
- DIVSL, DIVUL (68020)

// 논리
- ANDI, ORI, EORI (즉시값)

// 시프트
- ROXL, ROXR (확장 로테이트)
```

### 3. EA 모드 디코딩 확장
```zig
// 절대 주소
- AbsShort: mode=7, reg=0
- AbsLong: mode=7, reg=1

// PC 상대
- PCDisp: mode=7, reg=2
- PCIndex: mode=7, reg=3
```

---

## Phase 3.3 - Translator 확장

### 1. 새 명령어 변환 구현
```zig
- translateEXG() - 레지스터 교환
- translateSWAP() - 상하위 워드 교환
- translateEXT() - 부호 확장
- translateMOVEM() - 다중 레지스터 이동
- translateADDX() - 확장 덧셈
- translateSUBX() - 확장 뺄셈
```

### 2. EA 모드 핸들러 확장
```zig
loadEA() / storeEA():
- AbsShort, AbsLong
- PCDisp, PCIndex
- 68020 확장 모드
```

---

## Phase 3.4 - Cycles 업데이트

### 1. 새 명령어 사이클
```zig
CycleData.getInstructionCycles():
- EXG: 6 사이클
- SWAP: 4 사이클
- EXT: 4 사이클
- MOVEM: 8 + 4*N
- ADDX/SUBX: 4-8 사이클
```

---

## 우선순위

1. **Decoder 완성** (최우선)
   - 모든 함수 필드 업데이트
   - 컴파일 오류 해결

2. **기본 명령어 구현**
   - EXG, SWAP, EXT 변환
   - 사이클 데이터

3. **EA 모드 확장**
   - AbsShort, AbsLong
   - 메모리 접근

4. **MOVEM 구현**
   - 레지스터 마스크 처리
   - 다중 전송

---

## 목표

### 단기 (오늘/내일)
- Decoder 컴파일 가능 상태
- EXG, SWAP, EXT 완전 구현
- 테스트 프로그램 실행

### 중기 (이번 주)
- 데이터 이동 18개 완성
- 산술 연산 25개 시작
- 체크리스트 10% 달성

### 장기 (10주)
- 68020 전체 164개 항목 완성
- 사이클 정확도 100%
- 성능 목표 달성

---

**다음 세션**: Decoder 완성 작업 시작

**작성일**: 2026-02-12 16:20
