#!/bin/bash
#
# Script creates RAM-drive and copies database (without archive) there.
#
# Default size is 24G
#

#sudo mkdir /var/ton-work2
#sudo chown dmitry:dmitry /var/ton-work2
#chmod 755 /var/ton-work2
sudo mount -t tmpfs -o size=24G myramdisk /var/ton-work2

cp -R /var/ton-work/etc /var/ton-work2

mkdir /var/ton-work2/db/
ln -s /var/ton-work/db/archive       /var/ton-work2/db/archive
cp    /var/ton-work/db/config.json   /var/ton-work2/db/
cp -R /var/ton-work/db/adnl          /var/ton-work2/db
cp -R /var/ton-work/db/catchains     /var/ton-work2/db
cp -R /var/ton-work/db/celldb        /var/ton-work2/db
cp -R /var/ton-work/db/config.json   /var/ton-work2/db
cp -R /var/ton-work/db/dht*          /var/ton-work2/db
cp -R /var/ton-work/db/error         /var/ton-work2/db
cp -R /var/ton-work/db/files         /var/ton-work2/db
cp -R /var/ton-work/db/keyring       /var/ton-work2/db
cp -R /var/ton-work/db/overlays      /var/ton-work2/db
cp -R /var/ton-work/db/state         /var/ton-work2/db
cp -R /var/ton-work/db/tmp           /var/ton-work2/db

free

# sudo umount /var/ton-work/db2
