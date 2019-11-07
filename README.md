# Mycroft Mark 2 Pi Enclosure

This repository holds the files, documentation and scripts for building Mark 2 Pi device images.

Currently this build is based off of the latest Mark 1 image. `base_setup.sh` is run to convert the Mark 1 image to one with the mycroft-mark-2 package. Then `setup.sh` is run which will add the rest of the Mark 2 Pi specific setup.

## Mark II Pi Image Setup
1. Burn latest Mark I prod image to SD Card.

2. Re-mount SD Card and move build files to /boot partition of card (/Volumes/boot MacOS):
    - wpa_supplicant.conf (With valid network creds)
    - identity2.json (Pre-paired on home.mycroft.ai)
    - stt.json (Google Streaming STT Service key)
    - Kusal TTS Setup Recordings
    - base_setup.sh
    - setup.sh

3. Boot up device and move files to appropriate locations:
```
sudo mv /boot/wpa_supplicant.conf /etc/wpa_supplicant/
sudo mv /boot/identity2.json ~/.mycroft/identity/
sudo chown pi:pi ~/.mycroft/identity/identity2.json
sudo mv /boot/base_setup.sh .
sudo mv /boot/setup.sh .
```

4. Connect to the internet
```
sudo reboot

# or if you are too lazy to reboot
sudo wpa_cli -i wlan0 reconfigure
```

To continue with SSH you can run this command:
```
sudo raspi-config nonint do_ssh 0
```

5. Run base setup (will have to answer with 'y' for installing mycroft.conf file)
```
./base_setup.sh 2>&1 | tee base_setup.log
sudo reboot
```

6. Run setup
```
source /opt/venvs/mycroft-core/bin/activate
bash setup.sh 2>&1 | tee setup.log
```

## Creating Image

1. Create raw image
```
LINUX (/dev/sdX)
sudo dd if=/dev/sdc of=mark2pi-20190718-raw.img bs=20M

OSX (/dev/rdiskX)
sudo dd if=/dev/rdisk2 of=mark2pi-20190718-raw.img bs=20m
```

2. (OSX) Run Ubuntu Docker container for steps 7 and 8, mounts
the current working directory to `/images` in the Docker container.
```
docker run --privileged --rm -it -v ${PWD}:/images ubuntu:18.04
```

3. PiShrink
```
apt-get update
apt-get install -y git parted zip
git clone https://github.com/Drewsif/PiShrink.git
export PATH=/PiShrink/:${PATH}
cd /images
pishrink.sh mark2pi-20190718-raw.img mark2pi-20190718-shrink.img
```

4. Zip
```
zip mark2pi-20190718.zip mark2pi-20190718-shrink.img
```

## Files

**image_recipe.md**
Documentation on going from Mark 1 to Mark 2 Pi.

**setup.sh**
Script to set up Mark 2 Pi base image off of Mark I image. GitHub install.

**setup.sh**
Script to set up Mark 2 Pi off of Mark II base image.

**.bashrc**
    Runs auto_run.sh on startup. Bash config.

**auto_run.sh**
    The startup script for the device. Audio setup. Starts mycroft-core.

**mycroft-wipe**
    Prepares device for imaging. Resets wifi and pairing setup.

**etc/mycroft/mycroft.conf**
    System level configuration file.

**etc/wpa_supplicant/wpa_supplicant.conf**
    Wi-Fi config for Mycroft Wifi Setup
    
## Flash 48kHz ReSpeaker Firmware
```
# Make sure virtual env is activate
source ~/mycroft-core/.venv/bin/activate

# Install Dependencies
pip install pyusb
pip install click

# Clone repo
git clone https://github.com/respeaker/usb_4_mic_array.git
cd usb_4_mic_array

# Flash 48k firmware with sudo priviledges. 
sudo $(which python) dfu.py --download 48k_1_channel_firmware.bin
```

## Update Core and Skills

Burn 10.18 to sd card with Balena Etcher (MacOS)

Boot Mark 2 Pi up and complete Wi-Fi setup

Complete pairing on Home with account with no devices (If Spotify / Pandora creds or other settings get pulled down from other device settings those need to be wiped, safer to use fresh blank Home account)

ssh in to the device
```
# Stop Mic Monitor
ps aux | grep mic # get pid
kill -9 {pid}

# Stop Core
~/mycroft-core/stop-mycroft.sh all

# Update core
cd mycroft-core
git pull
CI=true ./dev_setup.sh

# Force Skills Update
rm /opt/mycroft/skills/.msm
~/mycroft-core/start-mycroft.sh all

# Confirm Skill Update Complete
tail -f /var/log/mycroft/skills.log # look for “Skill update complete” log.

# Wipe Wi-Fi creds, paired identity and logs
cd ~
./reset.sh
```

Let’s be paranoid. Cat these files and ensure there are no credentials remaining:
/etc/wpa_supplicant/wpa_supplicant.conf
            /opt/mycroft/skills/mycroft-spotify.forslund/settings.json
            /opt/mycroft/skills/mycroft-pandora.mycroft/settings.json
            ~/.config/pianobar/*

           And also check that ~/.mycroft/identity2.json and /var/logs/mycroft/* have been removed.

```
history -c
history -w
sudo shutdown now
```

Follow image creation steps in repo


## Update Mark 2 Pi Image
A quick update to the image will pull the latest for core with `cd ~/mycroft-core && git pull` and update the skills. This can be done by pairing the device and running `python -m mycroft.messagebus.send skillmanager.update`.
