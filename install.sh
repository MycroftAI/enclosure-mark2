#!/usr/bin/env bash
sudo avrdude -p atmega328p -C avrdude-gpio.conf -c linuxgpio -v -U flash:w:enclosure.hex
