FROM debian:bullseye
MAINTAINER support-staff@lists.grid5000.fr

RUN apt-get update && apt-get -y install build-essential devscripts equivs

WORKDIR /sources
ADD --chmod=555 docker_entrypoint.sh /build.sh
ENTRYPOINT /build.sh
