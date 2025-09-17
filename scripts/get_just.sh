#!/usr/bin/env bash
# run this file by running `bash scripts/get_just.sh`

set -euo pipefail

echo "Installing just command runner..."

# create ~/bin
mkdir -p ~/bin

# download and extract just to ~/bin/just
echo "Downloading just..."
if [ -f ~/bin/just ]; then
    echo "just is already installed at ~/bin/just"
else
    curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/bin
fi

# Detect the user's actual shell (not the shell running this script)
USER_SHELL=""
if [ -n "${SHELL:-}" ]; then
    USER_SHELL=$(basename "$SHELL")
fi

# Fallback: check what's available on the system
if [ -z "$USER_SHELL" ]; then
    if command -v zsh >/dev/null 2>&1; then
        USER_SHELL="zsh"
    elif command -v bash >/dev/null 2>&1; then
        USER_SHELL="bash"
    else
        USER_SHELL="sh"
    fi
fi

echo "Detected shell: $USER_SHELL"

# Add ~/bin to PATH in the appropriate shell configuration file
case "$USER_SHELL" in
    zsh)
        SHELL_RC="$HOME/.zshrc"
        # Create .zshrc if it doesn't exist (common on fresh Mac setups)
        touch "$SHELL_RC"
        ;;
    bash)
        SHELL_RC="$HOME/.bashrc"
        # On macOS, bash often uses .bash_profile instead of .bashrc
        if [[ "$OSTYPE" == "darwin"* ]] && [ -f "$HOME/.bash_profile" ]; then
            SHELL_RC="$HOME/.bash_profile"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # Create .bash_profile on macOS if neither exists
            SHELL_RC="$HOME/.bash_profile"
            touch "$SHELL_RC"
        else
            touch "$SHELL_RC"
        fi
        ;;
    *)
        SHELL_RC="$HOME/.profile"
        touch "$SHELL_RC"
        ;;
esac

# Check if PATH export already exists to avoid duplicates
PATH_EXPORT='export PATH="$PATH:$HOME/bin"'
if ! grep -q 'export PATH.*$HOME/bin' "$SHELL_RC" 2>/dev/null; then
    echo "Adding ~/bin to PATH in $SHELL_RC"
    echo "$PATH_EXPORT" >> "$SHELL_RC"
    echo "Added PATH export to $SHELL_RC"
else
    echo "~/bin already in PATH in $SHELL_RC"
fi

# Update PATH for current shell session
export PATH="$PATH:$HOME/bin"

# Verify installation
if command -v just >/dev/null 2>&1; then
    echo "✅ just successfully installed!"
    echo "Version: $(just --version)"
    echo ""
    echo "You can now use 'just' command. If it's not found in new shell sessions,"
    echo "restart your terminal or run: source $SHELL_RC"
else
    echo "❌ Installation failed. just command not found."
    exit 1
fi
