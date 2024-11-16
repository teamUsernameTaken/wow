#!/usr/bin/bash

PASSWORD="!@#123qweQWE"

info(){
echo -e "\n================\nTeam Number: 17-0197\nUID: WVV7-DSWG-7XYD\nDecryption Key:\n================\n"
}

notify(){
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
    echo "$setting $value" >> "$configFile"
  fi
}

# actions

passwordChange(){
    # Get all users with UID >= 1000 (typical for regular users)
    local users
    local PASSWD_FILE="/etc/passwd"  # Add this line to define PASSWD_FILE
    users=$(awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' "$PASSWD_FILE")

    # Prepare the options for whiptail
    local options=("ALL" "All Users" OFF)
    
    while IFS= read -r user; do
        options+=("$user" "" OFF)
    done <<< "$users"

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

    select opt in "${options[@]}"
    do
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

clamscan() {
    # Check if ClamAV is installed
    if ! command -v clamscan &> /dev/null; then
        echo "ClamAV is not installed. Installing now..."
        sudo apt-get update
        sudo apt-get install -y clamav
    fi

    # Update virus definitions
    echo "Updating virus definitions..."
    sudo freshclam

    # Run the scan
    echo "Starting system scan..."
    sudo clamscan -r / --exclude-dir="^/sys|^/proc|^/dev" --move=/var/quarantine
    
    notify "ClamAV scan completed"
}

commencement() {
    echo 'Welcome to the commencement script!'
    showLogo() {
    echo ".--.      .--.    ,-----.    .--.      .--. .---.  ";
    echo "|  |_     |  |  .'  .-,  '.  |  |_     |  | \   /  ";
    echo "| _( )_   |  | / ,-.|  \ _ \ | _( )_   |  | |   |  ";
    echo "|(_ o _)  |  |;  \  '_ /  | :|(_ o _)  |  |  \ /   ";
    echo "| (_,_) \ |  ||  _\`,/ \ _/  || (_,_) \ |  |   v    ";
    echo "|  |/    \|  |: (  '\_/ \   ;|  |/    \|  |  _ _   ";
    echo "|  '  /\  \`  | \ \`\"/  \  ) / |  '  /\  \`  | (_I_)  ";
    echo "|    /  \    |  '. \_/\`\`\".'  |    /  \    |(_(=)_) ";
    echo "\`---'    \`---\`    '-----'    \`---'    \`---\` (_I_)  ";
    echo "                                                   ";
}
    sudo bash commencementv2.sh
}


secureFTP() {
    if [ -f "config/secureFTP.sh" ]; then
        sudo bash config/secureFTP.sh
    else
        echo "Error: secureFTP.sh not found in current directory"
        exit 1
    fi
}

userCheck() {
    if [ -f "audit/userAudit.sh" ]; then
        sudo bash audit/userAudit.sh
    else
        echo "Error: useraudit.sh not found in current directory"
        exit 1
    fi
}

installConfigureOSSEC() {
    if [ -f "config/OSSEC.sh" ]; then
        sudo bash config/OSSEC.sh
    else
        echo "Error: OSSEC.sh not found in current directory"
        exit 1
    fi
}

setupEncryptedDirectory() {
    if [ -f "config/encryptedDirectory.sh" ]; then
        sudo bash config/encryptedDirectory.sh
    else
        echo "Error: encryptedDirectory.sh not found in config directory"
        exit 1
    fi
}

configureRemote() {
    if [ -f "config/remote.sh" ]; then
        sudo bash config/remote.sh
    else
        echo "Error: remote.sh not found in config directory"
        exit 1
    fi
}

selectionScreen(){
    PS3="Select item please: "

    items=(
        "Info" 
        "Clamscan" 
        "Commencement" 
        "User Check" 
        "Password Change" 
        "Setup Encrypted Directory"
        "Install and Configure OSSEC"
        "System Cleanup"
        "Secure FTP"
        "Configure Remote Access"
    )

    while true; do
        select item in "${items[@]}" Quit
        do
            case $REPLY in
                1) info; break;;
                2) clamscan; break;;
                3) commencement; break;;
                4) userCheck; break;;
                5) passwordChange; break;;
                6) setupEncryptedDirectory; break;;
                7) installConfigureOSSEC; break;;
                8) systemCleanup; break;;
                9) secureFTP; break;;
                10) configureRemote; break;;
                $((${#items[@]}+1))) echo "We're done!"; break 2;;
                *) echo "Unknown choice $REPLY"; break;
            esac
        done
    done
}

menu() {
    showLogo
    selectionScreen
}


main() {
    menu
}

main

