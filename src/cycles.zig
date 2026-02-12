// Cycle Counter - 68020 사이클 정확도 추적
//
// 각 명령어의 정확한 실행 시간 (사이클 단위) 계산

const std = @import("std");
const Decoder = @import("decoder.zig");
const Operation = Decoder.Operation;
const EAMode = Decoder.EAMode;
const Size = Decoder.Size;

/// 사이클 카운터
pub const CycleCounter = struct {
    total_cycles: u64,
    
    pub fn init() CycleCounter {
        return .{ .total_cycles = 0 };
    }
    
    /// 사이클 추가
    pub fn add(self: *CycleCounter, cycles: u32) void {
        self.total_cycles += cycles;
    }
    
    /// 현재 사이클 수 반환
    pub fn get(self: *CycleCounter) u64 {
        return self.total_cycles;
    }
    
    /// 리셋
    pub fn reset(self: *CycleCounter) void {
        self.total_cycles = 0;
    }
};

/// 68020 명령어 사이클 데이터
pub const CycleData = struct {
    /// 명령어의 기본 사이클 수 계산
    pub fn getInstructionCycles(op: Operation, size: Size, src_mode: EAMode, dst_mode: EAMode) u32 {
        return switch (op) {
            // Data Movement
            .MOVEQ => 4,  // MOVEQ: 4(1/0) cycles
            .MOVE => getMoveCycles(size, src_mode, dst_mode),
            .MOVEA => getMoveCycles(size, src_mode, .AddrRegDirect),
            .LEA => getLeaCycles(src_mode),
            .PEA => getPeaCycles(src_mode),
            
            // Arithmetic
            .ADD, .SUB => getArithmeticCycles(size, src_mode, dst_mode),
            .ADDA, .SUBA => getAddaCycles(size, src_mode),
            .ADDI, .SUBI => getImmediateCycles(size, dst_mode),
            .ADDQ, .SUBQ => getQuickCycles(size, dst_mode),
            .MULS => 44,  // MULS.W: 44(1/0) worst case
            .MULU => 44,  // MULU.W: 44(1/0) worst case
            .DIVS => 158, // DIVS.W: 158(1/0) worst case
            .DIVU => 142, // DIVU.W: 142(1/0) worst case
            .NEG => getNegCycles(size, dst_mode),
            .CLR => getClearCycles(size, dst_mode),
            
            // Logical
            .AND, .OR, .EOR => getLogicCycles(size, src_mode, dst_mode),
            .ANDI, .ORI, .EORI => getImmediateCycles(size, dst_mode),
            .NOT => getNotCycles(size, dst_mode),
            
            // Shift/Rotate
            .ASL, .ASR, .LSL, .LSR => getShiftCycles(size, dst_mode),
            .ROL, .ROR => getRotateCycles(size, dst_mode),
            
            // Bit Manipulation
            .BTST => getBtstCycles(src_mode, dst_mode),
            .BSET, .BCLR, .BCHG => getBitOpCycles(dst_mode),
            
            // Compare
            .CMP => getCmpCycles(size, src_mode),
            .CMPI => getImmediateCycles(size, dst_mode),
            .TST => getTstCycles(size, dst_mode),
            
            // Branch
            .BRA => 10,   // BRA.B: 10(2/0), BRA.W: 10(2/0)
            .BSR => 18,   // BSR.B: 18(2/2), BSR.W: 18(2/2)
            .Bcc => 10,   // Bcc.B taken: 10(2/0), not taken: 8(2/0)
            .DBcc => 12,  // DBcc not expired: 12(2/0), expired: 14(3/0)
            
            // Jump
            .JMP => getJmpCycles(src_mode),
            .JSR => getJsrCycles(src_mode),
            .RTS => 16,   // RTS: 16(4/0)
            
            // System
            .LINK => 16,  // LINK: 16(2/2)
            .UNLK => 12,  // UNLK: 12(3/0)
            .NOP => 4,    // NOP: 4(1/0)
            
            .ILLEGAL => 4,
            else => 4,    // Default fallback
        };
    }
    
    /// EA(Effective Address) 모드의 추가 사이클
    pub fn getEACycles(mode: EAMode, size: Size) u32 {
        _ = size;
        return switch (mode) {
            .DataRegDirect => 0,
            .AddrRegDirect => 0,
            .AddrRegIndirect => 4,      // (An): 4 cycles
            .AddrRegIndirectPost => 4,  // (An)+: 4 cycles
            .AddrRegIndirectPre => 6,   // -(An): 6 cycles
            .AddrRegDisp => 8,          // d16(An): 8 cycles
            .AddrRegIndex => 10,        // d8(An,Xn): 10 cycles
            .Immediate => 4,            // #<data>: 4 cycles
        };
    }
    
    // === Private helpers ===
    
    fn getMoveCycles(size: Size, src_mode: EAMode, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 4,
        };
        const src_ea = getEACycles(src_mode, size);
        const dst_ea = getEACycles(dst_mode, size);
        return base + src_ea + dst_ea;
    }
    
    fn getLeaCycles(mode: EAMode) u32 {
        return switch (mode) {
            .AddrRegIndirect => 4,
            .AddrRegDisp => 8,
            .AddrRegIndex => 12,
            else => 4,
        };
    }
    
    fn getPeaCycles(mode: EAMode) u32 {
        return switch (mode) {
            .AddrRegIndirect => 12,
            .AddrRegDisp => 16,
            .AddrRegIndex => 20,
            else => 12,
        };
    }
    
    fn getArithmeticCycles(size: Size, src_mode: EAMode, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 6,
        };
        if (dst_mode == .DataRegDirect) {
            return base + getEACycles(src_mode, size);
        } else {
            return base + getEACycles(dst_mode, size) + 4;
        }
    }
    
    fn getAddaCycles(size: Size, src_mode: EAMode) u32 {
        const base: u32 = if (size == .Long) 6 else 8;
        return base + getEACycles(src_mode, size);
    }
    
    fn getImmediateCycles(size: Size, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 8,
            .Long => 16,
        };
        return base + getEACycles(dst_mode, size);
    }
    
    fn getQuickCycles(size: Size, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 8,
        };
        if (dst_mode == .DataRegDirect or dst_mode == .AddrRegDirect) {
            return base;
        } else {
            return base + getEACycles(dst_mode, size) + 4;
        }
    }
    
    fn getNegCycles(size: Size, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 6,
        };
        if (dst_mode == .DataRegDirect) {
            return base;
        } else {
            return base + getEACycles(dst_mode, size) + 4;
        }
    }
    
    fn getClearCycles(size: Size, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 6,
        };
        if (dst_mode == .DataRegDirect) {
            return base;
        } else {
            return base + getEACycles(dst_mode, size);
        }
    }
    
    fn getLogicCycles(size: Size, src_mode: EAMode, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 6,
        };
        if (dst_mode == .DataRegDirect) {
            return base + getEACycles(src_mode, size);
        } else {
            return base + getEACycles(dst_mode, size) + 4;
        }
    }
    
    fn getNotCycles(size: Size, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 6,
        };
        if (dst_mode == .DataRegDirect) {
            return base;
        } else {
            return base + getEACycles(dst_mode, size) + 4;
        }
    }
    
    fn getShiftCycles(size: Size, dst_mode: EAMode) u32 {
        _ = size;
        if (dst_mode == .DataRegDirect) {
            return 6; // + 2 per shift count
        } else {
            return 8;
        }
    }
    
    fn getRotateCycles(size: Size, dst_mode: EAMode) u32 {
        _ = size;
        if (dst_mode == .DataRegDirect) {
            return 6; // + 2 per rotate count
        } else {
            return 8;
        }
    }
    
    fn getBtstCycles(src_mode: EAMode, dst_mode: EAMode) u32 {
        _ = src_mode;
        if (dst_mode == .DataRegDirect) {
            return 6;
        } else {
            return 4 + getEACycles(dst_mode, .Byte);
        }
    }
    
    fn getBitOpCycles(dst_mode: EAMode) u32 {
        if (dst_mode == .DataRegDirect) {
            return 8;
        } else {
            return 8 + getEACycles(dst_mode, .Byte);
        }
    }
    
    fn getCmpCycles(size: Size, src_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 6,
        };
        return base + getEACycles(src_mode, size);
    }
    
    fn getTstCycles(size: Size, dst_mode: EAMode) u32 {
        const base: u32 = switch (size) {
            .Byte, .Word => 4,
            .Long => 4,
        };
        return base + getEACycles(dst_mode, size);
    }
    
    fn getJmpCycles(mode: EAMode) u32 {
        return switch (mode) {
            .AddrRegIndirect => 8,
            .AddrRegDisp => 10,
            .AddrRegIndex => 14,
            else => 8,
        };
    }
    
    fn getJsrCycles(mode: EAMode) u32 {
        return switch (mode) {
            .AddrRegIndirect => 16,
            .AddrRegDisp => 18,
            .AddrRegIndex => 22,
            else => 16,
        };
    }
};

test "cycle counts" {
    const cycles = CycleData.getInstructionCycles(.MOVEQ, .Long, .Immediate, .DataRegDirect);
    try std.testing.expectEqual(@as(u32, 4), cycles);
    
    const move_cycles = CycleData.getInstructionCycles(.MOVE, .Long, .DataRegDirect, .DataRegDirect);
    try std.testing.expectEqual(@as(u32, 4), move_cycles);
}
