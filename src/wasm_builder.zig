// WASM Bytecode Generator
//
// Generate WASM binary format directly

const std = @import("std");

/// WASM value types
pub const ValType = enum(u8) {
    i32 = 0x7F,
    i64 = 0x7E,
    f32 = 0x7D,
    f64 = 0x7C,
};

/// WASM opcodes
pub const Opcode = enum(u8) {
    // Control
    unreachable_ = 0x00,
    nop = 0x01,
    block = 0x02,
    loop = 0x03,
    if_ = 0x04,
    else_ = 0x05,
    end = 0x0B,
    br = 0x0C,
    br_if = 0x0D,
    br_table = 0x0E,
    return_ = 0x0F,
    call = 0x10,
    call_indirect = 0x11,
    
    // Parametric
    drop = 0x1A,
    select = 0x1B,
    
    // Variable
    local_get = 0x20,
    local_set = 0x21,
    local_tee = 0x22,
    global_get = 0x23,
    global_set = 0x24,
    
    // Memory
    i32_load = 0x28,
    i64_load = 0x29,
    i32_store = 0x36,
    i64_store = 0x37,
    memory_size = 0x3F,
    memory_grow = 0x40,
    
    // Numeric i32
    i32_const = 0x41,
    i32_eqz = 0x45,
    i32_eq = 0x46,
    i32_ne = 0x47,
    i32_lt_s = 0x48,
    i32_lt_u = 0x49,
    i32_gt_s = 0x4A,
    i32_gt_u = 0x4B,
    i32_le_s = 0x4C,
    i32_le_u = 0x4D,
    i32_ge_s = 0x4E,
    i32_ge_u = 0x4F,
    
    // Numeric i32 operations
    i32_clz = 0x67,
    i32_ctz = 0x68,
    i32_popcnt = 0x69,
    i32_add = 0x6A,
    i32_sub = 0x6B,
    i32_mul = 0x6C,
    i32_div_s = 0x6D,
    i32_div_u = 0x6E,
    i32_rem_s = 0x6F,
    i32_rem_u = 0x70,
    i32_and = 0x71,
    i32_or = 0x72,
    i32_xor = 0x73,
    i32_shl = 0x74,
    i32_shr_s = 0x75,
    i32_shr_u = 0x76,
    i32_rotl = 0x77,
    i32_rotr = 0x78,
};

/// WASM section IDs
pub const SectionId = enum(u8) {
    custom = 0,
    type = 1,
    import = 2,
    function = 3,
    table = 4,
    memory = 5,
    global = 6,
    export_ = 7,
    start = 8,
    element = 9,
    code = 10,
    data = 11,
};

/// WASM module builder
pub const ModuleBuilder = struct {
    allocator: std.mem.Allocator,
    sections: std.ArrayList(u8),
    
    pub fn init(allocator: std.mem.Allocator) ModuleBuilder {
        return .{
            .allocator = allocator,
            .sections = std.ArrayList(u8).init(allocator),
        };
    }
    
    pub fn deinit(self: *ModuleBuilder) void {
        self.sections.deinit();
    }
    
    /// Write WASM magic number and version
    pub fn writeHeader(self: *ModuleBuilder) !void {
        // Magic: \0asm
        try self.sections.append(0x00);
        try self.sections.append(0x61);
        try self.sections.append(0x73);
        try self.sections.append(0x6D);
        
        // Version: 1
        try self.sections.append(0x01);
        try self.sections.append(0x00);
        try self.sections.append(0x00);
        try self.sections.append(0x00);
    }
    
    /// Add type section (function signatures)
    pub fn addTypeSection(self: *ModuleBuilder) !void {
        try self.sections.append(@intFromEnum(SectionId.type));
        
        var section_data = std.ArrayList(u8).init(self.allocator);
        defer section_data.deinit();
        
        // 1 type entry
        try self.writeLEB128ToList(&section_data, 1);
        
        // func type
        try section_data.append(0x60);
        
        // 0 parameters
        try self.writeLEB128ToList(&section_data, 0);
        
        // 1 result (i32)
        try self.writeLEB128ToList(&section_data, 1);
        try section_data.append(@intFromEnum(ValType.i32));
        
        // Write section size + data
        try self.writeLEB128(section_data.items.len);
        try self.sections.appendSlice(section_data.items);
    }
    
    /// Add function section (function type indices)
    pub fn addFunctionSection(self: *ModuleBuilder, count: u32) !void {
        try self.sections.append(@intFromEnum(SectionId.function));
        
        var section_data = std.ArrayList(u8).init(self.allocator);
        defer section_data.deinit();
        
        // Function count
        try self.writeLEB128ToList(&section_data, count);
        
        // All functions use type 0
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            try self.writeLEB128ToList(&section_data, 0);
        }
        
        try self.writeLEB128(section_data.items.len);
        try self.sections.appendSlice(section_data.items);
    }
    
    /// Add memory section (linear memory)
    pub fn addMemorySection(self: *ModuleBuilder, initial_pages: u32, max_pages: ?u32) !void {
        try self.sections.append(@intFromEnum(SectionId.memory));
        
        var section_data = std.ArrayList(u8).init(self.allocator);
        defer section_data.deinit();
        
        // 1 memory
        try self.writeLEB128ToList(&section_data, 1);
        
        if (max_pages) |max| {
            // limits with max
            try section_data.append(0x01);
            try self.writeLEB128ToList(&section_data, initial_pages);
            try self.writeLEB128ToList(&section_data, max);
        } else {
            // limits without max
            try section_data.append(0x00);
            try self.writeLEB128ToList(&section_data, initial_pages);
        }
        
        try self.writeLEB128(section_data.items.len);
        try self.sections.appendSlice(section_data.items);
    }
    
    /// Add export section
    pub fn addExportSection(self: *ModuleBuilder, name: []const u8, kind: ExportKind, index: u32) !void {
        try self.sections.append(@intFromEnum(SectionId.export_));
        
        var section_data = std.ArrayList(u8).init(self.allocator);
        defer section_data.deinit();
        
        // 1 export
        try self.writeLEB128ToList(&section_data, 1);
        
        // name length + name
        try self.writeLEB128ToList(&section_data, name.len);
        try section_data.appendSlice(name);
        
        // kind
        try section_data.append(@intFromEnum(kind));
        
        // index
        try self.writeLEB128ToList(&section_data, index);
        
        try self.writeLEB128(section_data.items.len);
        try self.sections.appendSlice(section_data.items);
    }
    
    /// Add code section with function bodies
    pub fn addCodeSection(self: *ModuleBuilder, functions: []const []const u8) !void {
        try self.sections.append(@intFromEnum(SectionId.code));
        
        var section_data = std.ArrayList(u8).init(self.allocator);
        defer section_data.deinit();
        
        // Function count
        try self.writeLEB128ToList(&section_data, functions.len);
        
        // Each function body
        for (functions) |func_code| {
            // Function body size
            try self.writeLEB128ToList(&section_data, func_code.len);
            try section_data.appendSlice(func_code);
        }
        
        try self.writeLEB128(section_data.items.len);
        try self.sections.appendSlice(section_data.items);
    }
    
    /// Write LEB128 unsigned integer to main buffer
    fn writeLEB128(self: *ModuleBuilder, value: usize) !void {
        var v = value;
        while (true) {
            var byte = @as(u8, @truncate(v & 0x7F));
            v >>= 7;
            if (v != 0) {
                byte |= 0x80;
            }
            try self.sections.append(byte);
            if (v == 0) break;
        }
    }
    
    /// Write LEB128 to an ArrayList
    fn writeLEB128ToList(self: *ModuleBuilder, list: *std.ArrayList(u8), value: usize) !void {
        _ = self;
        var v = value;
        while (true) {
            var byte = @as(u8, @truncate(v & 0x7F));
            v >>= 7;
            if (v != 0) {
                byte |= 0x80;
            }
            try list.append(byte);
            if (v == 0) break;
        }
    }
    
    /// Build final module
    pub fn build(self: *ModuleBuilder) ![]u8 {
        const result = try self.allocator.dupe(u8, self.sections.items);
        return result;
    }
};

/// Export kinds
pub const ExportKind = enum(u8) {
    func = 0,
    table = 1,
    mem = 2,
    global = 3,
};

/// Function builder
pub const FunctionBuilder = struct {
    allocator: std.mem.Allocator,
    code: std.ArrayList(u8),
    locals: std.ArrayList(ValType),
    
    pub fn init(allocator: std.mem.Allocator) FunctionBuilder {
        return .{
            .allocator = allocator,
            .code = std.ArrayList(u8).init(allocator),
            .locals = std.ArrayList(ValType).init(allocator),
        };
    }
    
    pub fn deinit(self: *FunctionBuilder) void {
        self.code.deinit();
        self.locals.deinit();
    }
    
    /// Add local variable
    pub fn addLocal(self: *FunctionBuilder, type_: ValType) !u32 {
        const index = @as(u32, @intCast(self.locals.items.len));
        try self.locals.append(type_);
        return index;
    }
    
    /// Initialize standard 68k registers as locals
    pub fn initRegisters(self: *FunctionBuilder) !void {
        // D0-D7 (8 data registers)
        var i: u8 = 0;
        while (i < 8) : (i += 1) {
            _ = try self.addLocal(.i32);
        }
        
        // A0-A7 (8 address registers)
        i = 0;
        while (i < 8) : (i += 1) {
            _ = try self.addLocal(.i32);
        }
        
        // PC, SR (2 control registers)
        _ = try self.addLocal(.i32);
        _ = try self.addLocal(.i32);
        
        // Flags: C, V, Z, N, X (5 flag registers)
        i = 0;
        while (i < 5) : (i += 1) {
            _ = try self.addLocal(.i32);
        }
        
        // Cycle counter (1)
        _ = try self.addLocal(.i32);
        
        // Total: 24 locals
    }
    
    /// Emit opcode
    pub fn emit(self: *FunctionBuilder, op: Opcode) !void {
        try self.code.append(@intFromEnum(op));
    }
    
    /// Emit i32.const
    pub fn emitI32Const(self: *FunctionBuilder, value: i32) !void {
        try self.emit(.i32_const);
        var v = value;
        var more = true;
        while (more) {
            var byte = @as(u8, @truncate(v & 0x7F));
            v >>= 7;
            if ((v == 0 and (byte & 0x40) == 0) or (v == -1 and (byte & 0x40) != 0)) {
                more = false;
            } else {
                byte |= 0x80;
            }
            try self.code.append(byte);
        }
    }
    
    /// Emit local.get
    pub fn emitLocalGet(self: *FunctionBuilder, index: u32) !void {
        try self.emit(.local_get);
        try self.emitU32(index);
    }
    
    /// Emit local.set
    pub fn emitLocalSet(self: *FunctionBuilder, index: u32) !void {
        try self.emit(.local_set);
        try self.emitU32(index);
    }
    
    /// Emit unsigned integer (LEB128)
    fn emitU32(self: *FunctionBuilder, value: u32) !void {
        var v = value;
        while (true) {
            var byte = @as(u8, @truncate(v & 0x7F));
            v >>= 7;
            if (v != 0) {
                byte |= 0x80;
            }
            try self.code.append(byte);
            if (v == 0) break;
        }
    }
    
    /// Finalize function body (with locals section)
    pub fn finalize(self: *FunctionBuilder) ![]u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        errdefer result.deinit();
        
        // Locals section
        if (self.locals.items.len > 0) {
            // Count locals by type (all i32 for now)
            try self.emitLEB128ToList(&result, 1); // 1 local group
            try self.emitLEB128ToList(&result, self.locals.items.len); // count
            try result.append(@intFromEnum(ValType.i32)); // type
        } else {
            try self.emitLEB128ToList(&result, 0); // 0 local groups
        }
        
        // Function code
        try result.appendSlice(self.code.items);
        
        // End
        try result.append(@intFromEnum(Opcode.end));
        
        return result.toOwnedSlice();
    }
    
    fn emitLEB128ToList(self: *FunctionBuilder, list: *std.ArrayList(u8), value: usize) !void {
        _ = self;
        var v = value;
        while (true) {
            var byte = @as(u8, @truncate(v & 0x7F));
            v >>= 7;
            if (v != 0) {
                byte |= 0x80;
            }
            try list.append(byte);
            if (v == 0) break;
        }
    }
};

test "WASM module header" {
    var builder = ModuleBuilder.init(std.testing.allocator);
    defer builder.deinit();
    
    try builder.writeHeader();
    
    const module = try builder.build();
    defer std.testing.allocator.free(module);
    
    // Check magic
    try std.testing.expectEqual(@as(u8, 0x00), module[0]);
    try std.testing.expectEqual(@as(u8, 0x61), module[1]);
    try std.testing.expectEqual(@as(u8, 0x73), module[2]);
    try std.testing.expectEqual(@as(u8, 0x6D), module[3]);
    
    // Check version
    try std.testing.expectEqual(@as(u8, 0x01), module[4]);
}

test "i32.const emission" {
    var func = FunctionBuilder.init(std.testing.allocator);
    defer func.deinit();
    
    try func.emitI32Const(42);
    
    const code = try func.finalize();
    defer std.testing.allocator.free(code);
    
    try std.testing.expectEqual(@as(u8, 0x41), code[0]); // i32.const
    try std.testing.expectEqual(@as(u8, 42), code[1]);    // value
}
