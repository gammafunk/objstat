#!/bin/bash

## Run an individual objstat job

remove_summary=false
need_tty=false
out_dir=.
crawl_dir=.
num_iters=1
levels=
while getopts "h?rtc:d:l:n:" opt; do
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
        r)  remove_summary=true
            ;;
        t)  need_tty=true
            ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

tldir=$(cd "$crawl_dir" && git rev-parse --show-toplevel)
source_dir="$tldir/crawl-ref/source"

echo "Running objstat in dir $out_dir for $num_iters iterations"
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
$tty_command ./crawl -objstat "$levels" -iters "$num_iters"
rm -r $tty_command crawl dat morgue saves
## Remove the AllLevels summary
if [ "$remove_summary" = "true" ]; then
    for i in objstat*.txt
    do
        cat "$i" | grep -v AllLevels > tmp.$$
        mv tmp.$$ "$i"
    done
fi
zip "$out_dir".zip objstat*.txt >/dev/null
echo "Objstat in dir $out_dir complete"
