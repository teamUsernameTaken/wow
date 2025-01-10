#!/usr/bin/bash

#==========================================#
#          SCRIPT INITIALIZATION           #
#==========================================#
cd "$(dirname "$0")" || exit 1


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

#==========================================#
#          DISPLAY FUNCTIONS               #
#==========================================#

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

#==========================================#
#       INITIALIZATION FUNCTIONS           #
#==========================================#

commencement() {
    echo 'Welcome to the commencement script!'
    showLogo
    sudo bash commencementv2.sh
}


#==========================================#
#         SSH KEYS REMOVAL                #
#==========================================#

remove_ssh_keys() {
    echo "Removing SSH keys..."
    # Backup existing keys
    if [ -d ~/.ssh ]; then
        backup_dir=~/.ssh/backup_$(date +%Y%m%d_%H%M%S)
        mkdir -p "$backup_dir"
        cp ~/.ssh/id_* "$backup_dir/" 2>/dev/null || true
    fi
    
    # Remove all types of SSH keys
    rm -f ~/.ssh/id_*
    echo "SSH keys removed (backup created in $backup_dir if keys existed)"
}


#==========================================#
#      PASSWORD CHANGE FUNCTIONS          #
#==========================================#

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

#==========================================#
#     SYSTEM CLEANUP FUNCTIONS             #
#==========================================#

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

#==========================================#
#         MENU AND UI FUNCTIONS            #
#==========================================#
selectionScreen(){
    PS3="Select item please: "

    items=(
        "Info" 
        "Security Scan" 
        "Commencement"
        "Password Change" 
        "System Cleanup"
        "Run All Configs"
    )

    while true; do
        select item in "${items[@]}" Quit
        do
            case $REPLY in
                1) info; break;;
                2) scan; break;;
                3) commencement; break;;
                4) passwordChange; break;;
                5) systemCleanup; break;;
                6) sudo bash allConfigs.sh; break;;
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

#==========================================#
#        DEPENDENCY CHECK             #
#==========================================#
checkDependencies() {
    local required_scripts=(
        "allConfigs.sh"
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

#==========================================#
#           MAIN EXECUTION                 #
#==========================================#
main() {
    checkDependencies
    menu
}

main

