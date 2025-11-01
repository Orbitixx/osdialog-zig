const std = @import("std");
const builtin = @import("builtin");

// Although this function looks imperative, it does not perform the build
// directly and instead it mutates the build graph (`b`) that will be then
// executed by an external runner. The functions in `std.Build` implement a DSL
// for defining build steps and express dependencies between them, allowing the
// build runner to parallelize the build automatically (and the cache system to
// know when a step doesn't need to be re-run).
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "osdialog-zig",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.addCSourceFile(.{ .file = b.path("src/osdialog/osdialog.c") });
    lib.addIncludePath(b.path("src/osdialog/"));
    lib.linkLibC();

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

    b.installArtifact(lib);

    // Export a MODULE that is linked to the library
    const module = b.addModule("osdialog-zig", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    module.linkLibrary(lib);
    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_module = module,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // Exposes a `test` step to the `zig build --help` menu, providing a way
    // for the user to request running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
