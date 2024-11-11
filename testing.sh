#!/bin/bash

commencementConfigureBrowsers() {
    echo "Configuring browser security settings..."
    
    # Firefox configuration
    if command -v firefox &> /dev/null; then
        # Create Firefox policies directory if it doesn't exist
        sudo mkdir -p /usr/lib/firefox/distribution
        
        # Create or update policies.json
        sudo tee /usr/lib/firefox/distribution/policies.json > /dev/null <<EOT
{
    "policies": {
        "BlockAboutConfig": true,
        "DisableFormHistory": true,
        "DisableTelemetry": true,
        "EnableTrackingProtection": {
            "Value": true,
            "Locked": true
        },
        "FileDownloadRestrictions": {
            "All": {
                "Extensions": {
                    "Blocked": [
                        "exe",
                        "msi",
                        "bat",
                        "cmd",
                        "vbs",
                        "ps1"
                    ]
                }
            }
        },
        "NetworkPrediction": false,
        "PasswordManagerEnabled": false,
        "PopupBlocking": {
            "Default": true,
            "Locked": true
        }
    }
}
EOT
        echo "Firefox security settings configured."
    fi

    # Chrome/Chromium configuration (if installed)
    if command -v google-chrome &> /dev/null || command -v chromium-browser &> /dev/null; then
        sudo mkdir -p /etc/opt/chrome/policies/managed/
        
        sudo tee /etc/opt/chrome/policies/managed/security_policies.json > /dev/null <<EOT
{
    "DownloadRestrictions": 3,
    "SafeBrowsingEnabled": true,
    "SafeBrowsingProtectionLevel": 2,
    "IncognitoModeAvailability": 1,
    "AutofillAddressEnabled": false,
    "AutofillCreditCardEnabled": false
}
EOT
        echo "Chrome/Chromium security settings configured."
    fi
}

showMenu() {
    echo "=== Security Configuration Menu ==="
    echo "1. Configure Browser Security Settings"
    echo "0. Exit"
    echo "=================================="
    echo -n "Please enter your choice: "
}

# Main menu loop
while true; do
    showMenu
    read choice

    case $choice in
        1)
            commencementConfigureBrowsers
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac

    echo
    echo "Press Enter to continue..."
    read
    clear
done
