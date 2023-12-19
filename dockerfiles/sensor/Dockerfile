FROM ubuntu:latest

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y \
    python3 \
    python3-pip \
    libglib2.0-dev

RUN useradd \
    --home-dir /home/hummer \
    --create-home \
    --shell /bin/bash \
    --groups sudo \
    hummer


RUN pip3 install lywsd03mmc

USER hummer

# Is the user necessary? Output from this should be consumed by database feeder

USER root


ENTRYPOINT ["lywsd03mmc"]