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
# update.sh
##########################################################################
# This script is executed by the auto_run.sh when a new version is found
# at https://github.com/MycroftAI/enclosure-picroft/tree/stretch

REPO_PATH="https://raw.githubusercontent.com/MycroftAI/enclosure-mark2/master"

if [ ! -f /home/pi/MARK-2_README ] ;
then
    # Assume this is a fresh Mark 1 install, setup the system from there
    echo "Would you like to install Mark 2.pi on this machine?"
    echo -n "Choice [Y/N]: "
    read -N1 -s key
    case $key in
      [Yy])
        ;;

      *)
        echo "Aborting install."
        exit
        ;;
    esac
    
    # Setup HDMI output on by default
    sudo echo "# Enable HDMI 1024x768 for debugging" > sudo tee -a /boot/config.txt    
    sudo echo "hdmi_force_hotplug=1" > sudo tee -a /boot/config.txt
    sudo echo "hdmi_drive=2" | sudo tee -a /boot/config.txt
    sudo echo "hdmi_group=2" | sudo tee -a /boot/config.txt
    sudo echo "hdmi_mode=87" | sudo tee -a /boot/config.txt
    sudo echo "hdmi_mode=87" | sudo tee -a /boot/config.txt
    sudo echo "display_rotate=1" | sudo tee -a /boot/config.txt
    sudo echo "hdmi_cvt 800 400 60 6 0 0 0" | sudo tee -a /boot/config.txt
    sudo echo "dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait consoleblank=0 quiet splash plymouth.ignore-serial-consoles" | sudo tee /boot/cmdline

    # Remove Debian package versions of Core and Mark 1 and Arduino bits
    sudo apt-get remove mycroft-mark-1
    sudo apt-get remove mycroft-core
    sudo apt-get remove avrdude libftdi1
    sudo rm -rf /opt/venv

    # Install I2C support (might require raspi-config changes first)
    sudo apt-get install i2c-tools

    # Create basic folder structures
    mkdir ~/bin
    # Correct permissions from Mark 1 (which used the 'mycroft' user to run)
    sudo chown -R pi:pi /var/log/mycroft
    sudo chmod 666 /var/log/mycroft/*

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
fi

# update software
echo "Updating Mark 2.pi scripts"
cd ~
wget -N $REPO_PATH/home/pi/.bashrc
wget -N $REPO_PATH/home/pi/auto_run.sh
wget -N $REPO_PATH/home/pi/version
wget -N $REPO_PATH/home/pi/MARK-2_README

cd ~/bin
wget -N $REPO_PATH/home/pi/bin/mycroft-wipe
chmod +x mycroft-wipe

