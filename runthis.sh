configure_passwd_files() {
    echo "Configuring /etc/passwd and related files security..."

    # Backup critical files first
    local timestamp=$(date +%Y%m%d-%H%M%S)
    echo "Creating backups with timestamp: $timestamp"
    
    sudo cp /etc/passwd "/etc/passwd.backup-$timestamp"
    sudo cp /etc/shadow "/etc/shadow.backup-$timestamp"
    sudo cp /etc/group "/etc/group.backup-$timestamp"
    sudo cp /etc/gshadow "/etc/gshadow.backup-$timestamp"

    # Set correct permissions and ownership
    echo "Setting secure permissions and ownership..."
    
    # /etc/passwd configuration
    sudo chmod 644 /etc/passwd
    sudo chown root:root /etc/passwd
    
    # /etc/shadow configuration
    sudo chmod 600 /etc/shadow
    sudo chown root:shadow /etc/shadow
    
    # /etc/group configuration
    sudo chmod 644 /etc/group
    sudo chown root:root /etc/group
    
    # /etc/gshadow configuration
    sudo chmod 600 /etc/gshadow
    sudo chown root:shadow /etc/gshadow

    # Verify passwd file format and permissions
    echo "Performing security audit on passwd files..."
    {
        echo "=== Password Files Security Audit ==="
        echo "Generated on: $(date)"
        echo ""

        echo "1. Checking /etc/passwd permissions:"
        ls -l /etc/passwd
        
        echo -e "\n2. Checking /etc/shadow permissions:"
        ls -l /etc/shadow
        
        echo -e "\n3. Checking for duplicate UIDs:"
        awk -F: '{print $3}' /etc/passwd | sort -n | uniq -d
        
        echo -e "\n4. Checking for duplicate usernames:"
        awk -F: '{print $1}' /etc/passwd | sort | uniq -d
        
        echo -e "\n5. Checking for duplicate GIDs:"
        awk -F: '{print $3}' /etc/group | sort -n | uniq -d
        
        echo -e "\n6. Checking for users with UID 0 (should only be root):"
        awk -F: '($3 == 0) {print $1}' /etc/passwd
        
        echo -e "\n7. Checking for empty passwords:"
        sudo awk -F: '($2 == "") {print $1}' /etc/shadow
        
        echo -e "\n8. Checking for system accounts with login shells:"
        awk -F: '($3 < 1000 && $7 != "/usr/sbin/nologin" && $7 != "/bin/false") {print $1}' /etc/passwd

    } | sudo tee /var/log/passwd_audit.log

    # Fix common issues
    echo "Fixing common security issues..."

    # Ensure root is the only UID 0 account
    for user in $(awk -F: '($3 == 0 && $1 != "root") {print $1}' /etc/passwd); do
        echo "WARNING: User $user has UID 0! Please investigate immediately!"
    done

    # Ensure system accounts have nologin shell
    for user in $(awk -F: '($3 < 1000 && $7 != "/usr/sbin/nologin" && $7 != "/bin/false" && $1 != "root") {print $1}' /etc/passwd); do
        echo "Setting /usr/sbin/nologin shell for system user $user"
        sudo usermod -s /usr/sbin/nologin "$user"
    done

    # Lock any account with empty password
    for user in $(sudo awk -F: '($2 == "") {print $1}' /etc/shadow); do
        echo "Locking account with empty password: $user"
        sudo passwd -l "$user"
    done

    echo "Password files configuration completed."
    echo "Audit report saved to /var/log/passwd_audit.log"
    echo ""
    echo "Important actions taken:"
    echo "1. Created backups of critical files"
    echo "2. Set secure permissions and ownership"
    echo "3. Performed security audit"
    echo "4. Fixed common security issues"
    echo ""
    echo "Please review /var/log/passwd_audit.log for detailed findings"
}
