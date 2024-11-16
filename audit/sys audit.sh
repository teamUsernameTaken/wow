#!/bin/bash

# Function to disable and remove services
disable_remove_services() {
    echo "Disabling and removing services..."
    read -p "Enter the services to disable and remove (space-separated): " services
    for service in $services; do
        sudo systemctl stop $service
        sudo systemctl disable $service
        sudo rm /etc/systemd/system/$service
        sudo systemctl daemon-reload
        echo "Service $service has been disabled and removed."
    done
}

# Function to uninstall applications
uninstall_applications() {
    echo "Uninstalling applications..."
    read -p "Enter the applications to uninstall (space-separated): " apps
    for app in $apps; do
        sudo apt-get remove --purge $app -y
        sudo apt-get autoremove -y
        echo "Application $app has been uninstalled."
    done
}

# Function to enable services/applications
enable_services_apps() {
    echo "Enabling services/applications..."
    read -p "Enter the services/applications to enable (space-separated): " items
    for item in $items; do
        sudo systemctl enable $item
        sudo systemctl start $item
        echo "Service/application $item has been enabled."
    done
}

# Function to disable services/applications
disable_services_apps() {
    echo "Disabling services/applications..."
    read -p "Enter the services/applications to disable (space-separated): " items
    for item in $items; do
        sudo systemctl disable $item
        sudo systemctl stop $item
        echo "Service/application $item has been disabled."
    done
}

# Function to remove malware and unwanted software
remove_malware() {
    echo "Removing malware and unwanted software..."
    malware_list=(
        "Botnet" "Mayhem" "Linux.Remaiten" "Mirai" "GafGyt" "BASHLITE" "Qbot" "LuaBot" "Hydra" "Aidra" "LightAidra" "NewAidra" "EnergyMech"
        "Linux.Encoder.1" "Lilocked" "Snakso" "Effusion" "Kaiten" "horse" "Rexob" "Waterfall" "screensaver" "Tsunami.gen" "Turla" "Xor DDoS" "Hummingbad" "NyaDrop" "PNScan" "SpeakUp"
        "42" "Arches" "Alaeda" "Binom" "Bliss" "Brundle" "Bukowski" "Caveat" "Cephei" "Coin" "Hasher" "Lacrimae" "Nuxbee" "Podloso" "RELx" "Rike" "RST" "Staog" "Vit" "Winter" "Winux" "Wit" "Zariche" "ZipWorm"
        "Adm" "Adore" "Bad Bunny" "Cheese" "Devnull" "Kork" "Linux/Lion" "Linux.Darlloz" "Linux/Lupper.worm" "Mighty" "Millen" "Slapper" "SSH Bruteforce"
    )
    
    for malware in "${malware_list[@]}"; do
        echo "Searching for and removing $malware..."
        sudo find / -name "*$malware*" -type f -delete
        sudo find / -name "*$malware*" -type d -exec rm -rf {} +
    done
    echo "Malware removal process completed."
}

# Function to configure password settings
configure_passwd() {
    echo "Configuring password and authentication settings..."
    
    # Check if passwdConfig.sh exists and is executable
    if [ -f "./passwdConfig.sh" ]; then
        # Source the file to get access to the function
        source ./passwdConfig.sh
        
        # Run the password configuration function
        if declare -F secure_passwd_config >/dev/null; then
            secure_passwd_config
        else
            echo "Error: secure_passwd_config function not found in passwdConfig.sh"
            return 1
        fi
    else
        echo "Error: passwdConfig.sh not found in current directory"
        return 1
    fi
}

# Main menu
while true; do
    echo ""
    echo "Main Menu:"
    echo "1. Disable and remove services"
    echo "2. Uninstall applications"
    echo "3. Enable services/applications"
    echo "4. Disable services/applications"
    echo "5. Remove malware and unwanted software"
    echo "6. Configure Password Settings"
    echo "7. Exit"
    read -p "Enter your choice (1-7): " choice

    case $choice in
        1) disable_remove_services ;;
        2) uninstall_applications ;;
        3) enable_services_apps ;;
        4) disable_services_apps ;;
        5) remove_malware ;;
        6) configure_passwd ;;
        7) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
done
