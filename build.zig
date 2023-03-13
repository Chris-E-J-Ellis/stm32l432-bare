const std = @import("std");

pub fn build(b: *std.Build) void {
    // Target STM32L432
    const target = .{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
        .os_tag = .freestanding,
        .abi = .eabi,
    };

    const optimize = b.standardOptimizeOption(.{});

    const elf = b.addExecutable(.{
        .name = "stm32l432-raw.elf",
        .root_source_file = .{ .path = "src/startup.zig" },
        .target = target,
        .optimize = optimize,
    });

    const vector_obj = b.addObject(.{
        .name = "vector",
        .root_source_file = .{ .path = "src/vector.zig" },
        .target = target,
        .optimize = optimize,
    });

    elf.addObject(vector_obj);
    elf.setLinkerScriptPath(.{ .path = "src/linker.ld" });

    const obj_cpy_step = elf.addObjCopy(.{
        .basename = "stm32l432-raw.bin",
        .format = .bin,
    });

    const install_bin_step = b.addInstallBinFile(obj_cpy_step.getOutputSource(), obj_cpy_step.basename);

    const bin_step = b.step("bin", "Generate binary file to be flashed");
    bin_step.dependOn(&obj_cpy_step.step);
    bin_step.dependOn(&install_bin_step.step);

    // Likely a better way to get this path, but this'll do me (testing)
    var path_to_bin_buffer = [_]u8{0} ** 128;
    const path_to_bin = std.fmt.bufPrint(&path_to_bin_buffer, "{s}\\{s}", .{ b.install_path, obj_cpy_step.basename }) catch unreachable;
    _ = path_to_bin;

    const stm32_programmer_cli_path = "C:\\Applications\\STM\\STM32CubeProgrammer\\bin\\"; // Local path, fight me!
    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        stm32_programmer_cli_path ++ "STM32_Programmer_CLI.exe",
        "-c port=SWD",
        "-w",
        "./zig-out/bin/stm32l432-raw.bin",
        "0x08000000",
        // "-V", // Verify
        "-Rst", // Reset MCU
    });
    flash_cmd.step.dependOn(bin_step);

    const flash_step = b.step("flash", "flash binary into MCU");
    flash_step.dependOn(&flash_cmd.step);

    b.default_step.dependOn(bin_step);
    b.installArtifact(elf);
}
