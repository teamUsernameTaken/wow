#!/bin/bash

check_apparmor() {
    echo "Checking AppArmor status:"
    if ! sudo aa-status; then
        echo "Error: Unable to check AppArmor status"
    fi
    echo "Look for: Enabled profiles and any reported errors"
}

start_enable_auditd() {
    echo "Starting and enabling auditd:"
    if ! sudo systemctl start auditd; then
        echo "Error: Unable to start auditd"
    fi
    if ! sudo systemctl enable auditd; then
        echo "Error: Unable to enable auditd"
    fi
}

check_avc_messages() {
    echo "Checking for AVC messages:"
    sudo ausearch -m avc
    sudo ausearch -m avc -ts today
    echo "Look for: Denied operations and their contexts"
}

check_system_calls() {
    echo "Checking system calls:"
    sudo ausearch -m syscall -ts today
    sudo ausearch -m syscall --key sensitive_files
    echo "Look for: Unusual or unauthorized system calls"
}

check_file_access_logs() {
    echo "Checking file access logs:"
    sudo ausearch -f /etc/shadow -ts today
    sudo ausearch -f /etc/passwd -ts today
    echo "Look for: Unauthorized access attempts to sensitive files"
}

check_user_changes() {
    echo "Checking user account and role changes:"
    sudo ausearch -m USER_ACCT -ts today
    sudo ausearch -m USER_ROLE_CHANGE -ts today
    echo "Look for: Unexpected account creations or role modifications"
}

check_executed_commands() {
    echo "Checking executed commands:"
    sudo ausearch -m EXECVE -ts today
    echo "Look for: Suspicious or unauthorized command executions"
}

view_all_audit_logs() {
    echo "Viewing all audit logs for today:"
    sudo ausearch -ts today | less
    echo "Look for: Any patterns of suspicious activity"
}

setup_shadow_monitoring() {
    echo "Setting up shadow file access monitoring:"
    sudo auditctl -w /etc/shadow -p wa -k shadow_access
    sudo ausearch -k shadow_access -ts today
    echo "Look for: Any attempts to access or modify the shadow file"
}

check_failed_logins() {
    echo "Checking failed login attempts:"
    sudo ausearch -m USER_LOGIN -ts today --success no
    echo "Look for: Repeated failed login attempts from the same source"
}

find_large_png_files() {
    echo "Searching for large PNG files:"
    sudo find / -type f -name "*.png" -size +5M
    echo "Look for: Unexpectedly large image files that could contain hidden data"
}

find_recent_png_files() {
    echo "Searching for recently modified PNG files:"
    sudo find / -type f -name "*.png" -mtime -7
    echo "Look for: Recently modified image files in unexpected locations"
}

check_broken_packages() {
    echo "Checking for broken packages:"
    sudo apt list --installed | grep -i "broken"
    echo "Look for: Any packages listed as broken, which may need repair or reinstallation"
}

install_auditd() {
    echo "Installing AuditD:"
    if ! sudo apt install auditd -y; then
        echo "Error: Unable to install AuditD"
        return 1
    fi
    echo "AuditD installed successfully"
}

add_audit_rules() {
    echo "Adding Audit Rules:"
    local rules_file="/etc/audit/rules.d/audit.rules"
    
    # Check if the file exists
    if [ ! -f "$rules_file" ]; then
        echo "Error: $rules_file does not exist"
        return 1
    fi

    # Add rules if they don't already exist
    if ! grep -q "passwd_changes" "$rules_file"; then
        echo "-w /etc/passwd -p wa -k passwd_changes" | sudo tee -a "$rules_file"
    fi
    if ! grep -q "shadow_changes" "$rules_file"; then
        echo "-w /etc/shadow -p wa -k shadow_changes" | sudo tee -a "$rules_file"
    fi

    # Restart AuditD to apply new rules
    if ! sudo systemctl restart auditd; then
        echo "Error: Unable to restart AuditD"
        return 1
    fi
    echo "Audit rules added and AuditD restarted successfully"
}

find_world_writable_files() {
    echo "Finding world-writable files:"
    sudo find / -perm -2 ! -type l -ls
    echo "Look for: Files with unexpected world-writable permissions"
}

monitor_ports_and_services() {
    echo "Monitoring Ports and Services:"
    echo "Open ports:"
    sudo netstat -tuln
    echo "Look for: Unexpected open ports"

    echo -e "\nActive services:"
    systemctl list-units --type=service --state=active
    echo "Look for: Unauthorized or unexpected active services"

    echo -e "\nWould you like to disable any services? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Enter the name of the service you want to disable (or 'q' to quit):"
        while true; do
            read -r service_name
            if [[ "$service_name" == "q" ]]; then
                break
            fi
            echo "Disabling $service_name..."
            sudo systemctl disable "$service_name"
            sudo systemctl mask "$service_name.service"
            echo "Service $service_name has been disabled and masked."
            echo "Enter another service name to disable (or 'q' to quit):"
        done
    fi
}

run_all_checks() {
    install_auditd
    add_audit_rules
    check_apparmor
    start_enable_auditd
    check_avc_messages
    check_system_calls
    check_file_access_logs
    check_user_changes
    check_executed_commands
    view_all_audit_logs
    setup_shadow_monitoring
    check_failed_logins
    find_large_png_files
    find_recent_png_files
    check_broken_packages
    find_world_writable_files
    monitor_ports_and_services
}

show_menu() {
    echo "Diagnostic Logging Menu:"
    echo "1) Install AuditD"
    echo "2) Add Audit Rules"
    echo "3) Check AppArmor status"
    echo "4) Start and enable auditd"
    echo "5) Check AVC messages"
    echo "6) Check system calls"
    echo "7) Check file access logs"
    echo "8) Check user account and role changes"
    echo "9) Check executed commands"
    echo "10) View all audit logs for today"
    echo "11) Setup shadow file access monitoring"
    echo "12) Check failed login attempts"
    echo "13) Find large PNG files"
    echo "14) Find recently modified PNG files"
    echo "15) Check for broken packages"
    echo "16) Find world-writable files"
    echo "17) Monitor ports and services"
    echo "18) Run all checks"
    echo "0) Exit"
    echo -n "Enter your choice: "
}

main() {
    local log_file="/tmp/diagnostic_log_$(date +%Y%m%d_%H%M%S).txt"
    echo "Output will be saved to $log_file"

    while true; do
        show_menu
        read choice

        case $choice in
            1) install_auditd | tee -a "$log_file" ;;
            2) add_audit_rules | tee -a "$log_file" ;;
            3) check_apparmor | tee -a "$log_file" ;;
            4) start_enable_auditd | tee -a "$log_file" ;;
            5) check_avc_messages | tee -a "$log_file" ;;
            6) check_system_calls | tee -a "$log_file" ;;
            7) check_file_access_logs | tee -a "$log_file" ;;
            8) check_user_changes | tee -a "$log_file" ;;
            9) check_executed_commands | tee -a "$log_file" ;;
            10) view_all_audit_logs | tee -a "$log_file" ;;
            11) setup_shadow_monitoring | tee -a "$log_file" ;;
            12) check_failed_logins | tee -a "$log_file" ;;
            13) find_large_png_files | tee -a "$log_file" ;;
            14) find_recent_png_files | tee -a "$log_file" ;;
            15) check_broken_packages | tee -a "$log_file" ;;
            16) find_world_writable_files | tee -a "$log_file" ;;
            17) monitor_ports_and_services | tee -a "$log_file" ;;
            18) run_all_checks | tee -a "$log_file" ;;
            0) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac

        echo "Press Enter to continue..."
        read
    done
}

main
