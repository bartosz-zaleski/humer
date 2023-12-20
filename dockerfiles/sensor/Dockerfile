FROM ubuntu:latest

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y \
    python3 \
    python3-pip \
    libglib2.0-dev

RUN pip3 install lywsd03mmc

RUN useradd \
    --home-dir /home/hummer \
    --create-home \
    --shell /bin/bash \
    --groups sudo \
    hummer

USER hummer

ENTRYPOINT ["lywsd03mmc"]