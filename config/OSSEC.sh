#!/bin/bash

installConfigureOSSEC() {
    echo "Installing and configuring OSSEC..."
    
    # Install prerequisites
    sudo apt-get install build-essential make gcc libevent-dev zlib1g-dev libssl-dev libpcre2-dev -y
    
    # Download and install OSSEC
    local ossec_version="3.6.0"
    wget "https://github.com/ossec/ossec-hids/archive/${ossec_version}.tar.gz"
    tar -zxvf "${ossec_version}.tar.gz"
    cd "ossec-hids-${ossec_version}" || exit
    
    # Create an auto-answer file for unattended installation
    cat > auto-install.conf << EOF
OSSEC_LANGUAGE="en"
OSSEC_USER="ossec"
OSSEC_USER_MAIL="root@localhost"
OSSEC_USER_ENABLE="y"
OSSEC_UPDATE="y"
OSSEC_SYSCHECK="y"
OSSEC_ROOTCHECK="y"
OSSEC_ACTIVE_RESPONSE="y"
OSSEC_MAIL_REPORT="n"
OSSEC_INSTALL_TYPE="local"
EOF
    
    # Run installation with auto-answer file
    sudo ./install.sh auto-install.conf
    
    # Configure OSSEC
    sudo tee -a /var/ossec/etc/ossec.conf > /dev/null <<EOT
<ossec_config>
  <syscheck>
    <frequency>7200</frequency>
    <directories check_all="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories check_all="yes">/bin,/sbin</directories>
  </syscheck>

  <rootcheck>
    <frequency>7200</frequency>
  </rootcheck>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>
</ossec_config>
EOT
    
    # Start OSSEC
    sudo /var/ossec/bin/ossec-control start
    
    # Enable OSSEC to start on boot
    sudo systemctl enable ossec
    
    echo "OSSEC installation and configuration completed."
    echo "You can check OSSEC status with: sudo /var/ossec/bin/ossec-control status"
}