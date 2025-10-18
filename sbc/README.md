# SBC
This directory contains firmware for running Horus on SBCs like Raspberry Pi.

## Setup
The steps below will help you install cross-compilation on your host system to enable local development for the Pi2w target.

### Install ARM Cross-Compilation (macOS only)

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

Requirements:
- Homebrew
- Rust toolchain

The `just install-arm-toolchain` command automatically:
- Installs ARM GCC toolchain via Homebrew
- Adds the `armv7-unknown-linux-gnueabihf` Rust target
- Creates `.cargo/config.toml` with proper linker configuration


```bash
# Install ARM cross-compilation toolchain (macOS)
just install-arm-toolchain
```

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

To install and configure Meshtastic on a remote device, run the following command:

```bash
just install_meshtastic user@hostname
```

This command will connect to the remote device via SSH and:
- Install the Meshtastic daemon (`meshtasticd`).
- Configure it for use with an E22-900M30S LoRa module.
- Restart the `meshtasticd` service.

You will be prompted for the SSH password.
