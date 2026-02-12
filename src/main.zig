// Test main - 68k → WASM JIT (사이클 정확)

const std = @import("std");
const JIT = @import("jit.zig");
const Decoder = @import("decoder.zig").Decoder;
const CycleData = @import("cycles.zig").CycleData;

pub fn main() !void {
    std.debug.print("68k → WASM JIT Compiler (Cycle-Accurate)\n", .{});
    std.debug.print("==========================================\n\n", .{});
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Test program (big-endian)
    const program = [_]u8{
        0x70, 0x42, // MOVEQ #42, D0
        0x72, 0x14, // MOVEQ #20, D1
        0xD0, 0x81, // ADD.L D1, D0  → D0 = 62
        0xC0, 0x81, // AND.L D1, D0  → D0 = 20
        0x60, 0x04, // BNE +4        → Skip if Z=0
        0x70, 0x00, // MOVEQ #0, D0  → (skipped)
        0x4E, 0x71, // NOP
    };
    
    std.debug.print("📝 68k Program ({} bytes):\n", .{program.len});
    var i: usize = 0;
    var expected_cycles: u32 = 0;
    
    while (i < program.len) : (i += 2) {
        if (i + 1 < program.len) {
            const opcode = (@as(u16, program[i]) << 8) | @as(u16, program[i + 1]);
            const instr = Decoder.decode(opcode);
            const cycles = CycleData.getInstructionCycles(
                instr.op,
                instr.size,
                instr.src_mode,
                instr.dst_mode,
            );
            
            std.debug.print("  ${X:0>4}: 0x{X:0>4}  {s:<8} ({} cycles)\n", .{
                0x1000 + i,
                opcode,
                @tagName(instr.op),
                cycles,
            });
            
            expected_cycles += cycles;
        }
    }
    std.debug.print("\n", .{});
    std.debug.print("⏱️  Expected total cycles: {}\n\n", .{expected_cycles});
    
    std.debug.print("🔧 Compiling to WASM (with cycle tracking)...\n", .{});
    
    var compiler = JIT.JITCompiler.init(allocator);
    const wasm_module = try compiler.compile(&program);
    defer allocator.free(wasm_module);
    
    std.debug.print("  ✅ Generated WASM module: {} bytes\n\n", .{wasm_module.len});
    
    // Verify WASM header
    std.debug.print("📦 WASM Module:\n", .{});
    std.debug.print("  Magic: 0x{X:0>2}{X:0>2}{X:0>2}{X:0>2}", .{
        wasm_module[0],
        wasm_module[1],
        wasm_module[2],
        wasm_module[3],
    });
    
    if (wasm_module[0] == 0x00 and wasm_module[1] == 0x61 and 
        wasm_module[2] == 0x73 and wasm_module[3] == 0x6D) {
        std.debug.print(" ✅ Valid\n", .{});
    } else {
        std.debug.print(" ❌ Invalid\n", .{});
    }
    
    std.debug.print("  Version: {}\n", .{wasm_module[4]});
    std.debug.print("  Size: {} bytes\n\n", .{wasm_module.len});
    
    // Save to file
    const output_path = "output.wasm";
    const file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();
    
    try file.writeAll(wasm_module);
    
    std.debug.print("💾 Saved to: {s}\n\n", .{output_path});
    
    std.debug.print("✅ Cycle-Accurate JIT Compilation Complete!\n\n", .{});
    std.debug.print("📌 Summary:\n", .{});
    std.debug.print("  - 68k program: {} bytes\n", .{program.len});
    std.debug.print("  - WASM module: {} bytes\n", .{wasm_module.len});
    std.debug.print("  - Ratio: {d:.1}x\n", .{
        @as(f64, @floatFromInt(wasm_module.len)) / @as(f64, @floatFromInt(program.len)),
    });
    std.debug.print("  - Expected cycles: {}\n", .{expected_cycles});
    std.debug.print("\n", .{});
    
    std.debug.print("🚀 Next steps:\n", .{});
    std.debug.print("  1. Run: wasmer run output.wasm\n", .{});
    std.debug.print("  2. The function returns total cycle count!\n", .{});
}
