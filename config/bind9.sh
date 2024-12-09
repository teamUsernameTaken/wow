#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# Check if BIND9 is already installed
if dpkg -l | grep -q bind9; then
    echo "BIND9 is already installed"
    echo "1. Reconfigure existing setup"
    echo "2. Apply security hardening"
    echo "3. Add/Modify zones"
    echo "4. Exit"
    read -p "Select an option: " choice

    case $choice in
        1)
            echo "Proceeding with reconfiguration..."
            ;;
        2)
            echo "Applying security hardening..."
            # Create a backup of the original config
            cp /etc/bind/named.conf.options /etc/bind/named.conf.options.backup
            
            # Hide version number and disallow zone transfers with less restrictive settings
            cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    
    # More permissive ACL
    acl "trusted" {
        localhost;
        localnets;
        any;
    };
    
    allow-recursion { trusted; };
    allow-query { trusted; };
    allow-transfer { none; };
    version none;
    
    # Basic rate limiting
    rate-limit {
        responses-per-second 20;
        window 5;
    };

    # More reasonable cache settings
    max-cache-size 128M;
    max-cache-ttl 86400;
    max-ncache-ttl 3600;
    
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
};
EOF
            # Restart BIND9 safely
            systemctl restart bind9 || {
                echo "Error restarting BIND9, rolling back changes..."
                mv /etc/bind/named.conf.options.backup /etc/bind/named.conf.options
                systemctl restart bind9
            }
            
            # Verify BIND9 is running
            if systemctl is-active --quiet bind9; then
                echo "Security hardening completed successfully"
            else
                echo "Warning: BIND9 service is not running. Check logs with 'journalctl -xe'"
            fi
            ;;
        3)
            echo "Current zones:"
            grep "zone" /etc/bind/named.conf.local
            echo ""
            read -p "Enter domain name for new zone (or press enter to skip): " domain
            if [ ! -z "$domain" ]; then
                read -p "Enter IP address for $domain: " ip
                # Create zone files and add configuration
                # ... (zone creation code here)
            fi
            ;;
        4)
            exit 0
            ;;
    esac

else
    # Original installation code
    echo "Installing BIND9..."
    apt-get update
    apt-get install -y bind9 bind9utils bind9-doc

    # Check if directories exist
    [ ! -d "/etc/bind/zones" ] && mkdir -p /etc/bind/zones

    # Create initial secure configuration
    cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    recursion yes;
    allow-recursion { trusted; };
    allow-transfer { none; };
    version none;
    hostname none;
    server-id none;
    
    acl "trusted" {
        localhost;
        localnets;
    };
    
    rate-limit {
        responses-per-second 10;
        window 5;
    };

    max-cache-size 256M;
    max-cache-ttl 86400;
    max-ncache-ttl 3600;
    
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };
};
EOF

    # Check if zone files exist before creating
    if [ ! -f "/etc/bind/zones/db.forward" ]; then
        cat > /etc/bind/zones/db.forward << EOF
\$TTL    604800
@       IN      SOA     ns1.example.com. admin.example.com. (
                     $(date +%Y%m%d)01   ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.example.com.
@       IN      A       192.168.1.10    ; Replace with your server IP
ns1     IN      A       192.168.1.10    ; Replace with your server IP
EOF
    fi

    # Set proper permissions
    chown -R bind:bind /etc/bind/zones
    chmod -R 755 /etc/bind/zones

    # Configure logging
    cat >> /etc/bind/named.conf.local << EOF
logging {
    channel security_file {
        file "/var/log/bind/security.log" versions 3 size 30m;
        severity dynamic;
        print-time yes;
    };
    category security {
        security_file;
    };
};
EOF

    # Create log directory if it doesn't exist
    mkdir -p /var/log/bind
    chown bind:bind /var/log/bind

    # Restart and check status
    systemctl restart bind9
    if systemctl is-active --quiet bind9; then
        echo "BIND9 installation and configuration completed successfully"
    else
        echo "Error: BIND9 failed to start. Check logs with 'journalctl -xe'"
    fi
fi

# Final security checks
echo "Performing security checks..."
named-checkconf
echo "Checking zone files..."
for zone in /etc/bind/zones/db.*; do
    if [ -f "$zone" ]; then
        named-checkzone $(basename "$zone") "$zone"
    fi
done
