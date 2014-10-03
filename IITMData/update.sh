#!/bin/sh
wget -N ftp://www.tropmet.res.in/pub/data/txtn/\*
wget -N ftp://www.tropmet.res.in/pub/data/rain/\*
make txt2dat
./txtdat
