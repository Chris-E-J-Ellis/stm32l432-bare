# A test project to explore an STM32L432 
- A playpen to lark about with the STM32L432 Nucleo board
- Based on a [great blog post](https://rbino.com/posts/zig-stm32-blink/) by Riccardo Binetti 

# Software Versions
## Project bringup
- Zig: 0.11.0-dev.1580+a5b34a61a
- Regz: 
    - https://github.com/ZigEmbeddedGroup/regz
    - Commit: 341b0177d90a56f4307cc3226d552b39b048e7fa

# Rough project setup steps
- [Placeholder]

# TODO
- Simple UART

# TODONE
- Get demo building and flashing 
- Blink user LED
- Enable and configure Systick interrupt
- Add Flash as a build step
- Get debugging toolchain working (OCD/GDB, Potentially CLion)
- Examine ReleaseSmall differences/size
- Init clocks (HSI)

# Hardware

## Board
NUCLEO-L432KC

## Chip
STM32L432KCU6

## SVD
STM32L4x2.svd
