#!/bin/sh
yr=`date +%Y`
mo=`date +%m`
# will be turned off soon...
base=ftp://ftp.cdc.noaa.gov/Datasets/noaa.oisst.v2.highres
if [ -f downloaded_$yr$mo ]; then
  echo "Already downloaded daily 1/4º SST OI v2 this month"
  exit
fi
###set -x
tool=cdo

for type in anom mean
do
    i=1981
    file=$0
    file=sst.day.${type}.$i.v2.nc
    [ $i -ge $((yr-1)) -o ! -s $file ] && wget -q -N $base/$file
    while [ -s $file ]; do
        if [ ! -s sst.month.${type}.$i.nc -o sst.month.${type}.$i.nc -ot sst.day.${type}.$i.v2.nc ]; then
            if [ $tool = cdo ]; then
                cdo -r -f nc4 -z zip monmean sst.day.${type}.$i.v2.nc aap.nc
                if [ $i = 1981 ]; then
                    cdo -r -f nc4 -z zip settaxis,${i}-09-15,0:00,1mon aap.nc sst.month.${type}.$i.nc
                else
                    cdo -r -f nc4 -z zip settaxis,${i}-01-15,0:00,1mon aap.nc sst.month.${type}.$i.nc
                fi
            else
                daily2longerfield sst.day.${type}.$i.v2.nc 12 mean add_persist sst.month.${type}.$i.nc
            fi
        fi
        if [ ! -s sst.day.${type}.$i.05.nc -o sst.day.${type}.$i.05.nc -ot sst.day.${type}.$i.v2.nc ]; then
            if [ $tool = cdo ]; then
                cdo -r -f nc4 -z zip remapbil,r720x360 sst.day.${type}.$i.v2.nc sst.day.${type}.$i.05.nc
            else
                averagefieldspace sst.day.${type}.$i.v2.nc 2 2 sst.day.${type}.$i.05.nc
            fi
        fi
        if [ $type = anom ]; then
            if [ ! -s nino12_daily_$i.dat -o nino12_daily_$i.dat -ot sst.day.${type}.$i.v2.nc ]; then
                get_index sst.day.${type}.$i.v2.nc 270 280 -10 0 > nino12_daily_$i.dat
            fi
            if [ ! -s nino3_daily_$i.dat -o nino3_daily_$i.dat -ot sst.day.${type}.$i.v2.nc ]; then
                get_index sst.day.${type}.$i.v2.nc 210 270 -5 5 > nino3_daily_$i.dat
            fi
            if [ ! -s nino34_daily_$i.dat -o nino34_daily_$i.dat -ot sst.day.${type}.$i.v2.nc ]; then
                get_index sst.day.${type}.$i.v2.nc 190 240 -5 5 > nino34_daily_$i.dat
            fi
            if [ ! -s nino4_daily_$i.dat -o nino4_daily_$i.dat -ot sst.day.${type}.$i.v2.nc ]; then
                get_index sst.day.${type}.$i.v2.nc 160 210 -5 5 > nino4_daily_$i.dat
            fi
        fi
        i=$((i+1))
        file=sst.day.${type}.$i.v2.nc
        [ $i -ge $((yr-1)) -o ! -s $file ] && wget -q -N $base/$file
    done
    cdo -r -f nc4 -z zip copy sst.month.${type}.*.nc oisst_v2_${type}_monthly.nc
    file=oisst_v2_${type}_monthly.nc
    . $HOME/climexp/add_climexp_url_field.cgi
    cdo -r -f nc4 -z zip copy sst.day.${type}.*.05.nc oisst_v2_${type}_daily.nc
    file=oisst_v2_${type}_daily.nc
    . $HOME/climexp/add_climexp_url_field.cgi    
done

for index in 12 3 34 4;do
    cat <<EOF > nino${index}_daily.dat
# Nino$index [K] daily Nino$index index from SST OI v2 1/4 degree
EOF
    init=0
    for file in nino${index}_daily_????.dat; do
        if [ $init = 0 ]; then
            fgrep ' :: ' $file | fgrep -v time_coverage >> nino${index}_daily.dat
            init=1
        fi
        fgrep -v '#' $file >> nino${index}_daily.dat
    done
done
rsync -avt oisst_v2_????_monthly.nc oisst_v2_????_daily.nc nino*_daily.dat bhlclim:climexp/NCEPData/
date > downloaded_$yr$mo