#!/bin/bash

USB_disable() {
    echo "Securing Remote Access..."

    # Disable unused USB ports
    echo "Disabling unused USB ports..."
    sudo tee /etc/modprobe.d/disable-usb.conf > /dev/null <<EOT
install usb-storage /bin/true
EOT
    sudo update-initramfs -u

    # Call the new SSH configuration function
    configureSSHPort

    echo "Remote Access security measures have been implemented."
}