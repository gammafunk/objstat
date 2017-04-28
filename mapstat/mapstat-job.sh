#!/bin/bash

## Run an individual mapstat job

need_tty=false
out_dir=.
crawl_dir=.
num_iters=1
levels=
while getopts "h?c:d:l:n:t" opt; do
    case "$opt" in
        h|\?)
            help="$0 [-t] [-r] [-c <crawl-dir>] [-d <out-dir>] [-l <levels>]"
            help+=" [-n <num>]"
            echo "$help"
            exit 0
            ;;
        c)  crawl_dir="$OPTARG"
            ;;
        d)  out_dir="$OPTARG"
            ;;
        l)  levels="$OPTARG"
            ;;
        n)  num_iters="$OPTARG"
            ;;
        t)  need_tty=true
            ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

tldir=$(cd "$crawl_dir" && git rev-parse --show-toplevel)
source_dir="$tldir/crawl-ref/source"

echo "Running mapstat in dir $out_dir for $num_iters iterations"
set -e
mkdir -p "$out_dir"

tty_command=
if [ "$need_tty" = "true" ]; then
    tty_command=./fake_pty
fi
rm -rf "$out_dir/dat"
cp -r $tty_command "$source_dir/crawl" "$source_dir/dat" "$out_dir"
cd "$out_dir"

## Have to build the db first since crawl gets confused when building
## the map cache time under objstat/mapstat.
./crawl -builddb
$tty_command ./crawl -mapstat "$levels" -iters "$num_iters"
rm -r $tty_command crawl dat morgue saves
echo "Mapstat in dir $out_dir complete"
