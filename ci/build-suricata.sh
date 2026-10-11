#!/bin/sh
#
# Build Suricata and install it with its headers and libsuricata-config.
#
# Usage: build-suricata.sh <branch> <prefix>
#
# <branch> is a git branch or tag of OISF/suricata, for example "main" or
# "main-8.0.x".

set -e

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <branch> <prefix>" >&2
    exit 1
fi

branch="$1"
prefix="$2"

git clone --depth 1 --branch "$branch" https://github.com/OISF/suricata suricata
cd suricata
./autogen.sh
./configure --prefix="$prefix" --disable-gccmarch-native
make -j "$(nproc)"
make install install-headers

# "make install-library" would also install libsuricata-config, but it
# installs the large static libraries too, which plugins don't need.
install -m 0755 libsuricata-config "$prefix/bin/libsuricata-config"
