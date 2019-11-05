# Mycroft Mark 2 Pi Enclosure

This repository holds the files, documentation and scripts for building Mark 2 Pi device images.

Currently this build is based off of the latest Mark 1 image. `base_setup.sh` is run to convert the Mark 1 image to a Mark 2 Base image so the ~30 minute `dev_setup.sh` does not have to be repeated for every image. Then off of the Mark 2 Pi Base image `setup.sh` is run which will get a working Mark 2 Pi image. Sometimes newer images are made off of this image if the change is as ligth as pulling the latest from dev and updating skills.

## Mark II Pi Base Image Setup
1. Burn latest Mark I prod image to SD Card.

2. Move base_setup.sh to /boot partition of card

3. Boot up device and setup Wi-Fi connection

4. `sudo mv /boot/base_setup.sh .` (move to home directory)

5. `./base_setup.sh 2>&1 | tee base_setup.log` (takes ~30min)

6. Remove Wi-Fi network from wpa_supplicant 

## Mark II Pi Setup
1. Burn latest Mark II base image to SD Card. (~6 min for 16GB card)

2. Move build files to /boot partition of card:
    - wpa_supplicant.conf (With valid network creds)
    - identity2.json (Pre-paired on home.mycroft.ai)
    - stt.json (Google Streaming STT Service key)
    - setup.sh
    - Kusal TTS Setup Recordings

3. Boot up device and move files to appropriate locations:
```
sudo mv /boot/wpa_supplicant.conf /etc/wpa_supplicant/
sudo mv /boot/identity2.json ~/.mycroft/identity/
sudo mv /boot/setup.sh .
```

4. Connect to the internet
```
sudo wpa_cli -i wlan0 reconfigure
```

5. Run setup (~12 min)
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

## Update Mark 2 Pi Image
A quick update to the image will pull the latest for core with `cd ~/mycroft-core && git pull` and update the skills. This can be done by pairing the device and running `python -m mycroft.messagebus.send skillmanager.update`.
