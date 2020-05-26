#!/bin/bash -eE

#
# Install Validator node as systemd service.
# Necessary for standardized management, auto-restart on startup or failure. 
#
# Assumes that node is built and setup.
# Example run after build.sh and setup.sh:
#   sudo node_systemd.sh
#

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

if [ ! -f $SCRIPT_DIR/run.sh ]; then
    echo "Cannot find TON_WORK_DIR/run.sh!"
    echo "Please build and setup Validator node first."
    exit
fi

if [ "$(pgrep validator-engin)" != "" ]; then
    echo "Validator-engine already running!"
    echo "Please stop it to proceed using: pkill -SIGTERM validator-engin"
    exit
fi

SYSTEMD_DIR=/etc/systemd/system
if [ ! -f $SYSTEMD_DIR/ton-validator.service ]; then

    echo "Systemd service not found - installing!"
    cp ../configs/ton-validator.service.template $SYSTEMD_DIR/
    ESCAPED=$(echo $SCRIPT_DIR | sed 's_/_\\/_g')
    sed -i -e "s/SCRIPT_DIR/$ESCAPED/g" $SYSTEMD_DIR/ton-validator.service.template
    mv $SYSTEMD_DIR/ton-validator.service.template $SYSTEMD_DIR/ton-validator.service
    systemctl daemon-reload
    systemctl enable ton-validator
    systemctl start ton-validator
    sleep 3

    echo "Getting status..."
    systemctl status ton-validator
else

    echo "Systemd service $SYSTEMD_DIR/ton-validator.service - already setup!"
fi

echo "Done!"
