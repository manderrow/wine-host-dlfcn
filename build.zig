const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run unit tests");

    const lib = b.addSystemCommand(&.{ "winegcc", "--winebuild" });
    lib.addFileArg(b.path("winebuild.sh"));
    if (optimize != .Debug) {
        lib.addArg("-O3");
    }
    lib.addArgs(&.{ "-m64", "-o" });
    const lib_basename = "host_dlfcn.dll.so";
    const lib_path = lib.addOutputFileArg(lib_basename);
    lib.addArg("-shared");
    lib.addFileArg(b.path("src/libhost_dlfcn.c"));
    lib.addFileArg(b.path("src/libhost_dlfcn.def"));

    b.addNamedLazyPath("lib", lib_path);
    b.getInstallStep().dependOn(&b.addInstallLibFile(lib_path, lib_basename).step);

    const proxy_lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "host_dlfcn_proxy",
        .root_module = b.addModule("proxy", .{
            .root_source_file = b.path("src/root.zig"),
            .target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu }),
            .optimize = optimize,
        }),
    });

    b.installArtifact(proxy_lib);

    const proxy_lib_unit_tests = b.addTest(.{
        .root_module = proxy_lib.root_module,
    });

    test_step.dependOn(&b.addRunArtifact(proxy_lib_unit_tests).step);

    const example_lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example_root.zig"),
            .target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu }),
            .optimize = optimize,
            .pic = true,
        }),
    });

    b.installArtifact(example_lib);

    const example_lib_unit_tests = b.addTest(.{
        .root_module = example_lib.root_module,
    });

    test_step.dependOn(&b.addRunArtifact(example_lib_unit_tests).step);

    const example_exe = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/example_main.zig"),
            .target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = .windows, .abi = .gnu }),
            .optimize = optimize,
        }),
    });

    example_exe.root_module.addImport("dlfcn", proxy_lib.root_module);

    b.installArtifact(example_exe);

    const run_cmd = b.addRunArtifact(example_exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const example_exe_unit_tests = b.addTest(.{
        .root_module = example_exe.root_module,
    });

    const run_example_exe_unit_tests = b.addRunArtifact(example_exe_unit_tests);

    run_example_exe_unit_tests.step.dependOn(b.getInstallStep());

    test_step.dependOn(&run_example_exe_unit_tests.step);
}
