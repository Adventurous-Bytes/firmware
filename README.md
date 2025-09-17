# Firmware Development Environment

This repository contains firmware for embedded systems with cross-compilation support for ARM targets.

## Quick Start

### 1. Install Just Command Runner

```bash
bash scripts/get_just.sh
```

This installs the `just` command runner and sets up your shell PATH.

### 2. View Available Commands

```bash
just
```

### 3. Install ARM Cross-Compilation (macOS only)

```bash
just install-arm-toolchain
```

This sets up the ARM cross-compilation toolchain for building firmware that runs on ARM Linux devices like Raspberry Pi.

## Development Commands

### Basic Commands

```bash
# Build for host architecture
just build

# Build for ARM (Raspberry Pi/embedded Linux)
just build-pi

# Build and compile tests for ARM (cannot run on macOS)
just test

# Build all tests for ARM target
just test-pi

# Quick ping test
just ping
```

### Setup Commands

```bash
# Add ARM target to Rust
just configure

# Install ARM cross-compilation toolchain (macOS)
just install-arm-toolchain
```

## Cross-Compilation Setup

### macOS

The `just install-arm-toolchain` command automatically:
- Installs ARM GCC toolchain via Homebrew
- Adds the `armv7-unknown-linux-gnueabihf` Rust target
- Creates `.cargo/config.toml` with proper linker configuration

Requirements:
- Homebrew
- Rust toolchain

### Other Platforms

Cross-compilation setup for other platforms is not currently automated. You'll need to manually install the appropriate cross-compilation toolchain for your system.

## Project Structure

```
firmware/
├── bmp390/                 # BMP390 sensor driver
│   ├── src/               # Library source code
│   ├── examples/          # Usage examples
│   └── Cargo.toml         # Package configuration
├── scripts/
│   └── get_just.sh        # Just command runner setup
├── .cargo/
│   └── config.toml        # Cross-compilation configuration (created by justfile)
├── justfile               # Command recipes
└── README.md              # This file
```
