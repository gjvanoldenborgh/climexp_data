#!/bin/bash

infile=o3area_and_o3massdeficit1979-2019.dat # mail from Michiel

header="# lost_ozon [Mt] ozone lost in the hole
# references :: De Laat et al, JGR, 2017, https://doi.org/10.1002/2016JD025723
# institution :: KNMI
# source_url :: http://www.temis.nl/protocols/o3hole/o3_history.php"

# daily series

echo "$header" > ozon_dy.dat
egrep -v '^#' $infile | cut -b 3-12,61-69 >> ozon_dy.dat

# monthly series

daily2longer ozon_dy.dat 12 mean > ozon_mo.dat

# annual series: both the total and the sum recommended by the ozone people

daily2longer ozon_dy.dat 1 mean > ozon_yr.dat

egrep '^#' ozon_dy.dat | sed -e 's/hole/hole dy 220-260/' > ozon_dy1.dat
echo "# averaged over dy 220-280 (7 Aug-6 Oct)" >> ozon_dy1.dat
egrep '^....  8  [7-9]' ozon_dy.dat >> ozon_dy1.dat
egrep '^....  8 [123]' ozon_dy.dat >> ozon_dy1.dat
egrep '^....  9' ozon_dy.dat >> ozon_dy1.dat
egrep '^.... 10  [1-6]' ozon_dy.dat >> ozon_dy1.dat
sort ozon_dy1.dat > aap.dat
mv aap.dat ozon_dy1.dat
daily2longer ozon_dy1.dat 1 mean minfac 0.15 > ozon_yr1.dat

$HOME/NINO/copyfilesall.sh ozon*.dat
