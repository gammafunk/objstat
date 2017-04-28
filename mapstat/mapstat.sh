#!/bin/bash

## Script to run mapstat with parallel jobs

num_iters=1
crawl_dir=.
num_jobs=1

while getopts "h?c:j:l:n:" opt; do
    case "$opt" in
        h|\?)
            echo "$0 [-c <crawl-dir> ] [-j <num>] [-n <num>] [-l <levels>]"
            exit 0
            ;;
        c)  crawl_dir="$OPTARG"
            ;;
        j)  num_jobs="$OPTARG"
            ;;
        l)  levels="$OPTARG"
            ;;
        n)  num_iters="$OPTARG"
            ;;
    esac
done



tldir=$(cd "$crawl_dir" && git rev-parse --show-toplevel)
source_dir="$tldir/crawl-ref/source"
if [ "$num_jobs" = 1 ]; then
    ./mapstat-job.sh -c "$crawl_dir" -d "job_1" -l "$levels" \
                     -n "$num_iters"
else
    # Need fake_pty since these are being run through parallel without a tty.
    # one-week timeout.
    gcc -DTIMEOUT=10080 "$source_dir"/util/fake_pty.c -o fake_pty -lutil

    iters_per_job=$((num_iters / num_jobs))
    command=
    for ((i=1; i <= num_jobs; i++)); do
        command+="./mapstat-job.sh -t -c \"$crawl_dir\" -d \"job_${i}\""
        command+=" -l \"${job_levels[$j]}\" -n \"$iters_per_job\""
        command+=$'\n'
    done
    parallel --ungroup <<< "$command"
fi
