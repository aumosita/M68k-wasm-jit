// 68k Instruction Decoder for JIT
//
// Simplified decoder for JIT compilation
// Focus on common instructions first

const std = @import("std");

/// Addressing modes (68020 전체)
pub const EAMode = enum(u8) {
    // 레지스터 직접
    DataRegDirect = 0,      // Dn
    AddrRegDirect = 1,      // An
    
    // 레지스터 간접
    AddrRegIndirect = 2,    // (An)
    AddrRegIndirectPost = 3,// (An)+
    AddrRegIndirectPre = 4, // -(An)
    AddrRegDisp = 5,        // d16(An)
    AddrRegIndex = 6,       // d8(An,Xn)
    
    // 절대 주소
    AbsShort = 7,           // (xxx).W
    AbsLong = 8,            // (xxx).L
    
    // PC 상대
    PCDisp = 9,             // d16(PC)
    PCIndex = 10,           // d8(PC,Xn)
    
    // 즉시값
    Immediate = 11,         // #<data>
    
    // 68020 확장 모드
    MemoryIndirect = 12,    // (bd,An,Xn)
    PCMemoryIndirect = 13,  // (bd,PC,Xn)
    
    // 특수
    StatusReg = 14,         // SR
    CCR = 15,               // CCR
    USP = 16,               // USP
};

/// Instruction size
pub const Size = enum(u8) {
    Byte = 0,
    Word = 1,
    Long = 2,
    
    pub fn bytes(self: Size) u8 {
        return switch (self) {
            .Byte => 1,
            .Word => 2,
            .Long => 4,
        };
    }
};

/// Instruction operation
pub const Operation = enum {
    // Data movement (18)
    MOVE,
    MOVEA,
    MOVEQ,
    MOVEM,      // NEW
    MOVEP,      // NEW
    LEA,
    PEA,
    EXG,        // NEW
    SWAP,       // NEW
    EXT,        // NEW
    EXTB,       // NEW - 68020
    LINK,
    UNLK,
    
    // Arithmetic (25)
    ADD,
    ADDA,
    ADDI,
    ADDQ,
    ADDX,       // NEW
    SUB,
    SUBA,
    SUBI,
    SUBQ,
    SUBX,       // NEW
    MULS,
    MULU,
    DIVS,
    DIVU,
    DIVSL,      // NEW - 68020
    DIVUL,      // NEW - 68020
    NEG,
    NEGX,       // NEW
    CLR,
    CMP,
    CMPA,       // NEW
    CMPI,
    CMPM,       // NEW
    TST,
    
    // Logical (8)
    AND,
    ANDI,
    OR,
    ORI,
    EOR,
    EORI,
    NOT,
    
    // Shift/Rotate (8)
    ASL,
    ASR,
    LSL,
    LSR,
    ROL,
    ROR,
    ROXL,       // NEW
    ROXR,       // NEW
    
    // Bit manipulation (13)
    BTST,
    BSET,
    BCLR,
    BCHG,
    BFCHG,      // NEW - 68020
    BFCLR,      // NEW - 68020
    BFEXTS,     // NEW - 68020
    BFEXTU,     // NEW - 68020
    BFFFO,      // NEW - 68020
    BFINS,      // NEW - 68020
    BFSET,      // NEW - 68020
    BFTST,      // NEW - 68020
    TAS,        // NEW
    
    // Compare (included above)
    
    // Branch (16)
    BRA,
    BSR,
    Bcc,        // conditional (all 16 conditions)
    DBcc,       // decrement and branch
    Scc,        // NEW - set according to condition
    
    // Jump (5)
    JMP,
    JSR,
    RTS,
    RTR,        // NEW
    RTE,        // NEW
    
    // System (15)
    TRAP,       // NEW
    TRAPV,      // NEW
    CHK,        // NEW
    CHK2,       // NEW - 68020
    CAS,        // NEW - 68020
    CAS2,       // NEW - 68020
    CMP2,       // NEW - 68020
    CALLM,      // NEW - 68020
    RTM,        // NEW - 68020
    PACK,       // NEW - 68020
    UNPK,       // NEW - 68020
    STOP,       // NEW
    RESET,      // NEW
    NOP,
    ILLEGAL,
};

/// Decoded instruction
pub const Instruction = struct {
    op: Operation,
    size: Size,
    
    // Source
    src_mode: EAMode,
    src_reg: u3,
    src_imm: ?i32,      // Immediate value if applicable
    
    // Destination
    dst_mode: EAMode,
    dst_reg: u3,
    dst_imm: ?i32,      // For dual operand instructions
    
    // Branch displacement
    disp: ?i16,
    
    // Condition code (for Bcc, DBcc, Scc)
    condition: u4,
    
    // Register mask (for MOVEM)
    reg_mask: u16,
    
    // Bit field parameters (68020)
    bf_offset: u5,
    bf_width: u5,
    
    // Instruction length
    length: u8,
};

pub const Decoder = struct {
    /// Decode a single 68k instruction
    pub fn decode(opcode: u16) Instruction {
        const primary = (opcode >> 12) & 0xF;
        
        return switch (primary) {
            0x0 => decodeGroup0(opcode),
            0x1, 0x2, 0x3 => decodeMOVE(opcode),
            0x4 => decodeGroup4(opcode),
            0x5 => decodeGroup5(opcode),
            0x6 => decodeBranch(opcode),
            0x7 => decodeMOVEQ(opcode),
            0x8 => decodeOR(opcode),
            0x9, 0xD => decodeSUBADD(opcode),
            0xB => decodeCMPEOR(opcode),
            0xC => decodeAND(opcode),
            0xE => decodeShift(opcode),
            else => makeIllegal(opcode),
        };
    }
    
    fn decodeGroup0(opcode: u16) Instruction {
        const bits_8_11 = (opcode >> 8) & 0xF;
        
        if (bits_8_11 == 0) {
            // Bit operations
            return decodeBitOp(opcode);
        }
        
        if (opcode == 0x4E71) {
            return makeNOP();
        }
        
        return makeIllegal(opcode);
    }
    
    fn decodeBitOp(opcode: u16) Instruction {
        const bit_op = (opcode >> 6) & 0x3;
        const mode = @as(u3, @truncate((opcode >> 3) & 0x7));
        const reg = @as(u3, @truncate(opcode & 0x7));
        
        const op: Operation = switch (bit_op) {
            0 => .BTST,
            1 => .BCHG,
            2 => .BCLR,
            3 => .BSET,
            else => unreachable,
        };
        
        return .{
            .op = op,
            .size = .Byte,
            .src_mode = .Immediate,
            .src_reg = 0,
            .src_imm = null,
            .dst_mode = @enumFromInt(mode),
            .dst_reg = reg,
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 4, // opcode + extension
        };
    }
    
    fn decodeMOVE(opcode: u16) Instruction {
        const size_bits = (opcode >> 12) & 0x3;
        const size: Size = switch (size_bits) {
            1 => .Byte,
            3 => .Word,
            2 => .Long,
            else => .Word,
        };
        
        const dst_reg = @as(u3, @truncate((opcode >> 9) & 0x7));
        const dst_mode = @as(u3, @truncate((opcode >> 6) & 0x7));
        const src_mode = @as(u3, @truncate((opcode >> 3) & 0x7));
        const src_reg = @as(u3, @truncate(opcode & 0x7));
        
        return .{
            .op = .MOVE,
            .size = size,
            .src_mode = @enumFromInt(src_mode),
            .src_reg = src_reg,
            .src_imm = null,
            .dst_mode = @enumFromInt(dst_mode),
            .dst_reg = dst_reg,
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn decodeGroup4(opcode: u16) Instruction {
        // Group 4: Miscellaneous instructions
        
        // NOP: 0100111001110001 (가장 구체적인 패턴 먼저)
        if (opcode == 0x4E71) {
            return makeNOP();
        }
        
        // RTS: 0100111001110101
        if (opcode == 0x4E75) {
            return .{
                .op = .RTS,
                .size = .Word,
                .src_mode = .DataRegDirect,
                .src_reg = 0,
                .src_imm = null,
                .dst_mode = .DataRegDirect,
                .dst_reg = 0,
                .dst_imm = null,
                .disp = null,
                .condition = 0,
                .reg_mask = 0,
                .bf_offset = 0,
                .bf_width = 0,
                .length = 2,
            };
        }
        
        // SWAP: 0100100001000xxx
        if ((opcode & 0xFFF8) == 0x4840) {
            return .{
                .op = .SWAP,
                .size = .Word,
                .src_mode = .DataRegDirect,
                .src_reg = @as(u3, @truncate(opcode & 0x7)),
                .src_imm = null,
                .dst_mode = .DataRegDirect,
                .dst_reg = @as(u3, @truncate(opcode & 0x7)),
                .dst_imm = null,
                .disp = null,
                .condition = 0,
                .reg_mask = 0,
                .bf_offset = 0,
                .bf_width = 0,
                .length = 2,
            };
        }
        
        // PEA: 0100100001xxxxxx
        if ((opcode & 0xFFC0) == 0x4840) {
            return .{
                .op = .PEA,
                .size = .Long,
                .src_mode = @enumFromInt(@as(u3, @truncate((opcode >> 3) & 0x7))),
                .src_reg = @as(u3, @truncate(opcode & 0x7)),
                .src_imm = null,
                .dst_mode = .DataRegDirect,
                .dst_reg = 0,
                .dst_imm = null,
                .disp = null,
                .condition = 0,
                .reg_mask = 0,
                .bf_offset = 0,
                .bf_width = 0,
                .length = 2,
            };
        }
        
        // LEA: 0100xxx111xxxxxx
        if (((opcode >> 6) & 0x3F) == 0x39) {
            return .{
                .op = .LEA,
                .size = .Long,
                .src_mode = @enumFromInt(@as(u3, @truncate((opcode >> 3) & 0x7))),
                .src_reg = @as(u3, @truncate(opcode & 0x7)),
                .src_imm = null,
                .dst_mode = .AddrRegDirect,
                .dst_reg = @as(u3, @truncate((opcode >> 9) & 0x7)),
                .dst_imm = null,
                .disp = null,
                .condition = 0,
                .reg_mask = 0,
                .bf_offset = 0,
                .bf_width = 0,
                .length = 2,
            };
        }
        
        // EXT: 0100100xxx000xxx
        if ((opcode & 0xFEB8) == 0x4880) {
            const op_mode = (opcode >> 6) & 0x7;
            const size: Size = if (op_mode == 2) .Word else .Long;
            
            return .{
                .op = .EXT,
                .size = size,
                .src_mode = .DataRegDirect,
                .src_reg = @as(u3, @truncate(opcode & 0x7)),
                .src_imm = null,
                .dst_mode = .DataRegDirect,
                .dst_reg = @as(u3, @truncate(opcode & 0x7)),
                .dst_imm = null,
                .disp = null,
                .condition = 0,
                .reg_mask = 0,
                .bf_offset = 0,
                .bf_width = 0,
                .length = 2,
            };
        }
        
        // EXG: 01001xxx1xxxx0xxx
        if ((opcode & 0xF130) == 0xC100) {
            return .{
                .op = .EXG,
                .size = .Long,
                .src_mode = .DataRegDirect,
                .src_reg = @as(u3, @truncate((opcode >> 9) & 0x7)),
                .src_imm = null,
                .dst_mode = .DataRegDirect,
                .dst_reg = @as(u3, @truncate(opcode & 0x7)),
                .dst_imm = null,
                .disp = null,
                .condition = 0,
                .reg_mask = 0,
                .bf_offset = 0,
                .bf_width = 0,
                .length = 2,
            };
        }
        
        return makeIllegal(opcode);
    }
    
    fn decodeGroup5(opcode: u16) Instruction {
        // ADDQ, SUBQ, Scc, DBcc
        const bit_8 = (opcode >> 8) & 1;
        
        if (bit_8 == 0) { // ADDQ
            return .{
                .op = .ADDQ,
                .size = getSizeFromBits((opcode >> 6) & 0x3),
                .src_mode = .Immediate,
                .src_reg = 0,
                .src_imm = getQuickData(opcode),
                .dst_mode = @enumFromInt(@as(u3, @truncate((opcode >> 3) & 0x7))),
                .dst_reg = @as(u3, @truncate(opcode & 0x7)),
                .dst_imm = null,
                .disp = null,
                .condition = 0,
                .reg_mask = 0,
                .bf_offset = 0,
                .bf_width = 0,
                .length = 2,
            };
        } else { // SUBQ
            return .{
                .op = .SUBQ,
                .size = getSizeFromBits((opcode >> 6) & 0x3),
                .src_mode = .Immediate,
                .src_reg = 0,
                .src_imm = getQuickData(opcode),
                .dst_mode = @enumFromInt(@as(u3, @truncate((opcode >> 3) & 0x7))),
                .dst_reg = @as(u3, @truncate(opcode & 0x7)),
                .dst_imm = null,
                .disp = null,
                .condition = 0,
                .reg_mask = 0,
                .bf_offset = 0,
                .bf_width = 0,
                .length = 2,
            };
        }
    }
    
    fn decodeBranch(opcode: u16) Instruction {
        const condition = @as(u4, @truncate((opcode >> 8) & 0xF));
        const disp8 = @as(i8, @bitCast(@as(u8, @truncate(opcode & 0xFF))));
        
        return .{
            .op = if (condition == 0) .BRA else .Bcc,
            .size = .Byte,
            .src_mode = .DataRegDirect,
            .src_reg = 0,
            .src_imm = null,
            .dst_mode = .DataRegDirect,
            .dst_reg = 0,
            .dst_imm = null,
            .disp = if (disp8 == 0) 0 else @as(i16, disp8),
            .condition = condition,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn decodeMOVEQ(opcode: u16) Instruction {
        const data = @as(i8, @bitCast(@as(u8, @truncate(opcode & 0xFF))));
        const dst_reg = @as(u3, @truncate((opcode >> 9) & 0x7));
        
        return .{
            .op = .MOVEQ,
            .size = .Long,
            .src_mode = .Immediate,
            .src_reg = 0,
            .src_imm = @as(i32, data), // Sign-extended
            .dst_mode = .DataRegDirect,
            .dst_reg = dst_reg,
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn decodeOR(opcode: u16) Instruction {
        return decodeLogic(opcode, .OR);
    }
    
    fn decodeSUBADD(opcode: u16) Instruction {
        const primary = (opcode >> 12) & 0xF;
        const op: Operation = if (primary == 0x9) .SUB else .ADD;
        const op_mode = (opcode >> 6) & 0x7;
        
        return .{
            .op = op,
            .size = getSizeFromBits(op_mode & 0x3),
            .src_mode = @enumFromInt(@as(u3, @truncate((opcode >> 3) & 0x7))),
            .src_reg = @as(u3, @truncate(opcode & 0x7)),
            .src_imm = null,
            .dst_mode = .DataRegDirect,
            .dst_reg = @as(u3, @truncate((opcode >> 9) & 0x7)),
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn decodeCMPEOR(opcode: u16) Instruction {
        const bit_8 = (opcode >> 8) & 1;
        const op: Operation = if (bit_8 == 0) .CMP else .EOR;
        
        return .{
            .op = op,
            .size = getSizeFromBits((opcode >> 6) & 0x3),
            .src_mode = @enumFromInt(@as(u3, @truncate((opcode >> 3) & 0x7))),
            .src_reg = @as(u3, @truncate(opcode & 0x7)),
            .src_imm = null,
            .dst_mode = .DataRegDirect,
            .dst_reg = @as(u3, @truncate((opcode >> 9) & 0x7)),
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn decodeAND(opcode: u16) Instruction {
        return decodeLogic(opcode, .AND);
    }
    
    fn decodeShift(opcode: u16) Instruction {
        const direction = (opcode >> 8) & 1; // 0=right, 1=left
        const type_ = (opcode >> 3) & 0x3;
        
        const op: Operation = switch (type_) {
            0 => if (direction == 0) .ASR else .ASL,
            1 => if (direction == 0) .LSR else .LSL,
            2 => if (direction == 0) .ROR else .ROL,
            else => .ILLEGAL,
        };
        
        return .{
            .op = op,
            .size = getSizeFromBits((opcode >> 6) & 0x3),
            .src_mode = .Immediate,
            .src_reg = 0,
            .src_imm = @as(i32, @as(u3, @truncate((opcode >> 9) & 0x7))),
            .dst_mode = .DataRegDirect,
            .dst_reg = @as(u3, @truncate(opcode & 0x7)),
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn decodeLogic(opcode: u16, op: Operation) Instruction {
        return .{
            .op = op,
            .size = getSizeFromBits((opcode >> 6) & 0x3),
            .src_mode = @enumFromInt(@as(u3, @truncate((opcode >> 3) & 0x7))),
            .src_reg = @as(u3, @truncate(opcode & 0x7)),
            .src_imm = null,
            .dst_mode = .DataRegDirect,
            .dst_reg = @as(u3, @truncate((opcode >> 9) & 0x7)),
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn makeNOP() Instruction {
        return .{
            .op = .NOP,
            .size = .Word,
            .src_mode = .DataRegDirect,
            .src_reg = 0,
            .src_imm = null,
            .dst_mode = .DataRegDirect,
            .dst_reg = 0,
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn makeIllegal(opcode: u16) Instruction {
        _ = opcode;
        return .{
            .op = .ILLEGAL,
            .size = .Word,
            .src_mode = .DataRegDirect,
            .src_reg = 0,
            .src_imm = null,
            .dst_mode = .DataRegDirect,
            .dst_reg = 0,
            .dst_imm = null,
            .disp = null,
            .condition = 0,
            .reg_mask = 0,
            .bf_offset = 0,
            .bf_width = 0,
            .length = 2,
        };
    }
    
    fn getSizeFromBits(bits: u16) Size {
        return switch (bits & 0x3) {
            0 => .Byte,
            1 => .Word,
            2 => .Long,
            else => .Word,
        };
    }
    
    fn getQuickData(opcode: u16) i32 {
        const data = @as(u3, @truncate((opcode >> 9) & 0x7));
        return if (data == 0) 8 else @as(i32, data);
    }
};

test "decode MOVEQ" {
    const instr = Decoder.decode(0x7042); // MOVEQ #42, D0
    try std.testing.expectEqual(Operation.MOVEQ, instr.op);
    try std.testing.expectEqual(@as(i32, 42), instr.src_imm.?);
    try std.testing.expectEqual(@as(u3, 0), instr.dst_reg);
}

test "decode NOP" {
    const instr = Decoder.decode(0x4E71);
    try std.testing.expectEqual(Operation.NOP, instr.op);
}

test "decode BRA" {
    const instr = Decoder.decode(0x6006); // BRA +6
    try std.testing.expectEqual(Operation.BRA, instr.op);
    try std.testing.expectEqual(@as(i16, 6), instr.disp.?);
}
