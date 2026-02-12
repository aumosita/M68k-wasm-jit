const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // WASM JIT Compiler library
    const lib = b.addStaticLibrary(.{
        .name = "m68k-wasm-jit",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    // WASM build (for JIT compiler itself)
    const wasm_lib = b.addSharedLibrary(.{
        .name = "m68k-jit-compiler",
        .root_source_file = b.path("src/root.zig"),
        .target = b.resolveTargetQuery(.{
            .cpu_arch = .wasm32,
            .os_tag = .wasi,
        }),
        .optimize = optimize,
    });
    wasm_lib.rdynamic = true;
    b.installArtifact(wasm_lib);
    
    const wasm_step = b.step("wasm", "Build WASM JIT compiler");
    wasm_step.dependOn(&wasm_lib.step);

    // Test executable
    const test_exe = b.addExecutable(.{
        .name = "test-jit",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(test_exe);

    const run_cmd = b.addRunArtifact(test_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    
    const run_step = b.step("run", "Run JIT test");
    run_step.dependOn(&run_cmd.step);

    // Comprehensive test executable
    const comprehensive_test = b.addExecutable(.{
        .name = "test-comprehensive",
        .root_source_file = b.path("src/test_comprehensive.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(comprehensive_test);

    const run_comprehensive = b.addRunArtifact(comprehensive_test);
    run_comprehensive.step.dependOn(b.getInstallStep());
    
    const comprehensive_step = b.step("test-comprehensive", "Run comprehensive instruction tests");
    comprehensive_step.dependOn(&run_comprehensive.step);

    // Unit tests
    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
