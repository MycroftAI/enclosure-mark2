# Mycroft Mark 2 Pi Enclosure

This repository holds the files, documentation and scripts for building Mark 2 Pi device images.

## Mark II Pi Setup
1. Burn latest Mark I prod image to SD Card.

2. Boot up Mark II device and setup Wi-Fi connection

3. `./setup.sh 2>&1 | tee setup.log` (takes ~30min)

3. Pair the device and test the build

4. `source bin/mycroft-wipe`

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


**image_recipe.md**
Documentation on going from Mark 1 to Mark 2 Pi.

**setup.sh**
Script to set up Mark 2 Pi off of Mark I image.

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
