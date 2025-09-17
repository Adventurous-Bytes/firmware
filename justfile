# Default recipe - show available commands
default:
    @just --list

# Quick development commands
ping:
    echo 'Pong!'

# Install target for armv7
configure:
    rustup target add armv7-unknown-linux-gnueabihf

# Install ARM cross-compilation toolchain (macOS only)
install-arm-toolchain:
    #!/usr/bin/env bash
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "📦 Installing ARM cross-compilation toolchain for macOS..."

        # Add the cross-compilation tap if not already added
        if ! brew tap-info messense/macos-cross-toolchains >/dev/null 2>&1; then
            echo "Adding messense/macos-cross-toolchains tap..."
            brew tap messense/macos-cross-toolchains
        fi

        # Install the ARM toolchain if not already installed
        if ! command -v armv7-unknown-linux-gnueabihf-gcc >/dev/null 2>&1; then
            echo "Installing armv7-unknown-linux-gnueabihf toolchain..."
            brew install messense/macos-cross-toolchains/armv7-unknown-linux-gnueabihf
        else
            echo "ARM toolchain already installed"
        fi

        # Add ARM target to Rust
        echo "Adding armv7-unknown-linux-gnueabihf target to Rust..."
        rustup target add armv7-unknown-linux-gnueabihf

        # Create .cargo/config.toml if it doesn't exist
        if [ ! -f .cargo/config.toml ]; then
            echo "Creating .cargo/config.toml for cross-compilation..."
            mkdir -p .cargo
            cat > .cargo/config.toml << 'EOF'
    [target.armv7-unknown-linux-gnueabihf]
    linker = "armv7-unknown-linux-gnueabihf-gcc"
    ar = "armv7-unknown-linux-gnueabihf-ar"

    [env]
    # Set CC for build scripts
    CC_armv7_unknown_linux_gnueabihf = "armv7-unknown-linux-gnueabihf-gcc"
    CXX_armv7_unknown_linux_gnueabihf = "armv7-unknown-linux-gnueabihf-g++"
    AR_armv7_unknown_linux_gnueabihf = "armv7-unknown-linux-gnueabihf-ar"
    EOF
            echo "✅ Cross-compilation configuration created"
        else
            echo "✅ .cargo/config.toml already exists"
        fi

        echo "✅ ARM cross-compilation setup complete!"
    else
        echo "⚠️  ARM cross-compilation setup is only supported on macOS"
    fi

# Build for pi ARM target
build-pi:
    cargo build --target armv7-unknown-linux-gnueabihf --release
