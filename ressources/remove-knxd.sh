#!/bin/bash
INSTALL_DIR=/usr/local/bin
TEMP_DIR=`mktemp -d /tmp/knxd.XXXXXX`
KNXD_bin=$INSTALL_DIR/knxd
sudo systemctl stop knxd.service
sudo systemctl disable knxd.service

#apt-get -qy install update
#apt-get -qy install git-core
#apt-get -qy install build-essential 
#apt-get -qy install cdbs
#apt-get -qy install autoconf
#apt-get -qy install libtool
#apt-get -qy install libusb-1.0-0-dev
#apt-get -qy install pkg-config
#apt-get -qy install libsystemd-deamon-dev 
#apt-get -qy install dh-systemd
sudo apt-get -qy purge knxd
cd $TEMP_DIR
rm /etc/knxd/pthsem_VERSION
rm /etc/knxd/KNXD_VERSION
rm -R pthsem-2.0.8
rm -R knxd