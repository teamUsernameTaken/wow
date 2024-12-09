#!/bin/bash

#make sure to run this script as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

secureFTP() {
    echo "Securing FTP access..."
    
    # Install vsftpd if not present
    sudo apt-get install vsftpd -y
    
    # Backup original config
    sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
    
    # Configure secure settings
    sudo tee /etc/vsftpd.conf > /dev/null <<EOT
# Disable anonymous login
anonymous_enable=NO

# Enable local user login
local_enable=YES

# Enable write permissions for local users
write_enable=YES

# Chroot local users to their home directories
chroot_local_user=YES
allow_writeable_chroot=YES

# Use SSL
ssl_enable=YES
rsa_cert_file=/etc/ssl/private/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.pem

# Force SSL for both data and login
force_local_data_ssl=YES
force_local_logins_ssl=YES

# Passive mode configuration
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=50000

# Logging
xferlog_enable=YES
xferlog_std_format=YES
xferlog_file=/var/log/vsftpd.log
dual_log_enable=YES

# Add these important missing settings
listen=YES
listen_ipv6=NO
EOT

# Function to manage FTP access

    # Generate SSL certificate
    sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/vsftpd.pem \
        -out /etc/ssl/private/vsftpd.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

    # Restart vsftpd service
    sudo systemctl restart vsftpd
    
    echo "FTP has been secured with SSL/TLS and strict access controls"

    # Add error handling and checks
    # Check if vsftpd installation was successful
    if ! dpkg -l | grep -q vsftpd; then
        echo "Error: Failed to install vsftpd"
        return 1
    fi

    # Check if SSL directory exists, create if not
    sudo mkdir -p /etc/ssl/private
    sudo chmod 700 /etc/ssl/private

    # Add error handling for SSL certificate generation
    if ! sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/vsftpd.pem \
        -out /etc/ssl/private/vsftpd.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"; then
        echo "Error: SSL certificate generation failed"
        return 1
    fi

    # Check if service starts successfully
    if ! sudo systemctl restart vsftpd; then
        echo "Error: Failed to restart vsftpd service"
        sudo systemctl status vsftpd
        return 1
    fi
}

# Add main execution block
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    secureFTP
fi