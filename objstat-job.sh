#!/bin/bash

## Run an individual objstat job

REMOVE_SUMMARY=0
OUT_DIR=.
CRAWL_DIR=.
NUM_ITERS=5
LEVELS=
while getopts "h?rc:d:l:n:" opt; do
    case "$opt" in
        h|\?)
            echo "$0 [-r] [-c <crawl-dir>] [-d <out-dir>] [-l <levels>] [-n <num>]"
            exit 0
            ;;
        c)  CRAWL_DIR="$OPTARG"
            ;;
        d)  OUT_DIR="$OPTARG"
            ;;
        l)  LEVELS="$OPTARG"
            ;;
        n)  NUM_ITERS="$OPTARG"
            ;;
        r)  REMOVE_SUMMARY=1
            ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift


tldir=`cd $CRAWL_DIR && git rev-parse --show-toplevel`
SDIR="$tldir/crawl-ref/source"

echo "Running objstat in dir $OUT_DIR for $NUM_ITERS iterations"
set -e
mkdir -p "$OUT_DIR"
cp -r fake_pty $SDIR/crawl $SDIR/dat $OUT_DIR
cd "$OUT_DIR"

## Have to build the db first since crawl gets confused when building
## the map cache time under objstat/mapstat.
./crawl -builddb
./fake_pty ./crawl -objstat "$LEVELS" -iters $NUM_ITERS
rm -r fake_pty crawl dat morgue saves
## Remove the AllLevels summary
if [ "$REMOVE_SUMMARY" -eq 1 ]
then
    for i in objstat*.txt
    do
        cat "$i" | grep -v AllLevels > tmp.$$
        mv tmp.$$ "$i"
    done
fi
zip "$1".zip objstat*.txt >/dev/null
echo "Objstat in dir $OUT_DIR complete"
