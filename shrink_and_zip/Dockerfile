FROM ubuntu:18.04
RUN apt-get update -y && apt-get install -y \
    git \
    parted \
    zip
RUN git clone https://github.com/Drewsif/PiShrink.git
COPY shrink_and_zip_image.sh /usr/local/bin
ENV PATH=/PiShrink/:${PATH}
WORKDIR /mnt/host
ENTRYPOINT ["shrink_and_zip_image.sh"]
