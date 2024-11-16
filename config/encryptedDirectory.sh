#!/bin/bash

setupEncryptedDirectory() {
    local mount_point
    local encrypted_dir

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"
        exit 1
    }

    # Check if ecryptfs-utils is installed
    if ! command -v ecryptfs-manager &> /dev/null; then
        echo "Installing ecryptfs-utils..."
        apt-get update && apt-get install -y ecryptfs-utils
    fi

    # Prompt for directory locations
    read -p "Enter the path for the encrypted directory: " encrypted_dir
    read -p "Enter the mount point: " mount_point

    # Create directories if they don't exist
    mkdir -p "$encrypted_dir"
    mkdir -p "$mount_point"

    # Set up the encrypted directory
    echo "Setting up encrypted directory..."
    mount -t ecryptfs "$encrypted_dir" "$mount_point"

    # Configure encryption options
    echo "Please select the following options when prompted:"
    echo "1. aes for cipher"
    echo "2. 16 bytes for key length"
    echo "3. Yes to enable filename encryption"
    echo "4. Yes to add the mount to fstab"

    # Add mount entry to /etc/fstab for persistence
    echo "Adding mount entry to /etc/fstab..."
    echo "$encrypted_dir $mount_point ecryptfs defaults 0 0" >> /etc/fstab

    # Set appropriate permissions
    chown -R "$SUDO_USER:$SUDO_USER" "$encrypted_dir"
    chown -R "$SUDO_USER:$SUDO_USER" "$mount_point"
    chmod 700 "$encrypted_dir"
    chmod 700 "$mount_point"

    echo "Encrypted directory setup complete!"
    echo "Your encrypted directory is at: $encrypted_dir"
    echo "Mount point is at: $mount_point"
    echo "Please keep your encryption passphrase safe. If you lose it, you cannot recover your data!"
}

# Run the main function
setupEncryptedDirectory