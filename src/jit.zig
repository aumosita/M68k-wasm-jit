// JIT Compiler - Complete WASM module generation
//
// High-level API for 68k → WASM compilation

const std = @import("std");
const Decoder = @import("decoder.zig").Decoder;
const Translator = @import("translator.zig").Translator;
const WasmBuilder = @import("wasm_builder.zig");
const ModuleBuilder = WasmBuilder.ModuleBuilder;

pub const JITCompiler = struct {
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) JITCompiler {
        return .{ .allocator = allocator };
    }
    
    /// Compile 68k binary to WASM module
    pub fn compile(self: *JITCompiler, m68k_binary: []const u8) ![]u8 {
        // Create module builder
        var module = ModuleBuilder.init(self.allocator);
        defer module.deinit();
        
        // Write header
        try module.writeHeader();
        
        // Type section: () -> i32
        try module.addTypeSection();
        
        // Function section: 1 function (main)
        try module.addFunctionSection(1);
        
        // Memory section: 256 pages (16MB)
        try module.addMemorySection(256, 256);
        
        // Export section: export "main" and "memory"
        try module.addExportSection("main", .func, 0);
        try module.addExportSection("memory", .mem, 0);
        
        // Generate function code
        const func_code = try self.compileFunctionBody(m68k_binary);
        defer self.allocator.free(func_code);
        
        // Code section
        const functions = [_][]const u8{func_code};
        try module.addCodeSection(&functions);
        
        // Build final module
        return try module.build();
    }
    
    /// Compile 68k instructions into a function body
    fn compileFunctionBody(self: *JITCompiler, m68k_binary: []const u8) ![]u8 {
        var translator = Translator.init(self.allocator);
        defer translator.deinit();
        
        // Initialize registers
        try translator.initRegisters();
        
        // Translate each instruction
        var offset: usize = 0;
        while (offset < m68k_binary.len) {
            // Read opcode (big-endian)
            if (offset + 2 > m68k_binary.len) break;
            
            const opcode = (@as(u16, m68k_binary[offset]) << 8) | 
                          @as(u16, m68k_binary[offset + 1]);
            
            // Decode
            const instr = Decoder.decode(opcode);
            
            // Translate
            translator.translate(instr) catch |err| {
                std.debug.print("Translation error at offset 0x{X}: {}\n", .{ offset, err });
                // Skip this instruction
            };
            
            offset += instr.length;
        }
        
        // Return cycle counter (instead of D0)
        try translator.func.emitLocalGet(23); // CYCLE_COUNTER
        
        // Finalize function body
        return try translator.func.finalize();
    }
};

test "compile simple program" {
    const allocator = std.testing.allocator;
    
    var compiler = JITCompiler.init(allocator);
    
    // MOVEQ #42, D0
    const program = [_]u8{ 0x70, 0x42 };
    
    const wasm_module = try compiler.compile(&program);
    defer allocator.free(wasm_module);
    
    // Should have WASM magic
    try std.testing.expectEqual(@as(u8, 0x00), wasm_module[0]);
    try std.testing.expectEqual(@as(u8, 0x61), wasm_module[1]);
    try std.testing.expectEqual(@as(u8, 0x73), wasm_module[2]);
    try std.testing.expectEqual(@as(u8, 0x6D), wasm_module[3]);
}
