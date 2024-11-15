os="undeclared"

commencementUbuntu(){
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
  
  # Enable unattended upgrades
  dpkg-reconfigure -plow unattended-upgrades

  # Enable and configure ufw
  ufw enable
  ufw default deny incomming
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

  fi


  # Ask to reboot now or later
  notify-send "Commencement V2: Completed updates please confirm reboot"
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
  detectOs
}

main
