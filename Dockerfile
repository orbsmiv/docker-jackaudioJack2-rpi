FROM resin/raspberrypi3-python:2.7-slim AS build
MAINTAINER orbsmiv@hotmail.com

RUN [ "cross-build-start" ]

# Set environment variables
ARG DEBIAN_FRONTEND=noninteractive

ARG VERSION_TAG="v1.9.12"

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
          g++-4.8

RUN mkdir /tmp/jackd-compile \
        && git clone --recursive --depth 1 --branch ${VERSION_TAG} \
        git://github.com/jackaudio/jack2 /tmp/jackd-compile

ARG CC=/usr/bin/gcc-4.8
ARG CXX=/usr/bin/g++-4.8

WORKDIR /tmp/jackd-compile

RUN ./waf configure --alsa --libdir=/usr/lib/arm-linux-gnueabihf/
RUN ./waf build
RUN ./waf install
RUN ldconfig

RUN [ "cross-build-end" ]

FROM resin/armv7hf-debian:jessie

RUN [ "cross-build-start" ]

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /

COPY --from=build /usr/local/bin/jack* /usr/local/bin/
COPY --from=build /usr/local/bin/alsa* /usr/local/bin/
COPY --from=build /usr/local/share/man/man1/jack* /usr/local/share/man/man1/
COPY --from=build /usr/local/share/man/man1/alsa* /usr/local/share/man/man1/
COPY --from=build /usr/lib/arm-linux-gnueabihf/libjack* /usr/lib/arm-linux-gnueabihf/
COPY --from=build /usr/lib/arm-linux-gnueabihf/jack/* /usr/lib/arm-linux-gnueabihf/jack/
COPY --from=build /usr/local/include/jack/* /usr/local/include/jack/
COPY --from=build /usr/lib/arm-linux-gnueabihf/pkgconfig/jack.pc /usr/lib/arm-linux-gnueabihf/pkgconfig/jack.pc


RUN echo "@audio - memlock 256000" >> /etc/security/limits.conf \
        && echo "@audio - rtprio 75" >> /etc/security/limits.conf

ENTRYPOINT ["/usr/local/bin/jackd"]
CMD ["-r", "-v", "-d", "alsa", "-d", "hw:0", "-p", "1024", "-n", "3", "-s", "-r", "48000", "-P"]

# CMD ["/usr/local/bin/jackd", "-r", "-v", "-d", "alsa", "-d", "hw:0", "-p", "1024", "-n", "3", "-s", "-r", "48000", "-P"]

RUN [ "cross-build-end" ]
