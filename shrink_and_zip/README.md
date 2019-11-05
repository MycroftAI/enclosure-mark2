PiShrink runs on Linux so for those running on MacOS wanting to use PiShrink and zip the image up this container will do that for you. 

First get the raw image from MacOS terminal with: `sudo dd if=/dev/rdisk2 of=mark2pi-20190718-raw.img bs=20m`

Build (from shrink_and_zip/ directory): `docker build -t shrink_and_zip .`

Run (from directory with raw image in it): `docker run --privileged --rm -it --volume=$PWD:/mnt/host shrink_and_zip mark2pi-20191104-raw.img`
