# x86 Bootloader & Kernel

A minimal x86 operating system built from scratch in 16-bit assembly as a self-learning project. The goal was to understand what happens at the hardware level before any OS takes over — from the BIOS handing off control to a bootloader, all the way to loading and executing a kernel.

## What It Does

1. The BIOS loads the 512-byte bootloader from sector 0 of a FAT12-formatted floppy disk image into memory at `0x7C00`.
2. The bootloader traverses the FAT12 filesystem to locate `KERNEL.BIN` in the root directory.
3. It loads the kernel into memory at `0x1000:0x0000` by following the FAT cluster chain.
4. Execution jumps to the kernel, which prints a confirmation message and halts.

## Technical Details

| Component | Description |
|---|---|
| **Bootloader** | 512-byte MBR-compatible, FAT12-aware |
| **Filesystem** | FAT12 on a 1.44MB 3.5" floppy disk image |
| **Disk addressing** | LBA-to-CHS conversion for BIOS `INT 13h` |
| **Console output** | BIOS `INT 10h` (teletype mode) |
| **Kernel load address** | `0x1000:0x0000` |
| **Mode** | 16-bit real mode throughout |

### Memory Layout

```
0x0000 – 0x7BFF   BIOS and system data
0x7C00 – 0x7DFF   Bootloader (512 bytes)
0x7E00             FAT table cache (9 sectors)
0x1000:0x0000      Kernel
```

## Stack

- **Language**: x86-16 Assembly (NASM, Intel syntax)
- **Build tools**: NASM, `dd`, `mkfs.fat`, `mcopy`
- **Emulation**: QEMU (execution), Bochs (debugging with GUI debugger)

## Project Structure

```
.
├── src/
│   ├── bootloader/boot.asm   # 512-byte FAT12 bootloader
│   ├── kernel/main.asm       # Kernel entry point
│   └── debug.asm             # Hex printing utilities for debugging
├── Makefile
└── bochsrc.txt               # Bochs emulator configuration
```

## Building and Running

**Requirements**: `nasm`, `qemu-system-i386`, `dosfstools`, `mtools`

```bash
# Build and create the bootable floppy image
make

# Run in QEMU
make run

# Debug with Bochs
make debug
```

## Challenges

**FAT12 traversal** was the most involved part of the project. FAT12 entries are 12 bits wide, stored packed across byte boundaries, so reading a cluster number requires handling even and odd entries differently — shifting and masking to extract the correct 12 bits. Getting this right took significant debugging.

**x86 segmented memory** took time to internalize. Real mode uses a `segment:offset` addressing model where multiple segment/offset combinations can resolve to the same physical address. Understanding how the bootloader, FAT cache, and kernel needed to coexist in memory without overlapping — and correctly setting up segment registers at each stage — required careful planning.

**Bochs debugging** was also a bit of a learning curve.

## Context and Approach

This was a self-learning project driven by curiosity about low-level systems. I used [nanobyte's OS development series](https://www.youtube.com/c/nanobyte-dev) and the [OSDev Wiki](https://wiki.osdev.org) as primary references. My approach was to write and test each component myself first, then compare with the reference implementation — which helped me actually understand the concepts rather than just copy working code.

Assembly is not a language I work in regularly, and this project was not intended to establish deep expertise in it. The goal was to understand the boot process and low-level hardware interaction, which it achieved.
