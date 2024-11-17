#!/bin/bash

echo "Starting recovery process..."

# Stop BIND9 service
sudo systemctl stop bind9

# Remove BIND9 configuration files
sudo rm -f /etc/bind/named.conf.options
sudo rm -f /etc/bind/named.conf.local

# Create a basic default configuration
sudo cat > /etc/bind/named.conf.options << EOF
options {
        directory "/var/cache/bind";
        forwarders {
                8.8.8.8;
                8.8.4.4;
        };
        dnssec-validation auto;
        listen-on-v6 { any; };
};
EOF

# Restart networking and DNS services
sudo systemctl restart networking
sudo systemctl restart systemd-resolved
sudo systemctl restart bind9

# Reset DNS resolver configuration
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

echo "Recovery completed. Your system should work normally now."
