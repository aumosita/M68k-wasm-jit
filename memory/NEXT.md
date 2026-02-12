# 다음 수순 - Phase 3.3

## 완료 사항 ✅
- Phase 1: 기초 구조 ✅
- Phase 2: 사이클 정확도 ✅
- Phase 3.1: 구조 확장 ✅
- Phase 3.2: 새 명령어 구현 ✅
- Git 커밋: 65fd6d5
- **진행도: 17/164 (10%)**

---

## 다음 작업: Phase 3.3 - 데이터 이동 완성

### 목표
데이터 이동 18개 중 11개 추가 → **18/18 (100%)**

### 구현할 명령어

#### 1. MOVEA (최우선)
```zig
MOVEA <ea>, An
- MOVE와 유사하지만 주소 레지스터에 저장
- 플래그 업데이트 안 함
```

#### 2. LINK / UNLK
```zig
LINK An, #<displacement>
- 스택 프레임 생성
- An을 스택에 push
- SP를 An에 복사
- SP += displacement

UNLK An
- 스택 프레임 해제
- An을 SP에 복사
- An을 스택에서 pop
```

#### 3. MOVEM (중요)
```zig
MOVEM <register_list>, <ea>
MOVEM <ea>, <register_list>
- 여러 레지스터를 한번에 이동
- 레지스터 마스크 사용 (16비트)
- 스택 저장/복원에 중요
```

#### 4. MOVEP (선택적)
```zig
MOVEP Dn, d(An)
MOVEP d(An), Dn
- 주변장치 데이터 전송
- 바이트 단위로 홀수 주소에만 접근
```

#### 5. EXTB (68020)
```zig
EXTB Dn
- Byte → Long 부호 확장
- EXT의 68020 확장
```

---

## 다음 단계: Phase 3.4 - 산술 연산

### 1. 즉시값 명령어 (6개)
```zig
ADDI, SUBI - immediate
ADDQ, SUBQ - quick (3-bit immediate)
ADDX, SUBX - extended (with X flag)
```

### 2. 곱셈/나눗셈 (6개)
```zig
MULS, MULU - 16×16 → 32-bit
DIVS, DIVU - 32÷16 → 16-bit
DIVSL, DIVUL - 64÷32 → 32-bit (68020)
```

### 3. 단항 연산 (3개)
```zig
NEG, NEGX - negate
CLR - clear to zero
```

### 4. 비교 (5개)
```zig
CMP, CMPA, CMPI, CMPM
TST
```

---

## 기술 부채

### Decoder 개선
```zig
- [ ] Extension word 읽기 (displacement, index)
- [ ] 레지스터 마스크 파싱 (MOVEM용)
- [ ] 즉시값 데이터 읽기 (word/long)
```

### Translator 개선
```zig
- [ ] EA 모드 완전 구현
  - AddrRegDisp (displacement)
  - AddrRegIndex (index register)
  - AbsShort, AbsLong
  - PCDisp, PCIndex
  
- [ ] 메모리 접근 올바른 구현
  - load8_u, load16_s, load32
  - store8, store16, store32
  
- [ ] 플래그 정확한 계산
  - C flag (carry/borrow)
  - V flag (overflow)
  - X flag (extend)
```

### WASM Builder 개선
```zig
- [ ] 제어 흐름 구조
  - block, loop, br, br_if
  - 실제 분기 구현
```

---

## 우선순위

### 1단계 (이번 주)
1. MOVEA 구현
2. LINK/UNLK 구현
3. 간단한 EA 모드 (displacement)

### 2단계 (다음 주)
1. MOVEM 구현
2. 즉시값 산술 (ADDI, SUBI 등)
3. 비교 명령어

### 3단계 (그 다음 주)
1. 곱셈/나눗셈
2. 시프트/로테이트
3. 비트 조작

---

## 일정

**Week 1** (현재): Phase 1-3.2 완료 ✅
**Week 2**: Phase 3.3-3.4 (데이터 이동 + 산술)
**Week 3-4**: Phase 3.5-3.7 (논리 + 시프트 + 비트)
**Week 5-6**: Phase 3.8 (프로그램 제어)
**Week 7-8**: Phase 3.9 (시스템 제어)
**Week 9-10**: 최적화 + 검증

---

## 목표

### 단기 (다음 세션)
- MOVEA, LINK, UNLK 구현
- 테스트 프로그램 작성

### 중기 (이번 주)
- 데이터 이동 18/18 완성
- 진행도 15% 달성

### 장기 (10주)
- 68020 전체 164/164 완성
- 사이클 정확도 100%
- 성능 목표 달성 (네이티브 80-95%)

---

**현재**: 17/164 (10%)  
**다음 목표**: 28/164 (17%)  
**최종 목표**: 164/164 (100%)

**다음 세션**: MOVEA + LINK/UNLK 구현

**작성일**: 2026-02-12 16:32
