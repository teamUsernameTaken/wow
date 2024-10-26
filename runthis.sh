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
        net-tools vsftpd vim rkhunter debsums
    )

    for package in "${packages[@]}"; do
        sudo apt install "$package" -y
    done
}

 ##
 ## DYLAN, THERE IS AN ISSUE: cursor is telling me that the } at the bottom of clamscan is not matching with the one at the start of the function. Is yours working or is it ok? Lemme know, i commented it out for now. 
 ##
# runinBG {
#     clamscan(){
#     apt update
#     freshclam
#     clamscan -r --infected --bell /
#     clamscan -r /home /etc /tmp --move=/var/virusquarantine
#     }

#     rkhunter(){
        
#     }

#     debsums(){
#         sudo debsums -c
#     }
#     }

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
    echo 'Welcome to the commencement script! Please be patient as this may take a while... (not)'
    commencementUpdateAll
    commencementInstallAll
    commencementEnableAll
    commencementConfigureUfw
    commencementChangePermissions
    commencementConfigureSSHD
    commencementConfigureJaill
    commencementUnattendedUpgrades
}

installConfigureOSSEC() {
    echo "Installing and configuring OSSEC..."
    
    # Download and install OSSEC
    local ossec_version="3.6.0"
    wget "https://github.com/ossec/ossec-hids/archive/${ossec_version}.tar.gz"
    tar -zxvf "${ossec_version}.tar.gz"
    cd "ossec-hids-${ossec_version}" || exit
    sudo ./install.sh
    
    # Configure OSSEC
    sudo tee -a /var/ossec/etc/ossec.conf > /dev/null <<EOT
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/auth.log</location>
</localfile>
EOT
    
    # Restart OSSEC
    sudo /var/ossec/bin/ossec-control restart
    
    echo "OSSEC installation and configuration completed."
}

secureRemoteAccess() {
    echo "Securing Remote Access..."

    # Disable unused USB ports
    echo "Disabling unused USB ports..."
    sudo tee /etc/modprobe.d/disable-usb.conf > /dev/null <<EOT
install usb-storage /bin/true
EOT
    sudo update-initramfs -u

    # # Configure SSH key-based authentication
    # echo "Configuring SSH key-based authentication..."
    # sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    # sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

    # # Enable SSH two-factor authentication
    # echo "Enabling SSH two-factor authentication..."
    # sudo apt install -y libpam-google-authenticator
    # sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    # sudo sed -i '/@include common-auth/a auth required pam_google_authenticator.so' /etc/pam.d/sshd

    # # Configure SSH to use a non-standard port
    # echo "Configuring SSH to use a non-standard port..."
    # local new_ssh_port=2222
    # sudo sed -i "s/^#Port 22/Port $new_ssh_port/" /etc/ssh/sshd_config

    # # Implement IP whitelisting for SSH
    # echo "Implementing IP whitelisting for SSH..."
    # echo "AllowUsers *@192.168.1.0/24" | sudo tee -a /etc/ssh/sshd_config

    # # Enable SSH connection multiplexing
    # echo "Enabling SSH connection multiplexing..."
    # echo "MaxSessions 10" | sudo tee -a /etc/ssh/sshd_config

    # Restart SSH service
    sudo systemctl restart ssh

    echo "Remote Access security measures have been implemented."
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

