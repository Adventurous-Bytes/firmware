#!/bin/bash

# WiFi Configuration Script
# Usage: configure_wifi.sh user@host

set -e

USER_AT_HOST="$1"

if [ -z "$USER_AT_HOST" ]; then
    echo "❌ Error: User@host required"
    echo "Usage: $0 user@host"
    exit 1
fi

# Check if .wifi file exists
if [ ! -f ".wifi" ]; then
    echo "❌ Error: .wifi file not found"
    echo "Please copy .wifi.example to .wifi and configure your networks:"
    echo "  cp .wifi.example .wifi"
    echo "  # Edit .wifi with your network details"
    exit 1
fi

echo "Configuring wireless networks on $USER_AT_HOST..."
echo "Reading networks from .wifi file..."

# Check if NetworkManager is running
ssh -t "$USER_AT_HOST" "sudo -v && \
                         if ! systemctl is-active --quiet NetworkManager; then \
                             echo '❌ Error: NetworkManager is not running. Please enable it first.'; \
                             exit 1; \
                         fi && \
                         echo '✅ NetworkManager is running'"

# Create a temporary script file with all network configurations
TEMP_SCRIPT="/tmp/wifi_config_$$.sh"

# Build the script
cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash

# Function to add or update a WiFi connection
add_wifi_connection() {
    local network_name="$1"
    local ssid="$2"
    local password="$3"
    local security="$4"
    
    echo "Processing network: $network_name ($ssid)"
    
    if [ -z "$ssid" ]; then
        echo "⚠️  Warning: SSID not specified for $network_name, skipping"
        return
    fi
    
    # Check if connection already exists (by SSID, not connection name)
    EXISTING_CONNECTION=$(nmcli connection show | grep "wifi" | while read name uuid type device; do
        if nmcli connection show "$name" | grep -q "802-11-wireless.ssid.*$ssid"; then
            echo "$name"
            break
        fi
    done)
    
    if [ -n "$EXISTING_CONNECTION" ]; then
        echo "  ⚠️  Connection already exists ($EXISTING_CONNECTION), updating..."
        
        # Update existing connection
        if [ "$security" = "OPEN" ]; then
            nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.key-mgmt none
            nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.psk ""
            nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.wep-key0 ""
        elif [ "$security" = "WEP" ]; then
            if [ -n "$password" ]; then
                nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.key-mgmt none
                nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.psk ""
                nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.wep-key0 "$password"
            else
                echo "  ⚠️  Warning: Password required for WEP, skipping"
                return
            fi
        else
            # WPA/WPA2/WPA3 (default)
            if [ -n "$password" ]; then
                nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.key-mgmt wpa-psk
                nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.psk "$password"
                nmcli connection modify "$EXISTING_CONNECTION" wifi-sec.wep-key0 ""
            else
                echo "  ⚠️  Warning: Password required for $security, skipping"
                return
            fi
        fi
    else
        echo "  ➕ Creating new connection..."
        
        # Create new NetworkManager connection using nmcli
        if [ "$security" = "OPEN" ]; then
            nmcli connection add type wifi con-name "$ssid" ifname wlan0 ssid "$ssid" wifi-sec.key-mgmt none
        elif [ "$security" = "WEP" ]; then
            if [ -n "$password" ]; then
                nmcli connection add type wifi con-name "$ssid" ifname wlan0 ssid "$ssid" wifi-sec.key-mgmt none wifi-sec.wep-key0 "$password"
            else
                echo "  ⚠️  Warning: Password required for WEP, skipping"
                return
            fi
        else
            # WPA/WPA2/WPA3 (default)
            if [ -n "$password" ]; then
                nmcli connection add type wifi con-name "$ssid" ifname wlan0 ssid "$ssid" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$password"
            else
                echo "  ⚠️  Warning: Password required for $security, skipping"
                return
            fi
        fi
    fi
    
    # Set connection to auto-connect
    if [ -n "$EXISTING_CONNECTION" ]; then
        nmcli connection modify "$EXISTING_CONNECTION" connection.autoconnect yes
    else
        nmcli connection modify "$ssid" connection.autoconnect yes
    fi
}

EOF

# Read .wifi file and add function calls to the script
while IFS='=' read -r network_name network_config; do
    # Skip empty lines and comments
    if [[ -z "$network_name" || "$network_name" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Parse network configuration: SSID,PASSWORD,SECURITY
    IFS=',' read -r ssid password security <<< "$network_config"
    
    # Trim whitespace
    network_name=$(echo "$network_name" | xargs)
    ssid=$(echo "$ssid" | xargs)
    password=$(echo "$password" | xargs)
    security=$(echo "$security" | xargs)
    
    # Set default security if not specified
    if [ -z "$security" ]; then
        security="WPA2"
    fi
    
    echo "Adding network: $network_name"
    echo "  SSID: $ssid"
    echo "  Security: $security"
    
    # Add function call to script
    echo "add_wifi_connection '$network_name' '$ssid' '$password' '$security'" >> "$TEMP_SCRIPT"
    
done < .wifi

# Execute the script on the remote host
scp "$TEMP_SCRIPT" "$USER_AT_HOST:/tmp/wifi_config.sh"
ssh -t "$USER_AT_HOST" "sudo bash /tmp/wifi_config.sh && rm -f /tmp/wifi_config.sh"

# Clean up local temp file
rm -f "$TEMP_SCRIPT"

# Reload NetworkManager configuration
echo "Reloading NetworkManager configuration..."
ssh -t "$USER_AT_HOST" "sudo nmcli connection reload && \
                         echo '✅ Wireless networks configured successfully!' && \
                         echo 'Available connections:' && \
                         nmcli connection show"
