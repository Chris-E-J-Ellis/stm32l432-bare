const registers = @import("registers.zig").registers;

// Used as default system freq if no clock configuration performed post reset
const default_MSI_freq_hz = 4_000_000;
const max_HSI_PLL_freq_hz = 80_000_000;
const ms_per_s = 1000; // Could use std.time?
var sys_ticks: u32 = 0;

export fn sysTickHandler() void {
    sys_ticks += 1;
}

pub fn main() void {
    // Test some things!
    //configureClock();
    //configureSysTick(max_HSI_PLL_freq_hz / 8 / 1000); // Using AHB/8 as clock source
    //configureSysTick(default_MSI_freq_hz / 8 / 1000); // Using AHB/8 as clock source
    configureSysTick(default_MSI_freq_hz / 1000); // Using processor as clock source
    enableUserLed();

    //const delayNops = default_MSI_freq_hz / 100;
    while (true) {
        //delay(delayNops);
        //toggleUserLed();

        // Test ticking
        if (@mod(sys_ticks, ms_per_s) == 0)
            toggleUserLed();
    }
}

fn configureClock() void {
    // Turn this champ up to 80MHz

    // Select HSE, wait, I need to bridge a solder joint to enable this
    // Use HSI instead!

    // Enable HSI
    registers.RCC.CR.modify(.{ .HSION = 1 });

    // Wait for HSI ready
    while (registers.RCC.CR.read().HSIRDY != 1) {}

    // Disable PLL before changing its configuration
    registers.RCC.CR.modify(.{ .PLLON = 0 });

    registers.RCC.PLLCFGR.modify(.{
        .PLLPDIV = 7,
        .PLLREN = 1,
        .PLLN = 0x0A,
        .PLLSRC = 2,
    });

    // Enable PLL
    registers.RCC.CR.modify(.{ .PLLON = 1 });

    // Wait for PLL ready
    while (registers.RCC.CR.read().PLLRDY != 1) {}

    // Enable flash data and instruction cache and set flash latency to 4 wait states
    registers.FLASH.ACR.modify(.{ .DCEN = 1, .ICEN = 1, .LATENCY = 4 });

    // Select PLL as clock source
    registers.RCC.CFGR.modify(.{ .SW = 3, .SWS = 3 });

    var cfgr = registers.RCC.CFGR.read();
    while (cfgr.SW != 3 and cfgr.SWS != 3) : (cfgr = registers.RCC.CFGR.read()) {}
}

fn configureSysTick(tick_frequency_hz: u24) void {
    // Dedicate all 4 bits for pre-emption priority,
    // PRIGROUP[10:8]
    registers.SCB.AIRCR.modify(.{ .PRIGROUP = 0x03 }); //NVIC_PRIORITYGROUP_4

    // Enable Systick clock
    registers.SCS.SysTick.CTRL.modify(.{ .ENABLE = 1 }); // Enable systick
    //registers.SCS.SysTick.CTRL.modify(.{ .CLKSOURCE = 0 }); // Default Use Processor clock / 8 (AHB/8)
    registers.SCS.SysTick.CTRL.modify(.{ .CLKSOURCE = 1 }); // Use Processor clock (AHB)
    registers.SCS.SysTick.CTRL.modify(.{ .TICKINT = 1 }); // Enable interrupt on tick count reaching zero
    registers.SCS.SysTick.LOAD.modify(.{ .RELOAD = tick_frequency_hz }); // Set systick reload value

    registers.SCB.SHPR3.modify(.{ .PRI_15 = 0xF0 }); // Set systick priority based on STMCube example value
}

fn enableUserLed() void {
    // Should I read this back/wait?
    registers.RCC.AHB2ENR.modify(.{ .GPIOBEN = 1 }); // IO port B clock enable
    registers.GPIOB.MODER.modify(.{ .MODER3 = 0b01 }); // Enable PB3
}

fn toggleUserLed() void {
    //chip.registers.GPIOB.BSRR.modify(.{ .BS3 = 1 }); // set diode On BSRR
    //chip.registers.GPIOB.ODR.modify(.{ .ODR3 = 1 }); // set diode On ODR
    const gpio_reg = registers.GPIOB.ODR.read();
    registers.GPIOB.ODR.modify(.{ .ODR3 = ~gpio_reg.ODR3 });
}

pub fn delay(nops: u32) void {
    var i = nops;
    while (i > 0) : (i -= 1) {
        asm volatile ("nop");
    }
}
