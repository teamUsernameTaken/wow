#!/usr/bin/bash

cd "$(dirname "$0")" || exit 1

PASSWORD="!@#123qweQWE"

#----------------------------------#

info() {
    echo -e "\n================\nTeam Number: 17-0197\nUID: WVV7-DSWG-7XYD\nDecryption Key:\n================\n"
}

notify() {
    echo "$1"
    notify-send "$1"
}

changeConfig() {
    local configFile="$1"
    local setting="$2"
    local value="$3"

    if grep -q "^[#]*\s*$setting" "$configFile"; then
        sed -i "s/^[#]*\s*$setting.*/$setting $value/" "$configFile"
    else
        echo "$setting $value" >>"$configFile"
    fi
}

#----------all primary scripts------------------------#
showLogo() {
    echo ".--.      .--.    ,-----.    .--.      .--. .---.  "
    echo "|  |_     |  |  .'  .-,  '.  |  |_     |  | \   /  "
    echo "| _( )_   |  | / ,-.|  \ _ \ | _( )_   |  | |   |  "
    echo "|(_ o _)  |  |;  \  '_ /  | :|(_ o _)  |  |  \ /   "
    echo "| (_,_) \ |  ||  _\`,/ \ _/  || (_,_) \ |  |   v    "
    echo "|  |/    \|  |: (  '\_/ \   ;|  |/    \|  |  _ _   "
    echo "|  '  /\  \`  | \ \`\"/  \  ) / |  '  /\  \`  | (_I_)  "
    echo "|    /  \    |  '. \_/\`\`\".'  |    /  \    |(_(=)_) "
    echo "\`---'    \`---\`    '-----'    \`---'    \`---\` (_I_)  "
    echo "                                                   "
}

commencement() {
    echo 'Welcome to the commencement script!'
    showLogo
    sudo bash commencementv2.sh
}

#------------ACTIONS----------------------#

remove_ssh_keys() {
    echo "Removing SSH keys..."
    rm -f ~/.ssh/id_rsa*
    echo "SSH keys removed"
}

passwordChange() {
    # Get all users with UID >= 1000 (typical for regular users)
    local users
    local PASSWD_FILE="/etc/passwd" # Add this line to define PASSWD_FILE
    users=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' "$PASSWD_FILE")

    # Prepare the options for whiptail
    local options=("ALL" "All Users" OFF)

    while IFS= read -r user; do
        options+=("$user" "" OFF)
    done <<<"$users"

    # Display the whiptail checklist
    local selected_users
    selected_users=$(whiptail --title "Password Change" \
        --checklist "Select users to change passwords (use SPACE to select):" \
        20 60 15 \
        "${options[@]}" \
        3>&1 1>&2 2>&3)

    # Check if user canceled the operation
    if [ $? -ne 0 ]; then
        echo "Operation canceled by the user."
        exit 1
    fi

    # Remove quotes from the selected_users string
    selected_users=$(echo "$selected_users" | tr -d '"')

    # Check if "ALL" is selected
    if [[ "$selected_users" == *"ALL"* ]]; then
        selected_users="$users"
    else
        # Remove "ALL" from the selection if it's there but not all users are selected
        selected_users=$(echo "$selected_users" | sed 's/ALL //')
    fi

    # Check if there are users selected after processing
    if [ -z "$selected_users" ]; then
        echo "No users selected for password change."
        exit 0
    fi

    # Change passwords for selected users
    for user in $selected_users; do
        echo "Changing password for $user"
        echo "$user:$PASSWORD" | chpasswd
    done

    echo "Password change operations completed."
}

configureSSHPort() {
    echo "Configuring SSH port..."
    read -p "Enter desired SSH port number (1024-65535): " new_ssh_port

    # Validate port number
    if [[ "$new_ssh_port" =~ ^[0-9]+$ ]] && [ "$new_ssh_port" -ge 1024 ] && [ "$new_ssh_port" -le 65535 ]; then
        sudo sed -i "s/^#\?Port [0-9]*/Port $new_ssh_port/" /etc/ssh/sshd_config
        echo "SSH port has been changed to $new_ssh_port"
        # Restart SSH service to apply changes
        sudo systemctl restart sshd
    else
        echo "Invalid port number. Please enter a number between 1024 and 65535"
        return 1
    fi
}

systemCleanup() {
    local PS3="Select cleanup option: "
    local options=(
        "Remove Unused Packages"
        "Remove Malware/Botnets"
        "Back"
    )

    select opt in "${options[@]}"; do
        case $opt in
        "Remove Unused Packages")
            echo "Removing unused packages and cleaning apt cache..."
            sudo apt autoremove -y
            sudo apt clean
            echo "System cleanup completed!"
            break
            ;;
        "Remove Malware/Botnets")
            echo "Enter package/application name to remove: "
            read -r package_name
            if [ -n "$package_name" ]; then
                echo "Removing $package_name..."
                sudo apt remove -y "$package_name"
                sudo apt-get remove -y "$package_name"
                echo "Removal completed!"
            else
                echo "No package name provided!"
            fi
            break
            ;;
        "Back")
            break
            ;;
        *)
            echo "Invalid option $REPLY"
            ;;
        esac
    done
}

#-------------AUDITING SCANS---------------------#
scan() {
    sudo mkdir -p /var/quarantine

    echo "Starting system security scan..."

    # ClamAV Section
    if ! command -v clamscan &>/dev/null; then
        echo "ClamAV is not installed. Installing now..."
        sudo apt-get update
        sudo apt-get install -y clamav
    fi

    # Update ClamAV virus definitions
    echo "Updating ClamAV virus definitions..."
    sudo freshclam

    # Run ClamAV scan
    echo "Starting ClamAV system scan..."
    sudo clamscan -r / --exclude-dir="^/sys|^/proc|^/dev" --move=/var/quarantine
    notify "ClamAV scan completed"

    # RKHunter Section
    if ! command -v rkhunter &>/dev/null; then
        echo "RKHunter is not installed. Installing now..."
        sudo apt-get update
        sudo apt-get install -y rkhunter
    fi

    # Update RKHunter definitions
    echo "Updating RKHunter definitions..."
    sudo rkhunter --update

    # Run RKHunter scan
    echo "Starting RKHunter system scan..."
    sudo rkhunter --check --skip-keypress --report-warnings-only
    notify "RKHunter scan completed"

    # Lynis Section
    if ! command -v lynis &>/dev/null; then
        echo "Lynis is not installed. Installing now..."
        sudo apt-get update
        sudo apt-get install -y lynis
    fi

    # Run Lynis audit
    echo "Starting Lynis system audit..."
    sudo lynis audit system --quick
    # For detailed report: sudo lynis audit system
    notify "Lynis audit completed"

    # View Lynis report
    echo "Generating Lynis report..."
    if [ -f "/var/log/lynis.log" ]; then
        echo "Lynis log available at: /var/log/lynis.log"
        echo "Lynis report available at: /var/log/lynis-report.dat"
    fi

    echo "All security scans completed!"
}

#-------------CONFIGURATION OPTIONS---------------------#

config() {
    local PS3="Select configuration option: "
    local options=(
        "Secure FTP"
        "Install/Configure OSSEC"
        "Setup Encrypted Directory"
        "Disable USB Ports"
        "Run Source List"
        "Close Open Ports"
        "Configure Bind9"
        "Back"
    )

    select opt in "${options[@]}"; do
        case $opt in
        "Secure FTP")
            if [ -f "../config/secureFTP.sh" ]; then
                sudo bash ../config/secureFTP.sh
            else
                echo "Error: secureFTP.sh not found in current directory"
                exit 1
            fi
            break
            ;;
        "Install/Configure OSSEC")
            if [ -f "../config/OSSEC.sh" ]; then
                sudo bash ../config/OSSEC.sh
            else
                echo "Error: OSSEC.sh not found in current directory"
                exit 1
            fi
            break
            ;;
        "Setup Encrypted Directory")
            if [ -f "../config/encryptedDirectory.sh" ]; then
                sudo bash ../config/encryptedDirectory.sh
            else
                echo "Error: encryptedDirectory.sh not found in config directory"
                exit 1
            fi
            break
            ;;
        "Disable USB Ports")
            if [ -f ".../config/USB_disable.sh" ]; then
                sudo bash ../config/USB_disable.sh
            else
                echo "Error: USB_disable.sh not found in config directory"
                exit 1
            fi
            break
            ;;
        "Run Source List")
            if [ -f "../config/sourceslist.sh" ]; then
                echo "Running sourcelist.sh..."
                sudo bash ../config/sourceslist.sh
            else
                echo "Error: sourcelist.sh not found in current directory"
                exit 1
            fi
            break
            ;;
        "Close Open Ports")
            if [ -f "../config/closeOpenPorts.sh" ]; then
                sudo bash ../config/closeOpenPorts.sh
            else
                echo "Error: closeOpenPorts.sh not found in current directory"
                exit 1
            fi
            break
            ;;
        "Configure Bind9")
            if [ -f "../config/bind9.sh" ]; then
                # Run in a subshell to prevent environment contamination
                (sudo bash ../config/bind9.sh)
                # Reset the terminal after execution
                reset
            else
                echo "Error: bind9.sh not found in config directory"
                exit 1
            fi
            break
            ;;
        "Back")
            break
            ;;
        *)
            echo "Invalid option $REPLY"
            ;;
        esac
    done
}

selectionScreen() {
    PS3="Select item please: "

    items=(
        "Info"
        "Security Scan"
        "Commencement"
        "Password Change"
        "System Cleanup"
        "Configuration Options"
    )

    while true; do
        select item in "${items[@]}" Quit; do
            case $REPLY in
            1)
                info
                break
                ;;
            2)
                scan
                break
                ;;
            3)
                commencement
                break
                ;;
            4)
                passwordChange
                break
                ;;
            5)
                systemCleanup
                break
                ;;
            6)
                config
                break
                ;;
            $((${#items[@]} + 1)))
                echo "We're done!"
                break 2
                ;;
            *)
                echo "Unknown choice $REPLY"
                break
                ;;
            esac
        done
    done
}

menu() {
    showLogo
    selectionScreen
}

checkDependencies() {
    local required_scripts=(
        "../config/secureFTP.sh"
        "../config/OSSEC.sh"
        "../config/encryptedDirectory.sh"
        "../config/USB_disable.sh"
        "../config/sourceslist.sh"
        "../audit/closeOpenPorts.sh"
        "../config/bind9.sh"
        "./commencementv2.sh"
    )

    local missing_scripts=()
    for script in "${required_scripts[@]}"; do
        if [ ! -f "$script" ]; then
            missing_scripts+=("$script")
        fi
    done

    if [ ${#missing_scripts[@]} -ne 0 ]; then
        echo "Error: The following required scripts are missing:"
        printf '%s\n' "${missing_scripts[@]}"
        exit 1
    fi
}

main() {
    checkDependencies
    menu
}

main
