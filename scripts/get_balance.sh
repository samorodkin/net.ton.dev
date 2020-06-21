#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

cd $SCRIPT_DIR

if [ "$1" == "" ]
then
  addr=$( cat $KEYS_DIR/$(hostname -s).addr )
else
  addr=$1
fi

$TONOS_CLI_SRC_DIR/target/release/tonos-cli account $addr | grep balance | awk '{ print $2/1000000000 }'

