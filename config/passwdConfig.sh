#!/bin/bash

secure_passwd_config() {
    echo "Starting comprehensive password and authentication security configuration..."

    # Function to backup files with timestamp
    backup_file() {
        local file="$1"
        local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
        if sudo cp "$file" "$backup"; then
            echo "Created backup: $backup"
        else
            echo "Failed to backup $file - aborting for safety"
            exit 1
        fi
    }

    # Backup critical files
    echo "Creating backups of critical files..."
    critical_files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/login.defs"
        "/etc/pam.d/common-password"
        "/etc/pam.d/common-auth"
        "/etc/security/pwquality.conf"
    )

    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            backup_file "$file"
        else
            echo "Warning: $file not found!"
        fi
    done

    # Set strict permissions
    echo "Setting secure file permissions..."
    permission_settings=(
        "/etc/passwd:644:root:root"
        "/etc/shadow:600:root:shadow"
        "/etc/gshadow:600:root:shadow"
        "/etc/group:644:root:root"
        "/etc/login.defs:644:root:root"
        "/etc/passwd-:600:root:root"
        "/etc/shadow-:600:root:shadow"
        "/etc/group-:600:root:root"
    )

    for setting in "${permission_settings[@]}"; do
        IFS=: read -r file mode owner group <<< "$setting"
        if [ -f "$file" ]; then
            sudo chmod "$mode" "$file"
            sudo chown "$owner:$group" "$file"
            echo "Secured $file"
        fi
    done

    # Enhanced password policies in login.defs
    echo "Configuring enhanced password policies..."
    login_defs_settings=(
        "PASS_MAX_DAYS   60"
        "PASS_MIN_DAYS   7"
        "PASS_WARN_AGE   14"
        "UMASK           027"
        "ENCRYPT_METHOD  SHA512"
        "SHA_CRYPT_MIN_ROUNDS 5000"
        "SHA_CRYPT_MAX_ROUNDS 100000"
        "FAIL_DELAY      4"
    )

    for setting in "${login_defs_settings[@]}"; do
        key=$(echo "$setting" | awk '{print $1}')
        if grep -q "^${key}" /etc/login.defs; then
            sudo sed -i "s/^${key}.*/${setting}/" /etc/login.defs
        else
            echo "$setting" | sudo tee -a /etc/login.defs
        fi
    done

    # Configure advanced PAM password requirements
    echo "Configuring advanced PAM password requirements..."
    sudo tee /etc/pam.d/common-password > /dev/null <<EOT
# Enforce strong password policy
password    requisite     pam_pwquality.so retry=3 minlen=14 difok=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 reject_username enforce_for_root maxrepeat=3 gecoscheck=1 dictcheck=1

# Use SHA512 for password hashing
password    [success=1 default=ignore]      pam_unix.so obscure use_authtok try_first_pass sha512 rounds=65536 remember=5

# Prevent password reuse
password    required      pam_pwhistory.so  remember=5 use_authtok

password    requisite     pam_deny.so
password    required      pam_permit.so
EOT

    # Configure account lockout and brute force protection
    echo "Configuring account lockout protection..."
    sudo tee /etc/pam.d/common-auth > /dev/null <<EOT
auth    required    pam_tally2.so deny=5 unlock_time=1800 onerr=fail audit even_deny_root root_unlock_time=1800
auth    required    pam_faildelay.so delay=4000000
auth    [success=1 default=ignore]    pam_unix.so nullok
auth    requisite   pam_deny.so
auth    required    pam_permit.so
EOT

    # Enhanced pwquality configuration
    echo "Configuring advanced password quality requirements..."
    sudo tee /etc/security/pwquality.conf > /dev/null <<EOT
# Password length and complexity
minlen = 14
dcredit = -1
ucredit = -1
lcredit = -1
ocredit = -1
minclass = 4

# Password strength and reuse
difok = 3
maxrepeat = 3
gecoscheck = 1
dictcheck = 1
enforcing = 1
retry = 3
EOT

    # Audit user accounts
    echo "Performing comprehensive user account audit..."
    {
        echo "=== User Account Audit Report ==="
        echo "Generated on: $(date)"
        echo
        
        echo "1. Users with UID 0 (should only be root):"
        awk -F: '($3 == 0) {print $1}' /etc/passwd
        
        echo -e "\n2. System accounts with login shells:"
        awk -F: '($3 < 1000 && $7 != "/usr/sbin/nologin" && $7 != "/bin/false") {print $1 ": " $7}' /etc/passwd
        
        echo -e "\n3. User accounts with empty passwords:"
        sudo awk -F: '($2 == "" || $2 == "!") {print $1}' /etc/shadow
        
        echo -e "\n4. Users with duplicate UIDs:"
        sudo awk -F: '{print $3}' /etc/passwd | sort -n | uniq -d
        
        echo -e "\n5. Users with duplicate usernames:"
        sudo awk -F: '{print $1}' /etc/passwd | sort | uniq -d
        
        echo -e "\n6. Home directories with incorrect permissions:"
        for dir in /home/*; do
            if [ -d "$dir" ]; then
                perms=$(stat -c "%a" "$dir")
                if [ "$perms" != "750" ] && [ "$perms" != "700" ]; then
                    echo "$dir: $perms"
                fi
            fi
        done
    } | sudo tee /var/log/user_audit.log

    echo "Password and authentication security configuration completed."
    echo "Detailed audit report saved to /var/log/user_audit.log"
    echo
    echo "Important: Review the audit report and address any findings."
    echo "A system reboot may be required for all changes to take effect."
}