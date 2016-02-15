#!/bin/bash

## Script to run objstat to make 4 different datasets: 3-rune branches with
## swamp+snake, 3-rune with shoals+spider, extended without abyss,pan,zig, and
## abyss,pan,zig

NUM_ITERS=5
CRAWL_DIR=.
declare -A JOBS
JOBS["3-rune-swamp-snake"]="D,Temple,Sewer,Ossuary,Orc,Elf,Bailey,Lair, \
                            Swamp,Snake,IceCv,Volcano,Lab,Trove,Vaults, \
                            Crypt,Bazaar,WizLab,Depths,Zot"
JOBS["3-rune-shoals-spider"]="D,Temple,Sewer,Ossuary,Orc,Elf,Bailey,Lair,\
                              Shoals,Spider,IceCv,Volcano,Lab,Trove, \
                              Vaults,Crypt,Bazaar,WizLab,Depths,Zot"
JOBS["extended-no-abyss-pan-zig"]="D,Temple,Sewer,Ossuary,Orc,Elf,Bailey, \
                                   Lair,Swamp,Snake,Slime,IceCv,Volcano, \
                                   Lab,Trove,Vaults,Crypt,Tomb,Bazaar, \
                                   WizLab,Depths,Zot,Hell,Geh,Coc,Dis,Tar"
JOBS["abyss-pan-zig"]="Abyss,Pan,Zig"
JOB=
PARALLEL=false

function do_help() {
    echo "$0 [-p] [-c <crawl-dir> ] [-j <job-name>] [-n <num>]"
}

while getopts "h?pc:n:j:" opt; do
    case "$opt" in
        h|\?)
            do_help
            exit 0
            ;;
        c)  CRAWL_DIR="$OPTARG"
            ;;
        j)
            if [ -z "${JOBS[$OPTARG]}" ]; then
                echo "Job name must be one of: ${!JOBS[@]}"
                exit 1
            else
                JOB="$OPTARG"
            fi
            ;;
        n)  NUM_ITERS="$OPTARG"
            ;;
        p)  PARALLEL=true
    esac
done


tldir=`cd "$CRAWL_DIR" && git rev-parse --show-toplevel`
SDIR="$tldir/crawl-ref/source"


if [ -n "$JOB" ]; then
    JOB_ARGS=
    if [ "$JOB" = "abyss-pan-zig" ]; then
        JOB_ARGS="-r"
    fi
    ./objstat-job.sh -c "$CRAWL_DIR" -d "$JOB" -l "${JOBS[$JOB]}" -n "$NUM_ITERS" "$JOB_ARGS"
elif [ "$PARALLEL" = "true" ]; then
    # Need fake_pty since these are being run through parallel without a tty.
    # one-week timeout. A single job can take a few days on a EC2 micro instance
    # with only 10% of one cpu.
    gcc -DTIMEOUT=10080 "$SDIR"/util/fake_pty.c -o fake_pty -lutil

    parallel --ungroup <<EOF
./objstat-job.sh -t -c "$CRAWL_DIR" -d 3-rune-swamp-snake -l "${JOBS[3-rune-swamp-snake]}" -n "$NUM_ITERS"
./objstat-job.sh -t -c "$CRAWL_DIR" -d 3-rune-shoals-spider -l "${JOBS[3-rune-shoals-spider]}" -n "$NUM_ITERS"
./objstat-job.sh -t -c "$CRAWL_DIR" -d extended-no-abyss-pan-zig -l "${JOBS[extended-no-abyss-pan-zig]}" -n "$NUM_ITERS"
./objstat-job.sh -t -c "$CRAWL_DIR" -d abyss-pan-zig -l "${JOBS[abyss-pan-zig]}" -n "$NUM_ITERS" -r
EOF
else
    ./objstat-job.sh -c "$CRAWL_DIR" -d 3-rune-swamp-snake -l "${JOBS[3-rune-swamp-snake]}" -n "$NUM_ITERS"
    ./objstat-job.sh -c "$CRAWL_DIR" -d 3-rune-shoals-spider -l "${JOBS[3-rune-shoals-spider]}" -n "$NUM_ITERS"
    ./objstat-job.sh -c "$CRAWL_DIR" -d extended-no-abyss-pan-zig -l "${JOBS[extended-no-abyss-pan-zig]}" -n "$NUM_ITERS"
    ./objstat-job.sh -c "$CRAWL_DIR" -d abyss-pan-zig -l "${JOBS[abyss-pan-zig]}" -n "$NUM_ITERS" -r
fi
