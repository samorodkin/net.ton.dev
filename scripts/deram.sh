#!/bin/bash
#
# Script stops service, copies data from RAM to disk and Unmounts RAM drive.
#

./stop.sh

cp -R /var/ton-work2/etc /var/ton-work

#mkdir /var/ton-work2/db/
#ln -s /var/ton-work/db/archive       /var/ton-work2/db/archive
#cp    /var/ton-work/db/config.json   /var/ton-work2/db/
cp -R /var/ton-work2/db/adnl          /var/ton-work/db
cp -R /var/ton-work2/db/catchains     /var/ton-work/db
cp -R /var/ton-work2/db/celldb        /var/ton-work/db
cp -R /var/ton-work2/db/config.json   /var/ton-work/db
cp -R /var/ton-work2/db/dht*          /var/ton-work/db
cp -R /var/ton-work2/db/error         /var/ton-work/db
cp -R /var/ton-work2/db/files         /var/ton-work/db
cp -R /var/ton-work2/db/keyring       /var/ton-work/db
cp -R /var/ton-work2/db/overlays      /var/ton-work/db
cp -R /var/ton-work2/db/state         /var/ton-work/db
cp -R /var/ton-work2/db/tmp           /var/ton-work/db

sudo umount /var/ton-work2
