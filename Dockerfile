FROM resin/raspberrypi3-python:2.7-slim
MAINTAINER orbsmiv@hotmail.com

RUN [ "cross-build-start" ]

# Set environment variables
ENV DEBIAN_FRONTEND noninteractive

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
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
        && mkdir /tmp/jackd-compile \
        && git clone --depth 1 git://github.com/jackaudio/jack2 /tmp/jackd-compile \
        && cd /tmp/jackd-compile \
        && export CC=/usr/bin/gcc-4.8 \
        && export CXX=/usr/bin/g++-4.8 \
        && ./waf configure --alsa \
        && ./waf build \
        && ./waf install \
        && ldconfig \
        && cd / \
        && apt-get purge \
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
          g++-4.8 \
        && apt-get autoremove \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
        && rm -rf /tmp/jackd-compile


RUN echo "@audio - memlock 256000" >> /etc/security/limits.conf \
        && echo "@audio - rtprio 75" >> /etc/security/limits.conf


ENTRYPOINT ["/usr/local/bin/jackd"]
CMD ["-P75", "-dalsa", "-dhw:1", "-p1024", "-n3", "-s", "-r44100"]

RUN [ "cross-build-end" ]
