#!/bin/sh
files="$@"
if [ -z "$files" ]; then
  echo "usage: $0 files"
  echo "       copies files to Climate Explorer, ganesha and gatotkaca"
fi
cwd=`pwd`
dir=`basename $cwd`
if [ $HOST = pc160050.knmi.nl -o $HOST = bvlclim.knmi.nl ]; then
  rsync -e ssh -at --timeout=60 "$@" bhlclim:climexp/$dir/
  rsync -e ssh -avt --timeout=20 "$@" gj@gatotkaca.duckdns.org:NINO/$dir/
  ###rsync -e 'ssh -p 2222' -avt --timeout=10 "$@" gj@localhost:NINO/$dir/
  rsync -e ssh -avt --timeout=20 "$@" gj@ganesha.xs4all.nl:NINO/$dir/
fi

