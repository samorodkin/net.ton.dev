#!/bin/bash -eE

# Script to update Validator Node with minimal downtime
#
# 1. Checks for any new changes in git repository, exits if none.
#	Optionally pass in $1 specific branch or commit..
# 2. Get updates from git.
#	No git stash done, so script exits if any local uncommitted changes present.
# 3. Runs build.sh
# 4. Terminates validator engine processes.
# 5. Truncates ever-growing log file and archive it
#	Preserves tail lines from old log, so you easily monitor any changes!
# 6. Starts node.
#
# Examples:
#
# - Check with specific branch or commit:
#   ./node_update.sh 5e0fc9790cc337a390e469d3267a02b141ef177d
#
# - Run from cron once a day at 9am and relax:
#   0 9 * * * <scripts-path>/node_update.sh | tee -a <scripts-path>/updater.log 2>&1
#
# Tested on Ubuntu 18
#

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=env.sh
. "${SCRIPT_DIR}/env.sh"

# Checks for any new changes in git
UPSTREAM=${1:-'@{0}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
    echo "Up-to-date"
    exit
elif [ $LOCAL = $BASE ]; then
    echo "Need to pull"
elif [ $REMOTE = $BASE ]; then
    echo "Need to push"
    exit
else
    echo "Diverged"
    exit
fi

git pull

echo "Building..."
./build.sh

echo "Stopping validator engine..."
./stop.sh

echo "Rotating logs..."
LOGFILE="$TON_WORK_DIR/node.log"
# move old logs to archive
gzip -m $LOGFILE.*
# put current log w/datetime on review
datetime=`date +%Y%m%d-%H%M`
mv $LOGFILE $LOGFILE.$datetime
touch $LOGFILE
# preserve tail lines
tail -n100 $LOGFILE.$datetime > $LOGFILE
# archive old log
gzip -m $LOGFILE.$datetime
#or for solid archive, if you prefer:
#find $LOGFILE.* ! -name 'node.log.zip' -type f -exec zip -m $LOGFILE.zip {} +

echo "Starting validator engine..."
./run.sh

