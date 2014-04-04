#!/bin/sh
[ -z "$HOST" ] && HOST=`hostname`
if [ "$1" = force ]; then
	force=true
	download=false
else
    force=false
    download=true
fi
if [ $HOST != bhw330.knmi.nl -a $force != true ]; then
    echo "$0: error: only works on bhw330.knmi.nl, not $HOST"
    exit -1
fi
if [ "$download" != false ]; then
    c=`ecls | wc -l`
    if [ $c -lt 2 ]; then
        echo "Make sure you are logged in with eccert"
        exit -1
    fi
fi
cdoflags="-r -R -f nc4 -z zip"

# construct the list of months
var=msl # let's assume all went well and the other variables were downloaded as well...
m=0
curyr=`date "+%Y"`
begyr=$((curyr-1))
curmo=`date "+%m"`
curm=${curmo#0}
###prevyr=`date -d "1 month ago" "+%Y"`
###prevmo=`date -d "1 month ago" "+%m"`
yr=$begyr
dates=""
while [ $yr -lt $curyr -o $m -lt $curm ]
do
    m=$((m+1))
    if [ $m -gt 12 ]; then
        m=$((m-12))
        yr=$((yr+1))
    fi
    if [ $m -lt 10 ]; then
        mo=0$m
    else
        mo=$m
    fi
    rsync -e ssh -avt bvlclim:climexp/ERA-interim/$var$yr$mo.grib .
    if [ -s $var$yr$mo.grib ]; then
        # clean up the operational analyses if the ERA-interim exists
        [ -f oper_$var$yr$mo.grib ] && rm oper_$var$yr$mo.grib
        [ -f oper_$var$yr$mo.nc ] && rm oper_$var$yr$mo.nc
    else
        echo "downloading oper_$var$yr$mo.grib ..."
        dates="$dates $yr$mo"
        # get the operational analysis
        if [ $yr -lt $curyr -o $m -lt $curm ]; then
            # get the whole month at once
            if [ $m = 2 ]; then
                if [ $((yr%4)) == 0 ]; then
                    lastday=29
                else
                    lastday=28
                fi
            elif [ $m = 4 -o $m = 6 -o $m = 9 -o $m = 11 ]; then
                lastday=30
            else
                lastday=31
            fi
        else
            lastday=`date "+%d"` # today
            lastday=$((lastday-1)) # yesterday
        fi
        list="${yr}-${mo}-01"
        d=2
        while [ $d -le $lastday ]
        do
            if [ $d -lt 10 ]; then
                dy=0$d
            else
                dy=$d
            fi
            list="$list/${yr}-${mo}-${dy}"
            d=$((d+1))
        done

        if [ "$download" != false ]; then
	        echo "submit MARS job to retrieve operational fields"
	        sed -e "s@LIST@$list@" -e "s/DATE/$yr$mo/" marsoper.sh > marsoper$yr$mo.sh
	        ecjput ecgate marsoper$yr$mo.sh
	
	        echo "wait for it to finish"
	        c=1
	        while [ $c = 1 ]
	        do
		        sleep 15
		        c=`ecjls|fgrep -c EXEC`
	        done
        fi

        echo "retrieve output"
        ivars=`fgrep "for var in t2m" marsoper.sh | sed -e "s/for var in //"`
        for var in $ivars
        do
            if [ $var != "#" ]; then
	            if [ "$download" != false ]; then
	                [ -f oper_${var}${yr}${mo}.grb ] && rm oper_${var}${yr}${mo}.grb
		            echo ecget oper_${var}${yr}${mo}.grb
		            ecget oper_${var}${yr}${mo}.grb
		            echo ecdelete oper_${var}${yr}${mo}.grb
		            ecdelete oper_${var}${yr}${mo}.grb
	            fi
	            if [ force=true -o ! -s oper_${var}${yr}${mo}.nc -o oper_${var}${yr}${mo}.nc -ot oper_${var}${yr}${mo}.grb ]; then
		            echo "converting oper_${var}${yr}${mo} to netcdf"
		            cdo $cdoflags copy oper_${var}${yr}${mo}.grb aap.nc
                    # shift time so that the 00, 06, 12 and 18 analyses are averaged
		            cdo $cdoflags shifttime,3hour aap.nc noot.nc
		            cdo $cdoflags daymean noot.nc aap.nc
		            # shift time back from 21 to 12 UTC in order not to confuse the next program
		            cdo $cdoflags shifttime,-9hour aap.nc oper_${var}${yr}${mo}.nc
		            rm -f aap.nc noot.nc
		            . ./gribcodes.sh
		            ncrename -O -v var$par,$var oper_${var}${yr}${mo}.nc aap.nc
		            ncatted -O -a long_name,$var,a,c,"$long_name" \
				        -a units,$var,a,c,"$units" \
				        -a axis,lon,a,c,"x" -a axis,lat,a,c,"y" \
				        -a title,global,a,c,"operational analysis" \
			            aap.nc oper_${var}${yr}${mo}.nc
			        if [ $var = t2m ]; then
			            cdo $cdoflags sub oper_${var}${yr}${mo}.nc oper_t2m_bias.nc aap.nc
			            mv aap.nc oper_${var}${yr}${mo}.nc
			        fi
			        rm aap.nc
            	fi
            fi
        done

        if [ 0 = 1 ]; then
        cvars=`fgrep "for var in pr" marsoper.sh | sed -e "s/for var in //"`
        for var in $cvars
        do
            if [ $var != "#" ]; then
	            for step in 12 24
            	do
		            if [ ! -s oper_${var}${yr}${mo}_$step.grb ]; then
			            echo "ecget oper_${var}${yr}${mo}_$step.grb"
			            ecget oper_${var}${yr}${mo}_$step.grb
		            fi
	            done
	            if [ force = true -o ! -s oper_${var}${yr}${mo}.nc -o oper_${var}${yr}${mo}_$step.nc -ot oper_${var}${yr}${mo}_24.grb ]; then
		            echo "adding and converting $var to netcdf"
		            cdo $cdoflags add oper_${var}${yr}${mo}_12.grb oper_${var}${yr}${mo}_24.grb aap.nc
		            . ./gribcodes.sh
		            cdo $cdoflags divc,$fac aap.nc oper_${var}${yr}${mo}.nc
		            ncrename -O -v var$par,$var oper_${var}${yr}${mo}.nc aap.nc
		            ncatted -O -a long_name,$var,a,c,"$long_name" \
				        -a units,$var,a,c,"$units" \
				        -a axis,lon,a,c,"x" -a axis,lat,a,c,"y" \
				        -a title,global,a,c,"ERA-interim reanalysis" \
			            aap.nc oper_${var}${yr}${mo}.nc
            	fi
                [ -f aap.nc ] && rm aap.nc
                [ -f noot.nc ] && rm noot.nc
            fi
        done
        fi # 0=1
    fi # download or not?
done # loop over yr,mo

for var in $ivars $cvars
do
    files=""
    for date in $dates
    do
        files="$files oper_$var$date.nc"
    done
    rsync -e ssh -avt oldenbor@bvlclim:climexp/ERA-interim/erai_${var}_daily.nc .
    echo cdo $cdoflags copy erai_${var}_daily.nc $files erai_${var}_daily_extended.nc
    cdo $cdoflags copy erai_${var}_daily.nc $files erai_${var}_daily_extended.nc
    $HOME/NINO/copyfiles.sh erai_${var}_daily_extended.nc
done
        
        
        
###$HOME/NINO/copyfiles.sh eraint_pme.nc
