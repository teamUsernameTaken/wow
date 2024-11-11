#!/bin/bash

# Function to install all required dependencies
install_dependencies() {
    echo "Checking and installing required dependencies..."
    
    # Check for package manager
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
    else
        echo "Error: Neither apt nor yum package manager found"
        exit 1
    fi

    # List of required packages
    REQUIRED_PACKAGES=(
        "imagemagick"    # For image manipulation
        "exiftool"       # For metadata extraction
        "ruby"           # For zsteg
        "python3"        # For stegano
        "python3-pip"    # For Python packages
        "hexedit"        # For hex editing
    )

    # Check and install each package
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            echo "Installing $package..."
            sudo $PKG_MANAGER install -y "$package"
        fi
    done

    # Install Python packages
    echo "Installing Python packages..."
    pip3 install stegano

    # Install Ruby gems
    echo "Installing Ruby gems..."
    if ! command -v zsteg >/dev/null 2>&1; then
        sudo gem install zsteg
    fi

    # Check ImageMagick policy to ensure it can process PDF files
    if [ -f "/etc/ImageMagick-6/policy.xml" ]; then
        sudo sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml
    fi

    echo "All dependencies installed successfully!"
}

# Modified menu display function
show_menu() {
    clear
    echo "=== Image Steganography Analysis Tool ==="
    echo "Select multiple options (space-separated numbers):"
    echo "1. Extract Metadata (ExifTool)"
    echo "2. Analyze with zsteg"
    echo "3. Extract Hidden Text (strings)"
    echo "4. Analyze Color Channels"
    echo "5. Check LSB Steganography"
    echo "6. Examine with Hex Editor"
    echo "7. Apply Image Filters"
    echo "8. Enhance Image Clarity"
    echo "9. Install/Update Dependencies"
    echo "10. Exit"
    echo "================================="
    echo "Example: '1 3 4' will run options 1, 3, and 4"
}

# Add this function before the main loop
analyze_hex_patterns() {
    local image="$1"
    echo "Analyzing hex patterns in $image..."
    
    # Look for common file signatures and suspicious patterns
    echo "Common file signatures:"
    xxd -l 32 "$image"  # Show first 32 bytes
    
    echo -e "\nSearching for suspicious patterns..."
    # Search for specific hex patterns (examples: PNG, JPEG, ZIP headers)
    hexdump -C "$image" | grep -E "89 50 4e 47|ff d8 ff|50 4b 03 04" || echo "No common file headers found"
    
    # Count and display frequency of byte values
    echo -e "\nByte frequency analysis (top 10 most common):"
    xxd -p "$image" | tr -d '\n' | grep -o .. | sort | uniq -c | sort -rn | head -n 10
}

# Modified main logic to handle multiple selections
while true; do
    show_menu
    read -p "Enter your choices (space-separated numbers): " -a choices
    
    # Exit if 10 is among the choices
    if [[ " ${choices[@]} " =~ " 10 " ]]; then
        echo "Exiting..."
        exit 0
    fi

    # Process each selected option
    for choice in "${choices[@]}"; do
        echo -e "\n=== Processing option $choice ==="
        case $choice in
            1)
                echo "Extracting metadata..."
                exiftool "$image"
                ;;
            2)
                if command -v zsteg >/dev/null 2>&1; then
                    echo "Analyzing with zsteg..."
                    zsteg -a "$image"
                else
                    echo "zsteg not installed. Would you like to install it? (y/n)"
                    read install
                    if [ "$install" = "y" ]; then
                        sudo apt install ruby
                        sudo gem install zsteg
                        zsteg -a "$image"
                    fi
                fi
                ;;
            3)
                echo "Extracting hidden text..."
                strings "$image" | less
                ;;
            4)
                echo "Splitting color channels..."
                convert "$image" -channel R -separate "red_channel_$image"
                convert "$image" -channel G -separate "green_channel_$image"
                convert "$image" -channel B -separate "blue_channel_$image"
                echo "Created: red_channel_$image, green_channel_$image, blue_channel_$image"
                ;;
            5)
                if command -v python3 >/dev/null 2>&1; then
                    if python3 -c "import stegano" 2>/dev/null; then
                        echo "Checking LSB steganography..."
                        python3 -c "from stegano import lsb; print(lsb.reveal('$image'))"
                    else
                        echo "Stegano not installed. Would you like to install it? (y/n)"
                        read install
                        if [ "$install" = "y" ]; then
                            pip install stegano
                            python3 -c "from stegano import lsb; print(lsb.reveal('$image'))"
                        fi
                    fi
                fi
                ;;
            6)
                echo "Examining hex patterns..."
                if command -v hexedit >/dev/null 2>&1; then
                    echo "1. Open in hex editor"
                    echo "2. Analyze suspicious patterns"
                    echo "3. Both"
                    read -p "Choose an option (1-3): " hex_choice
                    case $hex_choice in
                        1)
                            hexedit "$image"
                            ;;
                        2)
                            analyze_hex_patterns "$image"
                            ;;
                        3)
                            analyze_hex_patterns "$image"
                            hexedit "$image"
                            ;;
                        *)
                            echo "Invalid choice"
                            ;;
                    esac
                else
                    echo "Hexedit not installed. Would you like to install it? (y/n)"
                    read install
                    if [ "$install" = "y" ]; then
                        sudo apt install hexedit
                        hexedit "$image"
                    fi
                fi
                ;;
            7)
                echo "Applying filters..."
                convert "$image" -contrast -contrast "high_contrast_$image"
                convert "$image" -negate "inverted_$image"
                echo "Created: high_contrast_$image, inverted_$image"
                ;;
            8)
                enhance_image "$image"
                ;;
            9)
                install_dependencies
                ;;
            *)
                echo "Invalid option: $choice"
                ;;
        esac
    done
    
    read -p "Press Enter to continue..."
done
