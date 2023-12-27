FROM ubuntu:latest

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y \
    python3 \
    python3-pip \
    libglib2.0-dev

RUN pip3 install lywsd03mmc

COPY lywsd03mmc /usr/local/bin/lywsd03mmc

ENTRYPOINT ["lywsd03mmc"]