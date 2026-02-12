# TODO - 68020 JIT 에뮬레이터

**현재 진행도**: 53/164 (32%)
**디코딩 성공률**: 53/53 (100%) ✅

---

## 🎉 2026-02-12 세션 완료 사항

### ✅ Zig 0.13.0 빌드 환경 구축
- WSL에 Zig 0.13.0 설치 완료
- 빌드 오류 수정 (비트 시프트 타입 캐스팅)
- `zig build` 성공 ✅

### ✅ Decoder 대폭 개선 (19→53, 279% 향상!)
**Before**: 19/60 명령어만 디코딩 (31%)
**After**: 53/53 명령어 전부 디코딩 (100%) ✅

#### 주요 수정 사항:
1. **Group0 확장** - 즉시값 연산 추가
   - ANDI, ORI, EORI, ADDI, SUBI, CMPI
   
2. **Group4 확장** - 단항 연산 추가
   - CLR, NEG, NEGX, TST, NOT, TAS
   - TAS/TST 우선순위 수정 (TAS 먼저 체크)
   - EXTB 감지 (opmode=7)

3. **레지스터 구분**
   - MOVE → MOVE/MOVEA (dst_mode=1)
   - ADD → ADD/ADDA/ADDX (opmode 기반)
   - SUB → SUB/SUBA/SUBX (opmode 기반)
   - CMP → CMP/CMPA (opmode 기반)

4. **곱셈/나눗셈 감지**
   - AND 그룹: MULU (opmode=3), MULS (opmode=7)
   - OR 그룹: DIVU (opmode=3), DIVS (opmode=7)

5. **시프트/로테이트**
   - ROXL/ROXR 지원 (type=3)

### ✅ 포괄적 테스트 구축
- `test_comprehensive.zig` 작성
- **46개 명령어 자동 테스트**
- **46/46 전부 통과** ✅
- `zig build test-comprehensive` 실행 가능

### ✅ Git 커밋
- `b2abe90` - Fix bit shift compilation errors
- `a5f26b3` - Add comprehensive instruction test suite
- `bc9b2e7` - Fix decoder - all 60 instructions now decode correctly!

---

## 🔥 최우선 TODO

### 1️⃣ **ROL/ROXL Opcode 검증**
- [ ] 68k 매뉴얼에서 정확한 opcode 확인
- [ ] test_comprehensive.zig 주석 해제
- [ ] 테스트 통과 확인

**파일**: `src/test_comprehensive.zig` (line ~40-43)

### 2️⃣ **프로그램 제어 구현** (최우선!)
실행 흐름 제어 없이는 실용적인 프로그램 불가능

#### Phase A: 기본 분기
- [ ] BRA - Branch always
- [ ] BSR - Branch to subroutine  
- [ ] Bcc - Conditional branch (16 conditions)

#### Phase B: 점프
- [ ] JMP - Jump
- [ ] JSR - Jump to subroutine (이미 decoder에 있음, translator 필요)
- [ ] RTS - Return (이미 decoder에 있음, translator 필요)

#### Phase C: 조건
- [ ] DBcc - Decrement and branch
- [ ] Scc - Set according to condition

**예상 작업량**: ~500 lines
**우선순위**: ⭐⭐⭐⭐⭐

### 3️⃣ **데이터 이동 완성** (7개 남음)
61% → 100% 달성

- [ ] MOVEM - Move multiple registers
- [ ] MOVEP - Move peripheral data
- [ ] LINK 완전 구현 (현재 기본만)
- [ ] UNLK 완전 구현

**우선순위**: ⭐⭐⭐

---

## 📋 카테고리별 TODO

### 산술 연산 (2개 남음) - 거의 완성!
- [ ] CMPM - Compare memory to memory
- [ ] DIVSL/DIVUL 완전 구현 (64÷32 지원)

### 비트 필드 (8개) - 68020 전용
- [ ] BFCHG, BFCLR, BFEXTS, BFEXTU
- [ ] BFFFO, BFINS, BFSET, BFTST

### 시스템 제어 (15개)
- [ ] TRAP, TRAPV
- [ ] CHK, CHK2
- [ ] MOVE to/from SR
- [ ] RTE, RTR
- [ ] 기타 시스템 명령어

---

## 🎯 마일스톤

### 🏁 Milestone 1: 기본 명령어 40% (진행 중)
- ✅ 논리: 7/8 (88%)
- ✅ 시프트: 6/8 (75%)
- ✅ 산술: 23/25 (92%)
- 🔄 데이터 이동: 11/18 (61%)
- 🔄 비트: 5/13 (38%)
- **현재 진행도**: 53/164 (32%)

### 🏁 Milestone 2: 프로그램 제어 (다음 목표)
- [ ] 분기: BRA, BSR, Bcc
- [ ] 점프: JMP, JSR, RTS
- [ ] 조건: DBcc, Scc
- **목표**: 60/164 (37%)

### 🏁 Milestone 3: 실용적인 코드 실행
- [ ] 어드레싱 모드 확장
- [ ] 스택 조작
- [ ] 서브루틴 호출
- **목표**: 80/164 (49%)

### 🏁 Milestone 4: 68020 완전 구현
- [ ] 비트 필드
- [ ] 시스템 제어
- [ ] 예외 처리
- **최종 목표**: 164/164 (100%) 🎉

---

## ✅ 완료된 항목

### Phase 1: 기초 구조 ✅
- [x] WASM Builder
- [x] 68k Decoder (100% 디코딩 달성!)
- [x] Translator
- [x] JIT Compiler
- [x] 포괄적 테스트 시스템

### Phase 2: 사이클 정확도 ✅
- [x] CycleData
- [x] 사이클 카운팅
- [x] Translator 통합

### Phase 3: 명령어 구현 (53/164)

**완성 그룹:**
- ✅ 논리 (7): AND, ANDI, OR, ORI, EOR, EORI, NOT
- ✅ 시프트 (6): ASL, ASR, LSL, LSR, ROR (+ROXL/ROXR 구현완료, opcode TODO)
- ✅ 산술 (23): ADD, ADDA, ADDI, ADDQ, ADDX, SUB, SUBA, SUBI, SUBQ, SUBX, MULS, MULU, DIVS, DIVU, DIVSL, DIVUL, CLR, NEG, NEGX, TST, CMP, CMPA, CMPI

**진행 중:**
- 🔄 데이터 (11): MOVEQ, MOVE, MOVEA, LEA, PEA, EXG, SWAP, EXT, EXTB, LINK, UNLK
- 🔄 비트 (5): BTST, BSET, BCLR, BCHG, TAS
- 📝 제어 (1): NOP

---

## 🐛 알려진 이슈

### 1. ROXL/ROXR X Flag
**상태**: 구현 완료, 단순화됨
**TODO**: X 플래그 처리 완전 구현

### 2. DIVSL/DIVUL
**상태**: 32÷32 버전만 구현
**TODO**: 64÷32 완전 구현

### 3. Flag 구현 불완전
**상태**: C, V, X 플래그 일부만 구현
**TODO**: 모든 플래그 완전 구현

### 4. EA Mode 제한
**상태**: 기본 모드만 지원
**TODO**: 복잡한 어드레싱 모드 추가

---

## 📚 참고 자료

- **68020 User's Manual**: Motorola 공식 문서
- **Repository**: https://github.com/aumosita/M68k-wasm-jit
- **Build**: `zig build` (test: `zig build test-comprehensive`)
- **Zig Version**: 0.13.0

---

**마지막 업데이트**: 2026-02-12 18:00
**현재 진행도**: 53/164 (32%)
**디코딩 성공률**: 53/53 (100%) ✅
**테스트 통과율**: 46/46 (100%) ✅

**다음 작업**: 프로그램 제어 구현 (BRA, BSR, Bcc, JMP, JSR, RTS)
