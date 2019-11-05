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
# This script sets up a Mark 2 Pi based off of the Mark II Pi base image.

REPO_PATH="https://raw.githubusercontent.com/MycroftAI/enclosure-mark2/master"

test=$(python -c "from mycroft.api import has_been_paired; msg = 'PAIRED' if has_been_paired() else ''; print(msg)" | grep -c PAIRED)
echo $test
if ! ((test)) ; then
    echo "Not paired or no internet."
    exit 1
fi

# Correct permissions from Mark 1 (which used the 'mycroft' user to run)
sudo chown -R pi:pi /var/log/mycroft
rm /var/log/mycroft/*
sudo chown -R pi:pi /opt/mycroft
sudo rm -rf /tmp/*
sudo rm -rf /tmp/.skills-repo/
rm -rf /opt/mycroft/skills/*

# Locale fix
sudo sed -i.bak 's|AcceptEnv LANG LC_\*||' /etc/ssh/sshd_config

DEFAULT_PA="/etc/pulse/default.pa"
PULSE_CLIENT="/etc/pulse/client.conf"

function update_pulse_default_pa () {
    if grep -q "Mycroft additions 0.1" ${DEFAULT_PA} ; then
        echo "Updating pulse default.pa"
        # Remove old changes
        sed -i '/Mycroft additions 0.1/Q' ${DEFAULT_PA}

        cat >> ${DEFAULT_PA} <<- EOF
## Mycroft additions 0.2 Start
## Mycroft additions End
EOF
    else
        echo "${DEFAULT_PA} is already patched"
    fi
}


function update_pulse_client () {
    if grep -q "Mycroft additions 0.1" ${PULSE_CLIENT} ; then
        echo "Updateing pulse client.conf"
        # Remove old changes
        sed -i '/Mycroft additions 0.1/Q' ${PULSE_CLIENT}
        cat >> ${PULSE_CLIENT} <<- EOF
## Mycroft additions 0.2 Start
## Mycroft additions End
EOF
    else
        echo "${PULSE_CLIENT} is already patched"
    fi
}

update_pulse_default_pa
update_pulse_client

# Audio Setup
sudo echo "# Mycroft Mark 2 Pi Audio Settings" | sudo tee -a /etc/pulse/daemon.conf
sudo echo "resample-method = ffmpeg" | sudo tee -a /etc/pulse/daemon.conf
sudo echo "default-sample-format = s24le" | sudo tee -a /etc/pulse/daemon.conf
sudo echo "default-sample-rate = 48000" | sudo tee -a /etc/pulse/daemon.conf
sudo echo "alternate-sample-rate = 44100" | sudo tee -a /etc/pulse/daemon.conf
sudo echo "# Mycroft Mark 2 Pi Audio Settings" | sudo tee -a /etc/pulse/default.pa
sudo echo "unload-module module-role-cork" | sudo tee -a /etc/pulse/default.pa
sudo echo "load-module module-role-ducking" | sudo tee -a /etc/pulse/default.pa
sudo echo "unload-module module-stream-restore" | sudo tee -a /etc/pulse/default.pa

cd /etc
sudo wget -N $REPO_PATH/etc/libao.conf
cd ~

# Display Setup
sudo echo "# Mark 2 Pi Display Settings" | sudo tee -a /boot/config.txt    
sudo echo "hdmi_force_hotplug=1" | sudo tee -a /boot/config.txt
sudo echo "hdmi_drive=2" | sudo tee -a /boot/config.txt
sudo echo "hdmi_group=2" | sudo tee -a /boot/config.txt
sudo echo "hdmi_mode=87" | sudo tee -a /boot/config.txt
sudo echo "display_rotate=1" | sudo tee -a /boot/config.txt
sudo echo "hdmi_cvt 800 480 60 6 0 0 0" | sudo tee -a /boot/config.txt

# Removing boot up text printed to tty1 console
sudo echo "dwc_otg.lpm_enable=0 console=tty2 logo.nologo root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait consoleblank=0 quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0" | sudo tee /boot/cmdline.txt
sudo sed -i.bak -e 's|ExecStart.*|ExecStart=-/sbin/agetty --skip-login --noclear --noissue --login-options "-f pi" %I $TERM|' /etc/systemd/system/autologin@.service
sudo sed -i.bak -e 's| /bin/uname -snrvm||' /etc/pam.d/login
touch ~/.hushlogin

# GUI: Install plymouth
git clone https://github.com/forslund/mycroft-plymouth-theme
cd mycroft-plymouth-theme
echo -n "Press any key? Okay!" | ./install.sh
cd ~
sudo plymouth-set-default-theme mycroft-plymouth-theme

# Volume: Install I2C support (might require raspi-config changes first)
sudo apt-get install -y i2c-tools
sudo raspi-config nonint do_i2c 0

# LED Support
sudo mkdir -p /etc/udev/rules.d
cd /etc/udev/rules.d
sudo wget -N $REPO_PATH/etc/udev/rules.d/98-mic-array.rules
cd ~

# Get the Picroft conf file
cd /etc/mycroft
sudo wget -N $REPO_PATH/etc/mycroft/mycroft.conf
cd ~

wget -N $REPO_PATH/home/pi/.bashrc
wget -N $REPO_PATH/home/pi/auto_run.sh
wget -N $REPO_PATH/home/pi/mic_monitor.py
wget -N $REPO_PATH/home/pi/mycroft.fb

mkdir -p ~/bin
cd ~/bin
wget -N $REPO_PATH/home/pi/bin/mycroft-wipe
chmod +x mycroft-wipe
cd ~

# Streaming STT
source /opt/venvs/mycroft-core/bin/activate
# Insert stt key, remove placeholder comment, format and write to file.
sed '/# Google Service Key/r /boot/stt.json' /etc/mycroft/mycroft.conf \
    | sed 's|# Google Service.*||' \
    | python -m json.tool \
    | sudo tee /etc/mycroft/mycroft.conf

# skills
msm -p mycroft_mark_2pi default
msm install https://github.com/MycroftAI/skill-mark-2-pi.git

# Development
sudo raspi-config nonint do_ssh 0
sudo apt-get autoremove -y

# Run Mycroft until TTS, Intents, and Precise are cached
sudo systemctl restart mycroft-messagebus
sudo systemctl restart mycroft-speech-client
sudo systemctl restart mycroft-skills
sudo systemctl restart mycroft-enclosure-client
sudo systemctl restart mycroft-audio

until grep -q "Successfully downloaded Pre-loaded cache" <(sudo journalctl -u mycroft-audio); do sleep 5; done
echo "TTS Cached"
until grep -q "Precise download complete" <(sudo journalctl -u mycroft-speech-client); do sleep 5; done
echo "Precise Cached"
until egrep -q "(Training complete|Some objects timed out while training)" <(sudo journalctl -u mycroft-skills); do sleep 5; done
if grep -q "Some objects timed out while training" <(sudo journalctl -u mycroft-skills); then
    echo "Training timed out. Restarting training..."
    python -m mycroft.messagebus.send mycroft.skills.initialized
fi
until grep -q "Training complete" <(sudo journalctl -u mycroft-skills); do sleep 5; done
echo "Intents Cached"
sudo systemctl stop mycroft-messagebus
sudo systemctl stop mycroft-speech-client
sudo systemctl stop mycroft-skills
sudo systemctl stop mycroft-enclosure-client
sudo systemctl stop mycroft-audio

# Populate Mimic2 Cache with Kusal Wifi/Pairing Setup Recordings
sudo mv /boot/Kusal-TTS-Cache/* /opt/mycroft/preloaded_cache/Mimic2/

# regenerate ssh key
sudo rm /etc/ssh/ssh_host_*
sudo dpkg-reconfigure openssh-server
sudo systemctl restart ssh

# Blank-out network settings
cd /etc/wpa_supplicant
sudo wget -N $REPO_PATH/etc/wpa_supplicant/wpa_supplicant.conf
cd ~

# Size Reduction
sudo rm -rf /var/lib/apt/lists/*
rm -rf ~/.cache/*

# Hostname
sudo raspi-config nonint do_hostname mark_2

# Unpair
rm -f ~/.mycroft/identity/identity2.json

# Reset bash history
history -c
history -w

# Done
echo "Setup is complete. Shutting down..."
sleep 1
sudo shutdown now
