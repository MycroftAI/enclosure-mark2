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
# This script sets up a Mark 2 Pi base image off of a Mark 1 image. 
# Switches from debian package install to source install.

# Remove Debian package versions of Core and Mark 1 and Arduino bits
sudo systemctl stop mycroft*
sudo rm /etc/cron.hourly/mycroft-core
sudo apt-get purge -y mycroft-core
sudo rm -rf /opt/venvs/mycroft-core/

# Update mycroft-wifi-setup so update does not reinstall mycroft-core package
sudo apt-get update
sudo apt-get install -y mycroft-wifi-setup
sudo apt-get install -y mycroft-mark2
