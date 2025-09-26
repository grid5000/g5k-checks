#!/bin/sh

set -e

TARGETDIR=${TARGETDIR:-build}

mk-build-deps -ir -t 'apt-get -y --no-install-recommends'
dpkg-buildpackage
if [ ! -d build ]; then mkdir $TARGETDIR; fi
cp ../g5k-checks*.deb $TARGETDIR/
rm g5k-checks-build-deps_*

