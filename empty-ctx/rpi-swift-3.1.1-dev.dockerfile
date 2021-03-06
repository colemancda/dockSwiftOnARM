# Dockerfile
#
#   docker run -i --tty --name "swift-dev" --rm helje5/rpi-swift-dev:3.1.1
#
FROM helje5/rpi-swift:3.1.1

# rpi-swift sets it to swift
USER root

ENV DEBIAN_FRONTEND noninteractive

ARG CLANG_VERSION=3.8

RUN apt-get install -y apt-utils \
                       vim emacs make \
                       git libicu55 libedit2

# rpi-swift is installing stuff into site-packages, need to move them away
RUN bash -c "\
  mv /usr/lib/python2.7/site-packages /usr/lib/python2.7/site-packages.swift; \
  apt-get install -y python2.7-minimal; \
  mv /usr/lib/python2.7/site-packages.swift/* \
     /usr/local/lib/python2.7/dist-packages/; \
  rmdir /usr/lib/python2.7/site-packages.swift \
"

RUN apt-get install -y \
  python                      \
  \
  clang-$CLANG_VERSION libc6-dev \
  \
  libicu-dev                  \
  autoconf libtool pkg-config \
  libblocksruntime-dev        \
  libkqueue-dev               \
  libpthread-workqueue-dev    \
  systemtap-sdt-dev           \
  libbsd-dev libbsd0          \
  curl libcurl4-openssl-dev   \
  libedit-dev                 \
  libxml2                     \
  wget sudo

RUN bash -c "update-alternatives --quiet --install /usr/bin/clang \
               clang   /usr/bin/clang-$CLANG_VERSION   100;\
             update-alternatives --quiet --install /usr/bin/clang++ \
               clang++ /usr/bin/clang++-$CLANG_VERSION 100"

# setup sudo # TODO: sounds like we are supposed to use gosu instead

RUN bash -c "\
  adduser swift sudo; \
  echo 'swift ALL=(ALL:ALL) ALL' > /etc/sudoers.d/swift; \
  chmod 0440 /etc/sudoers.d/swift; \
  echo 'swift:swift' | chpasswd \
"

USER swift
WORKDIR /home/swift
