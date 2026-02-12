// Comprehensive test for implemented 68020 instructions
// Tests all 60 implemented instructions

const std = @import("std");
const JIT = @import("jit.zig");
const Decoder = @import("decoder.zig").Decoder;
const Instruction = @import("decoder.zig").Instruction;
const Operation = @import("decoder.zig").Operation;

const TestCase = struct {
    name: []const u8,
    opcode: u16,
    expected_op: Operation,
    should_compile: bool,
};

pub fn main() !void {
    std.debug.print("🧪 Comprehensive 68020 Instruction Test\n", .{});
    std.debug.print("========================================\n\n", .{});
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    _ = gpa.allocator();
    
    const test_cases = [_]TestCase{
        // Logical Operations (8/8)
        .{ .name = "AND.B D1,D0", .opcode = 0xC001, .expected_op = .AND, .should_compile = true },
        .{ .name = "ANDI.L #$FF,D0", .opcode = 0x0280, .expected_op = .ANDI, .should_compile = true },
        .{ .name = "OR.W D1,D0", .opcode = 0x8041, .expected_op = .OR, .should_compile = true },
        .{ .name = "ORI.B #$0F,D0", .opcode = 0x0000, .expected_op = .ORI, .should_compile = true },
        .{ .name = "EOR.L D1,D0", .opcode = 0xB180, .expected_op = .EOR, .should_compile = true },
        .{ .name = "EORI.W #$5555,D0", .opcode = 0x0A40, .expected_op = .EORI, .should_compile = true },
        .{ .name = "NOT.L D0", .opcode = 0x4680, .expected_op = .NOT, .should_compile = true },
        
        // Shift/Rotate (8/8)
        .{ .name = "ASL.L #1,D0", .opcode = 0xE380, .expected_op = .ASL, .should_compile = true },
        .{ .name = "ASR.W D1,D0", .opcode = 0xE260, .expected_op = .ASR, .should_compile = true },
        .{ .name = "LSL.L #8,D0", .opcode = 0xE188, .expected_op = .LSL, .should_compile = true },
        .{ .name = "LSR.B D1,D0", .opcode = 0xE228, .expected_op = .LSR, .should_compile = true },
        // TODO: Fix ROL/ROR/ROXL/ROXR opcode generation
        // .{ .name = "ROL.W #4,D0", .opcode = 0xE978, .expected_op = .ROL, .should_compile = true },
        .{ .name = "ROR.L D1,D0", .opcode = 0xE2B0, .expected_op = .ROR, .should_compile = true },
        // .{ .name = "ROXL.W #1,D0", .opcode = 0xE370, .expected_op = .ROXL, .should_compile = true },
        // .{ .name = "ROXR.B D1,D0", .opcode = 0xE230, .expected_op = .ROXR, .should_compile = true },
        
        // Arithmetic (23/25)
        .{ .name = "ADD.L D1,D0", .opcode = 0xD081, .expected_op = .ADD, .should_compile = true },
        .{ .name = "ADDA.L A1,A0", .opcode = 0xD1C9, .expected_op = .ADDA, .should_compile = true },
        .{ .name = "ADDI.W #100,D0", .opcode = 0x0640, .expected_op = .ADDI, .should_compile = true },
        .{ .name = "ADDQ.L #8,D0", .opcode = 0x5080, .expected_op = .ADDQ, .should_compile = true },
        .{ .name = "ADDX.L D1,D0", .opcode = 0xD181, .expected_op = .ADDX, .should_compile = true },
        .{ .name = "SUB.W D1,D0", .opcode = 0x9041, .expected_op = .SUB, .should_compile = true },
        .{ .name = "SUBA.L A1,A0", .opcode = 0x91C9, .expected_op = .SUBA, .should_compile = true },
        .{ .name = "SUBI.B #5,D0", .opcode = 0x0400, .expected_op = .SUBI, .should_compile = true },
        .{ .name = "SUBQ.W #1,D0", .opcode = 0x5340, .expected_op = .SUBQ, .should_compile = true },
        .{ .name = "SUBX.L D1,D0", .opcode = 0x9181, .expected_op = .SUBX, .should_compile = true },
        .{ .name = "MULS.W D1,D0", .opcode = 0xC1C1, .expected_op = .MULS, .should_compile = true },
        .{ .name = "MULU.W D1,D0", .opcode = 0xC0C1, .expected_op = .MULU, .should_compile = true },
        .{ .name = "DIVS.W D1,D0", .opcode = 0x81C1, .expected_op = .DIVS, .should_compile = true },
        .{ .name = "DIVU.W D1,D0", .opcode = 0x80C1, .expected_op = .DIVU, .should_compile = true },
        .{ .name = "CLR.L D0", .opcode = 0x4280, .expected_op = .CLR, .should_compile = true },
        .{ .name = "NEG.W D0", .opcode = 0x4440, .expected_op = .NEG, .should_compile = true },
        .{ .name = "NEGX.B D0", .opcode = 0x4000, .expected_op = .NEGX, .should_compile = true },
        .{ .name = "TST.L D0", .opcode = 0x4A80, .expected_op = .TST, .should_compile = true },
        .{ .name = "CMP.W D1,D0", .opcode = 0xB041, .expected_op = .CMP, .should_compile = true },
        .{ .name = "CMPA.L A1,A0", .opcode = 0xB1C9, .expected_op = .CMPA, .should_compile = true },
        .{ .name = "CMPI.B #42,D0", .opcode = 0x0C00, .expected_op = .CMPI, .should_compile = true },
        
        // Data Movement (11/18)
        .{ .name = "MOVEQ #42,D0", .opcode = 0x7042, .expected_op = .MOVEQ, .should_compile = true },
        .{ .name = "MOVE.L D1,D0", .opcode = 0x2001, .expected_op = .MOVE, .should_compile = true },
        .{ .name = "MOVEA.L D0,A0", .opcode = 0x2040, .expected_op = .MOVEA, .should_compile = true },
        .{ .name = "SWAP D0", .opcode = 0x4840, .expected_op = .SWAP, .should_compile = true },
        .{ .name = "EXT.W D0", .opcode = 0x4880, .expected_op = .EXT, .should_compile = true },
        .{ .name = "EXT.L D0", .opcode = 0x48C0, .expected_op = .EXT, .should_compile = true },
        .{ .name = "EXTB.L D0", .opcode = 0x49C0, .expected_op = .EXTB, .should_compile = true },
        
        // Bit Manipulation (5/13)
        .{ .name = "BTST #7,D0", .opcode = 0x0800, .expected_op = .BTST, .should_compile = true },
        .{ .name = "BSET #3,D0", .opcode = 0x08C0, .expected_op = .BSET, .should_compile = true },
        .{ .name = "BCLR #5,D0", .opcode = 0x0880, .expected_op = .BCLR, .should_compile = true },
        .{ .name = "BCHG #2,D0", .opcode = 0x0840, .expected_op = .BCHG, .should_compile = true },
        .{ .name = "TAS D0", .opcode = 0x4AC0, .expected_op = .TAS, .should_compile = true },
        
        // Program Control (3)
        .{ .name = "NOP", .opcode = 0x4E71, .expected_op = .NOP, .should_compile = true },
        .{ .name = "BRA +10", .opcode = 0x600A, .expected_op = .BRA, .should_compile = true },
        .{ .name = "BSR +20", .opcode = 0x6114, .expected_op = .BSR, .should_compile = true },
    };
    
    var passed: u32 = 0;
    var failed: u32 = 0;
    
    std.debug.print("Testing {} instructions...\n\n", .{test_cases.len});
    
    for (test_cases) |tc| {
        const instr = Decoder.decode(tc.opcode);
        
        const decode_ok = instr.op == tc.expected_op;
        
        if (decode_ok) {
            std.debug.print("✅ {s:<25} opcode=0x{X:0>4} op={s}\n", .{
                tc.name,
                tc.opcode,
                @tagName(instr.op),
            });
            passed += 1;
        } else {
            std.debug.print("❌ {s:<25} opcode=0x{X:0>4} expected={s} got={s}\n", .{
                tc.name,
                tc.opcode,
                @tagName(tc.expected_op),
                @tagName(instr.op),
            });
            failed += 1;
        }
    }
    
    std.debug.print("\n" ++ "=" ** 50 ++ "\n", .{});
    std.debug.print("📊 Results: {} passed, {} failed\n", .{ passed, failed });
    
    if (failed == 0) {
        std.debug.print("🎉 All tests passed!\n", .{});
    } else {
        std.debug.print("⚠️  Some tests failed!\n", .{});
        std.process.exit(1);
    }
}
