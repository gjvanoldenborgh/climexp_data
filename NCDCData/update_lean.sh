#!/bin/sh
if [ "$1" != debug ]; then
    wget -N -r ftp://data.ncdc.noaa.gov/cdr/solar-irradiance/tsi/
fi

# annual values

file=`ls -t data.ncdc.noaa.gov/cdr/solar-irradiance/tsi/yearly/*.nc|head -1`
myfile=tsi_ncdc_yearly.nc
if [ ! -s $myfile -o $myfile -ot $file ]; then
    cdo selname,TSI $file $myfile 
    # note: ncks drags the uncertainty along, which is
    # good but not what I need for my old software
fi

# monthly values 

myfile=tsi_ncdc_monthly.nc
base=data.ncdc.noaa.gov/cdr/solar-irradiance/tsi/monthly
doit=false
yr=1882
files=""
file=`ls -t $base/*s${yr}01_*.nc | fgrep -v preliminary | head -1`
while [ -n "$file" -a -s "$file" ]; do
    if [ ! -s $myfile -o $myfile -ot $file ]; then
        doit=true
    fi
    files="$files $file"
    echo $file
    yr=$((yr+1))
    file=`ls -t $base/*${yr}01_*.nc | fgrep -v preliminary | head -1`
done
# back up and look for monthly files
now=`date +%Y`
m=1
while [ $yr -le $now ]; do
    mo=`printf %02i $m`
    file=`ls -t $base/*s${yr}${mo}_*.nc | fgrep preliminary | head -1`
    if [ $? = 0 -a -n "$file" -a -s "$file" ]; then
        if [ ! -s $myfile -o $myfile -ot $file ]; then
            doit=true
        fi
        files="$files $file"
        echo $file
    fi
    m=$((m+1))
    if [ $m -gt 12 ]; then
        m=$((m-12))
        yr=$((yr+1))
    fi
done

if [ $doit = true ]; then
    ###echo "cdo copy $files aap.nc"
    cdo copy $files aap.nc
    cdo selname,TSI aap.nc $myfile
    rm aap.nc
fi

$HOME/NINO/copyfilesall.sh tsi_ncdc_*.nc