# Mycroft Mark 2 Pi Enclosure

This repository holds the files, documentation and scripts for building Mark 2 Pi device images.

## Mark II Pi Base Image Setup
1. Burn latest Mark I prod image to SD Card.

2. Move base_setup.sh to /boot partition of card

3. Boot up device and setup Wi-Fi connection

4. `sudo mv /boot/base_setup.sh .` (move to home directory)

5. `./base_setup.sh 2>&1 | tee base_setup.log` (takes ~30min)

6. Remove Wi-Fi network from wpa_supplicant 

## Mark II Pi Setup
1. Burn latest Mark II base image to SD Card.

2. Move build files to /boot partition of card:
    - wpa_supplicant.conf (With valid network creds)
    - identity2.json (Pre-paired on home.mycroft.ai)
    - stt.json (Google Streaming STT Service key)
    - setup.sh

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

5. Run setup
```
source ~/mycroft-core/.venv/bin/activate
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

2. (OSX) Run Ubuntu Docker container for steps 7 and 8
```
docker run --privileged --rm -it -v ${PWD}:/shrink ubuntu:18.04
```

3. PiShrink
```
apt-get update
apt-get install git parted zip
git clone https://github.com/Drewsif/PiShrink.git
export PATH=/PiShrink/:${PATH}
cd /shrink
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
