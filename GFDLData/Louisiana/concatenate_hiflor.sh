#!/bin/sh
#
# concatenate the HiFLOR grid boxes on the original 25km grid.
# 1860 run: 1901-2101
outfile=bestaatniet
iens=0
i=0
while [ $i -lt 40 ]; do
    ((i++))
    j=0
    while [ $j -lt 8 ]; do
        ((j++))
        for ref in 1860 1940 1990 2015; do
            case $ref in
                1860) nyr=200;end=0200;;
                1940) nyr=75;end=0076;;
                1990) nyr=300;end=0301;;
                2015) nyr=70;end=0070;;
            esac
            file=atmos_daily.${ref}-Ctl.00010101-${end}1231.precip_LA_all_ce_${i}_${j}.nc
            outfile=prcp_hiflor_conc_${i}_${j}.nc
            if [ -f $file ]; then # land point
                if [ ! -f $outfile -o $outfile -ot $file ]; then
                    if [ $ref = 1860 ]; then
                        cdo settaxis,$((1601-20))-01-01,0:00,1day $file aap.nc
                        cdo seldate,1601-01-01,$((1601+nyr-21))-12-31 aap.nc $outfile
                        myr=$((1601+nyr-20))
                    else
                        cdo settaxis,$((myr-20))-01-01,0:00,1day $file aap.nc
                        cdo seldate,${myr}-01-01,$((myr+nyr-21))-12-31 aap.nc noot.nc
                        myr=$((myr+nyr-20))
                        cdo copy $outfile noot.nc mies.nc
                        mv mies.nc $outfile
                    fi
                fi
                if [ $ref = 2015 ]; then
                    echo $outfile
                    describefield $outfile
                    datfile=${outfile%.nc}.dat
                    if [ ! -s $datfile -o $datfile -ot $outfile ]; then
                        netcdf2dat $outfile > $datfile
                        sleep 1
                        touch $outfile
                        ls -l $outfile $datfile
                    fi
                    ens=`printf %03i $iens`
                    lfile=prcp_hiflor_conc_${ens}.nc
                    [ -L $lfile ] && rm $lfile
                    ln -s $outfile $lfile
                    lfile=prcp_hiflor_conc_${ens}.dat
                    [ -L $lfile ] && rm $lfile
                    ln -s $datfile $lfile
                    ((iens++))
                fi
            fi
        done
###[ -f $outfile ] && exit
    done
done