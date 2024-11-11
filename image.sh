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

# Call the installation function at startup
install_dependencies

# ... existing dependency check function ...

# New function for unpixelating/enhancing clarity
enhance_image() {
    local image=$1
    echo "Enhancing image clarity..."
    
    # Create enhanced versions with different algorithms
    convert "$image" -adaptive-sharpen 0x2 "enhanced_sharp_$image"
    convert "$image" -unsharp 0x5 "enhanced_unsharp_$image"
    convert "$image" -scale 400% -scale 25% "enhanced_scale_$image"
    
    # Advanced enhancement using multiple passes
    convert "$image" -modulate 100,150,100 \
        -unsharp 0x5 \
        -adaptive-sharpen 0x2 \
        -contrast-stretch 0.15x0.05% \
        "enhanced_complete_$image"
    
    echo "Created enhanced versions:"
    echo "- enhanced_sharp_$image (Basic sharpening)"
    echo "- enhanced_unsharp_$image (Unsharp mask)"
    echo "- enhanced_scale_$image (Scale method)"
    echo "- enhanced_complete_$image (Complete enhancement)"
}

# New function to analyze hex patterns
analyze_hex_patterns() {
    local image=$1
    local temp_hex="temp_hex_dump.txt"
    local output_file="suspicious_patterns.txt"
    
    echo "Analyzing hex patterns for suspicious sequences..."
    
    # Create hex dump
    xxd "$image" > "$temp_hex"
    
    # Initialize output file
    echo "=== Suspicious Pattern Analysis ===" > "$output_file"
    date >> "$output_file"
    echo "Analyzing: $image" >> "$output_file"
    echo "=================================" >> "$output_file"
    
    # Look for common patterns
    echo -e "\nRepeated sequences (42 42 42):" >> "$output_file"
    grep -n "42 42 42" "$temp_hex" >> "$output_file"
    
    echo -e "\nPossible file signatures:" >> "$output_file"
    grep -n "FF D8" "$temp_hex" >> "$output_file"  # JPEG
    grep -n "89 50 4E 47" "$temp_hex" >> "$output_file"  # PNG
    grep -n "47 49 46 38" "$temp_hex" >> "$output_file"  # GIF
    
    # Look for repeated byte sequences
    echo -e "\nRepeated byte sequences:" >> "$output_file"
    for pattern in "00 00 00 00" "FF FF FF FF" "AA AA AA AA" "55 55 55 55"; do
        echo "Checking pattern: $pattern" >> "$output_file"
        grep -n "$pattern" "$temp_hex" >> "$output_file"
    done
    
    # Look for potential ASCII text in hex
    echo -e "\nPotential ASCII text sequences:" >> "$output_file"
    strings "$temp_hex" | grep -i "secret\|pass\|key\|flag\|hidden" >> "$output_file"
    
    # Extract sections around suspicious patterns
    echo -e "\nExtracted contexts around suspicious patterns:" >> "$output_file"
    while IFS=: read -r line_num content; do
        if [[ $content =~ (42.*42.*42|FF.*D8|89.*50.*4E.*47) ]]; then
            echo -e "\nSuspicious pattern at line $line_num:" >> "$output_file"
            # Extract 5 lines before and after the pattern
            sed -n "$((line_num-5)),$((line_num+5))p" "$temp_hex" >> "$output_file"
        fi
    done < "$temp_hex"
    
    # Cleanup
    rm "$temp_hex"
    
    echo "Analysis complete. Results saved to $output_file"
    echo "Would you like to view the results now? (y/n)"
    read view_results
    if [ "$view_results" = "y" ]; then
        less "$output_file"
    fi
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
    echo "9. Exit"
    echo "================================="
    echo "Example: '1 3 4' will run options 1, 3, and 4"
}

# Modified main logic to handle multiple selections
while true; do
    show_menu
    read -p "Enter your choices (space-separated numbers): " -a choices
    
    # Exit if 9 is among the choices
    if [[ " ${choices[@]} " =~ " 9 " ]]; then
        echo "Exiting..."
        exit 0
    fi

    # Get image filename once for all operations
    read -p "Enter image filename: " image
    
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
            *)
                echo "Invalid option: $choice"
                ;;
        esac
    done
    
    read -p "Press Enter to continue..."
done
