#!/bin/bash

configure_ubuntu_dns() {
    echo "Configuring DNS for Ubuntu..."
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
    sudo sh -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
    sudo systemctl restart systemd-resolved
    echo "Ubuntu DNS configuration completed"
}

configure_mint_dns() {
    echo "Configuring DNS for Linux Mint..."
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    sudo nmcli connection modify "$(nmcli -t -f NAME connection show --active)" ipv4.dns "8.8.8.8,8.8.4.4"
    sudo systemctl restart NetworkManager
    echo "Linux Mint DNS configuration completed"
}

configure_debian_dns() {
    echo "Configuring DNS for Debian..."
    sudo cp /etc/resolv.conf /etc/resolv.conf.backup
    sudo sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
    sudo sh -c 'echo "nameserver 8.8.4.4" >> /etc/resolv.conf'
    sudo chattr +i /etc/resolv.conf  # Make file immutable to prevent overwriting
    echo "Debian DNS configuration completed"
}

# Detect distribution and run appropriate function
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
        "ubuntu")
            configure_ubuntu_dns
            ;;
        "linuxmint")
            configure_mint_dns
            ;;
        "debian")
            configure_debian_dns
            ;;
        *)
            echo "Unsupported distribution: $ID"
            exit 1
            ;;
    esac
else
    echo "Could not determine distribution"
    exit 1
fi
