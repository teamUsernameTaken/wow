#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Function to prompt for confirmation
confirm() {
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

# Function to check if a service is already installed
check_installed() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Main configuration function
configure_all() {
    echo "Starting comprehensive system configuration for Linux Mint 21..."
    
    ###########################################
    #           BIND9 CONFIGURATION          #
    ###########################################
    if ! check_installed bind9; then
        if confirm "Install and configure BIND9 DNS server? [y/N]"; then
            # Install BIND9
            apt update
            apt install -y bind9 bind9utils bind9-doc
            
            # Backup original configuration
            cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup

            # Configure BIND9 options with security settings
            cat > /etc/bind/named.conf.options << EOF
options {
        directory "/var/cache/bind";
        
        // Restrict queries to localhost and internal network
        listen-on { 127.0.0.1; };
        listen-on-v6 { ::1; };
        
        // Disable recursive queries from external sources
        allow-recursion { 127.0.0.1; };
        allow-transfer { none; };
        
        // Enable DNSSEC
        dnssec-validation auto;
        
        // Disable zone transfers
        allow-transfer { none; };
        
        // Hide version number
        version none;
        
        // Additional security measures
        auth-nxdomain no;
        recursive-clients 10;
        
        // Prevent cache poisoning
        max-cache-size 2m;
        max-ncache-ttl 300;
        
        // Rate limiting
        rate-limit {
                responses-per-second 10;
                window 5;
        };
};
EOF

            # Configure default zones
            cat > /etc/bind/named.conf.local << EOF
// Prime the server with knowledge of the root servers
zone "." {
        type hint;
        file "/usr/share/dns/root.hints";
};

// Be authoritative for the localhost forward and reverse zones
zone "localhost" {
        type master;
        file "/etc/bind/db.local";
        allow-update { none; };
};

zone "127.in-addr.arpa" {
        type master;
        file "/etc/bind/db.127";
        allow-update { none; };
};
EOF

            # Set proper permissions
            chown -R bind:bind /etc/bind
            chmod -R 644 /etc/bind
            chmod 755 /etc/bind
            
            # Enable and restart BIND9
            systemctl enable named
            systemctl restart named

            echo "BIND9 installation and configuration completed."
            echo "Please review /etc/bind/named.conf.options for any needed customization."
        fi
    fi

    ###########################################
    #           APACHE CONFIGURATION         #
    ###########################################
    if ! check_installed apache2; then
        if confirm "Install and configure Apache? [y/N]"; then
            apt update
            apt install -y apache2 apache2-utils libapache2-mod-php
            
            # Enable required modules
            a2enmod ssl
            a2enmod rewrite
            a2enmod headers

            # Create web root directory with proper permissions
            mkdir -p /var/www/html
            chown -R www-data:www-data /var/www/html
            chmod -R 755 /var/www/html
            
            # Only generate SSL cert if it doesn't exist
            if [ ! -f "/etc/ssl/certs/apache-selfsigned.crt" ]; then
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout /etc/ssl/private/apache-selfsigned.key \
                    -out /etc/ssl/certs/apache-selfsigned.crt \
                    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
            fi

            # Configure Apache security settings
            cat > /etc/apache2/conf-available/security.conf << EOF
ServerTokens Prod
ServerSignature Off
TraceEnable Off
Header set X-Content-Type-Options nosniff
Header set X-Frame-Options SAMEORIGIN
Header set X-XSS-Protection "1; mode=block"
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
Header set Referrer-Policy "strict-origin-when-cross-origin"
Header set Permissions-Policy "geolocation=(), microphone=(), camera=()"
EOF
            a2enconf security
            systemctl restart apache2
            systemctl enable apache2
        fi
    fi

    ###########################################
    #            DNS CONFIGURATION           #
    ###########################################
    if confirm "Configure DNS settings? [y/N]"; then
        echo "Configuring DNS for Linux Mint..."
        cp /etc/resolv.conf /etc/resolv.conf.backup
        nmcli connection modify "$(nmcli -t -f NAME connection show --active)" ipv4.dns "8.8.8.8,8.8.4.4"
        systemctl restart NetworkManager
    fi

    ###########################################
    #          OSSEC CONFIGURATION          #
    ###########################################
    if ! check_installed ossec; then
        if confirm "Install OSSEC HIDS? [y/N]"; then
            apt-get install -y build-essential make gcc libevent-dev zlib1g-dev libssl-dev libpcre2-dev
            wget "https://github.com/ossec/ossec-hids/archive/3.6.0.tar.gz"
            tar -zxvf "3.6.0.tar.gz"
            cd "ossec-hids-3.6.0" || exit
            
            # Create auto-answer file
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
            ./install.sh auto-install.conf
            cd .. || exit
        fi
    fi

    ###########################################
    #            FTP CONFIGURATION           #
    ###########################################
    if check_installed vsftpd; then
        if confirm "Secure existing FTP server? [y/N]"; then
            cp /etc/vsftpd.conf /etc/vsftpd.conf.backup
            
            cat > /etc/vsftpd.conf << EOF
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
ssl_enable=YES
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem
force_local_data_ssl=YES
force_local_logins_ssl=YES
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000
xferlog_enable=YES
xferlog_std_format=YES
xferlog_file=/var/log/vsftpd.log
dual_log_enable=YES
listen=YES
listen_ipv6=NO
EOF

            # Generate SSL certificate if it doesn't exist
            if [ ! -f "/etc/ssl/private/vsftpd.pem" ]; then
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout /etc/ssl/private/vsftpd.pem \
                    -out /etc/ssl/private/vsftpd.pem \
                    -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
            fi

            systemctl restart vsftpd
        fi
    fi

    ###########################################
    #         SOURCES LIST UPDATE            #
    ###########################################
    if confirm "Update sources.list? [y/N]"; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
        # Update for Linux Mint 21 (based on Ubuntu 22.04)
        cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu jammy-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse
deb http://archive.canonical.com/ubuntu jammy partner
EOF
        apt update
    fi

    ###########################################
    #         USB PORT SECURITY              #
    ###########################################
    if confirm "Disable USB storage? This can be difficult to reverse. [y/N]"; then
        echo "install usb-storage /bin/true" > /etc/modprobe.d/disable-usb.conf
        update-initramfs -u
    fi

    ###########################################
    #         USER ACCOUNT AUDIT             #
    ###########################################
    if confirm "Run user account audit? [y/N]"; then
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

        echo "Audit report saved to /var/log/user_audit.log"
    fi

    ###########################################
    #      CRITICAL FILE PERMISSIONS         #
    ###########################################
    if confirm "Set strict permissions for critical system files? [y/N]"; then
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
    fi

    ###########################################
    #         PASSWORD POLICIES              #
    ###########################################
    if confirm "Configure enhanced password policies in login.defs? [y/N]"; then
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
    fi

    ###########################################
    #         PAM CONFIGURATION              #
    ###########################################
    if confirm "Configure advanced PAM password requirements? [y/N]"; then
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
    fi

    ###########################################
    #         ACCOUNT LOCKOUT                #
    ###########################################
    if confirm "Configure account lockout protection? [y/N]"; then
        sudo tee /etc/pam.d/common-auth > /dev/null <<EOT
auth    required    pam_tally2.so deny=5 unlock_time=1800 onerr=fail audit even_deny_root root_unlock_time=1800
auth    required    pam_faildelay.so delay=4000000
auth    [success=1 default=ignore]    pam_unix.so nullok
auth    requisite   pam_deny.so
auth    required    pam_permit.so
EOT
    fi

    echo "Configuration complete! Please review any error messages above."
    echo "Note: Some services may need to be restarted for changes to take effect."
}

# Run the main configuration
configure_all
