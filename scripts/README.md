# README

This HOWTO contains instructions on how to use some of the scripts located here. The instructions and scripts below were verified on Ubuntu 18.04 and 20.04. Monitoring dashboard setup instructions see configs/telegraf.conf
# Scripts

## build.sh
Script for building a node from online git repository.

## setup.sh
Script to setup a node, which you normally run only once after initial `git clone` and `build.sh`.

## setup_systemd.sh
Script to setup the existing node as systemd service. 

## run.sh
Script to start the node, whether it is service or not.

## stop.sh
Script to stop the node, whether it is service or not.

## node_update.sh
Script to update validator node with minimal downtime.

1. Checks for any new changes in git repository, exits if none.
      Optionally pass in `$1` specific branch or commit..
2. Get updates from git.
      No git stash done, so script exits if any local uncommitted changes present.
3. Runs `build.sh` to create new version of binaries.
4. Terminates validator engine processes.
5. Truncates ever-growing log file and archive it
      Preserves tail lines from old log, so you easily monitor any changes!
6. Starts the node.

Examples:

 - Check with specific branch or commit:
   `./node_update.sh 5e0fc9790cc337a390e469d3267a02b141ef177d`

 - Run from cron once a day at 9am and relax:
   `0 9 * * * <scripts-path>/node_update.sh | tee -a <scripts-path>/updater.log 2>&1`

## node_avg.sh
Script counts and displays average duration time from `node.log`.
If not enough lines present, then it waits for log file to grow.
Note:
   this is a very rough performance measurement, and for better results,
   I belive we should grep timings of only one type of operations.
Primary purpose is monitoring with external tools (at least until tonos-cli upgrade).

Example:
 - Display average from 100 measures
   `./node_avg.sh 100`

## get_balance.sh
Simple script which displays current wallet's balance. Primary purpose is monitoring with external tools (at least until tonos-cli upgrade).

Example:
   `./get_balance.sh`
   `./get_balance.sh <ALONGBUTNOTLONELYWALLET>`

