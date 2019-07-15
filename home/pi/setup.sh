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
sudo apt-get remove -y mycroft-mark-1
sudo apt-get remove -y mycroft-core
sudo apt-get remove -y avrdude libftdi1
sudo rm -rf /opt/venv
sudo apt-get autoremove

# Correct permissions from Mark 1 (which used the 'mycroft' user to run)
sudo chown -R pi:pi /var/log/mycroft
sudo chmod 666 /var/log/mycroft/*

# Display Setup
sudo echo "# Mark 2 Pi Display Settings" | sudo tee -a /boot/config.txt    
sudo echo "hdmi_force_hotplug=1" | sudo tee -a /boot/config.txt
sudo echo "hdmi_drive=2" | sudo tee -a /boot/config.txt
sudo echo "hdmi_group=2" | sudo tee -a /boot/config.txt
sudo echo "hdmi_mode=87" | sudo tee -a /boot/config.txt
sudo echo "display_rotate=1" | sudo tee -a /boot/config.txt
sudo echo "hdmi_cvt 800 400 60 6 0 0 0" | sudo tee -a /boot/config.txt

# Removing boot up text printed to tty1 console
sudo echo "dwc_otg.lpm_enable=0 console=tty2 logo.nologo root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait consoleblank=0 quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0" | sudo tee /boot/cmdline
sudo sed -i.bak -e 's|ExecStart.*|ExecStart=-/sbin/agetty --skip-login --noclear --noissue --login-options "-f pi" %I $TERM|' /etc/systemd/system/autologin@.service
sudo sed -i.bak -e 's| /bin/uname -snrvm||' /etc/pam.d/login
touch ~/.hushlogin

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
git checkout dev 

echo
echo "Beginning building mycroft-core.  This'll take a bit.  Answer: Y Y N to questions"
echo "then take a break for an hour!  Results will be in the ~/build.log"
IS_TRAVIS=true bash dev_setup.sh 2>&1 | tee ../build.log
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