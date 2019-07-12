# Mycroft Mark 2 Pi Enclosure

This repository holds the files, documentation and scripts for building Mark 2 Pi device images.

image_recipe.md
Documentation on going from Mark 1 to Mark 2 Pi.

setup.sh
Script to set up Mark 2 Pi off of Mark I image.

update.sh
Pulls down latest scripts from this repo:
    .bashrc
        Runs auto_run.sh on startup. Bash config.
        
    auto_run.sh
        The startup script for the device. Starts mycroft-core.

    version
        Release versioning for repository.

    mycroft-wipe
        Prepares device for imaging. Resets wifi and pairing setup.

etc/mycroft/mycroft.conf
    System level configuration file.