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

export PATH="$HOME/bin:$HOME/mycroft-core/bin:$PATH"
source mycroft-core/venv-activate.sh -q
if [ "$SSH_CLIENT" == "" ] && [ "$(/usr/bin/tty)" = "/dev/tty1" ];
then
    # running at the local console (e.g. plugged into the HDMI output)

    # Set audio output volume to a reasonable level initially
    sudo i2cset -y 1 0x4b 25

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
