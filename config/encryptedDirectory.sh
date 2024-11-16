#!/bin/bash

setupEncryptedDirectory() {
    echo "Setting up encrypted directory..."
    
    # Install ecryptfs-utils
    sudo apt install ecryptfs-utils -y
    
    # Create the directory to be encrypted
    sudo mkdir -p /encrypted    
    
    # Mount the encrypted directory
    sudo mount -t ecryptfs /encrypted /encrypted
    
    # The mount command will prompt for encryption options interactively
    # After setup, inform the user
    echo "Encrypted directory setup complete. It's mounted at /encrypted"
    echo "Remember your passphrase and encryption details for future access!"
}