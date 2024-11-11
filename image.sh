#!/bin/bash

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
                if command -v hexedit >/dev/null 2>&1; then
                    hexedit "$image"
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
