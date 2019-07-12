#!/bin/bash

# Copyright 2018 Mycroft AI Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

##########################################################################
# setup.sh
##########################################################################
# This script sets up a Mark 2 Pi based off of a Mark 1 image

REPO_PATH="https://raw.githubusercontent.com/MycroftAI/enclosure-mark2/master"

# Remove Debian package versions of Core and Mark 1 and Arduino bits
sudo apt-get remove mycroft-mark-1
sudo apt-get remove mycroft-core
sudo apt-get remove avrdude libftdi1
sudo rm -rf /opt/venv

# Correct permissions from Mark 1 (which used the 'mycroft' user to run)
sudo chown -R pi:pi /var/log/mycroft
sudo chmod 666 /var/log/mycroft/*

# Display Setup
sudo echo "# Mark 2 Pi Display Settings" | sudo tee -a /boot/config.txt    
sudo echo "hdmi_force_hotplug=1" | sudo tee -a /boot/config.txt
sudo echo "hdmi_drive=2" | sudo tee -a /boot/config.txt
sudo echo "hdmi_group=2" | sudo tee -a /boot/config.txt
sudo echo "hdmi_mode=87" | sudo tee -a /boot/config.txt
sudo echo "hdmi_mode=87" | sudo tee -a /boot/config.txt
sudo echo "display_rotate=1" | sudo tee -a /boot/config.txt
sudo echo "hdmi_cvt 800 400 60 6 0 0 0" | sudo tee -a /boot/config.txt
sudo echo "dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait consoleblank=0 quiet splash plymouth.ignore-serial-consoles" | sudo tee /boot/cmdline

# GUI: Install plymouth
git clone https://github.com/forslund/mycroft-plymouth-theme
cd mycroft-plymouth-theme
./install.sh
cd ..
sudo plymouth-set-default-theme mycroft-plymouth-theme

# Volume: Install I2C support (might require raspi-config changes first)
sudo apt-get install i2c-tools

# Create basic folder structures
mkdir ~/bin

# Get the Picroft conf file
cd /etc/mycroft
sudo wget -N $REPO_PATH/etc/mycroft/mycroft.conf

echo "Downloading 'mycroft-core'..."
cd ~
git clone https://github.com/MycroftAI/mycroft-core.git
cd mycroft-core
git checkout master

echo
echo "Beginning building mycroft-core.  This'll take a bit.  Answer: Y Y N to questions"
echo "then take a break for an hour!  Results will be in the ~/build.log"
bash dev_setup.sh -y 2>&1 | tee ../build.log
echo "Build complete.  Press any key to review the output before it is deleted."
read -N1 -s key
nano ../build.log
rm ../build.log

echo
echo "Retrieving default skills"
sudo chown -R pi:pi /opt/mycroft
~/mycroft-core/bin/mycroft-msm default

cd ~
bash ./update.sh