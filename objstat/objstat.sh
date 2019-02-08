#!/bin/bash

## Script to run objstat to make 4 different datasets: 3-rune branches with
## swamp+snake, 3-rune with shoals+spider, extended without abyss,pan,zig, and
## abyss,pan,zig

num_iters=1
crawl_dir=.

declare -A job_levels
declare -A job_args
base_levels="Bailey,Bazaar,Crypt,D,Depths,Desolation,Elf,IceCv,Gauntlet,Lair,Orc"
base_levels+=",Ossuary,Sewer,Temple,Trove,Vaults,Volcano,WizLab,Zot"

job_levels["3-rune-swamp-snake"]="${base_levels},Swamp,Snake"
job_args["3-rune-swamp-snake"]=

job_levels["3-rune-shoals-spider"]="${base_levels},Shoals,Spider"
job_args["3-rune-shoals-spider"]=

job_levels["extended-no-abyss-pan-zig"]="${job_levels[3-rune-swamp-snake]}"
job_levels["extended-no-abyss-pan-zig"]+=",Coc,Dis,Geh,Hell,Slime,Tar,Tomb"
job_args["extended-no-abyss-pan-zig"]=

job_levels["abyss-pan-zig"]="Abyss,Pan,Zig"
job_args["abyss-pan-zig"]="-r"

## Run all jobs by default; this makes them run in a specific order.
default_jobs="extended-no-abyss-pan-zig 3-rune-swamp-snake"
default_jobs+=" 3-rune-shoals-spider abyss-pan-zig"
job=
do_parallel=false

while getopts "h?pc:n:j:" opt; do
    case "$opt" in
        h|\?)
            echo "$0 [-p] [-c <crawl-dir> ] [-j <job-name>] [-n <num>]"
            exit 0
            ;;
        c)  crawl_dir="$OPTARG"
            ;;
        j)
            if [ -z "${job_levels[$OPTARG]}" ]; then
                echo "Job name must be one of: ${!job_levels[@]}"
                exit 1
            else
                job="$OPTARG"
            fi
            ;;
        n)  num_iters="$OPTARG"
            ;;
        p)  do_parallel=true
    esac
done


tldir=$(cd "$crawl_dir" && git rev-parse --show-toplevel)
source_dir="$tldir/crawl-ref/source"
if [ -n "$job" ]; then
    ./objstat-job.sh -c "$crawl_dir" -d "$job" -l "${job_levels[$job]}" \
                     -n "$num_iters" ${job_args[$job]}
elif [ "$do_parallel" = "true" ]; then
    # Need fake_pty since these are being run through parallel without a tty.
    # one-week timeout. A single job can take a few days on a EC2 micro
    # instance with only 10% of one cpu.
    gcc -DTIMEOUT=10080 "$source_dir"/util/fake_pty.c -o fake_pty -lutil

    command=
    for j in $default_jobs; do
        command+="time ./objstat-job.sh -t -c \"$crawl_dir\" -d \"$j\""
        command+=" -l \"${job_levels[$j]}\" ${job_args[$j]} -n \"$num_iters\""
        command+=$'\n'
    done
    parallel --ungroup <<< "$command"
else
    for j in $default_jobs; do
        time ./objstat-job.sh -c "$crawl_dir" -d "$j" -l "${job_levels[$j]}" \
             ${job_args[$j]} -n "$num_iters"
    done
fi
