#!/bin/bash

mkdir -p tmp_potwind
DEBUG=false
if [ "$DEBUG" != true ]; then
    wget=wget
    unzip=unzip
else
    echo "DEBUG, NO DATA RETRIEVED"
    wget="echo wget"
    unzip="echo unzip"
fi
# new data
base=http://projects.knmi.nl/klimatologie/onderzoeksgegevens/potentiele_wind-sigma/
$wget -O list.html $base
files=`fgrep .zip list.html | sed -e 's/^.*href=["]//' -e 's/["].*$//'`

for file in $files; do
    $wget -q -N $base$file
done

base=http://projects.knmi.nl/klimatologie/onderzoeksgegevens/potentiele_wind/up_upd/
# old data
histfile=20140307_update_up.zip
$wget -q -N $base/$histfile
# older data
oldfile=20090515_update_up.zip
$wget -q -N $base/$oldfile

cd tmp_potwind
for file in ../potwind*.zip; do
    $unzip -o $file
done
$unzip -o ../$histfile
$unzip -o ../$oldfile
cd ..


stations=`ls tmp_potwind | sed -e 's/potwind_//' -e 's/_.*$//' | sort | uniq`
nstations=`echo $stations | wc -w`
((nstations = nstations - 10)) # skipped files below
for ext in "" _sea _coast _land; do
    # this will be wrong when stations are added but it is purely cosmetic.
    case $ext in
        _sea) nstations=8;;
        _coast) nstations=11;;
        _land) nstations=36;;
    esac
    cat > list_upx$ext.txt <<EOF
located $nstations stations in 50.0N:56.5N, 1.5E:8.0E
EOF
    nstations=""
done
for station in $stations; do
    # stations with two numbers
    extrastation=XXX
    extrastation1=XXX
    case $station in
        252) extrastation=550;;
        254) extrastation=554;;
        269) extrastation=041;extrastation1=008;; # just a few months
        277) extrastation=605;;
        279) extrastation=615;;
        321) extrastation=553;;
        343) extrastation=609;;
        356) extrastation=604;;
        008) station=;;
        041) station=;;
        271) station=;; # second Stavoren station with no added value.
        550) station=;;
        553) station=;;
        554) station=;;
        604) station=;;
        605) station=;;
        609) station=;;
        615) station=;;
    esac
    if [ -n "$station" ]; then
        if [ ! -s latlon_wind$station.txt ]; then
            if [ ! -x RDNAPTRANS2008/rdnaptrans2008 ]; then
                cd RDNAPTRANS2008
                c++ -o rdnaptrans2008 rdnaptrans2008.cpp
                cd ..
            fi
            if [ ! -x RDNAPTRANS2008/rdnaptrans2008 ]; then
                echo "Please compile rdnaptrans2008.cpp"
                exit -1
            fi
            lastfile=`ls tmp_potwind/potwind_${station}_???? | tail -n 1`
            line=`fgrep COORDINATES $lastfile`
            x=`echo $line | sed -e 's/^.*X ://' -e 's/;.*$//'`
            y=`echo $line | sed -e 's/^.*Y ://'`
            cd RDNAPTRANS2008
            ./rdnaptrans2008 <<EOF > ../aap.txt
2
$x
$y
0
0
EOF
            cd ..
            lat=`cat aap.txt | fgrep phi | sed -e 's/phi *//'`
            lon=`cat aap.txt | fgrep lambda | sed -e 's/lambda *= *//'`
            cat > latlon_wind$station.txt <<EOF
$station
$lat N
$lon E
EOF
        fi
        ./txt2dat_potwind tmp_potwind/potwind_${station}_???? tmp_potwind/potwind_${extrastation}_???? tmp_potwind/potwind_${extrastation1}_???? >> list_upx.txt
        gzip -c upx$station.dat > upx$station.gz
    fi
done
echo "==============================================" >> list_upx.txt
$HOME/NINO/copyfiles.sh upx* list_upx*.txt
