FROM resin/raspberrypi3-python:2.7-slim AS build
MAINTAINER orbsmiv@hotmail.com

RUN [ "cross-build-start" ]

# Set environment variables
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
        apt-get install -y --no-install-recommends \
          alsa-base \
          libicu-dev \
          libasound2-dev \
          libsamplerate0-dev \
          libsndfile1-dev \
          libreadline-dev \
          libxt-dev \
          libudev-dev \
          libavahi-client-dev \
          git \
          gcc-4.8 \
          g++-4.8 && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /tmp/jackd-compile \
        && git clone --depth 1 git://github.com/jackaudio/jack2 /tmp/jackd-compile

ARG CC=/usr/bin/gcc-4.8
ARG CXX=/usr/bin/g++-4.8

WORKDIR /tmp/jackd-compile

RUN ./waf configure --alsa --libdir=/usr/lib/arm-linux-gnueabihf/
RUN ./waf build
RUN ./waf install
RUN ldconfig

RUN [ "cross-build-end" ]

FROM resin/armv7hf-debian:latest

RUN [ "cross-build-start" ]

ARG DEBIAN_FRONTEND=noninteractive

COPY --from=build /usr/local/bin/jackd /usr/local/bin/jackd

RUN echo "@audio - memlock 256000" >> /etc/security/limits.conf \
        && echo "@audio - rtprio 75" >> /etc/security/limits.conf

# ENTRYPOINT ["/usr/local/bin/jackd"]
CMD ["/usr/local/bin/jackd", "-r", "-v", "-d", "alsa", "-d", "hw:0", "-p", "1024", "-n", "3", "-s", "-r", "48000", "-P"]

RUN [ "cross-build-end" ]
