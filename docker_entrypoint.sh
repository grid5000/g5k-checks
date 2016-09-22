#!/bin/sh

set -e

cd /sources
mk-build-deps --install
debuild -us -uc
if [ ! -d build ]; then mkdir build; fi
cp ../g5kchecks* build
rm g5kchecks-build-deps*.deb

