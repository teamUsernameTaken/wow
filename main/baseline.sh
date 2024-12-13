#!/bin/bash

# Output directory
outputDir="systemComparisonOutputs"
mkdir -p "$outputDir"

# Notify start
echo "Generating system comparison outputs in: $outputDir"

# 1. Sources.list
{
    outputFile="$outputDir/sourcesList.txt"
    echo "Contents of /etc/apt/sources.list:" >"$outputFile"
    cat /etc/apt/sources.list >>"$outputFile" 2>/dev/null || echo "/etc/apt/sources.list not found." >>"$outputFile"
}

# 2. Package lists
{
    outputFile="$outputDir/packageList.txt"
    echo "Installed Packages (dpkg):" >"$outputFile"
    dpkg --get-selections >>"$outputFile" 2>/dev/null || echo "dpkg not found." >>"$outputFile"
}

# 3. Unit Files
{
    outputFile="$outputDir/unitFiles.txt"
    echo "Active Services:" >"$outputFile"
    systemctl list-units --type=service >>"$outputFile" 2>/dev/null || echo "systemctl not found." >>"$outputFile"
}

# 4. Cron Jobs and Timers
{
    outputFile="$outputDir/cronJobsTimers.txt"
    echo "User Cron Jobs:" >"$outputFile"
    crontab -l >>"$outputFile" 2>/dev/null || echo "No user crontab found." >>"$outputFile"
    echo "\nSystemd Timers:" >>"$outputFile"
    systemctl list-timers >>"$outputFile" 2>/dev/null || echo "No systemd timers found." >>"$outputFile"
}

# 5. Listening Ports
{
    outputFile="$outputDir/listeningPorts.txt"
    echo "Active Network Ports:" >"$outputFile"
    netstat -tuln >>"$outputFile" 2>/dev/null || echo "netstat not found." >>"$outputFile"
}

# 6. DNS
{
    outputFile="$outputDir/dnsConfig.txt"
    echo "Contents of /etc/resolv.conf:" >"$outputFile"
    cat /etc/resolv.conf >>"$outputFile" 2>/dev/null || echo "/etc/resolv.conf not found." >>"$outputFile"
}

# 7. Hosts File
{
    outputFile="$outputDir/hostsFile.txt"
    echo "Contents of /etc/hosts:" >"$outputFile"
    cat /etc/hosts >>"$outputFile" 2>/dev/null || echo "/etc/hosts not found." >>"$outputFile"
}

# 8. Kernel Modules
{
    outputFile="$outputDir/kernelModules.txt"
    echo "Loaded Kernel Modules:" >"$outputFile"
    lsmod >>"$outputFile" 2>/dev/null || echo "lsmod not found." >>"$outputFile"
}

# 9. Sudoers Configuration
{
    outputFile="$outputDir/sudoersConfig.txt"
    echo "Contents of /etc/sudoers:" >"$outputFile"
    cat /etc/sudoers >>"$outputFile" 2>/dev/null || echo "/etc/sudoers not found." >>"$outputFile"
    echo "\nContents of /etc/sudoers.d/ directory:" >>"$outputFile"
    ls -l /etc/sudoers.d/ >>"$outputFile" 2>/dev/null || echo "/etc/sudoers.d/ directory not found." >>"$outputFile"
}

# 10. Environment Variables
{
    outputFile="$outputDir/environmentVariables.txt"
    echo "Global Variables (from /etc/environment):" >"$outputFile"
    cat /etc/environment >>"$outputFile" 2>/dev/null || echo "/etc/environment not found." >>"$outputFile"
    echo "\nUser-Specific Variables:" >>"$outputFile"
    for user in $(cut -f1 -d: /etc/passwd); do
        if [ -f "/home/$user/.bashrc" ]; then
            echo "\n$user's .bashrc:" >>"$outputFile"
            cat "/home/$user/.bashrc" >>"$outputFile"
        fi
    done
}

# Notify completion
echo "System comparison outputs have been generated in: $outputDir"
