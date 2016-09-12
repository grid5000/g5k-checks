## Build Debian package

### Build docker image

  $ docker build --tag grid5000/g5kchecks-debuilt .

### Run docker

  $ docker run --rm -v $(pwd):/sources grid5000/g5kchecks-debuilt

Checks `./build` directory.

