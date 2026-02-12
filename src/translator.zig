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
            .LEA => try self.translateLEA(instr),
            .PEA => try self.translatePEA(instr),
            .EXG => try self.translateEXG(instr),
            .SWAP => try self.translateSWAP(instr),
            .EXT => try self.translateEXT(instr),
            .ADD => try self.translateADD(instr),
            .SUB => try self.translateSUB(instr),
            .AND => try self.translateAND(instr),
            .OR => try self.translateOR(instr),
            .EOR => try self.translateEOR(instr),
            .NOP => try self.translateNOP(instr),
            .BRA => try self.translateBRA(instr),
            .Bcc => try self.translateBcc(instr),
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
