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

    const bin = b.addInstallRaw(elf, "stm32l432-raw.bin", .{});
    const bin_step = b.step("bin", "Generate binary file to be flashed");
    bin_step.dependOn(&bin.step);

    const stm32_programmer_cli_path = "C:\\Applications\\STM\\STM32CubeProgrammer\\bin\\"; // Local path, fight me!
    const flash_cmd = b.addSystemCommand(&[_][]const u8{
        stm32_programmer_cli_path ++ "STM32_Programmer_CLI.exe",
        "-c port=SWD",
        "-w",
        b.getInstallPath(bin.dest_dir, bin.dest_filename),
        "0x08000000",
        // "-V", // Verify
        "-Rst", // Reset MCU
    });
    flash_cmd.step.dependOn(&bin.step);

    const flash_step = b.step("flash", "flash binary into MCU");
    flash_step.dependOn(&flash_cmd.step);

    b.default_step.dependOn(&elf.step);
    b.installArtifact(elf);
}
