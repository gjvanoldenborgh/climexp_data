#!/bin/sh
files="$@"
if [ -z "$files" ]; then
  echo "usage: $0 files"
  echo "       copies files to Climate Explorer"
fi
cwd=`pwd`
dir=`basename $cwd`
[ -z "$HOST" ] && HOST=`hostname`
if [ $HOST = pc160050.knmi.nl -o $HOST = bvlclim.knmi.nl ]; then
  rsync --copy-links -e ssh "$@" climexp.knmi.nl:climexp/$dir/
fi
