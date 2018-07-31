#!/bin/sh
var="$1"
if [ -z "$var" ]; then
    echo "usage: $0 mean|min|max"
    exit -1
fi
case $var in
    mean) ext="";;
    min|max) ext="_$var";;
    *) echo "$0: error: unknown variable $var, should be mean|min|max"; exit -1;;
esac
yr=`date -d '1 week ago' +%Y`
infile=cet_${var}_est_$yr
url=https://www.metoffice.gov.uk/hadobs/hadcet/$infile
wget -N --no-check-certificate $url
file=cet_${var}_ext.dat
cat > $file <<EOF
# source_url :: $url
# T$var [Celsius] CET $var temperature
EOF
month=0
while [ $month -lt 12 ]; do
    ((month++))
    echo $yr $month
    day=0
    tail -n +5 $infile | sed -e 's/ */ /' | while [ $day -lt 31 ]; do
        ((day++))
        read line
        val=`echo $line | cut -f $((month+1)) -d ' ' | sed -e 's/\(.$\)/.\1/'`
        if [ $val != -3276.8 ]; then
            echo "$yr $month $day $val" >> $file
        fi
    done
done
set -x
patchseries daily_cet$ext.dat $file > daily_cet${ext}_ext.dat
# let's give it the same name as the old one
mv daily_cet${ext}_ext.dat daily_cet${ext}.dat