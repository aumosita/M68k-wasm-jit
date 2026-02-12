// 68k → WASM Translator
//
// Translate 68k instructions to WASM bytecode

const std = @import("std");
const Decoder = @import("decoder.zig").Decoder;
const Instruction = @import("decoder.zig").Instruction;
const Operation = @import("decoder.zig").Operation;
const WasmBuilder = @import("wasm_builder.zig");
const Opcode = WasmBuilder.Opcode;
const FunctionBuilder = WasmBuilder.FunctionBuilder;
const CycleData = @import("cycles.zig").CycleData;

/// Register indices (local variables)
pub const Reg = struct {
    pub const D0: u32 = 0;
    pub const D1: u32 = 1;
    pub const D2: u32 = 2;
    pub const D3: u32 = 3;
    pub const D4: u32 = 4;
    pub const D5: u32 = 5;
    pub const D6: u32 = 6;
    pub const D7: u32 = 7;
    
    pub const A0: u32 = 8;
    pub const A1: u32 = 9;
    pub const A2: u32 = 10;
    pub const A3: u32 = 11;
    pub const A4: u32 = 12;
    pub const A5: u32 = 13;
    pub const A6: u32 = 14;
    pub const A7: u32 = 15; // Stack pointer
    
    pub const PC: u32 = 16;
    pub const SR: u32 = 17;
    
    pub const FLAG_C: u32 = 18;
    pub const FLAG_V: u32 = 19;
    pub const FLAG_Z: u32 = 20;
    pub const FLAG_N: u32 = 21;
    pub const FLAG_X: u32 = 22;
    
    pub const CYCLE_COUNTER: u32 = 23; // 사이클 카운터 (누적)
    
    pub fn dataReg(n: u3) u32 {
        return D0 + @as(u32, n);
    }
    
    pub fn addrReg(n: u3) u32 {
        return A0 + @as(u32, n);
    }
};

pub const Translator = struct {
    allocator: std.mem.Allocator,
    func: FunctionBuilder,
    registers_initialized: bool,
    
    pub fn init(allocator: std.mem.Allocator) Translator {
        return .{
            .allocator = allocator,
            .func = FunctionBuilder.init(allocator),
            .registers_initialized = false,
        };
    }
    
    pub fn deinit(self: *Translator) void {
        self.func.deinit();
    }
    
    /// Initialize registers (call once at start)
    pub fn initRegisters(self: *Translator) !void {
        if (self.registers_initialized) return;
        
        try self.func.initRegisters();
        
        // Initialize SP (A7) = 0x10000
        try self.func.emitI32Const(0x10000);
        try self.func.emitLocalSet(Reg.A7);
        
        // Initialize PC = 0x1000
        try self.func.emitI32Const(0x1000);
        try self.func.emitLocalSet(Reg.PC);
        
        self.registers_initialized = true;
    }
    
    /// Translate a single 68k instruction to WASM
    pub fn translate(self: *Translator, instr: Instruction) !void {
        // 1. 명령어 사이클 계산
        const cycles = CycleData.getInstructionCycles(
            instr.op,
            instr.size,
            instr.src_mode,
            instr.dst_mode,
        );
        
        // 2. 사이클 카운터 업데이트
        try self.addCycles(cycles);
        
        // 3. 명령어 변환
        switch (instr.op) {
            .MOVEQ => try self.translateMOVEQ(instr),
            .MOVE => try self.translateMOVE(instr),
            .MOVEA => try self.translateMOVEA(instr),
            .LEA => try self.translateLEA(instr),
            .PEA => try self.translatePEA(instr),
            .LINK => try self.translateLINK(instr),
            .UNLK => try self.translateUNLK(instr),
            .EXG => try self.translateEXG(instr),
            .SWAP => try self.translateSWAP(instr),
            .EXT => try self.translateEXT(instr),
            .EXTB => try self.translateEXTB(instr),
            .ADD => try self.translateADD(instr),
            .ADDA => try self.translateADDA(instr),
            .ADDI => try self.translateADDI(instr),
            .ADDQ => try self.translateADDQ(instr),
            .ADDX => try self.translateADDX(instr),
            .SUB => try self.translateSUB(instr),
            .SUBA => try self.translateSUBA(instr),
            .SUBI => try self.translateSUBI(instr),
            .SUBQ => try self.translateSUBQ(instr),
            .SUBX => try self.translateSUBX(instr),
            .MULS => try self.translateMULS(instr),
            .MULU => try self.translateMULU(instr),
            .DIVS => try self.translateDIVS(instr),
            .DIVU => try self.translateDIVU(instr),
            .DIVSL => try self.translateDIVSL(instr),
            .DIVUL => try self.translateDIVUL(instr),
            .CLR => try self.translateCLR(instr),
            .NEG => try self.translateNEG(instr),
            .NEGX => try self.translateNEGX(instr),
            .TST => try self.translateTST(instr),
            .CMP => try self.translateCMP(instr),
            .CMPA => try self.translateCMPA(instr),
            .CMPI => try self.translateCMPI(instr),
            .CMPM => try self.translateCMPM(instr),
            .AND => try self.translateAND(instr),
            .ANDI => try self.translateANDI(instr),
            .OR => try self.translateOR(instr),
            .ORI => try self.translateORI(instr),
            .EOR => try self.translateEOR(instr),
            .EORI => try self.translateEORI(instr),
            .NOT => try self.translateNOT(instr),
            .ASL => try self.translateASL(instr),
            .ASR => try self.translateASR(instr),
            .LSL => try self.translateLSL(instr),
            .LSR => try self.translateLSR(instr),
            .ROL => try self.translateROL(instr),
            .ROR => try self.translateROR(instr),
            .ROXL => try self.translateROXL(instr),
            .ROXR => try self.translateROXR(instr),
            .BTST => try self.translateBTST(instr),
            .BSET => try self.translateBSET(instr),
            .BCLR => try self.translateBCLR(instr),
            .BCHG => try self.translateBCHG(instr),
            .TAS => try self.translateTAS(instr),
            .NOP => try self.translateNOP(instr),
            .BRA => try self.translateBRA(instr),
            .BSR => try self.translateBSR(instr),
            .Bcc => try self.translateBcc(instr),
            .JMP => try self.translateJMP(instr),
            .JSR => try self.translateJSR(instr),
            .RTS => try self.translateRTS(instr),
            else => {
                std.debug.print("Unsupported operation: {}\n", .{instr.op});
                return error.UnsupportedOperation;
            },
        }
    }
    
    /// 사이클 카운터에 사이클 추가
    fn addCycles(self: *Translator, cycles: u32) !void {
        // CYCLE_COUNTER += cycles
        try self.func.emitLocalGet(Reg.CYCLE_COUNTER);
        try self.func.emitI32Const(@as(i32, @intCast(cycles)));
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.CYCLE_COUNTER);
    }
    
    /// MOVEQ #imm8, Dn → (local.set $dn (i32.const imm))
    fn translateMOVEQ(self: *Translator, instr: Instruction) !void {
        // MOVEQ #imm, Dn
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Set data register
        try self.func.emitI32Const(imm);
        try self.func.emitLocalSet(dst);
        
        // Update flags
        // N = (result < 0)
        try self.func.emitLocalGet(dst);
        try self.func.emitI32Const(0);
        try self.func.emit(.i32_lt_s);
        try self.func.emitLocalSet(Reg.FLAG_N);
        
        // Z = (result == 0)
        try self.func.emitLocalGet(dst);
        try self.func.emit(.i32_eqz);
        try self.func.emitLocalSet(Reg.FLAG_Z);
        
        // V = 0, C = 0
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// MOVE - supports multiple EA modes
    fn translateMOVE(self: *Translator, instr: Instruction) !void {
        const dst = if (instr.dst_mode == .DataRegDirect) 
            Reg.dataReg(instr.dst_reg) 
        else if (instr.dst_mode == .AddrRegDirect)
            Reg.addrReg(instr.dst_reg)
        else
            return error.UnsupportedAddressingMode;
        
        // Load source value onto stack
        try self.loadEA(instr.src_mode, instr.src_reg, instr.size);
        
        // Store to destination
        if (instr.dst_mode == .DataRegDirect or instr.dst_mode == .AddrRegDirect) {
            // Register direct
            try self.func.emitLocalSet(dst);
        } else if (instr.dst_mode == .AddrRegIndirect) {
            // (An) - store to memory
            try self.storeEA(instr.dst_mode, instr.dst_reg, instr.size);
        } else {
            return error.UnsupportedAddressingMode;
        }
        
        // Update flags (N, Z)
        if (instr.dst_mode == .DataRegDirect) {
            try self.updateFlagsNZ(dst);
        }
    }
    
    /// MOVEA - Move to Address register (no flags updated)
    fn translateMOVEA(self: *Translator, instr: Instruction) !void {
        // MOVEA <ea>, An
        // Similar to MOVE but:
        // 1. Destination is always An
        // 2. Does NOT update flags
        // 3. Always sign-extends to 32-bit if source is .Word
        
        const dst = Reg.addrReg(instr.dst_reg);
        
        // Load source value
        try self.loadEA(instr.src_mode, instr.src_reg, instr.size);
        
        // Sign-extend if Word size
        if (instr.size == .Word) {
            // Sign extend 16-bit to 32-bit
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shl);
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shr_s);
        }
        
        // Store to address register
        try self.func.emitLocalSet(dst);
        
        // No flag updates for MOVEA
    }
    
    /// Load effective address value onto stack
    fn loadEA(self: *Translator, mode: @import("decoder.zig").EAMode, reg: u3, size: @import("decoder.zig").Size) !void {
        switch (mode) {
            .DataRegDirect => {
                // Get from data register
                try self.func.emitLocalGet(Reg.dataReg(reg));
            },
            .AddrRegDirect => {
                // Get from address register
                try self.func.emitLocalGet(Reg.addrReg(reg));
            },
            .AddrRegIndirect => {
                // Load from memory at (An)
                try self.func.emitLocalGet(Reg.addrReg(reg));
                try self.emitMemoryLoad(size);
            },
            .AddrRegIndirectPost => {
                // Load from (An), then An = An + size
                const a_reg = Reg.addrReg(reg);
                
                // Load value
                try self.func.emitLocalGet(a_reg);
                try self.emitMemoryLoad(size);
                
                // Increment An
                try self.func.emitLocalGet(a_reg);
                try self.func.emitI32Const(@as(i32, size.bytes()));
                try self.func.emit(.i32_add);
                try self.func.emitLocalSet(a_reg);
            },
            .AddrRegIndirectPre => {
                // An = An - size, then load from (An)
                const a_reg = Reg.addrReg(reg);
                
                // Decrement An
                try self.func.emitLocalGet(a_reg);
                try self.func.emitI32Const(-@as(i32, size.bytes()));
                try self.func.emit(.i32_add);
                try self.func.emitLocalSet(a_reg);
                
                // Load value
                try self.func.emitLocalGet(a_reg);
                try self.emitMemoryLoad(size);
            },
            .Immediate => {
                return error.ImmediateLoadNotSupported;
            },
            else => {
                return error.UnsupportedEAMode;
            },
        }
    }
    
    /// Store value from stack to effective address
    fn storeEA(self: *Translator, mode: @import("decoder.zig").EAMode, reg: u3, size: @import("decoder.zig").Size) !void {
        switch (mode) {
            .AddrRegIndirect => {
                // Store to memory at (An)
                // Stack: [value]
                try self.func.emitLocalGet(Reg.addrReg(reg));
                // Stack: [value, addr]
                try self.emitMemoryStore(size);
            },
            .AddrRegIndirectPost => {
                // Store to (An), then An = An + size
                const a_reg = Reg.addrReg(reg);
                
                // Store
                try self.func.emitLocalGet(a_reg);
                try self.emitMemoryStore(size);
                
                // Increment An
                try self.func.emitLocalGet(a_reg);
                try self.func.emitI32Const(@as(i32, size.bytes()));
                try self.func.emit(.i32_add);
                try self.func.emitLocalSet(a_reg);
            },
            .AddrRegIndirectPre => {
                // An = An - size, then store to (An)
                const a_reg = Reg.addrReg(reg);
                
                // Decrement An
                try self.func.emitLocalGet(a_reg);
                try self.func.emitI32Const(-@as(i32, size.bytes()));
                try self.func.emit(.i32_add);
                try self.func.emitLocalSet(a_reg);
                
                // Store
                try self.func.emitLocalGet(a_reg);
                try self.emitMemoryStore(size);
            },
            else => {
                return error.UnsupportedStoreMode;
            },
        }
    }
    
    /// Emit memory load instruction
    fn emitMemoryLoad(self: *Translator, size: @import("decoder.zig").Size) !void {
        switch (size) {
            .Byte => {
                // i32.load8_u (unsigned byte)
                try self.func.emit(.i32_load);
                // TODO: proper load8_u encoding
            },
            .Word => {
                // i32.load16_s (signed word)
                try self.func.emit(.i32_load);
                // TODO: proper load16_s encoding
            },
            .Long => {
                // i32.load
                try self.func.emit(.i32_load);
            },
        }
    }
    
    /// Emit memory store instruction
    fn emitMemoryStore(self: *Translator, size: @import("decoder.zig").Size) !void {
        switch (size) {
            .Byte => {
                // i32.store8
                try self.func.emit(.i32_store);
                // TODO: proper store8 encoding
            },
            .Word => {
                // i32.store16
                try self.func.emit(.i32_store);
                // TODO: proper store16 encoding
            },
            .Long => {
                // i32.store
                try self.func.emit(.i32_store);
            },
        }
    }
    
    /// ADD Dn, Dm → (local.set $dm (i32.add (local.get $dm) (local.get $dn)))
    fn translateADD(self: *Translator, instr: Instruction) !void {
        const src = Reg.dataReg(instr.src_reg);
        const dst = Reg.dataReg(instr.dst_reg);
        
        // dst = dst + src
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(src);
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(dst);
        
        // Update flags
        try self.updateFlagsNZ(dst);
        // TODO: C, V flags
    }
    
    /// ADDA - Add to address register (no flags)
    fn translateADDA(self: *Translator, instr: Instruction) !void {
        // ADDA <ea>, An
        // Add to address register, no flag updates
        const dst = Reg.addrReg(instr.dst_reg);
        
        // Load source
        try self.loadEA(instr.src_mode, instr.src_reg, instr.size);
        
        // Sign-extend if Word size
        if (instr.size == .Word) {
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shl);
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shr_s);
        }
        
        // An = An + src
        try self.func.emitLocalGet(dst);
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(dst);
        
        // No flag updates for ADDA
    }
    
    /// ADDI - Add immediate
    fn translateADDI(self: *Translator, instr: Instruction) !void {
        // ADDI #imm, <ea>
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // dst = dst + imm
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(imm);
            try self.func.emit(.i32_add);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
        } else {
            // Memory destination
            return error.UnsupportedEAMode;
        }
    }
    
    /// ADDQ - Add quick (1-8 immediate)
    fn translateADDQ(self: *Translator, instr: Instruction) !void {
        // ADDQ #imm, <ea>
        // imm is 1-8 (stored as 0-7, 0 means 8)
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        const actual_imm = if (imm == 0) @as(i32, 8) else @as(i32, @intCast(imm));
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_imm);
            try self.func.emit(.i32_add);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
        } else if (instr.dst_mode == .AddrRegDirect) {
            // Address register - no flag update
            const dst = Reg.addrReg(instr.dst_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_imm);
            try self.func.emit(.i32_add);
            try self.func.emitLocalSet(dst);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// ADDX - Add extended (with X flag)
    fn translateADDX(self: *Translator, instr: Instruction) !void {
        // ADDX Dx, Dy  or  ADDX -(Ax), -(Ay)
        // dst = dst + src + X
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            const dst = Reg.dataReg(instr.dst_reg);
            
            // dst = dst + src + X
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emit(.i32_add);
            try self.func.emitLocalGet(Reg.FLAG_X);
            try self.func.emit(.i32_add);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
            // TODO: C, V, X flags properly
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// SUB Dn, Dm
    fn translateSUB(self: *Translator, instr: Instruction) !void {
        const src = Reg.dataReg(instr.src_reg);
        const dst = Reg.dataReg(instr.dst_reg);
        
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(src);
        try self.func.emit(.i32_sub);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(dst);
    }
    
    /// SUBA - Subtract from address register (no flags)
    fn translateSUBA(self: *Translator, instr: Instruction) !void {
        // SUBA <ea>, An
        // Subtract from address register, no flag updates
        const dst = Reg.addrReg(instr.dst_reg);
        
        // Load source
        try self.loadEA(instr.src_mode, instr.src_reg, instr.size);
        
        // Sign-extend if Word size
        if (instr.size == .Word) {
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shl);
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shr_s);
        }
        
        // An = An - src
        try self.func.emitLocalGet(dst);
        try self.func.emit(.i32_sub);
        try self.func.emitLocalSet(dst);
        
        // No flag updates for SUBA
    }
    
    /// SUBI - Subtract immediate
    fn translateSUBI(self: *Translator, instr: Instruction) !void {
        // SUBI #imm, <ea>
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // dst = dst - imm
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(imm);
            try self.func.emit(.i32_sub);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// SUBQ - Subtract quick (1-8 immediate)
    fn translateSUBQ(self: *Translator, instr: Instruction) !void {
        // SUBQ #imm, <ea>
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        const actual_imm = if (imm == 0) @as(i32, 8) else @as(i32, @intCast(imm));
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_imm);
            try self.func.emit(.i32_sub);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
        } else if (instr.dst_mode == .AddrRegDirect) {
            // Address register - no flag update
            const dst = Reg.addrReg(instr.dst_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_imm);
            try self.func.emit(.i32_sub);
            try self.func.emitLocalSet(dst);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// SUBX - Subtract extended (with X flag)
    fn translateSUBX(self: *Translator, instr: Instruction) !void {
        // SUBX Dx, Dy  or  SUBX -(Ax), -(Ay)
        // dst = dst - src - X
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            const dst = Reg.dataReg(instr.dst_reg);
            
            // dst = dst - src - X
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emit(.i32_sub);
            try self.func.emitLocalGet(Reg.FLAG_X);
            try self.func.emit(.i32_sub);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
            // TODO: C, V, X flags properly
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// MULS - Signed multiply (16-bit → 32-bit)
    fn translateMULS(self: *Translator, instr: Instruction) !void {
        // MULS <ea>, Dn
        // Dn(32-bit) = Dn(low 16-bit) * src(16-bit) (signed)
        
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Load source (16-bit)
        try self.loadEA(instr.src_mode, instr.src_reg, .Word);
        
        // Sign-extend source to 32-bit
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shl);
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shr_s);
        
        // Get low 16 bits of Dn and sign-extend
        try self.func.emitLocalGet(dst);
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shl);
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shr_s);
        
        // Multiply (signed)
        try self.func.emit(.i32_mul);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(dst);
        
        // V = 0, C = 0 (always for MUL)
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// MULU - Unsigned multiply (16-bit → 32-bit)
    fn translateMULU(self: *Translator, instr: Instruction) !void {
        // MULU <ea>, Dn
        // Dn(32-bit) = Dn(low 16-bit) * src(16-bit) (unsigned)
        
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Load source (16-bit)
        try self.loadEA(instr.src_mode, instr.src_reg, .Word);
        
        // Zero-extend source to 32-bit (mask to 16 bits)
        try self.func.emitI32Const(0xFFFF);
        try self.func.emit(.i32_and);
        
        // Get low 16 bits of Dn and zero-extend
        try self.func.emitLocalGet(dst);
        try self.func.emitI32Const(0xFFFF);
        try self.func.emit(.i32_and);
        
        // Multiply (unsigned - same as signed for low 32 bits)
        try self.func.emit(.i32_mul);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(dst);
        
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// DIVS - Signed divide (32-bit / 16-bit)
    fn translateDIVS(self: *Translator, instr: Instruction) !void {
        // DIVS <ea>, Dn
        // Dn(low 16) = Dn(32) / src(16) (quotient)
        // Dn(high 16) = Dn(32) % src(16) (remainder)
        
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Load divisor (16-bit)
        try self.loadEA(instr.src_mode, instr.src_reg, .Word);
        
        // Sign-extend divisor
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shl);
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shr_s);
        const divisor = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(divisor);
        
        // Check for divide by zero
        // TODO: Should trigger exception
        
        // Quotient = Dn / divisor (signed)
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(divisor);
        try self.func.emit(.i32_div_s);
        const quotient = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(quotient);
        
        // Remainder = Dn % divisor (signed)
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(divisor);
        try self.func.emit(.i32_rem_s);
        const remainder = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(remainder);
        
        // Pack result: (remainder << 16) | (quotient & 0xFFFF)
        try self.func.emitLocalGet(remainder);
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shl);
        try self.func.emitLocalGet(quotient);
        try self.func.emitI32Const(0xFFFF);
        try self.func.emit(.i32_and);
        try self.func.emit(.i32_or);
        try self.func.emitLocalSet(dst);
        
        // Update flags based on quotient
        try self.updateFlagsNZ(quotient);
        
        // V = overflow (quotient doesn't fit in 16 bits)
        // C = 0 (always)
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// DIVU - Unsigned divide (32-bit / 16-bit)
    fn translateDIVU(self: *Translator, instr: Instruction) !void {
        // DIVU <ea>, Dn
        // Similar to DIVS but unsigned
        
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Load divisor (16-bit)
        try self.loadEA(instr.src_mode, instr.src_reg, .Word);
        
        // Zero-extend divisor
        try self.func.emitI32Const(0xFFFF);
        try self.func.emit(.i32_and);
        const divisor = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(divisor);
        
        // Quotient = Dn / divisor (unsigned)
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(divisor);
        try self.func.emit(.i32_div_u);
        const quotient = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(quotient);
        
        // Remainder = Dn % divisor (unsigned)
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(divisor);
        try self.func.emit(.i32_rem_u);
        const remainder = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(remainder);
        
        // Pack result
        try self.func.emitLocalGet(remainder);
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shl);
        try self.func.emitLocalGet(quotient);
        try self.func.emitI32Const(0xFFFF);
        try self.func.emit(.i32_and);
        try self.func.emit(.i32_or);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(quotient);
        
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// DIVSL - Signed divide long (68020)
    fn translateDIVSL(self: *Translator, instr: Instruction) !void {
        // DIVSL.L <ea>, Dq (quotient only)
        // DIVSL.L <ea>, Dr:Dq (64-bit dividend)
        // 68020 specific - 64-bit / 32-bit → 32-bit quotient
        
        // Simplified: treat as 32-bit / 32-bit for now
        // TODO: Implement proper 64-bit dividend handling
        
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Load divisor (32-bit)
        try self.loadEA(instr.src_mode, instr.src_reg, .Long);
        const divisor = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(divisor);
        
        // Quotient = Dn / divisor (signed)
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(divisor);
        try self.func.emit(.i32_div_s);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(dst);
        
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// DIVUL - Unsigned divide long (68020)
    fn translateDIVUL(self: *Translator, instr: Instruction) !void {
        // DIVUL.L <ea>, Dq (quotient only)
        // DIVUL.L <ea>, Dr:Dq (64-bit dividend)
        // 68020 specific - 64-bit / 32-bit → 32-bit quotient
        
        // Simplified: treat as 32-bit / 32-bit for now
        
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Load divisor (32-bit)
        try self.loadEA(instr.src_mode, instr.src_reg, .Long);
        const divisor = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(divisor);
        
        // Quotient = Dn / divisor (unsigned)
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(divisor);
        try self.func.emit(.i32_div_u);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(dst);
        
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// CLR - Clear operand (set to zero)
    fn translateCLR(self: *Translator, instr: Instruction) !void {
        // CLR <ea>
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // dst = 0
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(dst);
            
            // Flags: N=0, Z=1, V=0, C=0
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_N);
            try self.func.emitI32Const(1);
            try self.func.emitLocalSet(Reg.FLAG_Z);
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_V);
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_C);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// NEG - Negate (0 - operand)
    fn translateNEG(self: *Translator, instr: Instruction) !void {
        // NEG <ea>
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // dst = 0 - dst
            try self.func.emitI32Const(0);
            try self.func.emitLocalGet(dst);
            try self.func.emit(.i32_sub);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
            // TODO: C, V, X flags
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// NEGX - Negate with extend (0 - operand - X)
    fn translateNEGX(self: *Translator, instr: Instruction) !void {
        // NEGX <ea>
        // dst = 0 - dst - X
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // dst = 0 - dst - X
            try self.func.emitI32Const(0);
            try self.func.emitLocalGet(dst);
            try self.func.emit(.i32_sub);
            try self.func.emitLocalGet(Reg.FLAG_X);
            try self.func.emit(.i32_sub);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
            // TODO: C, V, X flags
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// TST - Test operand (compare with 0)
    fn translateTST(self: *Translator, instr: Instruction) !void {
        // TST <ea>
        // Updates flags but doesn't modify operand
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // Just update flags based on current value
            try self.updateFlagsNZ(dst);
            
            // V=0, C=0
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_V);
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_C);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// CMP - Compare (src - dst, update flags only)
    fn translateCMP(self: *Translator, instr: Instruction) !void {
        // CMP <ea>, Dn
        // Compute dst - src, update flags, don't store result
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Load source
        try self.loadEA(instr.src_mode, instr.src_reg, instr.size);
        
        // Compute dst - src
        try self.func.emitLocalGet(dst);
        try self.func.emit(.i32_sub);
        
        // Store in temp for flag calculation
        const temp = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(temp);
        
        // Update flags based on temp
        try self.updateFlagsNZ(temp);
        // TODO: C, V flags
    }
    
    /// CMPA - Compare address
    fn translateCMPA(self: *Translator, instr: Instruction) !void {
        // CMPA <ea>, An
        // Compute An - src, update flags only (no store)
        const dst = Reg.addrReg(instr.dst_reg);
        
        // Load source
        try self.loadEA(instr.src_mode, instr.src_reg, instr.size);
        
        // Sign-extend if Word size
        if (instr.size == .Word) {
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shl);
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shr_s);
        }
        
        // Compute An - src
        try self.func.emitLocalGet(dst);
        try self.func.emit(.i32_sub);
        
        // Store in temp
        const temp = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(temp);
        
        try self.updateFlagsNZ(temp);
        // TODO: C, V flags
    }
    
    /// CMPI - Compare immediate
    fn translateCMPI(self: *Translator, instr: Instruction) !void {
        // CMPI #imm, <ea>
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // Compute dst - imm
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(imm);
            try self.func.emit(.i32_sub);
            
            // Store in temp
            const temp = try self.func.addLocal(.i32);
            try self.func.emitLocalSet(temp);
            
            try self.updateFlagsNZ(temp);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// CMPM - Compare memory
    fn translateCMPM(self: *Translator, instr: Instruction) !void {
        // CMPM (Ax)+, (Ay)+
        // Compare memory with post-increment on both
        
        if (instr.src_mode == .AddrRegIndirectPost and instr.dst_mode == .AddrRegIndirectPost) {
            const src_reg = Reg.addrReg(instr.src_reg);
            const dst_reg = Reg.addrReg(instr.dst_reg);
            
            // Load src value from (Ax)+
            try self.func.emitLocalGet(src_reg);
            try self.emitMemoryLoad(instr.size);
            
            // Increment Ax
            try self.func.emitLocalGet(src_reg);
            try self.func.emitI32Const(@as(i32, instr.size.bytes()));
            try self.func.emit(.i32_add);
            try self.func.emitLocalSet(src_reg);
            
            // Load dst value from (Ay)+
            try self.func.emitLocalGet(dst_reg);
            try self.emitMemoryLoad(instr.size);
            
            // Increment Ay
            try self.func.emitLocalGet(dst_reg);
            try self.func.emitI32Const(@as(i32, instr.size.bytes()));
            try self.func.emit(.i32_add);
            try self.func.emitLocalSet(dst_reg);
            
            // Compare: dst - src
            try self.func.emit(.i32_sub);
            
            const temp = try self.func.addLocal(.i32);
            try self.func.emitLocalSet(temp);
            
            try self.updateFlagsNZ(temp);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// AND Dn, Dm
    fn translateAND(self: *Translator, instr: Instruction) !void {
        const src = Reg.dataReg(instr.src_reg);
        const dst = Reg.dataReg(instr.dst_reg);
        
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(src);
        try self.func.emit(.i32_and);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(dst);
        
        // V = 0, C = 0
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// ANDI - AND immediate
    fn translateANDI(self: *Translator, instr: Instruction) !void {
        // ANDI #imm, <ea>
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(imm);
            try self.func.emit(.i32_and);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
            
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_V);
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_C);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// OR Dn, Dm
    fn translateOR(self: *Translator, instr: Instruction) !void {
        const src = Reg.dataReg(instr.src_reg);
        const dst = Reg.dataReg(instr.dst_reg);
        
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(src);
        try self.func.emit(.i32_or);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(dst);
        
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// ORI - OR immediate
    fn translateORI(self: *Translator, instr: Instruction) !void {
        // ORI #imm, <ea>
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(imm);
            try self.func.emit(.i32_or);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
            
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_V);
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_C);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// EOR Dn, Dm
    fn translateEOR(self: *Translator, instr: Instruction) !void {
        const src = Reg.dataReg(instr.src_reg);
        const dst = Reg.dataReg(instr.dst_reg);
        
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalGet(src);
        try self.func.emit(.i32_xor);
        try self.func.emitLocalSet(dst);
        
        try self.updateFlagsNZ(dst);
        
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_V);
        try self.func.emitI32Const(0);
        try self.func.emitLocalSet(Reg.FLAG_C);
    }
    
    /// EORI - EOR immediate
    fn translateEORI(self: *Translator, instr: Instruction) !void {
        // EORI #imm, <ea>
        const imm = instr.src_imm orelse return error.InvalidInstruction;
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(imm);
            try self.func.emit(.i32_xor);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
            
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_V);
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_C);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// NOT - Logical complement
    fn translateNOT(self: *Translator, instr: Instruction) !void {
        // NOT <ea>
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // dst = ~dst (bitwise NOT)
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(-1);
            try self.func.emit(.i32_xor);
            try self.func.emitLocalSet(dst);
            
            try self.updateFlagsNZ(dst);
            
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_V);
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_C);
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// ASL - Arithmetic shift left
    fn translateASL(self: *Translator, instr: Instruction) !void {
        // ASL Dx, Dy  or  ASL #imm, Dy
        const dst = Reg.dataReg(instr.dst_reg);
        
        if (instr.src_mode == .DataRegDirect) {
            // Shift count in register
            const src = Reg.dataReg(instr.src_reg);
            
            // dst = dst << (src & 63)
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emitI32Const(63);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_shl);
            try self.func.emitLocalSet(dst);
        } else {
            // Immediate shift count (1-8)
            const count = instr.src_imm orelse return error.InvalidInstruction;
            const actual_count = if (count == 0) @as(i32, 8) else @as(i32, @intCast(count));
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_count);
            try self.func.emit(.i32_shl);
            try self.func.emitLocalSet(dst);
        }
        
        try self.updateFlagsNZ(dst);
        // TODO: C, V, X flags
    }
    
    /// ASR - Arithmetic shift right
    fn translateASR(self: *Translator, instr: Instruction) !void {
        // ASR Dx, Dy  or  ASR #imm, Dy
        const dst = Reg.dataReg(instr.dst_reg);
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            
            // dst = dst >> (src & 63) (arithmetic)
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emitI32Const(63);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_shr_s); // Arithmetic shift (sign-extend)
            try self.func.emitLocalSet(dst);
        } else {
            const count = instr.src_imm orelse return error.InvalidInstruction;
            const actual_count = if (count == 0) @as(i32, 8) else @as(i32, @intCast(count));
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_count);
            try self.func.emit(.i32_shr_s);
            try self.func.emitLocalSet(dst);
        }
        
        try self.updateFlagsNZ(dst);
    }
    
    /// LSL - Logical shift left
    fn translateLSL(self: *Translator, instr: Instruction) !void {
        // LSL Dx, Dy  or  LSL #imm, Dy
        const dst = Reg.dataReg(instr.dst_reg);
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emitI32Const(63);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_shl);
            try self.func.emitLocalSet(dst);
        } else {
            const count = instr.src_imm orelse return error.InvalidInstruction;
            const actual_count = if (count == 0) @as(i32, 8) else @as(i32, @intCast(count));
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_count);
            try self.func.emit(.i32_shl);
            try self.func.emitLocalSet(dst);
        }
        
        try self.updateFlagsNZ(dst);
        // TODO: C, X flags
    }
    
    /// LSR - Logical shift right
    fn translateLSR(self: *Translator, instr: Instruction) !void {
        // LSR Dx, Dy  or  LSR #imm, Dy
        const dst = Reg.dataReg(instr.dst_reg);
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            
            // dst = dst >> (src & 63) (logical)
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emitI32Const(63);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_shr_u); // Logical shift (zero-extend)
            try self.func.emitLocalSet(dst);
        } else {
            const count = instr.src_imm orelse return error.InvalidInstruction;
            const actual_count = if (count == 0) @as(i32, 8) else @as(i32, @intCast(count));
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_count);
            try self.func.emit(.i32_shr_u);
            try self.func.emitLocalSet(dst);
        }
        
        try self.updateFlagsNZ(dst);
    }
    
    /// ROL - Rotate left
    fn translateROL(self: *Translator, instr: Instruction) !void {
        // ROL Dx, Dy  or  ROL #imm, Dy
        const dst = Reg.dataReg(instr.dst_reg);
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            
            // dst = rotl(dst, src & 63)
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emitI32Const(63);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_rotl);
            try self.func.emitLocalSet(dst);
        } else {
            const count = instr.src_imm orelse return error.InvalidInstruction;
            const actual_count = if (count == 0) @as(i32, 8) else @as(i32, @intCast(count));
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_count);
            try self.func.emit(.i32_rotl);
            try self.func.emitLocalSet(dst);
        }
        
        try self.updateFlagsNZ(dst);
        // TODO: C flag (last bit rotated)
    }
    
    /// ROR - Rotate right
    fn translateROR(self: *Translator, instr: Instruction) !void {
        // ROR Dx, Dy  or  ROR #imm, Dy
        const dst = Reg.dataReg(instr.dst_reg);
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            
            // dst = rotr(dst, src & 63)
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emitI32Const(63);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_rotr);
            try self.func.emitLocalSet(dst);
        } else {
            const count = instr.src_imm orelse return error.InvalidInstruction;
            const actual_count = if (count == 0) @as(i32, 8) else @as(i32, @intCast(count));
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_count);
            try self.func.emit(.i32_rotr);
            try self.func.emitLocalSet(dst);
        }
        
        try self.updateFlagsNZ(dst);
    }
    
    /// ROXL - Rotate left with extend
    fn translateROXL(self: *Translator, instr: Instruction) !void {
        // ROXL Dx, Dy  or  ROXL #imm, Dy
        // Rotate through X flag (9-bit rotate for byte/word, 33-bit for long)
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Simplified: treat as regular rotate for now
        // TODO: Implement proper 9/17/33-bit rotate with X flag
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emitI32Const(63);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_rotl);
            try self.func.emitLocalSet(dst);
        } else {
            const count = instr.src_imm orelse return error.InvalidInstruction;
            const actual_count = if (count == 0) @as(i32, 8) else @as(i32, @intCast(count));
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_count);
            try self.func.emit(.i32_rotl);
            try self.func.emitLocalSet(dst);
        }
        
        try self.updateFlagsNZ(dst);
        // TODO: X flag handling
    }
    
    /// ROXR - Rotate right with extend
    fn translateROXR(self: *Translator, instr: Instruction) !void {
        // ROXR Dx, Dy  or  ROXR #imm, Dy
        const dst = Reg.dataReg(instr.dst_reg);
        
        // Simplified: treat as regular rotate for now
        // TODO: Implement proper 9/17/33-bit rotate with X flag
        
        if (instr.src_mode == .DataRegDirect) {
            const src = Reg.dataReg(instr.src_reg);
            
            try self.func.emitLocalGet(dst);
            try self.func.emitLocalGet(src);
            try self.func.emitI32Const(63);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_rotr);
            try self.func.emitLocalSet(dst);
        } else {
            const count = instr.src_imm orelse return error.InvalidInstruction;
            const actual_count = if (count == 0) @as(i32, 8) else @as(i32, @intCast(count));
            
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(actual_count);
            try self.func.emit(.i32_rotr);
            try self.func.emitLocalSet(dst);
        }
        
        try self.updateFlagsNZ(dst);
    }
    
    /// BTST - Test bit
    fn translateBTST(self: *Translator, instr: Instruction) !void {
        // BTST Dn, <ea>  or  BTST #imm, <ea>
        // Test bit, set Z flag (Z = !bit)
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            if (instr.src_mode == .DataRegDirect) {
                // Bit number in register
                const src = Reg.dataReg(instr.src_reg);
                
                // bit_num = src & 31 (for long)
                // bit_value = (dst >> bit_num) & 1
                try self.func.emitLocalGet(dst);
                try self.func.emitLocalGet(src);
                try self.func.emitI32Const(31);
                try self.func.emit(.i32_and);
                try self.func.emit(.i32_shr_u);
                try self.func.emitI32Const(1);
                try self.func.emit(.i32_and);
                
                // Z = !bit_value
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalSet(Reg.FLAG_Z);
            } else {
                // Bit number immediate
                const bit_num = instr.src_imm orelse return error.InvalidInstruction;
                
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(bit_num);
                try self.func.emit(.i32_shr_u);
                try self.func.emitI32Const(1);
                try self.func.emit(.i32_and);
                
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalSet(Reg.FLAG_Z);
            }
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// BSET - Set bit
    fn translateBSET(self: *Translator, instr: Instruction) !void {
        // BSET Dn, <ea>  or  BSET #imm, <ea>
        // Test bit (set Z), then set bit to 1
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            if (instr.src_mode == .DataRegDirect) {
                const src = Reg.dataReg(instr.src_reg);
                
                // bit_num = src & 31
                // Test current bit
                try self.func.emitLocalGet(dst);
                try self.func.emitLocalGet(src);
                try self.func.emitI32Const(31);
                try self.func.emit(.i32_and);
                const bit_num = try self.func.addLocal(.i32);
                try self.func.emitLocalSet(bit_num);
                
                try self.func.emitLocalGet(bit_num);
                try self.func.emit(.i32_shr_u);
                try self.func.emitI32Const(1);
                try self.func.emit(.i32_and);
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalSet(Reg.FLAG_Z);
                
                // Set bit: dst |= (1 << bit_num)
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(1);
                try self.func.emitLocalGet(bit_num);
                try self.func.emit(.i32_shl);
                try self.func.emit(.i32_or);
                try self.func.emitLocalSet(dst);
            } else {
                const bit_num = instr.src_imm orelse return error.InvalidInstruction;
                
                // Test
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(bit_num);
                try self.func.emit(.i32_shr_u);
                try self.func.emitI32Const(1);
                try self.func.emit(.i32_and);
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalSet(Reg.FLAG_Z);
                
                // Set
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(@as(i32, 1) << @as(u5, @intCast(bit_num)));
                try self.func.emit(.i32_or);
                try self.func.emitLocalSet(dst);
            }
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// BCLR - Clear bit
    fn translateBCLR(self: *Translator, instr: Instruction) !void {
        // BCLR Dn, <ea>  or  BCLR #imm, <ea>
        // Test bit (set Z), then clear bit to 0
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            if (instr.src_mode == .DataRegDirect) {
                const src = Reg.dataReg(instr.src_reg);
                
                // bit_num = src & 31
                try self.func.emitLocalGet(dst);
                try self.func.emitLocalGet(src);
                try self.func.emitI32Const(31);
                try self.func.emit(.i32_and);
                const bit_num = try self.func.addLocal(.i32);
                try self.func.emitLocalSet(bit_num);
                
                // Test
                try self.func.emitLocalGet(bit_num);
                try self.func.emit(.i32_shr_u);
                try self.func.emitI32Const(1);
                try self.func.emit(.i32_and);
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalSet(Reg.FLAG_Z);
                
                // Clear bit: dst &= ~(1 << bit_num)
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(1);
                try self.func.emitLocalGet(bit_num);
                try self.func.emit(.i32_shl);
                try self.func.emitI32Const(-1);
                try self.func.emit(.i32_xor); // NOT
                try self.func.emit(.i32_and);
                try self.func.emitLocalSet(dst);
            } else {
                const bit_num = instr.src_imm orelse return error.InvalidInstruction;
                
                // Test
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(bit_num);
                try self.func.emit(.i32_shr_u);
                try self.func.emitI32Const(1);
                try self.func.emit(.i32_and);
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalSet(Reg.FLAG_Z);
                
                // Clear
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(~(@as(i32, 1) << @as(u5, @intCast(bit_num))));
                try self.func.emit(.i32_and);
                try self.func.emitLocalSet(dst);
            }
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// BCHG - Change (toggle) bit
    fn translateBCHG(self: *Translator, instr: Instruction) !void {
        // BCHG Dn, <ea>  or  BCHG #imm, <ea>
        // Test bit (set Z), then toggle bit
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            if (instr.src_mode == .DataRegDirect) {
                const src = Reg.dataReg(instr.src_reg);
                
                // bit_num = src & 31
                try self.func.emitLocalGet(dst);
                try self.func.emitLocalGet(src);
                try self.func.emitI32Const(31);
                try self.func.emit(.i32_and);
                const bit_num = try self.func.addLocal(.i32);
                try self.func.emitLocalSet(bit_num);
                
                // Test
                try self.func.emitLocalGet(bit_num);
                try self.func.emit(.i32_shr_u);
                try self.func.emitI32Const(1);
                try self.func.emit(.i32_and);
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalSet(Reg.FLAG_Z);
                
                // Toggle bit: dst ^= (1 << bit_num)
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(1);
                try self.func.emitLocalGet(bit_num);
                try self.func.emit(.i32_shl);
                try self.func.emit(.i32_xor);
                try self.func.emitLocalSet(dst);
            } else {
                const bit_num = instr.src_imm orelse return error.InvalidInstruction;
                
                // Test
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(bit_num);
                try self.func.emit(.i32_shr_u);
                try self.func.emitI32Const(1);
                try self.func.emit(.i32_and);
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalSet(Reg.FLAG_Z);
                
                // Toggle
                try self.func.emitLocalGet(dst);
                try self.func.emitI32Const(@as(i32, 1) << @as(u5, @intCast(bit_num)));
                try self.func.emit(.i32_xor);
                try self.func.emitLocalSet(dst);
            }
        } else {
            return error.UnsupportedEAMode;
        }
    }
    
    /// TAS - Test and set (atomic)
    fn translateTAS(self: *Translator, instr: Instruction) !void {
        // TAS <ea>
        // Test byte, set flags, then set bit 7 (MSB) to 1
        // Used for semaphores in multiprocessing
        
        if (instr.dst_mode == .DataRegDirect) {
            const dst = Reg.dataReg(instr.dst_reg);
            
            // Test current value (byte)
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(0xFF);
            try self.func.emit(.i32_and);
            const byte_val = try self.func.addLocal(.i32);
            try self.func.emitLocalSet(byte_val);
            
            // Set flags based on byte value
            // N = bit 7
            try self.func.emitLocalGet(byte_val);
            try self.func.emitI32Const(0x80);
            try self.func.emit(.i32_and);
            try self.func.emit(.i32_eqz);
            try self.func.emit(.i32_eqz); // double negation
            try self.func.emitLocalSet(Reg.FLAG_N);
            
            // Z = (byte == 0)
            try self.func.emitLocalGet(byte_val);
            try self.func.emit(.i32_eqz);
            try self.func.emitLocalSet(Reg.FLAG_Z);
            
            // V = 0, C = 0
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_V);
            try self.func.emitI32Const(0);
            try self.func.emitLocalSet(Reg.FLAG_C);
            
            // Set bit 7: dst |= 0x80
            try self.func.emitLocalGet(dst);
            try self.func.emitI32Const(0x80);
            try self.func.emit(.i32_or);
            try self.func.emitLocalSet(dst);
        } else {
            // Memory operand
            // TODO: Implement atomic memory access
            return error.UnsupportedEAMode;
        }
    }
    
    /// NOP → nothing
    fn translateNOP(self: *Translator, instr: Instruction) !void {
        _ = instr;
        _ = self;
        // No operation
    }
    
    /// BRA → unconditional branch
    fn translateBRA(self: *Translator, instr: Instruction) !void {
        // BRA displacement
        // Update PC: PC = PC + 2 + displacement
        const disp = instr.disp orelse 0;
        
        // PC += 2 + disp
        try self.func.emitLocalGet(Reg.PC);
        try self.func.emitI32Const(2 + @as(i32, disp));
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.PC);
        
        // TODO: Actual branch (needs block/loop structure)
    }
    
    /// BSR → Branch to subroutine (push return address, then branch)
    fn translateBSR(self: *Translator, instr: Instruction) !void {
        // BSR displacement
        // 1. Push return address (PC + 2) to stack
        // 2. Update PC: PC = PC + 2 + displacement
        const disp = instr.disp orelse 0;
        
        // Return address = PC + 2
        try self.func.emitLocalGet(Reg.PC);
        try self.func.emitI32Const(2);
        try self.func.emit(.i32_add);
        
        // Push to stack: SP -= 4, *(SP) = return_addr
        // SP -= 4
        try self.func.emitLocalGet(Reg.A7);  // A7 = Stack Pointer
        try self.func.emitI32Const(4);
        try self.func.emit(.i32_sub);
        try self.func.emitLocalSet(Reg.A7);
        
        // Store return address at (SP)
        // TODO: Memory write operation
        // For now, just skip stack push (simplified)
        
        // Update PC
        try self.func.emitLocalGet(Reg.PC);
        try self.func.emitI32Const(2 + @as(i32, disp));
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.PC);
        
        // TODO: Actual subroutine call (needs proper stack handling)
    }
    
    /// Bcc → conditional branch
    fn translateBcc(self: *Translator, instr: Instruction) !void {
        const condition = instr.condition;
        const disp = instr.disp orelse 0;
        
        // Evaluate condition → push 0 or 1
        try self.evaluateCondition(condition);
        
        // if (condition) {
        //   PC += 2 + disp
        // }
        // Stack: [condition_result]
        
        try self.func.emit(.if_);
        {
            // Then: update PC
            try self.func.emitLocalGet(Reg.PC);
            try self.func.emitI32Const(2 + @as(i32, disp));
            try self.func.emit(.i32_add);
            try self.func.emitLocalSet(Reg.PC);
        }
        try self.func.emit(.end);
    }
    
    /// Evaluate 68k condition code
    fn evaluateCondition(self: *Translator, cc: u4) !void {
        switch (cc) {
            0x0 => { // T (always true)
                try self.func.emitI32Const(1);
            },
            0x1 => { // F (always false)
                try self.func.emitI32Const(0);
            },
            0x2 => { // HI: !C && !Z
                try self.func.emitLocalGet(Reg.FLAG_C);
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalGet(Reg.FLAG_Z);
                try self.func.emit(.i32_eqz);
                try self.func.emit(.i32_and);
            },
            0x3 => { // LS: C || Z
                try self.func.emitLocalGet(Reg.FLAG_C);
                try self.func.emitLocalGet(Reg.FLAG_Z);
                try self.func.emit(.i32_or);
            },
            0x4 => { // CC: !C
                try self.func.emitLocalGet(Reg.FLAG_C);
                try self.func.emit(.i32_eqz);
            },
            0x5 => { // CS: C
                try self.func.emitLocalGet(Reg.FLAG_C);
            },
            0x6 => { // NE: !Z
                try self.func.emitLocalGet(Reg.FLAG_Z);
                try self.func.emit(.i32_eqz);
            },
            0x7 => { // EQ: Z
                try self.func.emitLocalGet(Reg.FLAG_Z);
            },
            0x8 => { // VC: !V
                try self.func.emitLocalGet(Reg.FLAG_V);
                try self.func.emit(.i32_eqz);
            },
            0x9 => { // VS: V
                try self.func.emitLocalGet(Reg.FLAG_V);
            },
            0xA => { // PL: !N
                try self.func.emitLocalGet(Reg.FLAG_N);
                try self.func.emit(.i32_eqz);
            },
            0xB => { // MI: N
                try self.func.emitLocalGet(Reg.FLAG_N);
            },
            0xC => { // GE: N == V
                try self.func.emitLocalGet(Reg.FLAG_N);
                try self.func.emitLocalGet(Reg.FLAG_V);
                try self.func.emit(.i32_eq);
            },
            0xD => { // LT: N != V
                try self.func.emitLocalGet(Reg.FLAG_N);
                try self.func.emitLocalGet(Reg.FLAG_V);
                try self.func.emit(.i32_ne);
            },
            0xE => { // GT: !Z && (N == V)
                try self.func.emitLocalGet(Reg.FLAG_Z);
                try self.func.emit(.i32_eqz);
                try self.func.emitLocalGet(Reg.FLAG_N);
                try self.func.emitLocalGet(Reg.FLAG_V);
                try self.func.emit(.i32_eq);
                try self.func.emit(.i32_and);
            },
            0xF => { // LE: Z || (N != V)
                try self.func.emitLocalGet(Reg.FLAG_Z);
                try self.func.emitLocalGet(Reg.FLAG_N);
                try self.func.emitLocalGet(Reg.FLAG_V);
                try self.func.emit(.i32_ne);
                try self.func.emit(.i32_or);
            },
        }
    }
    
    /// JSR - Jump to subroutine
    /// JMP → Jump (unconditional)
    fn translateJMP(self: *Translator, instr: Instruction) !void {
        // JMP (EA)
        // Load target address from EA and set PC
        
        // Load target address
        try self.loadEA(instr.src_mode, instr.src_reg, .Long);
        try self.func.emitLocalSet(Reg.PC);
    }
    
    /// JSR → Jump to subroutine
    fn translateJSR(self: *Translator, instr: Instruction) !void {
        // JSR (An)
        // 1. Push return address to stack
        // 2. Jump to target
        
        // A7 -= 4 (push)
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitI32Const(-4);
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.A7);
        
        // Store return address (PC + instr.length)
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitLocalGet(Reg.PC);
        try self.func.emitI32Const(@as(i32, instr.length));
        try self.func.emit(.i32_add);
        try self.func.emit(.i32_store); // store at (A7)
        
        // Load target address
        try self.loadEA(instr.src_mode, instr.src_reg, .Long);
        try self.func.emitLocalSet(Reg.PC);
    }
    
    /// RTS → return from subroutine
    fn translateRTS(self: *Translator, instr: Instruction) !void {
        _ = instr;
        
        // Pop return address from stack
        // PC = *(A7)
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emit(.i32_load);
        try self.func.emitLocalSet(Reg.PC);
        
        // A7 += 4 (pop)
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitI32Const(4);
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.A7);
    }
    
    /// LINK - Link and allocate stack frame
    fn translateLINK(self: *Translator, instr: Instruction) !void {
        // LINK An, #displacement
        // 1. Push An to stack
        // 2. An = SP
        // 3. SP = SP + displacement
        
        const an = Reg.addrReg(instr.dst_reg);
        const disp = instr.disp orelse return error.InvalidInstruction;
        
        // Push An: SP -= 4
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitI32Const(-4);
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.A7);
        
        // Store An at (SP)
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitLocalGet(an);
        try self.func.emit(.i32_store);
        
        // An = SP
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitLocalSet(an);
        
        // SP = SP + displacement (usually negative to allocate)
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitI32Const(disp);
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.A7);
    }
    
    /// UNLK - Unlink (restore stack frame)
    fn translateUNLK(self: *Translator, instr: Instruction) !void {
        // UNLK An
        // 1. SP = An
        // 2. Pop An from stack
        
        const an = Reg.addrReg(instr.dst_reg);
        
        // SP = An
        try self.func.emitLocalGet(an);
        try self.func.emitLocalSet(Reg.A7);
        
        // Pop An: An = *(SP)
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emit(.i32_load);
        try self.func.emitLocalSet(an);
        
        // SP += 4
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitI32Const(4);
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.A7);
    }
    
    /// LEA - Load Effective Address
    fn translateLEA(self: *Translator, instr: Instruction) !void {
        // LEA <ea>, An
        // Calculate EA address and store in An
        const dst = Reg.addrReg(instr.dst_reg);
        
        // Calculate effective address
        try self.calculateEA(instr.src_mode, instr.src_reg);
        
        // Store to address register
        try self.func.emitLocalSet(dst);
    }
    
    /// PEA - Push Effective Address
    fn translatePEA(self: *Translator, instr: Instruction) !void {
        // PEA <ea>
        // Calculate EA and push to stack
        
        // A7 -= 4
        try self.func.emitLocalGet(Reg.A7);
        try self.func.emitI32Const(-4);
        try self.func.emit(.i32_add);
        try self.func.emitLocalSet(Reg.A7);
        
        // Calculate EA
        try self.calculateEA(instr.src_mode, instr.src_reg);
        
        // Store to (A7)
        try self.func.emitLocalGet(Reg.A7);
        // Stack: [ea_addr, sp]
        // Need: [sp, ea_addr] for i32.store
        try self.func.emit(.i32_store);
    }
    
    /// EXG - Exchange registers
    fn translateEXG(self: *Translator, instr: Instruction) !void {
        // EXG Rx, Ry
        const src = if (instr.src_mode == .DataRegDirect) 
            Reg.dataReg(instr.src_reg)
        else
            Reg.addrReg(instr.src_reg);
            
        const dst = if (instr.dst_mode == .DataRegDirect)
            Reg.dataReg(instr.dst_reg)
        else
            Reg.addrReg(instr.dst_reg);
        
        // temp = src
        try self.func.emitLocalGet(src);
        const temp = try self.func.addLocal(.i32);
        try self.func.emitLocalSet(temp);
        
        // src = dst
        try self.func.emitLocalGet(dst);
        try self.func.emitLocalSet(src);
        
        // dst = temp
        try self.func.emitLocalGet(temp);
        try self.func.emitLocalSet(dst);
    }
    
    /// SWAP - Swap register halves
    fn translateSWAP(self: *Translator, instr: Instruction) !void {
        // SWAP Dn
        // Swap upper and lower 16 bits
        const dn = Reg.dataReg(instr.dst_reg);
        
        // value = Dn
        try self.func.emitLocalGet(dn);
        
        // lower = value & 0xFFFF
        try self.func.emitLocalGet(dn);
        try self.func.emitI32Const(0xFFFF);
        try self.func.emit(.i32_and);
        
        // upper = (value >> 16) & 0xFFFF
        try self.func.emitLocalGet(dn);
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shr_u);
        
        // result = (lower << 16) | upper
        try self.func.emitI32Const(16);
        try self.func.emit(.i32_shl);
        try self.func.emit(.i32_or);
        
        // Dn = result
        try self.func.emitLocalSet(dn);
        
        // Update flags
        try self.updateFlagsNZ(dn);
    }
    
    /// EXT - Sign extend
    fn translateEXT(self: *Translator, instr: Instruction) !void {
        // EXT.W Dn (byte to word)
        // EXT.L Dn (word to long)
        const dn = Reg.dataReg(instr.dst_reg);
        
        if (instr.size == .Word) {
            // Byte to word: sign extend bit 7 to bits 8-15
            try self.func.emitLocalGet(dn);
            try self.func.emitI32Const(24);
            try self.func.emit(.i32_shl);
            try self.func.emitI32Const(24);
            try self.func.emit(.i32_shr_s);
        } else {
            // Word to long: sign extend bit 15 to bits 16-31
            try self.func.emitLocalGet(dn);
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shl);
            try self.func.emitI32Const(16);
            try self.func.emit(.i32_shr_s);
        }
        
        try self.func.emitLocalSet(dn);
        
        // Update flags
        try self.updateFlagsNZ(dn);
    }
    
    /// EXTB - Sign extend byte to long (68020)
    fn translateEXTB(self: *Translator, instr: Instruction) !void {
        // EXTB.L Dn
        // Sign extend byte (bit 7) to long (bits 8-31)
        const dn = Reg.dataReg(instr.dst_reg);
        
        // Shift left 24 to move bit 7 to bit 31, then arithmetic shift right
        try self.func.emitLocalGet(dn);
        try self.func.emitI32Const(24);
        try self.func.emit(.i32_shl);
        try self.func.emitI32Const(24);
        try self.func.emit(.i32_shr_s);
        
        try self.func.emitLocalSet(dn);
        
        // Update flags
        try self.updateFlagsNZ(dn);
    }
    
    /// Calculate effective address (not load value)
    fn calculateEA(self: *Translator, mode: @import("decoder.zig").EAMode, reg: u3) !void {
        switch (mode) {
            .AddrRegIndirect => {
                // Address is just An
                try self.func.emitLocalGet(Reg.addrReg(reg));
            },
            .AddrRegDisp => {
                // Address is An + displacement
                // TODO: need to read displacement from instruction stream
                try self.func.emitLocalGet(Reg.addrReg(reg));
            },
            .AbsShort, .AbsLong => {
                // TODO: read absolute address from instruction
                try self.func.emitI32Const(0); // placeholder
            },
            else => {
                return error.UnsupportedEAModeForLEA;
            },
        }
    }
    
    /// Update N and Z flags based on result
    fn updateFlagsNZ(self: *Translator, result_reg: u32) !void {
        // N = (result < 0)
        try self.func.emitLocalGet(result_reg);
        try self.func.emitI32Const(0);
        try self.func.emit(.i32_lt_s);
        try self.func.emitLocalSet(Reg.FLAG_N);
        
        // Z = (result == 0)
        try self.func.emitLocalGet(result_reg);
        try self.func.emit(.i32_eqz);
        try self.func.emitLocalSet(Reg.FLAG_Z);
    }
    
    /// Finalize and get WASM bytecode
    pub fn finalize(self: *Translator) ![]u8 {
        return try self.func.finalize();
    }
};

test "translate MOVEQ" {
    const instr = Decoder.decode(0x7042); // MOVEQ #42, D0
    
    var translator = Translator.init(std.testing.allocator);
    defer translator.deinit();
    
    try translator.translate(instr);
    
    const code = try translator.finalize();
    defer std.testing.allocator.free(code);
    
    // Should have generated WASM bytecode
    try std.testing.expect(code.len > 0);
}
