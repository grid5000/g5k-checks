#!/bin/sh

set -e

TARGETDIR=${TARGETDIR:-build}

mk-build-deps -ir -t 'apt-get -y --no-install-recommends'
dpkg-buildpackage
if [ ! -d build ]; then mkdir $TARGETDIR; fi
cp ../g5k-checks*.deb $TARGETDIR/
if ls g5k-checks-build-deps_* 1> /dev/null 2>&1; then rm g5k-checks-build-deps_*; fi
