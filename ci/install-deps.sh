#!/bin/sh
#
# Install the packages needed to build Suricata, nDPI and the plugin, and
# to run Suricata, on Ubuntu.

set -e

sudo apt-get update
sudo apt-get -y install \
    autoconf \
    automake \
    build-essential \
    cbindgen \
    git \
    libcap-ng-dev \
    libjansson-dev \
    liblz4-dev \
    libmagic-dev \
    libnet1-dev \
    libpcap-dev \
    libpcre2-dev \
    libtool \
    libyaml-dev \
    pkg-config \
    python3 \
    zlib1g-dev
