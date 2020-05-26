#!/bin/bash

# if systemd service installed, then stop it, otherwise terminate
if [ "$(systemctl|grep ton-validator)" != "" ]
then
    systemctl stop ton-validator
else
    pkill -SIGTERM validator-engin
fi
