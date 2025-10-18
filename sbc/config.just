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

# Enable interfaces on a remote Raspberry Pi via SSH
enable_interfaces user_at_host:
    #!/usr/bin/env bash
    ssh -t {{user_at_host}} "sudo -v && \
                             echo 'Enabling hardware interfaces (SPI, I2C, UART)...' && \
                             sudo raspi-config nonint set_config_var dtparam=spi on /boot/firmware/config.txt && \
                             sudo raspi-config nonint set_config_var dtparam=i2c_arm on /boot/firmware/config.txt && \
                             sudo raspi-config nonint do_serial_hw 0 && \
                             sudo raspi-config nonint do_serial_cons 1 && \
                             echo 'dtoverlay=spi0-0cs,no_cs' | sudo tee -a /boot/firmware/config.txt > /dev/null && \
                             echo 'Interfaces enabled. Rebooting now...' && \
                             sudo reboot"

# Configure wireless networks on a remote device using .wifi file
configure_wifi user_at_host:
    ./sbc/scripts/configure_wifi.sh {{user_at_host}}


# Install and configure Meshtastic on a remote device
install_meshtastic user_at_host:
    #!/usr/bin/env bash
    # Step 1: Install packages and backup old config
    echo "Installing Meshtastic and backing up existing config on {{user_at_host}}..."
    ssh -t {{user_at_host}} "sudo -v && \
                             echo 'deb http://download.opensuse.org/repositories/network:/Meshtastic:/beta/Raspbian_12/ /' | sudo tee /etc/apt/sources.list.d/network:Meshtastic:beta.list && \
                             curl -fsSL https://download.opensuse.org/repositories/network:Meshtastic:/beta/Raspbian_12/Release.key | sudo gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/network_Meshtastic_beta.gpg > /dev/null && \
                             sudo apt update && \
                             sudo apt install -y meshtasticd && \
                             if [ -f /etc/meshtasticd/config.yaml ]; then sudo mv /etc/meshtasticd/config.yaml /etc/meshtasticd/config.yaml.bak; fi"

    # Step 2: Upload the new configuration file
    echo "Uploading new configuration from meshtastic_config.yaml..."
    cat sbc/meshtastic_config.yaml | ssh {{user_at_host}} "sudo tee /etc/meshtasticd/config.yaml > /dev/null"

    # Step 3: Restart the Meshtastic service
    echo "Restarting Meshtastic service on {{user_at_host}}..."
    ssh -t {{user_at_host}} "sudo systemctl restart meshtasticd && echo '✅ Meshtastic installation and configuration complete.'"


# Complete device setup - enables interfaces, configures WiFi, and installs Meshtastic
setup_device user_at_host:
    echo "🚀 Starting complete device setup for {{user_at_host}}..."
    echo ""
    echo "📡 Step 1/3: Enabling hardware interfaces (SPI, I2C, UART)..."
    enable_interfaces {{user_at_host}}
    echo ""
    echo "📶 Step 2/3: Configuring WiFi networks..."
    configure_wifi {{user_at_host}}
    echo ""
    echo "📡 Step 3/3: Installing and configuring Meshtastic..."
    install_meshtastic {{user_at_host}}
    echo ""
    echo "✅ Complete device setup finished!"
    echo "Your device {{user_at_host}} is now fully configured with:"
    echo "  • Hardware interfaces enabled (SPI, I2C, UART)"
    echo "  • WiFi networks configured"
    echo "  • Meshtastic installed and configured"
