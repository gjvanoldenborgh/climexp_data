#!/bin/sh
export PATH=$HOME/climexp/bin:/usr/local/free/bin:$PATH
cdo="cdo -r -f nc4 -z zip"
mkdir -p CMORPH
yr=2002
mo=1
mm=`printf %02i $mo`
yrnow=`date -d yesterday "+%Y"`
mmnow=`date -d yesterday "+%m"`
monow=${mmnow#0}
dynow=`date -d yesterday "+%d"`

# skip over all existing files
while [ -s CMORPH/cmorph_${yr}${mm}.nc ]; do
    mo=$((mo+1))
    if [ $mo -gt 12 ]; then
        mo=$((mo-12))
        yr=$((yr+1))
    fi
    mm=`printf %02i $mo`
done

# except the last one
if [ $yr -gt 2002 -o $mo -gt 1 ]; then
    mo=$((mo-1))
    if [ $mo -lt 1 ]; then
        mo=$((mo+12))
        yr=$((yr-1))
    fi
    mm=`printf %02i $mo`
fi

set -x
# and re-obtain the data for the last existing file and all missing ones
while [ $yr -lt $yrnow -o \( $yr = $yrnow -a $mo -le $monow \) ]; do
    if [ $yr = $yrnow -a $mo = $monow ]; then
        dd=$dynow
    else
        case $mo in
            1|3|5|7|8|10|12) dpm=31;;
            4|6|9|11) dpm=30;;
            2)  if [ $((yr%4)) = 0 ]; then
                    dpm=29
                else
                    dpm=28
                fi;;
        esac
        dd=$dpm
    fi
    s0=`date -d 2005-02-23 "+%s"`
    s1=`date -d ${yr}-${mm}-01 "+%s"`
    s2=`date -d ${yr}-${mm}-${dd} "+%s"`
    # watch out for round-off error, apparently...
    d1=$(((s1-s0+12*60*60)/(24*60*60)))
    d2=$(((s2-s0+12*60*60)/(24*60*60)))
    if [ $dd = $dynow ]; then
        # IRI runs a few days behind...
        d2=""
    fi
    ###echo "d1,d2=$d1,$d2"
    ncks -O -d T,$d1,$d2 http://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NCEP/.CPC/.CMORPH/.daily/.mean/.morphed/.cmorph/dods aap.nc
    ncrename -O -v cmorph,prcp -d T,time -d X,lon -d Y,lat -v T,time -v X,lon -v Y,lat aap.nc noot.nc
    ncatted -a units,prcp,m,c,"mm/dy" noot.nc
    $cdo invertlat noot.nc aap.nc
    $cdo settaxis,${yr}-${mo}-01,0:00,1day aap.nc noot.nc
    $cdo mulc,24 noot.nc CMORPH/cmorph_${yr}${mm}.nc
    $HOME/climexp/bin/averagefieldspace CMORPH/cmorph_${yr}${mm}.nc 2 2 aap.nc
    $cdo copy aap.nc CMORPH/cmorph_${yr}${mm}_05.nc
    rm aap.nc noot.nc
    mo=$((mo+1))
    if [ $mo -gt 12 ]; then
        mo=$((mo-12))
        yr=$((yr+1))
    fi
    mm=`printf %02i $mo`
done
$cdo copy CMORPH/cmorph_??????_05.nc cmorph_daily_05.nc
$cdo copy CMORPH/cmorph_??????.nc cmorph_daily.nc
$cdo monmean cmorph_daily.nc cmorph_monthly.nc
$HOME/NINO/copyfiles.sh cmorph_monthly.nc cmorph_daily_05.nc cmorph_daily.nc