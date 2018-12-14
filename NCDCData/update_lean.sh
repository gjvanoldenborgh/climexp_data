#!/bin/bash
if [ "$1" != debug ]; then
    wget --no-check-certificate -q -N -r -np https://www.ncei.noaa.gov/data/total-solar-irradiance/access/monthly/
    wget --no-check-certificate -q -N -r -np https://www.ncei.noaa.gov/data/total-solar-irradiance/access/yearly/
fi

# annual values

file=`ls -t www.ncei.noaa.gov/data/total-solar-irradiance/access/yearly/*.nc|head -1`
myfile=tsi_ncdc_yearly.nc
if [ ! -s $myfile -o $myfile -ot $file ]; then
    cdo selname,TSI $file $myfile
    ncatted -h -a climexp_url,global,a,c,'https://climexp.knmi.nl/getindices.cgi?NCDCData/tsi_ncdc_yearly' $myfile
    # note: ncks drags the uncertainty along, which is
    # good but not what I need for my old software
fi

# monthly values 

myfile=tsi_ncdc_monthly.nc
base=www.ncei.noaa.gov/data/total-solar-irradiance/access/monthly
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
    ncatted -h -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" aap.nc
    cdo selname,TSI aap.nc $myfile
    rm aap.nc
    file=$myfile
    . $HOME/climexp/add_geospatial_time.sh
    ncatted -h -a climexp_url,global,a,c,'https://climexp.knmi.nl/getindices.cgi?NCDCData/tsi_ncdc_monthly' $file
fi

$HOME/NINO/copyfilesall.sh tsi_ncdc_*.nc