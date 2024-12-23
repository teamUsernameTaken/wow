#!/bin/bash

# Description: This script updates the Ubuntu `sources.list` file, backs up the existing one,
# and installs Git after updating the package list.

# Backup the existing sources.list
echo "Backing up the existing sources.list..."
sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak
if [[ $? -ne 0 ]]; then
    echo "Error: Unable to backup sources.list. Ensure you have sufficient permissions."
    exit 1
fi
echo "Backup completed: /etc/apt/sources.list.bak"

# Write the new sources.list content
echo "Updating sources.list with new repository entries..."
sudo tee /etc/apt/sources.list > /dev/null <<EOL
#deb cdrom:[Ubuntu 18.04 LTS _Bionic Beaver_ - Release amd64 (20180426)]/ bionic main restricted

# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://us.archive.ubuntu.com/ubuntu/ bionic main restricted
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic main restricted

## Major bug fix updates produced after the final release of the
## distribution.
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates main restricted

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb http://us.archive.ubuntu.com/ubuntu/ bionic universe
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic universe
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates universe
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates universe

## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://us.archive.ubuntu.com/ubuntu/ bionic multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic multiverse
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-updates multiverse

## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://us.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src http://us.archive.ubuntu.com/ubuntu/ bionic-backports main restricted universe multiverse

## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
deb http://archive.canonical.com/ubuntu bionic partner
deb-src http://archive.canonical.com/ubuntu bionic partner

deb http://security.ubuntu.com/ubuntu bionic-security main restricted
# deb-src http://security.ubuntu.com/ubuntu bionic-security main restricted
deb http://security.ubuntu.com/ubuntu bionic-security universe
# deb-src http://security.ubuntu.com/ubuntu bionic-security universe
deb http://security.ubuntu.com/ubuntu bionic-security multiverse
# deb-src http://security.ubuntu.com/ubuntu bionic-security multiverse
EOL

if [[ $? -ne 0 ]]; then
    echo "Error: Unable to write new sources.list. Ensure you have sufficient permissions."
    exit 1
fi
echo "sources.list updated successfully."

# Update the package list
echo "Updating the package list..."
sudo apt update
if [[ $? -ne 0 ]]; then
    echo "Error: Unable to update the package list. Check your internet connection or sources.list entries."
    exit 1
fi
echo "Package list updated successfully."

# Install git
echo "Installing Git..."
sudo apt install -y git
if [[ $? -ne 0 ]]; then
    echo "Error: Unable to install Git. Check your package list and try again."
    exit 1
fi
echo "Git installed successfully."

echo "Script completed. sources.list updated, and Git installed."