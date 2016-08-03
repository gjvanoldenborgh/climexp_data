#!/bin/sh
set -x
cleanup=true
force=false # true
update=true # false

# adjust with each version
version=v13.1
enddate="" # keep empty when shortening is not needed "2013-12-31"
nextdate="" # "2015-07-01" # keep empty when previous year is not needed "2014-01-01"

cdoflags="-r -f nc4 -z zip"

yr=`date -d "last month" "+%Y"`
for var in rr tg tn tx pp # rr tg tn tx pp # tg tn tx pp
do
  for res in 0.50 0.25
  do
    wget -q -N http://eca.knmi.nl/download/ensembles/data/Grid_${res}deg_reg/${var}_${res}deg_reg_${version}.nc.gz
    if [ -n "$nextdate" ]; then
        wget -q -N http://eca.knmi.nl/download/ensembles/data/months/${var}_${res}deg_reg_$((yr-1)).nc.gz
    fi
    [ $update = true ] && wget -q -N http://eca.knmi.nl/download/ensembles/data/months/${var}_${res}deg_reg_$yr.nc.gz
    if [ $force = true -o ${var}_${res}deg_reg_$yr.nc.gz -nt ${var}_${res}deg_reg_${version}u.nc ]; then
        if [ ! -s ${var}_${res}deg_reg_${version}.nc.gz -o ${var}_${res}deg_reg_${version}.nc -ot ${var}_${res}deg_reg_${version}.nc.gz ]; then
            gunzip -c ${var}_${res}deg_reg_${version}.nc.gz > ${var}_${res}deg_reg_${version}.nc
        fi
        if [ $update = true ]; then
            if [ -n "$nextdate" ]; then
                gunzip -c ${var}_${res}deg_reg_$((yr-1)).nc.gz > aap.nc
                cdo $cdoflags seldate,$nextdate,$((yr-1))-12-31 aap.nc ${var}_${res}deg_reg_$((yr-1)).nc
                rm aap.nc
            fi
            # this gets the whole of the year but I am too lazy to fix it now
            gunzip -c ${var}_${res}deg_reg_$yr.nc.gz > ${var}_${res}deg_reg_$yr.nc
            # convert to netcdf4
            if [ -n "$enddate" ]; then
                endyr=`echo $enddate | cut -d '-' -f 1`
                endmo=`echo $enddate | cut -d '-' -f 2`
                endmo=${endmo#0}
                cdo $cdoflags seldate,${endyr}-$((endmo+1))-01,${yr}-12-31 ${var}_${res}deg_reg_$yr.nc aap.nc
            else
                cdo $cdoflags copy ${var}_${res}deg_reg_$yr.nc aap.nc
            fi
            mv aap.nc ${var}_${res}deg_reg_$yr.nc

            rm -f ${var}_${res}deg_reg_${version}u.nc
            use_python=false
            if [ "$use_python" = false ]; then
                if [ -n "$nextdate" ]; then
                    cdo $cdoflags copy ${var}_${res}deg_reg_${version}.nc ${var}_${res}deg_reg_$((yr-1)).nc ${var}_${res}deg_reg_$yr.nc ${var}_${res}deg_reg_${version}u.nc
                    [ $? != 0 ] && echo "something went wrong" && exit -1
                else
                    cdo $cdoflags copy ${var}_${res}deg_reg_${version}.nc ${var}_${res}deg_reg_$yr.nc ${var}_${res}deg_reg_${version}u.nc
                    [ $? != 0 ] && echo "something went wrong" && exit -1
                fi
            else
                # v9 goes to 2013-06-30... 
                ./copyfields.py ${var}_${res}deg_reg_${version}.nc ${var}_${res}deg_reg_$((yr-1)).nc ${var}_${res}deg_reg_$yr.nc
                ###./copyfields.py ${var}_${res}deg_reg_${version}.nc ${var}_${res}deg_reg_$yr.nc
                [ $? != 0 ] && echo "something went wrong" && exit -1
                cdo $cdoflags copy ${var}_${res}deg_reg_${version}u.nc aap.nc
                mv aap.nc ${var}_${res}deg_reg_${version}u.nc
            fi
            if [ $res = 0.25 ]; then # reduce size under 2^31 elements (up to 2018)
            	cdo $cdoflags selindexbox,41,464,1,201 ${var}_${res}deg_reg_${version}u.nc aap.nc
            	mv aap.nc ${var}_${res}deg_reg_${version}u.nc
            fi
        else
            ln -s  ${var}_${res}deg_reg_${version}.nc ${var}_${res}deg_reg_${version}u.nc
        fi
        if [ $var = rr ]; then
            ncatted -a units,rr,m,c,"mm/day" -a long_name,time,m,c,"Time" -a title,global,c,c,"E-OBS analyses $version" ${var}_${res}deg_reg_${version}u.nc
        else
            ncatted -a long_name,time,m,c,"Time" -a title,global,c,c,"E-OBS analyses $version" ${var}_${res}deg_reg_${version}u.nc
        fi
        $HOME/NINO/copyfiles.sh ${var}_${res}deg_reg_${version}u.nc
        if [ $res = 0.25 ]; then
            cdo $cdoflags monmean ${var}_${res}deg_reg_${version}u.nc aap.nc
            cdo $cdoflags settaxis,1950-01-01,0:00,1mon aap.nc ${var}_${res}deg_reg_${version}u_mo.nc
            rm aap.nc
            $HOME/NINO/copyfiles.sh ${var}_${res}deg_reg_${version}u_mo.nc
            if [ $cleanup = true ]; then
                /bin/rm ${var}_${res}deg_reg_${version}u.nc
                touch ${var}_${res}deg_reg_${version}u.nc
            fi
        fi
        if [ $cleanup = true ]; then
            /bin/rm -f ${var}_${res}deg_reg_${version}.nc
            /bin/rm -f ${var}_${res}deg_reg_$yr.nc
        fi
    fi
  done
done

. ./merge_with_cru.sh