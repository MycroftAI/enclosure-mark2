#!/bin/bash
##########################################################################
# auto_run.sh - Mark 2pi
#
# Copyright 2019 Mycroft AI Inc.
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

# This script is executed by the .bashrc every time someone logs in to the
# system (including shelling in via SSH).

# DO NOT EDIT THIS SCRIPT!  It may be replaced later by the update process,
# but you can edit and customize the audio_setup.sh and custom_setup.sh
# script.  Use the audio_setup.sh to change audio output configuration and
# default volume; use custom_setup.sh to initialize any other IoT devices.
#

export PATH="$HOME/bin:$HOME/mycroft-core/bin:$PATH"


function speak() {
    ~/mycroft-core/mimic/bin/mimic -t $@ -o /tmp/speak.wav
    wavcmd=$( jq -r ".play_wav_cmdline" /etc/mycroft/mycroft.conf )
    wavcmd="${wavcmd/\%1/\/tmp\/speak.wav}"
    $( $wavcmd >/dev/null 2>&1 )
}

# this will regenerate new ssh keys on boot
# if keys don't exist. This is needed because
# ./bin/mycroft-wipe will delete old keys as
# a security measures
if ! ls /etc/ssh/ssh_host_* 1> /dev/null 2>&1; then
    echo "Generating fresh ssh host keys"
    sudo dpkg-reconfigure openssh-server
    sudo systemctl restart ssh
    echo "New ssh host keys were created. this requires a reboot"
    sleep 2
    sudo reboot
fi

# Read the current mycroft-core version
source mycroft-core/venv-activate.sh -q
mycroft_core_ver=$(python -c "import mycroft.version; print('mycroft-core: '+mycroft.version.CORE_VERSION_STR)" && echo "steve" | grep -o "mycroft-core:.*")
mycroft_core_branch=$(cd mycroft-core && git branch | grep -o "/* .*")

if [ "$SSH_CLIENT" == "" ] && [ "$(/usr/bin/tty)" = "/dev/tty1" ];
then
    # running at the local console (e.g. plugged into the HDMI output)

    # Set audio output volume to a reasonable level initially
    sudo i2cset -y 1 0x4b 25

    # Look for internet connection.
    if ping -q -c 1 -W 1 1.1.1.1 >/dev/null 2>&1
    then
        echo "**** Checking for updates to Mark 2 environment"
        cd /tmp
        wget -N -q https://raw.githubusercontent.com/MycroftAI/enclosure-mark2/master/home/pi/version >/dev/null
        if [ $? -eq 0 ]
        then
            if [ ! -f ~/version ] ; then
                echo "unknown" > ~/version
            fi

            cmp /tmp/version ~/version
            if  [ $? -eq 1 ]
            then
                # Versions don't match...update needed
                echo "**** Update found, downloadling new Mark 2 scripts!"
                speak "Updating Mark 2, please hold on."

                # Stop interactive parts of mycroft, as we don't
                # want the user interacting with it while updating.
                sudo service mycroft-skills stop

                wget -N -q https://raw.githubusercontent.com/MycroftAI/enclosure-mark2/master/home/pi/update.sh
                if [ $? -eq 0 ]
                then
                    source update.sh
                    cp /tmp/version ~/version

                    # restart
                    echo "Restarting..."
                    speak "Update complete, restarting."
                    sudo reboot now
                else
                    echo "ERROR: Failed to download update script."
                fi
            fi
        fi

        # TODO: Skip update check if done recently?
        echo -n "Checking for mycroft-core updates..."
        cd ~/mycroft-core
        git pull
        cd ~
    fi

    # Launch pulseaudio if needed
    if ! pidof pulseaudio > /dev/null; then
        pulseaudio -D
        sleep 1
    fi
    # Launch Mycroft Services ======================
    bash "$HOME/mycroft-core/start-mycroft.sh" all > /dev/null 2>&1
else
    # running in SSH session
    echo
fi

sleep 2
clear
cat mycroft.fb > /dev/fb0
