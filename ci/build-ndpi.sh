#!/bin/sh
#
# Build nDPI from a git tag and install it.
#
# Usage: build-ndpi.sh <version> <prefix> [<source-dir>]
#
# The source tree is left in <source-dir> (default: ./nDPI-<version>) so
# it can also be used with --with-ndpi=<source-dir>. The pcap used by
# tests/smoke-test.sh is copied to <prefix>/share/ndpi/pcap.

set -e

if [ "$#" -lt 2 ]; then
    echo "usage: $0 <version> <prefix> [<source-dir>]" >&2
    exit 1
fi

version="$1"
prefix="$2"
srcdir="${3:-nDPI-$version}"

git clone --depth 1 --branch "$version" https://github.com/ntop/nDPI "$srcdir"
cd "$srcdir"

# nDPI 4.x's autogen.sh also runs configure with the given arguments.
./autogen.sh --prefix="$prefix" --with-only-libndpi
make -j "$(nproc)"
make install

mkdir -p "$prefix/share/ndpi/pcap"
cp tests/cfgs/default/pcap/http-basic-auth.pcap "$prefix/share/ndpi/pcap/"
