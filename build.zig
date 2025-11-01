const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("osdialog-zig", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "osdialog-zig",
        .root_module = lib_mod,
    });

    lib.addCSourceFile(.{ .file = b.path("src/osdialog/osdialog.c") });

    if (builtin.os.tag == .linux) {
        lib.linkSystemLibrary("gtk+-3.0");
        lib.addCSourceFile(.{ .file = b.path("src/osdialog/osdialog_gtk.c") });
    } else if (builtin.os.tag == .windows) {
        lib.linkSystemLibrary("comdlg32");
        lib.addCSourceFile(.{ .file = b.path("src/osdialog/osdialog_win.c") });
    } else if (builtin.os.tag.isDarwin()) {
        lib.linkFramework("AppKit");
        lib.addCSourceFile(.{ .file = b.path("src/osdialog/osdialog_mac.m") });
    }

    lib.addIncludePath(b.path("src/osdialog/"));
    lib.linkLibC();

    b.installArtifact(lib);

    const module = b.addModule("osdialog-zig", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    module.linkLibrary(lib);

    const lib_unit_tests = b.addTest(.{
        .root_module = module,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
