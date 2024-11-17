os="undeclared"

checkNetworkConnection() {
    echo "Checking network connectivity..."
    
    # Try to ping Google's DNS server
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        echo "No network connectivity detected. Attempting fixes..."
        
        # Check NetworkManager.conf
        local nm_conf="/etc/NetworkManager/NetworkManager.conf"
        if [ -f "$nm_conf" ]; then
            if grep -q "managed=false" "$nm_conf"; then
                echo "Found managed=false in NetworkManager.conf, changing to managed=true"
                sed -i 's/managed=false/managed=true/' "$nm_conf"
                systemctl restart NetworkManager
                sleep 5  # Give NetworkManager time to restart
                
                # Test connectivity again
                if ping -c 1 8.8.8.8 &> /dev/null; then
                    echo "Network connection restored!"
                    return 0
                fi
            fi
        fi
        
        # Additional network troubleshooting steps
        echo "Performing additional network diagnostics..."
        
        # Check if NetworkManager service is running
        if ! systemctl is-active NetworkManager &> /dev/null; then
            echo "NetworkManager is not running. Starting it..."
            systemctl start NetworkManager
        fi
        
        # Check interface status
        echo "Checking network interfaces..."
        ip link show
        
        # Try to bring up all interfaces
        for interface in $(ip -o link show | awk -F': ' '{print $2}'); do
            if [[ $interface != "lo" ]]; then
                echo "Attempting to bring up interface: $interface"
                ip link set $interface up
            fi
        fi
        
        # Final connectivity check
        if ! ping -c 1 8.8.8.8 &> /dev/null; then
            echo "WARNING: Network connectivity issues persist. Please check:"
            echo "1. Physical network connection"
            echo "2. DHCP server availability"
            echo "3. Network interface configuration"
            echo "4. DNS settings"
            return 1
        fi
    else
        echo "Network connectivity confirmed."
        return 0
    fi
}

commencementUbuntu(){
  # Check network connectivity before proceeding
  checkNetworkConnection || {
    echo "Network connectivity check failed."
    read -p "Would you like to continue anyway? (y/N): " response
    if [[ ! $response =~ ^[Yy]$ ]]; then
      return 1
    fi
  }

  # Confirm with the user that the sources are correct
  echo "Please ensure the /etc/apt/sources.list file is correct"
  read -p "Press Enter to continue"
  # Update everything
  apt update -y
  apt upgrade -y

  # Detect if snap is installed
  if command -v snap &>/dev/null; then
    echo "Detected snap!"
    # Update snap store
    snap refresh
    echo "Updated snap!"
  else
    echo "Did not detect snap skipping snap updates..."
  fi

  # Install required packages
  apt install unattended-upgrades -y
  apt install apt-listchanges -y
  apt install bsd-mailx -y
  apt install ufw -y
  apt install vim -y
  apt install libpam-pwquality -y
  apt install less -y
  apt install auditd logwatch fail2ban apparmor apparmor-utils whiptail -y
  
  # Enable unattended upgrades
  dpkg-reconfigure -plow unattended-upgrades

  # Enable and configure ufw
  ufw enable
  ufw default deny incoming
  ufw default allow outgoing
  

  # Check to see if sshd is installed
  if command -v sshd &>/dev/null; then
    echo "Detected sshd!"

    editSshdConfig(){
      local sshdConfig="/etc/ssh/sshd_config"
      local param="$1"
      local value="$2"
      
      # Check if the param already exists in the file
      if grep -q "^#*$param" "$sshdConfig"; then
        # Update the param
        sed -i "s/^#*\($param\s*\).*$/\1$value/" "$sshdConfig"
      else
        # Add the param
        echo "$param $value" | tee -a "$sshdConfig" > /dev/null
      fi
    }

    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    editSshdConfig "PermitRootLogin" "no"
    editSshdConfig "MaxAuthTries" "3"
    editSshdConfig "LoginGraceTime" "20"
    editSshdConfig "PermitEmptyPasswords" "no"
    editSshdConfig "ChallengeResponseAuthentication" "no"
    editSshdConfig "KerberosAuthentication" "no"
    editSshdConfig "GSSAPIAuthentication" "no"
    editSshdConfig "X11Forwarding" "no"
    editSshdConfig "PermitUserEnviroment" "no"
    editSshdConfig "AllowAgentForwarding" "no"
    editSshdConfig "AllowTcpForwarding" "no"
    editSshdConfig "PermitTunnel" "no"
    editSshdConfig "DebianBanner" "no"

    echo "Configured sshd!"

  fi


  # Ask to reboot now or later
  while true; do
    read -p "Reboot now to apply kernal updates? (y/n): " choice
    case "$choice" in
      [Yy] )
        echo "Rebooting now..."
        reboot
        break
        ;;
      [Nn] )
        echo "Skipping reboot, please reboot at the end..."
        sleep 1
        break
        ;;
      * )
        echo "Invalid option!"
        ;;
    esac
  done

  # Password requirements
  pamConfig="/etc/pam.d/common-password"
  echo "Backing up common-password..."
  cp "$pamConfig" "$pamConfig.bak"

  # Check if pam_pwquality.so is already in the configuration file
  if grep -q "pam_pwquality.so" "$pamConfig"; then
      # If pam_pwquality.so is found, modify it
      echo "Found pam_pwquality.so, updating its settings."
      
      # Update or add the necessary settings for pam_pwquality.so
      sudo sed -i 's/^.*pam_pwquality.so.*/password required pam_pwquality.so minlen=14 minclass=4 maxrepeat=3 maxsequence=3 enforce_for_root difok=4 retry=3/' "$pamConfig"
  else
      # If pam_pwquality.so is not found, add it as a new line with desired settings
      echo "pam_pwquality.so not found, adding it to the configuration."
      sudo sed -i '/password\s\+required\s\+pam_unix.so/a password required pam_pwquality.so minlen=14 minclass=4 maxrepeat=3 maxsequence=3 enforce_for_root difok=4 retry=3' "$pamConfig"
  fi

  # Check if pam_unix.so exists and add password history enforcement (e.g., remember=5)
  if ! grep -q "remember=5" "$pamConfig"; then
      echo "Enforcing password history: remember=5"
      sudo sed -i '/pam_unix.so/s/$/ remember=5/' "$pamConfig"
  fi

  echo "Finnished making changes to pam!"

  # Jail config

  # Copy the default jail.conf to jail.local if it doesn't already exist
  if [ ! -f /etc/fail2ban/jail.local ]; then
      cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
  fi

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


  # Change importiant file permissions

  # Remove immutable attribute if set
  sudo chattr -i /etc/passwd
  sudo chattr -i /etc/shadow
  sudo chattr -i /etc/sudoers
  
  sudo chmod 644 /etc/passwd
  sudo chmod 400 /etc/shadow
  sudo chmod 440 /etc/sudoers
  
  # Disable Root login
  sudo passwd -l root

  # Enable essential services
  systemctl enable --now ssh
  systemctl enable --now NetworkManager
  systemctl enable --now rsyslog
  systemctl enable --now systemd-journald
  systemctl enable --now systemd-timesyncd
  systemctl enable --now ntp
  systemctl enable --now apparmor
  systemctl enable --now cron
  systemctl enable --now apt-daily.timer
  systemctl enable --now apt-daily-upgrade.timer
  systemctl enable --now unattended-upgrades

  # Restart changed services
  systemctl restart fail2ban
  systemctl restart ssh
}

commencementFedora(){
  echo "Fedora stuff"
}

detectOs(){

   if [ -f /etc/os-release ]; then
        . /etc/os-release
        case $NAME in
            "Ubuntu")
                echo "detected os as ubuntu"
                os="ubuntu"
                commencementUbuntu
                read -p "Completed! Press any key to continue..."
                ;;
            "Fedora")
                echo "detected os as fedora"
                os="fedora"
                commencementFedora
                ;;
              *)
                echo "detected un-suppored os"
                os="invalid"
                echo "$NAME"
                exit 1
                ;;
        esac
    else
        echo "/etc/os-release file not found. Unable to detect distro."
    fi

}

main(){
  if [ $(id -u) -ne 0 ]; then
    echo "Script needs to be run as root!"
    exit 2
  fi
  commencementUbuntu
}

main
