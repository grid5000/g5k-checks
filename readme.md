## Build Debian package

### Build docker image

```bash
$ docker build -t g5kchecks .
```
```bash
$ podman build -t g5kchecks .
```

### Run docker

```bash
$ docker run --rm -it -v $(pwd):/sources g5kchecks
```
```bash
$ podman run --rm -it -v $(pwd):/sources g5kchecks
```

Checks `./build` directory.

