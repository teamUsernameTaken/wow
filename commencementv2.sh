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
  apt install vim -y
  apt install libpam-pwquality -y
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

  # This script needs to output to a temporary file first before piping to less
  # to preserve the color formatting
  TEMP_OUTPUT=$(mktemp)

  # Ensure temp file is removed on script exit
  trap "rm -f $TEMP_OUTPUT" EXIT

  # Set some color codes for better formatting
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  BLUE='\033[0;34m'
  YELLOW='\033[1;33m'
  NC='\033[0m' # No Color

  # Function to print section headers
  print_header() {
      echo -e "\n${RED}═══════════════════════════════════════════════════════════════════════════${NC}"
      echo -e "${YELLOW}   $1${NC}"
      echo -e "${RED}═══════════════════════════════════════════════════════════════════════════${NC}\n"
  }

  # Function to print subsection headers
  print_subheader() {
      echo -e "\n${BLUE}───────────────────────────────────────────────────────────────────────────${NC}"
      echo -e "${GREEN}   $1${NC}"
      echo -e "${BLUE}───────────────────────────────────────────────────────────────────────────${NC}\n"
  }

  {
      # Get system information
      print_header "SYSTEM INFORMATION"
      echo -e "Hostname: $(hostname)\n"
      echo -e "OS: $(lsb_release -d | cut -f2)\n"
      echo -e "Kernel: $(uname -r)\n"

      # Get installed packages
      print_header "INSTALLED PACKAGES"
      print_subheader "Total number of installed packages: $(dpkg --get-selections | wc -l)"
      dpkg-query -W -f='${Package}\t${Version}\t${Status}\n' | \
          grep "install ok installed" | \
          awk '{printf "%-40s %s\n\n", $1, $2}' | sort

      # Get all cron jobs
      print_header "CRON JOBS"

      # System-wide cron jobs
      print_subheader "System-wide cron jobs (/etc/crontab)"
      if [ -f /etc/crontab ]; then
          cat /etc/crontab | grep -v '^#' | grep -v '^$' | sed 's/$/\n/'
      else
          echo "No system-wide cron jobs found.\n"
      fi

      # System-wide cron directories
      print_subheader "System-wide cron directories (/etc/cron.*)"
      for CRONDIR in /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly; do
          if [ -d "$CRONDIR" ]; then
              echo -e "${GREEN}Contents of $CRONDIR:${NC}\n"
              ls -l "$CRONDIR" | grep -v '^total' | sed 's/$/\n/'
              echo
          fi
      done

      # User crontabs
      print_subheader "User crontabs"
      for USER in $(cut -f1 -d: /etc/passwd); do
          CRONTAB=$(crontab -u "$USER" -l 2>/dev/null)
          if [ $? -eq 0 ]; then
              echo -e "${GREEN}Crontab for user $USER:${NC}\n"
              echo "$CRONTAB" | grep -v '^#' | grep -v '^$' | sed 's/$/\n/'
              echo
          fi
      done

      # Get services
      print_header "SERVICES"

      # Systemd services
      print_subheader "Systemd Services Status"
      systemctl list-units --type=service --all | \
          grep -E '\.service' | \
          awk '{printf "%-40s %-10s %s\n\n", $1, $3, $4}'

      # Get running services
      print_subheader "Running Services"
      systemctl list-units --type=service --state=running | \
          grep -E '\.service' | \
          awk '{printf "%-40s %-10s %s\n\n", $1, $3, $4}'

      # Get failed services
      print_subheader "Failed Services"
      systemctl list-units --type=service --state=failed | \
          grep -E '\.service' | \
          awk '{printf "%-40s %-10s %s\n\n", $1, $3, $4}' || \
          echo "No failed services found.\n"

  } > "$TEMP_OUTPUT"

  # Pipe the output to less with RAW control chars preserved (-R)
  # and don't wrap long lines (-S)
  less -RS "$TEMP_OUTPUT"


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
  detectOs
}

main
