#!/bin/bash

## Script to run objstat to make 4 different datasets: 3-rune branches with
## swamp+snake, 3-rune with shoals+spider, extended without abyss,pan,zig, and
## abyss,pan,zig

NUM_ITERS=5
CRAWL_DIR=.
while getopts "h?c:n:" opt; do
    case "$opt" in
        h|\?)
            echo "$0 [-c <crawl-dir> ] [-n <num>]"
            exit 0
            ;;
        c)  CRAWL_DIR="$OPTARG"
            ;;
        n)  NUM_ITERS="$OPTARG"
            ;;
    esac
done

SWSN_DIR=3-rune-swamp-snake
SWSN_LEV="D,Temple,Sewer,Ossuary,Orc,Elf,Bailey,Lair,Swamp,Snake,IceCv,Volcano,Lab,Trove,Vaults,Crypt,Bazaar,WizLab,Depths,Zot"

SHSP_DIR=3-rune-shoals-spider
SHSP_LEV="D,Temple,Sewer,Ossuary,Orc,Elf,Bailey,Lair,Shoals,Spider,IceCv,Volcano,Lab,Trove,Vaults,Crypt,Bazaar,WizLab,Depths,Zot"

EXT_DIR=extended-no-abyss-pan-zig
EXT_LEV="D,Temple,Sewer,Ossuary,Orc,Elf,Bailey,Lair,Swamp,Snake,Slime,IceCv,Volcano,Lab,Trove,Vaults,Crypt,Tomb,Bazaar,WizLab,Depths,Zot,Hell,Geh,Coc,Dis,Tar"

APZ_DIR=abyss-pan-zig
APZ_LEV="Abyss,Pan,Zig"

tldir=`cd "$CRAWL_DIR" && git rev-parse --show-toplevel`
SDIR="$tldir/crawl-ref/source"
# 24-hour timeout since a single job can take many hours
gcc -DTIMEOUT=1440 "$SDIR"/util/fake_pty.c -o fake_pty -lutil

parallel --ungroup <<EOF
./objstat-job.sh -c $CRAWL_DIR -d $APZ_DIR -l $APZ_LEV -n $NUM_ITERS -r
./objstat-job.sh -c $CRAWL_DIR -d $SWSN_DIR -l $SWSN_LEV -n $NUM_ITERS 
./objstat-job.sh -c $CRAWL_DIR -d $SHSP_DIR -l $SHSP_LEV -n $NUM_ITERS
./objstat-job.sh -c $CRAWL_DIR -d $EXT_DIR -l $EXT_LEV -n $NUM_ITERS
EOF

