#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to quarantine files by type
quarantine_files() {
    echo "Quarantining files by type..."
    read -p "Enter file type to quarantine (e.g., media, ssh): " file_type
    
    case $file_type in
        "media")
            mkdir -p /quarantine/media
            find / -type f -regex ".*\.\(jpg\|jpeg\|png\|mp4\|avi\|mp3\)" -exec mv {} /quarantine/media/ \;
            ;;
        "ssh")
            mkdir -p /quarantine/ssh
            find / -name "id_rsa*" -exec mv {} /quarantine/ssh/ \;
            ;;
        *)
            echo -e "${RED}Invalid file type${NC}"
            ;;
    esac
}

# Function to remove SSH keys
remove_ssh_keys() {
    echo "Removing SSH keys..."
    rm -f ~/.ssh/id_rsa*
    echo -e "${GREEN}SSH keys removed${NC}"
}

# Function to update DNS records
update_dns_records() {
    echo "Updating DNS records..."
    systemctl restart bind9
    rndc reload
}

# Function to migrate files
migrate_files() {
    echo "Migrating files..."
    read -p "Enter source directory: " source_dir
    read -p "Enter destination directory: " dest_dir
    
    if [ -d "$source_dir" ] && [ -d "$dest_dir" ]; then
        rsync -av "$source_dir" "$dest_dir"
    else
        echo -e "${RED}Invalid directories${NC}"
    fi
}

# Function to check bind9
check_bind9() {
    echo "Checking bind9 status..."
    named-checkconf
    systemctl status bind9
}


}

# Function to manage root UID access
manage_root_access() {
    echo "Managing root access..."
    read -p "Enter username: " username
    read -p "Grant root access? (y/n): " grant
    
    if [ "$grant" = "y" ]; then
        usermod -aG sudo "$username"
    else
        gpasswd -d "$username" sudo
    fi
}

# Main menu
while true; do
    clear
    echo "=== System Management Menu ==="
    echo "1. Quarantine files by type"
    echo "2. Remove SSH keys"
    echo "3. Update DNS records"
    echo "4. Migrate files"
    echo "5. Check bind9"
    echo "6. Manage FTP access"
    echo "7. Manage root access"
    echo "8. Exit"
    
    read -p "Enter your choice (1-8): " choice
    
    case $choice in
        1) quarantine_files ;;
        2) remove_ssh_keys ;;
        3) update_dns_records ;;
        4) migrate_files ;;
        5) check_bind9 ;;
        6) manage_ftp_access ;;
        7) manage_root_access ;;
        8) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
    
    read -p "Press Enter to continue..."
done
