#!/usr/bin/bash

PASSWORD="!@#123qweQWE"

info(){
echo -e "\n================\nTeam Number: 17-0197\nUID: WVV7-DSWG-7XYD\nDecryption Key:\n================\n"
}

notify(){
    echo "$1"
    notify-send "$1"
}

userCheck() {
  local NC='\033[0m'    # No Color
  local RED='\033[0;31m'

  local inputFile="allowedusers.txt"

  local normalUsers=()
  local adminUsers=()
  local unauthorizedUsers=()

  local systemUsers
  systemUsers=$(awk -F':' '($3 >= 1000 && $3 < 60000) {print $1}' /etc/passwd)

    if [[ ! -f "$inputFile" ]]; then
        echo "Error: Allowed users file '$inputFile' not found."
        exit 1
    fi

  # Loop through all normal users
  for user in $systemUsers; do
    if grep -qw "^${user}$" "$inputFile"; then
        # Determine if the user has admin privileges
        if groups "$user" | grep -qwE 'sudo|wheel'; then
            adminUsers+=("$user")
        else
            normalUsers+=("$user")
        fi
    else
        # Flag unauthorized users with a warning
        unauthorizedUsers+=("${RED}WARNING: USER: $user NOT IN allowedusers.txt${NC}")
    fi
  done

  # Normal Users
  echo -e "\nNormal Users:"
    if [[ ${#normalUsers[@]} -eq 0 ]]; then
        echo "  None"
    else
        for user in "${normalUsers[@]}"; do
            echo "  - $user"
        done
    fi

  # Admin Users
 echo "==============="

    echo "Admin Users:"
    if [[ ${#adminUsers[@]} -eq 0 ]]; then
        echo "  None"
    else
        for user in "${adminUsers[@]}"; do
            echo "  - $user"
        done
    fi

  # Unauthorized Users
    echo "==============="

    echo "Unauthorized Users:"
    if [[ ${#unauthorizedUsers[@]} -eq 0 ]]; then
        echo "  None"
    else
        for user in "${unauthorizedUsers[@]}"; do
            echo -e "  - $user"
        done
    fi

  # Display management options
  echo -e "\nUser Management Options:"
  echo "1. Change user permissions (normal ↔ admin)"
  echo "2. Remove user"
  echo "3. Add user to group"
  echo "4. Remove user from group"
  echo "5. Exit"

  read -p "Select an option (1-5): " choice

  case $choice in
    1)
      read -p "Enter username to modify: " username
      if id "$username" &>/dev/null; then
        if groups "$username" | grep -qwE 'sudo|wheel'; then
          # Remove from sudo group
          sudo gpasswd -d "$username" sudo
          echo "Removed admin privileges from $username"
        else
          # Add to sudo group
          sudo usermod -aG sudo "$username"
          echo "Granted admin privileges to $username"
        fi
      else
        echo "User $username does not exist"
      fi
      ;;
    2)
      read -p "Enter username to remove: " username
      if id "$username" &>/dev/null; then
        sudo userdel -r "$username"
        echo "Removed user $username"
      else
        echo "User $username does not exist"
      fi
      ;;
    3)
      read -p "Enter username: " username
      read -p "Enter group name: " groupname
      if id "$username" &>/dev/null; then
        if getent group "$groupname" >/dev/null; then
          sudo usermod -aG "$groupname" "$username"
          echo "Added $username to group $groupname"
        else
          echo "Group $groupname does not exist"
        fi
      else
        echo "User $username does not exist"
      fi
      ;;
    4)
      read -p "Enter username: " username
      read -p "Enter group name: " groupname
      if id "$username" &>/dev/null; then
        if getent group "$groupname" >/dev/null; then
          sudo gpasswd -d "$username" "$groupname"
          echo "Removed $username from group $groupname"
        else
          echo "Group $groupname does not exist"
        fi
      else
        echo "User $username does not exist"
      fi
      ;;
    5)
      echo "Exiting user management"
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
}

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

setupEncryptedDirectory() {
    echo "Setting up encrypted directory..."
    
    # Install ecryptfs-utils
    sudo apt install ecryptfs-utils -y
    
    # Create the directory to be encrypted
    sudo mkdir -p /encrypted    
    
    # Mount the encrypted directory
    sudo mount -t ecryptfs /encrypted /encrypted
    
    # The mount command will prompt for encryption options interactively
    # After setup, inform the user
    echo "Encrypted directory setup complete. It's mounted at /encrypted"
    echo "Remember your passphrase and encryption details for future access!"
}

commencementConfigureSSHD(){
  changeConfig "/etc/ssh/sshd_config" "PermitRootLogin" "no"
  changeConfig "/etc/ssh/sshd_config" "PermitEmptyPasswords" "no"
  changeConfig "/etc/ssh/sshd_config" "X11Forwarding" "no"
  changeConfig "/etc/ssh/sshd_config" "MaxAuthTries" "3"
  changeConfig "/etc/ssh/sshd_config" "ClientAliveInterval" "300"
  changeConfig "/etc/ssh/sshd_config" "ClientAliveCountMax" "2"
  changeConfig "/etc/ssh/sshd_config" "Port" "2222" # Maybe Change Later Depends
}

commencementUpdateAll(){
    #Update apt
    sudo apt update
    sudo apt upgrade -y

    #Update snap
    sudo snap refresh
    sudo killall snap-store
    sudo snap refresh
    notify 'Please open snap store now...'
    sleep 5
    notify 'Done!'
}

commencementInstallAll(){
    sudo apt update -y
    sudo apt autoremove -y

    local packages=(
        acl logwatch fail2ban auditd exiftool libpam-pwquality clamav
        apparmor apparmor-utils ufw gufw unattended-upgrades whiptail
        net-tools vsftpd vim rkhunter debsums exiftool
    )

    for package in "${packages[@]}"; do
        sudo apt install "$package" -y
    done
}

commencementUnattendedUpgrades(){
    # Enable unatended upgrades
    echo "Updating and upgrading the system..."
    sudo apt update && sudo apt upgrade -y
    echo "Installing unattended-upgrades, apt-listchanges, and bsd-mailx without configuration..."
    sudo apt install -y unattended-upgrades apt-listchanges bsd-mailx
    echo "Reconfiguring unattended-upgrades..."
    sudo dpkg-reconfigure -plow unattended-upgrades

    # dpkg-reconfigure unattended-upgrades
    # systemctl enable unattended-upgrades
    # systemctl start unattended-upgrades
}

commencementEnableAll() {
        local services=(
            ssh
            NetworkManager
            rsyslog
            systemd-journald
            systemd-timesyncd
            ntp
            apparmor
            cron
            apt-daily.timer
            apt-daily-upgrade.timer
            vsftpd
            unattended-upgrades

        )

        echo "Enabling and starting essential services..."
        for service in "${services[@]}"; do
            sudo systemctl enable "$service"
            if [[ $? -ne 0 ]]; then
                echo "Warning: Failed to enable $service." >&2
            fi

            sudo systemctl start "$service"
            if [[ $? -ne 0 ]]; then
                echo "Warning: Failed to start $service." >&2
            fi
        done
    }

## to fix: why bash script does not give points, but manually does?
commencementConfigureUfw() {
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    sudo systemctl enable ufw
    sudo systemctl start ufw
}

commencementConfigureJaill() {
  # Copy the default jail.conf to jail.local if it doesn't already exist
  if [ ! -f /etc/fail2ban/jail.local ]; then
      cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  fi

  edit_fail2ban_ssh() {
      # Check if the file exists
      if [ ! -f /etc/fail2ban/jail.local ]; then
          echo "Error: /etc/fail2ban/jail.local does not exist."
          return 1
      fi

      # Use sed to edit the [ssh] section
      sudo sed -i '/^\[ssh\]/,/^\[/ {
          s/^enabled *=.*/enabled = true/
          s/^port *=.*/port = ssh/
          s/^filter *=.*/filter = sshd/
          s/^logpath *=.*/logpath = \/var\/log\/auth.log/
          s/^maxretry *=.*/maxretry = 3/
          s/^bantime *=.*/bantime = 600/
      }' /etc/fail2ban/jail.local

      echo "The [ssh] section in /etc/fail2ban/jail.local has been updated."
  }

  # Run the function to edit the SSH section
  edit_fail2ban_ssh

  # Restart fail2ban to apply the changes
  sudo systemctl restart fail2ban
}

commencementChangePermissions(){
    # Remove immutable attribute if set
    sudo chattr -i /etc/passwd
    sudo chattr -i /etc/shadow
    sudo chattr -i /etc/sudoers
    
    sudo chmod 644 /etc/passwd
    sudo chmod 400 /etc/shadow
    sudo chmod 440 /etc/sudoers

    sudo passwd -l root
}

commencementConfigureJail(){
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    # Check if the file exists
    if [ ! -f /etc/fail2ban/jail.local ]; then
      notify "Jail config not found"
    else
        # Use sed to edit the [ssh] section
        sudo sed -i '/^\[ssh\]/,/^\[/ {
            s/^enabled *=.*/enabled = true/
            s/^port *=.*/port = ssh/
            s/^filter *=.*/filter = sshd/
            s/^logpath *=.*/logpath = \/var\/log\/auth.log/
            s/^maxretry *=.*/maxretry = 3/
            s/^bantime *=.*/bantime = 600/
            /^\[ssh\]/,/^\[/!d
        }' /etc/fail2ban/jail.local
        notify "Jail config complete!"
    fi
}
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

commencement() {
    echo 'Welcome to the commencement script!'
    
    PS3="Select configurations to run (select multiple, choose Done when finished): "
    
    options=(
        "Update All Systems"
        "Install Required Packages"
        "Enable Essential Services"
        "Configure UFW Firewall"
        "Change System Permissions"
        "Configure SSHD"
        "Configure Fail2ban Jail"
        "Configure Unattended Upgrades"
        "Run All"
        "Done"
    )
    
    selected=()
    
    while true; do
        select opt in "${options[@]}"
        do
            case $opt in
                "Run All")
                    commencementUpdateAll
                    commencementInstallAll
                    commencementEnableAll
                    commencementConfigureUfw
                    commencementChangePermissions
                    commencementConfigureSSHD
                    commencementConfigureJaill
                    commencementUnattendedUpgrades
                    break 2
                    ;;
                "Done")
                    # Execute selected configurations
                    for item in "${selected[@]}"; do
                        case $item in
                            "Update All Systems") commencementUpdateAll ;;
                            "Install Required Packages") commencementInstallAll ;;
                            "Enable Essential Services") commencementEnableAll ;;
                            "Configure UFW Firewall") commencementConfigureUfw ;;
                            "Change System Permissions") commencementChangePermissions ;;
                            "Configure SSHD") commencementConfigureSSHD ;;
                            "Configure Fail2ban Jail") commencementConfigureJaill ;;
                            "Configure Unattended Upgrades") commencementUnattendedUpgrades ;;
                        esac
                    done
                    break 2
                    ;;
                *)
                    if [[ " ${options[@]} " =~ " ${opt} " ]]; then
                        # Add to selected array if not already present
                        if [[ ! " ${selected[@]} " =~ " ${opt} " ]]; then
                            selected+=("$opt")
                            echo "Added: $opt"
                        fi
                    else
                        echo "Invalid option"
                    fi
                    break
                    ;;
            esac
        done
    done
}

installConfigureOSSEC() {
    echo "Installing and configuring OSSEC..."
    
    # Install prerequisites
    sudo apt-get install build-essential make gcc libevent-dev zlib1g-dev libssl-dev libpcre2-dev -y
    
    # Download and install OSSEC
    local ossec_version="3.6.0"
    wget "https://github.com/ossec/ossec-hids/archive/${ossec_version}.tar.gz"
    tar -zxvf "${ossec_version}.tar.gz"
    cd "ossec-hids-${ossec_version}" || exit
    
    # Create an auto-answer file for unattended installation
    cat > auto-install.conf << EOF
OSSEC_LANGUAGE="en"
OSSEC_USER="ossec"
OSSEC_USER_MAIL="root@localhost"
OSSEC_USER_ENABLE="y"
OSSEC_UPDATE="y"
OSSEC_SYSCHECK="y"
OSSEC_ROOTCHECK="y"
OSSEC_ACTIVE_RESPONSE="y"
OSSEC_MAIL_REPORT="n"
OSSEC_INSTALL_TYPE="local"
EOF
    
    # Run installation with auto-answer file
    sudo ./install.sh auto-install.conf
    
    # Configure OSSEC
    sudo tee -a /var/ossec/etc/ossec.conf > /dev/null <<EOT
<ossec_config>
  <syscheck>
    <frequency>7200</frequency>
    <directories check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories check_all="yes">/bin,/sbin</directories>
  </syscheck>

  <rootcheck>
    <frequency>7200</frequency>
  </rootcheck>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>
</ossec_config>
EOT
    
    # Start OSSEC
    sudo /var/ossec/bin/ossec-control start
    
    # Enable OSSEC to start on boot
    sudo systemctl enable ossec
    
    echo "OSSEC installation and configuration completed."
    echo "You can check OSSEC status with: sudo /var/ossec/bin/ossec-control status"
}

secureRemoteAccess() {
    echo "Securing Remote Access..."

    # Disable unused USB ports
    echo "Disabling unused USB ports..."
    sudo tee /etc/modprobe.d/disable-usb.conf > /dev/null <<EOT
install usb-storage /bin/true
EOT
    sudo update-initramfs -u
    # # Configure SSH to use a non-standard port
    # echo "Configuring SSH to use a non-standard port..."
    # local new_ssh_port=2222
    # sudo sed -i "s/^#Port 22/Port $new_ssh_port/" /etc/ssh/sshd_config

    echo "Remote Access security measures have been implemented."
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

selectionScreen(){
    PS3="Select item please: "

    items=(
        "Info" 
        "Clamscan" 
        "Commencement" 
        "User Check" 
        "Password Change" 
        "Run Background Tasks"
        "Setup Encrypted Directory"
        "Install and Configure OSSEC"
        "System Cleanup"
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
                6) runinBG; break;;
                7) setupEncryptedDirectory; break;;
                8) installConfigureOSSEC; break;;
                9) systemCleanup; break;;
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

