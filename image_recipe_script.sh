# WIP conversion of image_recipe.md to bash script

# TODO: Run a sudo check

# Change pi password
echo -e "mycroft\nmycroft" | passwd pi

# Expand filesystem
raspi-config nonint do_expand_rootfs
# Autologin
raspi-config nonint do_boot_behaviour 2
# Do not wait for network on boot
raspi-config nonint do_boot_wait 0
# Hostname
raspi-config nonint do_hostname 'mark_2' 
# Keyboard config
raspi-config nonint do_configure_keyboard

# Add Mycroft repo
apt-get update -y
apt-get install apt-transport-https -y
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F3B1AA8B
bash -c 'echo "deb http://repo.mycroft.ai/repos/apt/debian debian main" > /etc/apt/sources.list.d/repo.mycroft.ai.list'
apt-get update -y

# Dev Tools
apt-get install vim -y
apt-get install tmux -y

# Set default PulseAudio sample rate
sed -i.bak 's|; default-sample-rate = 44100|default-sample-rate = 44100|' /etc/pulse/daemon.conf

## Disable kernel boot TTY on GPIO UART
systemctl stop serial-getty@ttyAMA0.service
systemctl disable serial-getty@ttyAMA0.service

## Enable systemd-timesyncd
timedatectl set-ntp true

## Edit boot configuration settings
sed -i.bak s'|dtparam=i2c.*|dtparam=i2c_arm=on|' /boot/config.txt
sed -i.bak s'|dtparam=spi.*|dtparam=spi=on|' /boot/config.txt
sed -i.bak s'|dtparam=audio.*|#dtparam=audio=on|' /boot/config.txt
echo "dtoverlay=pi3-disable-bt" > /boot/config.txt
echo "dtoverlay=pi3-miniuart-bt" > /boot/config.txt
echo "dtoverlay=rpi-proto" > /boot/config.txt
# Remove ttyAMA0
# Remove 'console=serial0,115200'

## Setup soundcard
#Set correct volume and sound card settings
#alsamixer
#Press F6 and select 'snd_rpi_proto'
#Press F5 to show all settings
#Adjust settings to match as shown below.  User right-arrow to change selection, Up to change numbers, 'M' to change between options
#Raise 'Master' volume to 46 with up arrow presses
#Press right and enable 'Master Playback' with press of 'M'
#Press right three times and enable 'Mic' 'Capture' with press of spacebar
#Press right three times and enable 'Playback Deemp' with press of 'M'
#Press right three times and set 'Input Mux' to 'Mic' with press of up arrow
#Press right and enable 'Output Mixer HiFi' with press of 'M'
#Press right three times and enable 'Store DC Offset' with press of 'M'
#ESC to save and exit
  
# Enable ufw for a simple firewall allowing only port 22 incoming as well as dns, dhcp, and the Mycroft web socket
apt-get install ufw -y

# Block all incoming by default
ufw default deny incoming
 
# Allow ssh on port 22 when enabled
ufw allow 22
 
# WiFi setup client:
# Allow tcp connection to websocket
ufw allow in from 172.24.1.0/24 to any port 8181 proto tcp

# Allow tcp to web server
ufw allow in from 172.24.1.0/24 to any port 80 proto tcp

# Allow udp for dns
ufw allow in from 172.24.1.0/24 to any port 53 proto udp

# Allow udp for dhcp
ufw allow in from 0.0.0.0 port 68 to 255.255.255.255 port 67 proto udp

# Turn on the firewall
ufw enable

## Create RAM disk for IPC
mkdir /ramdisk
echo "tmpfs           /ramdisk        tmpfs   rw,nodev,nosuid,size=20M          0  0" >> /etc/fstab

## Upgrade packages
sudo apt-get update
echo "raspberrypi-kernel hold" | sudo dpkg --set-selections
sudo apt-get upgrade

## Setup packagekit
apt-get install packagekit

cat <<"EOT" >> /etc/polkit-1/localauthority/50-local.d/allow_mycroft_to_install_package.pkla
 Identity=unix-user:mycroft

 Action=org.freedesktop.packagekit.package-eula-accept;org.freedesktop.packagekit.package-install
 ResultAny=yes
EOT

## Allow mycroft user to install with pip
echo "mycroft ALL=(ALL) NOPASSWD: /usr/local/bin/pip install *" >> /etc/sudoers.d/011_mycroft-nopasswd
chmod -w /etc/sudoers.d/011_mycroft-nopasswd

## Install librespot
curl -sL https://dtcooper.github.io/raspotify/install.sh | sh

sudo systemctl stop raspotify
sudo systemctl disable raspotify

## Clear the Bash History
* history -c
* history -w