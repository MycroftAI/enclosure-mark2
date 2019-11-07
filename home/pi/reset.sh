REPO_PATH="https://raw.githubusercontent.com/MycroftAI/enclosure-mark2/master"

# Reset Wi-Fi settings
cd /etc/wpa_supplicant
sudo wget -N $REPO_PATH/etc/wpa_supplicant/wpa_supplicant.conf
cd ~

# Unpair
rm -f ~/.mycroft/identity/identity2.json

# Remove Logs
rm /var/log/mycroft/*

# Shutdown 
#sudo shutdown now
