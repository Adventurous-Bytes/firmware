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
# Build for ARM (Raspberry Pi/embedded Linux)
just build-pi

# Quick ping test
just ping
```

### Cross Compilation Setup Commands

*Build environment.* Add ARM target to Rust.
```bash
# Add ARM target to Rust
just configure
```

*Toolchain.* Install ARM cross-compilation toolchain.
```bash
# Install ARM cross-compilation toolchain (macOS)
just install-arm-toolchain
```


The `just install-arm-toolchain` command automatically:
- Installs ARM GCC toolchain via Homebrew
- Adds the `armv7-unknown-linux-gnueabihf` Rust target
- Creates `.cargo/config.toml` with proper linker configuration

Requirements:
- Homebrew
- Rust toolchain

### Other Platforms

Cross-compilation setup for other platforms is not currently automated. You'll need to manually install the appropriate cross-compilation toolchain for your system.


## Pi2w Configuration

### Enable Interfaces

On a remote Raspberry Pi, you can enable the necessary interfaces by running:

```bash
just enable_interfaces user@hostname
```

This command will connect to the remote device via SSH and run a script to enable SPI, I2C, and UART. You will be prompted for the SSH password.

### Install Meshtastic
```bash

```
