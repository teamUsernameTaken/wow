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

run_all_checks() {
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
}

show_menu() {
    echo "Diagnostic Logging Menu:"
    echo "1) Check AppArmor status"
    echo "2) Start and enable auditd"
    echo "3) Check AVC messages"
    echo "4) Check system calls"
    echo "5) Check file access logs"
    echo "6) Check user account and role changes"
    echo "7) Check executed commands"
    echo "8) View all audit logs for today"
    echo "9) Setup shadow file access monitoring"
    echo "10) Check failed login attempts"
    echo "11) Find large PNG files"
    echo "12) Find recently modified PNG files"
    echo "13) Check for broken packages"
    echo "14) Run all checks"
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
            1) check_apparmor | tee -a "$log_file" ;;
            2) start_enable_auditd | tee -a "$log_file" ;;
            3) check_avc_messages | tee -a "$log_file" ;;
            4) check_system_calls | tee -a "$log_file" ;;
            5) check_file_access_logs | tee -a "$log_file" ;;
            6) check_user_changes | tee -a "$log_file" ;;
            7) check_executed_commands | tee -a "$log_file" ;;
            8) view_all_audit_logs | tee -a "$log_file" ;;
            9) setup_shadow_monitoring | tee -a "$log_file" ;;
            10) check_failed_logins | tee -a "$log_file" ;;
            11) find_large_png_files | tee -a "$log_file" ;;
            12) find_recent_png_files | tee -a "$log_file" ;;
            13) check_broken_packages | tee -a "$log_file" ;;
            14) run_all_checks | tee -a "$log_file" ;;
            0) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac

        echo "Press Enter to continue..."
        read
    done
}

main
