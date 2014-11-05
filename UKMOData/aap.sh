#!/bin/sh
# download the EN3 objective ocean analysis

base=http://hadobs.metoffice.com/en3/data/EN3_v2a
version=EN3_v2a

yr=1994
OK=true
while [ $OK = true ]; do
    echo $((++yr))
    file=${version}_ObjectiveAnalyses_$yr.tar
    wget -N $base/$file
    if [ ! -s $file ]; then
	OK=false
    fi
done

