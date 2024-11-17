#!/bin/bash

setupApache() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"
        exit 1
    fi

    # Check if Apache is already installed
    if ! command -v apache2 &> /dev/null; then
        echo "Installing Apache..."
        apt-get update && apt-get install -y apache2
    else
        echo "Apache is already installed"
    fi

    # Enable required modules
    a2enmod ssl
    a2enmod rewrite

    # Create default SSL certificate if it doesn't exist
    if [ ! -f "/etc/ssl/certs/apache-selfsigned.crt" ]; then
        echo "Generating self-signed SSL certificate..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/ssl/private/apache-selfsigned.key \
            -out /etc/ssl/certs/apache-selfsigned.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    fi

    # Configure Apache security settings
    echo "Configuring security settings..."
    cat > /etc/apache2/conf-available/security.conf << EOF
ServerTokens Prod
ServerSignature Off
TraceEnable Off
Header set X-Content-Type-Options nosniff
Header set X-Frame-Options SAMEORIGIN
Header set X-XSS-Protection "1; mode=block"
EOF

    # Enable security configuration
    a2enconf security

    # Restart Apache to apply changes
    systemctl restart apache2

    # Enable Apache to start on boot
    systemctl enable apache2

    echo "Apache setup complete!"
    echo "Default website is available at http://localhost"
    echo "SSL website is available at https://localhost"
}

# Run the main function
setupApache
