#!/bin/bash

#==========================================#
#              AUDITING SCRIPT             #
#   Purpose: Comprehensive system auditing #
#   Author: Team 17-0197                  #
#==========================================#

# Script initialization and directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIT_DIR="${SCRIPT_DIR}/audit"

# Privilege check
if [[ $EUID -ne 0 ]] && ! sudo -v; then
    echo "This script must be run with sudo privileges"
    exit 1
fi

# Dependencies check
for cmd in auditctl ausearch systemctl debsums; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Required command not found: $cmd"
        exit 1
    fi
done

#==========================================#
#           USER AUDITING                  #
# Purpose: Executes user-specific audits   #
# Input: None                              #
# Output: User audit results               #
#==========================================#
userCheck() {
    if [ -f "audit/userAudit.sh" ]; then
        sudo bash audit/userAudit.sh
    else
        echo "Error: useraudit.sh not found in current directory"
        exit 1
    fi
}

#==========================================#
#           AUDIT RULES                    #
# Purpose: Configures system audit rules   #
# Monitors: /etc/passwd, /etc/shadow       #
# Output: Confirmation of rules added      #
#==========================================#
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

#==========================================#
#           AUDITD SERVICE                 #
# Purpose: Manages audit daemon            #
# Actions: Starts and enables auditd       #
# Output: Service status confirmation      #
#==========================================#
start_enable_auditd() {
    echo "Starting and enabling auditd:"
    if ! sudo systemctl start auditd; then
        echo "Error: Unable to start auditd"
        return 1
    fi
    if ! sudo systemctl enable auditd; then
        echo "Error: Unable to enable auditd"
        return 1
    fi
    return 0
}

#==========================================#
#           AUDIT ACTIONS                  #
# Purpose: Executes audit_actions.sh       #
# Input: None                              #
# Output: Audit action results             #
#==========================================#
audit_actions() {
    if [ -f "audit/audit_actions.sh" ]; then
        sudo bash audit/audit_actions.sh
    else
        echo "Error: audit_actions.sh not found in current directory"
        exit 1
    fi
}

#==========================================#
#           SHADOW MONITORING              #
# Purpose: Monitors shadow file access     #
# Monitors: /etc/shadow                    #
# Output: Access attempts log              #
#==========================================#
setup_shadow_monitoring() {
    echo "Setting up shadow file access monitoring:"
    sudo auditctl -w /etc/shadow -p wa -k shadow_access
    sudo ausearch -k shadow_access -ts today
    echo "Look for: Any attempts to access or modify the shadow file"
}

#==========================================#
#           AUDIT CHECKS                   #
# Purpose: Performs specific audit checks  #
# Types:                                   #
#  - AppArmor status                      #
#  - AVC messages                         #
#  - System calls                         #
#  - File access                          #
#  - User changes                         #
#  - Command execution                    #
#  - Login attempts                       #
#  - Package integrity                    #
#  - Directory analysis                   #
#  - System logs                          #
#  - Service status                       #
#==========================================#
check_audit_details() {
    local check_type="$1"
    echo "Performing audit check: $check_type"
    
    case "$check_type" in
        "apparmor")
            # Check AppArmor profiles and enforcement status
            if ! sudo aa-status; then
                echo "Error: Unable to check AppArmor status"
            fi
            echo "Look for: Enabled profiles and any reported errors"
            ;;
        "avc")
            # Check Access Vector Cache for security events
            sudo ausearch -m avc
            sudo ausearch -m avc -ts today
            echo "Look for: Denied operations and their contexts"
            ;;
        "syscalls")
            sudo ausearch -m syscall -ts today
            sudo ausearch -m syscall --key sensitive_files
            echo "Look for: Unusual or unauthorized system calls"
            ;;
        "file_access")
            sudo ausearch -f /etc/shadow -ts today
            sudo ausearch -f /etc/passwd -ts today
            echo "Look for: Unauthorized access attempts to sensitive files"
            ;;
        "user_changes")
            sudo ausearch -m USER_ACCT -ts today
            sudo ausearch -m USER_ROLE_CHANGE -ts today
            echo "Look for: Unexpected account creations or role modifications"
            ;;
        "executed_commands")
            sudo ausearch -m EXECVE -ts today
            echo "Look for: Suspicious or unauthorized command executions"
            ;;
        "all_logs")
            sudo ausearch -ts today | less
            echo "Look for: Any patterns of suspicious activity"
            ;;
        "failed_logins")
            sudo ausearch -m USER_LOGIN -ts today --success no
            echo "Look for: Repeated failed login attempts from the same source"
            ;;
        "package_integrity")
            if ! sudo debsums -c; then
                echo "Error: Some package files have been modified"
            fi
            echo "Look for: Modified or corrupted package files"
            ;;
        "directory_listing")
            ls -la
            echo "Look for: Hidden files and unusual permissions"
            ;;
        "system_journal")
            sudo journalctl -xe
            echo "Look for: Recent system events and errors"
            ;;
        "active_services")
            systemctl list-units --type=service --state=active
            echo "Look for: Unexpected or unauthorized running services"
            ;;
        *)
            echo "Invalid check type specified"
            return 1
            ;;
    esac
}

#==========================================#
#           AUDIT LOG CHECKER              #
# Purpose: Interactive menu for audits     #
# Input: User menu selection              #
# Output: Selected audit results          #
#==========================================#
check_audit_logs() {
    while true; do
        echo -e "\nAudit Log Check Menu:"
        echo "1) Check AppArmor status"
        echo "2) Check AVC messages"
        echo "3) Check system calls"
        echo "4) Check file access logs"
        echo "5) Check user account changes"
        echo "6) Check executed commands"
        echo "7) View all audit logs"
        echo "8) Check failed login attempts"
        echo "9) Check package integrity"
        echo "10) Show directory listing"
        echo "11) Check System Journal"
        echo "12) List Active Services"
        echo "13) Run all audit checks"
        echo "0) Return to main menu"
        echo -n "Enter your choice: "
        read -r subchoice

        case $subchoice in
            1) check_audit_details "apparmor" ;;
            2) check_audit_details "avc" ;;
            3) check_audit_details "syscalls" ;;
            4) check_audit_details "file_access" ;;
            5) check_audit_details "user_changes" ;;
            6) check_audit_details "executed_commands" ;;
            7) check_audit_details "all_logs" ;;
            8) check_audit_details "failed_logins" ;;
            9) check_audit_details "package_integrity" ;;
            10) check_audit_details "directory_listing" ;;
            11) check_audit_details "system_journal" ;;
            12) check_audit_details "active_services" ;;
            13)
                for check in "apparmor" "avc" "syscalls" "file_access" "user_changes" \
                            "executed_commands" "all_logs" "failed_logins" "package_integrity" \
                            "directory_listing" "system_journal" "active_services"; do
                    check_audit_details "$check"
                done
                ;;
            0) break ;;
            *) echo "Invalid option. Please try again." ;;
        esac

        echo -e "\nPress Enter to continue..."
        read -r
    done
}

#==========================================#
#           MENU DISPLAY                   #
# Purpose: Shows main program menu        #
# Input: None                             #
# Output: Menu options                    #
#==========================================#
show_menu() {
    cat << EOF
Audit and Security Menu:
1) User Check
2) Add Audit Rules
3) Setup Shadow Monitoring
4) Check Audit Logs
5) Start and Enable Auditd
6) Audit Actions
0) Exit
Enter your choice: 
EOF
}

#==========================================#
#           MAIN FUNCTION                  #
# Purpose: Main program loop              #
# Input: User menu selections             #
# Output: Program execution flow          #
#==========================================#
main() {
    while true; do
        show_menu
        read -r choice

        case $choice in 
            1) userCheck ;;
            2) add_audit_rules ;;
            3) setup_shadow_monitoring ;;
            4) check_audit_logs ;;
            5) start_enable_auditd ;;
            6) audit_actions ;;
            0) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac

        echo "Press Enter to continue..."
        read -r
    done
}

# Execute main program
main
