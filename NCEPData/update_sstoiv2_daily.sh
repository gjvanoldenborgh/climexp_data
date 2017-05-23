#!/bin/sh
yr=`date +%Y`
mo=`date +%m`
base=ftp://ftp.cdc.noaa.gov/Datasets/noaa.oisst.v2.highres
if [ -f downloaded_$yr$mo ]; then
  echo "Already downloaded daily 1/4º SST OI v2 this month"
  exit
fi
set -x
tool=cdo
i=1981
file=$0
file=sst.day.anom.$i.v2.nc
[ $i -ge $((yr-1)) ] && wget -q -N $base/$file
while [ -s $file ]; do
    if [ ! -s sst.month.anom.$i.nc -o sst.month.anom.$i.nc -ot sst.day.anom.$i.v2.nc ]; then
        if [ $tool = cdo ]; then
            cdo -r -f nc4 -z zip monmean sst.day.anom.$i.v2.nc aap.nc
            if [ $yr = 1981 ]; then
                cdo -r -f nc4 -z zip settaxis,${i}-09-15,0:00,1mon aap.nc sst.month.anom.$i.nc
            else
                cdo -r -f nc4 -z zip settaxis,${i}-01-15,0:00,1mon aap.nc sst.month.anom.$i.nc
            fi
        else
            daily2longerfield sst.day.anom.$i.v2.nc 12 mean add_persist sst.month.anom.$i.nc
        fi
    fi
    if [ ! -s sst.day.anom.$i.05.nc -o sst.day.anom.$i.05.nc -ot sst.day.anom.$i.v2.nc ]; then
        if [ $tool = cdo ]; then
            cdo -r -f nc4 -z zip remapbil,r720x360 sst.day.anom.$i.v2.nc sst.day.anom.$i.05.nc
        else
            averagefieldspace sst.day.anom.$i.v2.nc 2 2 sst.day.anom.$i.05.nc
        fi
    fi
    if [ ! -s nino12_daily_$i.dat -o nino12_daily_$i.dat -ot sst.day.anom.$i.v2.nc ]; then
        get_index sst.day.anom.$i.v2.nc 270 280 -10 0 > nino12_daily_$i.dat
    fi
    if [ ! -s nino3_daily_$i.dat -o nino3_daily_$i.dat -ot sst.day.anom.$i.v2.nc ]; then
        get_index sst.day.anom.$i.v2.nc 210 270 -5 5 > nino3_daily_$i.dat
    fi
    if [ ! -s nino34_daily_$i.dat -o nino34_daily_$i.dat -ot sst.day.anom.$i.v2.nc ]; then
        get_index sst.day.anom.$i.v2.nc 190 240 -5 5 > nino34_daily_$i.dat
    fi
    if [ ! -s nino4_daily_$i.dat -o nino4_daily_$i.dat -ot sst.day.anom.$i.v2.nc ]; then
        get_index sst.day.anom.$i.v2.nc 160 210 -5 5 > nino4_daily_$i.dat
    fi
    i=$((i+1))
    file=sst.day.anom.$i.v2.nc
    [ $i -ge $((yr-1)) ] && wget -q -N $base/$file
done
cdo -r -f nc4 -z zip copy sst.month.anom.*.nc oisst_v2_monthly.nc
cdo -r -f nc4 -z zip copy sst.day.anom.*.05.nc oisst_v2_daily.nc
for index in 12 3 34 4;do
    cat <<EOF > nino${index}_daily.dat
# Nino$ondex [K] daily Nino$index index from SST OI v2 1/4 degree
EOF
    for file in nino${index}_daily_????.dat; do
        fgrep -v '#' $file >> nino${index}_daily.dat
    done
done
rsync -avt oisst_v2_monthly.nc oisst_v2_daily.nc nino*_daily.dat bhlclim:climexp/NCEPData/
date > downloaded_$yr$mo