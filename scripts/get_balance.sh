#!/bin/bash

/home/dmitry/net.ton.dev/tonos-cli/target/release/tonos-cli account $1 | grep balance | awk '{ print $2/1000000000 }'
