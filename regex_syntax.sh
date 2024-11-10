#!/bin/bash

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to generate a string matching regex pattern
generate_string() {
    local pattern="$1"
    # Using grep to validate the pattern
    if ! echo "test" | grep -E "$pattern" >/dev/null 2>&1; then
        echo -e "${RED}Invalid regex pattern${NC}"
        return 1
    fi

    # For complex patterns, we'll use a more comprehensive character set
    local chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?/ '
    local length=50  # Increased default length for complex patterns
    local max_attempts=1000
    local attempt=0
    local result=""
    
    while ! echo "$result" | grep -E "^$pattern$" >/dev/null 2>&1; do
        result=""
        for ((i=0; i<length; i++)); do
            result+="${chars:RANDOM%${#chars}:1}"
        done
        
        ((attempt++))
        if ((attempt >= max_attempts)); then
            echo -e "${RED}Failed to generate matching string after $max_attempts attempts${NC}"
            return 1
        fi
    done
    
    echo -e "${GREEN}Generated string:${NC} $result"
}

# Function to decode/analyze a string
decode_string() {
    local input_string="$1"
    echo -e "${GREEN}String analysis:${NC}"
    echo "Length: ${#input_string}"
    echo "Contains digits: $(echo "$input_string" | grep -E '[0-9]' >/dev/null && echo "Yes" || echo "No")"
    echo "Contains uppercase: $(echo "$input_string" | grep -E '[A-Z]' >/dev/null && echo "Yes" || echo "No")"
    echo "Contains lowercase: $(echo "$input_string" | grep -E '[a-z]' >/dev/null && echo "Yes" || echo "No")"
    echo "Contains special chars: $(echo "$input_string" | grep -E '[^a-zA-Z0-9]' >/dev/null && echo "Yes" || echo "No")"
    echo "Matches common patterns:"
    [[ "$input_string" =~ ^[0-9]+$ ]] && echo "- Numbers only"
    [[ "$input_string" =~ ^[A-Za-z]+$ ]] && echo "- Letters only"
    [[ "$input_string" =~ ^[A-Z][a-z]+$ ]] && echo "- Capitalized word"
    [[ "$input_string" =~ ^[A-Za-z0-9]+$ ]] && echo "- Alphanumeric"
    [[ "$input_string" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && echo "- Email format"
}

# Main menu
while true; do
    echo -e "\n${GREEN}Regex String Tool${NC}"
    echo "1. Generate string from regex"
    echo "2. Decode/analyze string"
    echo "3. Exit"
    read -p "Choose an option (1-3): " choice

    case $choice in
        1)
            read -p "Enter regex pattern: " pattern
            generate_string "$pattern"
            ;;
        2)
            read -p "Enter string to analyze: " input_string
            decode_string "$input_string"
            ;;
        3)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done
