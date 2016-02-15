#!/bin/bash

## Run an individual objstat job

REMOVE_SUMMARY=false
NEED_TTY=false
OUT_DIR=.
CRAWL_DIR=.
NUM_ITERS=5
LEVELS=
while getopts "h?rtc:d:l:n:" opt; do
    case "$opt" in
        h|\?)
            echo "$0 [-t] [-r] [-c <crawl-dir>] [-d <out-dir>] [-l <levels>] [-n <num>]"
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
        r)  REMOVE_SUMMARY=true
            ;;
        t)  NEED_TTY=true
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


TTY_COMMAND=
if [ "$NEED_TTY" = "true" ]; then
    TTY_COMMAND=fake_pty
fi
cp -r $TTY_COMMAND $SDIR/crawl $SDIR/dat $OUT_DIR
cd "$OUT_DIR"

## Have to build the db first since crawl gets confused when building
## the map cache time under objstat/mapstat.
./crawl -builddb
./$TTY_COMMAND ./crawl -objstat "$LEVELS" -iters $NUM_ITERS
rm -r $TTY_COMMAND crawl dat morgue saves
## Remove the AllLevels summary
if [ "$REMOVE_SUMMARY" = "true" ]; then
    for i in objstat*.txt
    do
        cat "$i" | grep -v AllLevels > tmp.$$
        mv tmp.$$ "$i"
    done
fi
zip "$OUT_DIR".zip objstat*.txt >/dev/null
echo "Objstat in dir $OUT_DIR complete"
