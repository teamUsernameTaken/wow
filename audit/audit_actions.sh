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

# Function to check and remove security-concerning software
remove_security_concerns() {
    echo "Checking for security-concerning software..."
    
    # Define arrays of concerning software
    declare -A security_concerns=(
        # Outdated Web Technologies
        ["php5"]="Outdated PHP version with known vulnerabilities"
        ["apache2.2"]="Outdated Apache version"
        ["mysql-server-5.5"]="Outdated MySQL version"
        ["wordpress-4"]="Outdated WordPress version"
        
        # Outdated SSL/TLS
        ["openssl1.0"]="Outdated OpenSSL version"
        ["libssl1.0"]="Outdated SSL library"
        
        # Dangerous Services/Protocols
        ["telnetd"]="Insecure telnet server"
        ["rsh-server"]="Insecure remote shell"
        ["rlogin"]="Insecure remote login"
        ["rcp"]="Insecure remote copy"
        ["nis"]="Network Information Service (security risk)"
        ["tftp"]="Trivial File Transfer Protocol server"
        
        # Outdated Java Versions
        ["java-7"]="Outdated Java version"
        ["java-8"]="Outdated Java version"
        ["oracle-java7"]="Outdated Oracle Java"
        
        # Deprecated or Vulnerable Services
        ["vsftpd2"]="Outdated FTP server"
        ["proftpd1"]="Outdated FTP server"
        ["exim4"]="Mail server (if not needed)"
        ["sendmail"]="Mail server (if not needed)"
        ["bind9"]="DNS server (if not needed)"
        
        # Legacy Systems
        ["python2.7"]="Outdated Python version"
        ["ruby1.9"]="Outdated Ruby version"
        ["perl5.10"]="Outdated Perl version"
    )

    echo "Scanning for concerning software..."
    found_concerns=false

    for software in "${!security_concerns[@]}"; do
        if dpkg -l | grep -qi "$software"; then
            found_concerns=true
            echo "WARNING: Found $software - ${security_concerns[$software]}"
            read -p "Do you want to remove $software? (y/n): " choice
            if [[ $choice =~ ^[Yy]$ ]]; then
                echo "Removing $software..."
                sudo apt-get remove --purge "$software"* -y
                sudo apt-get autoremove -y
                echo "$software has been removed."
            fi
        fi
    done

    if [ "$found_concerns" = false ]; then
        echo "No immediate security concerns found in installed packages."
    fi

    # Additional checks for specific configurations
    echo "Checking for dangerous configurations..."
    
    # Check for SSLv3 and weak protocols in Apache
    if [ -f "/etc/apache2/mods-enabled/ssl.conf" ]; then
        if grep -q "SSLProtocol" "/etc/apache2/mods-enabled/ssl.conf"; then
            echo "WARNING: Please verify SSL/TLS configuration in Apache"
        fi
    fi

    # Check for weak SSH configurations
    if [ -f "/etc/ssh/sshd_config" ]; then
        if grep -q "PermitRootLogin yes" "/etc/ssh/sshd_config"; then
            echo "WARNING: Root login is permitted via SSH"
        fi
    fi

    echo "Security concern check completed."
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
    echo "6. Check and remove security concerns"
    echo "7. Exit"
    read -p "Enter your choice (1-7): " choice

    case $choice in
        1) disable_remove_services ;;
        2) uninstall_applications ;;
        3) enable_services_apps ;;
        4) disable_services_apps ;;
        5) remove_malware ;;
        6) remove_security_concerns ;;
        7) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
done
