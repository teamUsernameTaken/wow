#!/bin/bash

closeOpenPorts() {
echo "Checking open ports..."
    
    # Get list of open ports using ss command
    local open_ports=$(ss -antp 2>/dev/null | grep LISTEN | awk '{print $4}' | cut -d':' -f2 | sort -u)
    
    if [ -z "$open_ports" ]; then
        echo "No open ports found."
        return
    fi

    # Prepare the options for whiptail
    local options=("ALL" "All Ports" OFF)
    
    while IFS= read -r port; do
        # Get process using this port
        local process=$(ss -antp 2>/dev/null | grep ":$port" | awk '{print $7}' | cut -d'"' -f2)
        [ -z "$process" ] && process="Unknown"
        options+=("$port" "Used by: $process" OFF)
    done <<< "$open_ports"

    # Display the whiptail checklist
    local selected_ports
    selected_ports=$(whiptail --title "Close Open Ports" \
        --checklist "Select ports to close (use SPACE to select):" \
        20 60 15 \
        "${options[@]}" \
        3>&1 1>&2 2>&3)

    # Check if user canceled the operation
    if [ $? -ne 0 ]; then
        echo "Operation canceled by the user."
        return
    fi

    # Remove quotes from the selected_ports string
    selected_ports=$(echo "$selected_ports" | tr -d '"')

    # Check if "ALL" is selected
    if [[ "$selected_ports" == *"ALL"* ]]; then
        selected_ports="$open_ports"
    else
        # Remove "ALL" from the selection if it's there
        selected_ports=$(echo "$selected_ports" | sed 's/ALL //')
    fi

    # Check if there are ports selected after processing
    if [ -z "$selected_ports" ]; then
        echo "No ports selected for closing."
        return
    fi

    # Close selected ports using UFW
    for port in $selected_ports; do
        if sudo ufw status | grep -q "^$port"; then
            echo "Port $port is already denied in UFW"
        else
            echo "Closing port $port..."
            sudo ufw deny "$port"
        fi
    done

    echo "Port closing operations completed."
    echo "Current UFW status:"
    sudo ufw status
}