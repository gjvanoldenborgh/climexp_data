#!/bin/bash

yrnow=`date +%Y`
yrend=2010
yr=1979
mo=1
# the 2011 data are on a higher-resolution grid and from a different model :-(
# I could try and regrid and harmonise the orography some day.
while [ $yr -le $yrend ]
do
    if [ $mo -lt 10 ]; then
        mm=0$mo
    else
        mm=$mo
    fi
    for type in flxf06 pgblnl
    do
        file=$type.gdas.$yr$mm.grb2
        if [ ! -s $file ]; then
            echo "getting $file..."
            wget -N -q http://nomads.ncdc.noaa.gov/data/cfsrmon/$yr$mm/$file
            ###wget -N http://nomads.ncdc.noaa.gov/data/cfsrmon/$yr$mm/$file.inv
        fi
    done
    mo=$((mo+1))
    if [ $mo -gt 12 ]; then
        mo=1
        yr=$((yr+1))
    fi
done

for var in tmp2m tmin2m tmax2m tmpsfc prate uflx vflx u10m v10m shtfl lhtfl dlwrf_sfc ulwrf_sfc ulwrf_toa dswrf_sfc uswrf_sfc dswrf_toa uswrf_toa slp hgt t u v w q qrel
do
    echo "Processing $var"
    levs=0
    case $var in
        hgt)    type=pgblnl;pat1=HGT;pat2=" mb";levs="100 200 300 500 700 850";;
        t)      type=pgblnl;pat1=TMP;pat2=" mb";levs="100 200 300 500 700 850";;
        qrel)   type=pgblnl;pat1=RH;pat2=" mb";levs="100 200 300 500 700 850";;
        q)      type=pgblnl;pat1=SPFH;pat2=" mb";levs="100 200 300 500 700 850";;
        u)      type=pgblnl;pat1=UGRD;pat2=" mb";levs="100 200 300 500 700 850";;
        v)      type=pgblnl;pat1=VGRD;pat2=" mb";levs="100 200 300 500 700 850";;
        w)      type=pgblnl;pat1=VVEL;pat2=" mb";levs="100 200 300 500 700 850";;
        slp)    type=pgblnl;pat1=PRMSL;pat2="mean sea level";;
        tmp2m)  type=flxf06;pat1=TMP;pat2="2 m above ground";;
        tmpsfc) type=flxf06;pat1=TMP;pat2="surface";;
        tmin2m) type=flxf06;pat1=TMIN;pat2="2 m above ground";;
        tmax2m) type=flxf06;pat1=TMAX;pat2="2 m above ground";;
        prate)  type=flxf06;pat1=PRATE;pat2=;;
        uflx)  type=flxf06;pat1=UFLX;pat2="surface";;
        vflx)  type=flxf06;pat1=VFLX;pat2="surface";;
        u10m)  type=flxf06;pat1=UGRD;pat2="10 m above ground";;
        v10m)  type=flxf06;pat1=VGRD;pat2="10 m above ground";;
        shtfl)  type=flxf06;pat1=SHTFL;pat2=;;
        lhtfl)  type=flxf06;pat1=LHTFL;pat2=;;
        dlwrf_sfc) type=flxf06;pat1=DLWRF;pat2="surface";;
        ulwrf_sfc) type=flxf06;pat1=ULWRF;pat2="surface";;
        ulwrf_toa) type=flxf06;pat1=ULWRF;pat2="top of atmosphere";;
        dswrf_sfc) type=flxf06;pat1=DSWRF;pat2="surface";;
        uswrf_sfc) type=flxf06;pat1=USWRF;pat2="surface";;
        dswrf_toa) type=flxf06;pat1=DSWRF;pat2="top of atmosphere";;
        uswrf_toa) type=flxf06;pat1=USWRF;pat2="top of atmosphere";;
        *) echo "$0: error: unknown variable $var"; exit -1;;
    esac
    for z in $levs
    do
        if [ $z = 0 ]; then
            lev=""
        else
            lev=$z
        fi
        ncfile=cfsr_$var$lev.nc
        [ -f $ncfile ] && mv $ncfile $ncfile.old

        yr=1979
        mo=1
        while [ $yr -le $yrend ]
        do
            if [ $mo -lt 10 ]; then
                mm=0$mo
            else
                mm=$mo
            fi

            file=$type.gdas.$yr$mm.grb2
            if [ -f $file ]; then
                echo "wgrib2 -fix_ncep -inv /tmp/inv.txt $file -match "$pat1" -match "$lev$pat2" -append -netcdf $ncfile"
                wgrib2 -fix_ncep -inv /tmp/inv.txt $file -match "$pat1" -match "$lev$pat2" -append -netcdf $ncfile
            fi
            mo=$((mo+1))
            if [ $mo -gt 12 ]; then
                mo=1
                yr=$((yr+1))
            fi
        done
        echo "cdo -r -f nc4 -z zip -settaxis,1979-01-01,0:00,1mon $ncfile $ncfile.new"
        cdo -r -f nc4 -z zip -settaxis,1979-01-01,0:00,1mon $ncfile $ncfile.new
        mv $ncfile.new $ncfile
        ncatted -a long_name,time,d,c,"" $ncfile

        $HOME/NINO/copyfiles.sh $ncfile
    done # lev
done # var

cdo sub cfsr_dswrf_sfc.nc cfsr_uswrf_sfc.nc cfsr_swrf_sfc.nc
ncrename -O -vDSWRF_surface,SWRF_surface cfsr_swrf_sfc.nc aap.nc
ncatted -O -a long_name,SWRF_surface,m,c,"Net Short-Wave Rad. Flux" aap.nc cfsr_swrf_sfc.nc
$HOME/NINO/copyfiles.sh cfsr_swrf_sfc.nc

cdo sub cfsr_dswrf_toa.nc cfsr_uswrf_toa.nc cfsr_swrf_toa.nc
ncrename -O -vDSWRF_topofatmosphere,SWRF_topofatmosphere cfsr_swrf_toa.nc aap.nc
ncatted -O -a long_name,SWRF_topofatmosphere,m,c,"Net Short-Wave Rad. Flux" aap.nc cfsr_swrf_toa.nc
$HOME/NINO/copyfiles.sh cfsr_swrf_toa.nc

cdo sub cfsr_dlwrf_sfc.nc cfsr_ulwrf_sfc.nc cfsr_lwrf_sfc.nc
ncrename -O -vDLWRF_surface,LWRF_surface cfsr_lwrf_sfc.nc aap.nc
ncatted -O -a long_name,LWRF_surface,m,c,"Net Long-Wave Rad. Flux" aap.nc cfsr_lwrf_sfc.nc
$HOME/NINO/copyfiles.sh cfsr_lwrf_sfc.nc
