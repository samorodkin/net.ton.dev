#!/bin/bash
#
# Script copies updated data from RAM (ton-work2) to disk (ton-work)
#

cp -R /var/ton-work2/etc /var/ton-work
cp -R /var/ton-work2/db/adnl          /var/ton-work/db
sleep 1
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
