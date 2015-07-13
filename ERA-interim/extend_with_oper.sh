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
var=tp # let's assume all went well and the other variables were downloaded as well...
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
    echo "Getting \*$yr$mo.grib from bvlclim"
    rsync -e ssh -at bvlclim:climexp/ERA-interim/\*$yr$mo.grib . > /dev/null 2>&1
    echo "Getting \*$yr.grib from bvlclim"
    rsync -e ssh -at bvlclim:climexp/ERA-interim/\*$yr.grib . > /dev/null 2>&1
    if [ -s $var$yr$mo.grib -o -s $var$yr.grib ]; then
        # clean up the operational analyses if the ERA-interim exists
        [ -f oper_$var$yr$mo.grib ] && rm oper_*$yr$mo.grib
        [ -f oper_$var$yr$mo.nc ] && rm oper_*$yr$mo.nc
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
            lastday=${lastday#0} # NOT octal
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

        if [ $lastday -gt 0 ]; then
        if [ "$download" != false ]; then
	        echo "submit MARS job to retrieve operational fields"
	        sed -e "s@LIST@$list@" -e "s/DATE/$yr$mo/" marsoper.sh > marsoper$yr$mo.sh
	        ecjput ecgate marsoper$yr$mo.sh
	
	        c=1
	        while [ $c = 1 ]
	        do
    	        echo "wait for it to finish"
		        sleep 60
		        c=`ecjls|egrep -c 'INIT|WAIT|EXEC'`
	        done
	        sleep 15 # to give ECMWF time to finish copying the files
        fi
        echo "retrieve output"
        ivars=`fgrep "for var in t2m" marsoper.sh | sed -e "s/for var in //"`
        for var in $ivars
        do
            if [ $var != "#" ]; then
	            if [ "$download" != false ]; then
	                [ -f oper_${var}${yr}${mo}.grb ] && rm oper_${var}${yr}${mo}.grb
		            echo ecget oper_${var}${yr}${mo}.grb
		            while [ ! -s oper_${var}${yr}${mo}.grb ]; do
		                ecget oper_${var}${yr}${mo}.grb
		                [ ! -s oper_${var}${yr}${mo}.grb ] && sleep 60
		            done
		            echo ecdelete oper_${var}${yr}${mo}.grb
		            ecdelete oper_${var}${yr}${mo}.grb
	            fi
	            if [ force=true -o ! -s oper_${var}${yr}${mo}.nc -o oper_${var}${yr}${mo}.nc -ot oper_${var}${yr}${mo}.grb ]; then
		            echo "converting oper_${var}${yr}${mo} to netcdf"
		            cdo $cdoflags copy oper_${var}${yr}${mo}.grb aap.nc
                    # shift time so that the 00, 06, 12 and 18 analyses are averaged
		            cdo $cdoflags shifttime,3hour aap.nc noot.nc
		            cdo $cdoflags daymean noot.nc aap.nc
		            if [ 0 = 1 ]; then
    		            # shift time back from 21 to 12 UTC in order not to confuse the next program
	    	            cdo $cdoflags shifttime,-9hour aap.nc oper_${var}${yr}${mo}.nc
	    	        else
	    	            # somehow the time is already correct...
	    	            mv aap.nc oper_${var}${yr}${mo}.nc
	    	        fi
		            rm -f aap.nc noot.nc
		            . ./gribcodes.sh
		            ncrename -O -v var$par,$var oper_${var}${yr}${mo}.nc aap.nc
		            ncatted -O -a long_name,$var,a,c,"$long_name" \
				        -a units,$var,a,c,"$units" \
				        -a axis,lon,a,c,"x" -a axis,lat,a,c,"y" \
				        -a title,global,a,c,"operational analysis" \
			            aap.nc oper_${var}${yr}${mo}.nc
			        if [ $var = t2m -o $var = tmin -o $var = tmax ]; then
			            cdo $cdoflags sub oper_${var}${yr}${mo}.nc oper_t2m_bias.nc aap.nc
			            mv aap.nc oper_${var}${yr}${mo}.nc
			        fi
			        [ -f aap.nc ] && rm aap.nc
            	fi
            fi
        done

        cvars=`fgrep "for var in tp" marsoper.sh | sed -e "s/for var in //"`
        for var in $cvars
        do
            if [ $var != "#" ]; then
	            if [ "$download" != false ]; then
	                if [ $var = tmin -o $var = tmax ]; then
	                    exts="@"
	                else
	                    exts="_12 _24"
	                fi
	                for iext in $exts
	                do
	                    ext=${iext#@}
	                    file=oper_${var}${yr}${mo}$ext.grb
    	                [ -f $file ] && rm $file
	    	            echo ecget $file
		                while [ ! -s $file ]; do
		                    ecget $file
		                    [ ! -s $file ] && sleep 60
		                done
		                echo ecdelete $file
		                ecdelete $file
		            done
	            fi
            fi
            if [ $var = tmin -o $var = tmax ]; then
                if [ $var = tmin ]; then
                    oper=daymin
                elif [ $var = tmax ]; then
                    oper=daymax
                else
                    echo "$0: error: unknown var $var"
                    exit -1
                fi
	            if [ force=true -o ! -s oper_${var}${yr}${mo}.nc -o oper_${var}${yr}${mo}.nc -ot oper_${var}${yr}${mo}.grb ]; then
		            echo "converting oper_${var}${yr}${mo} to netcdf"
		            cdo $cdoflags copy oper_${var}${yr}${mo}.grb aap.nc
                    # shift time so that the 06, 12, 18 and 24 values are averaged
		            cdo $cdoflags shifttime,-3hour aap.nc noot.nc
		            cdo $cdoflags $oper noot.nc aap.nc
		            if [ 0 = 1 ]; then
    		            # shift time back from 21 to 12 UTC in order not to confuse the next program
	    	            cdo $cdoflags shifttime,-9hour aap.nc oper_${var}${yr}${mo}.nc
		            else
		                # the time is already at 12:00...
    		            mv aap.nc oper_${var}${yr}${mo}.nc
    		        fi
		            rm -f aap.nc noot.nc
		            . ./gribcodes.sh
		            ncrename -O -v var$par,$var oper_${var}${yr}${mo}.nc aap.nc
		            ncatted -O -a long_name,$var,a,c,"$long_name" \
				        -a units,$var,a,c,"$units" \
				        -a axis,lon,a,c,"x" -a axis,lat,a,c,"y" \
				        -a title,global,a,c,"operational analysis" \
			            aap.nc oper_${var}${yr}${mo}.nc
			        if [ $var = tmin -o $var = tmax ]; then
			            cdo $cdoflags sub oper_${var}${yr}${mo}.nc oper_t2m_bias.nc aap.nc
			            mv aap.nc oper_${var}${yr}${mo}.nc
			        fi
			        rm aap.nc
            	fi
            elif [ $var = "tp" ]; then
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
        fi # any days in the month?
    fi # download or not?
done # loop over yr,mo

if [ "$forecast" != false ]; then
    echo "submit MARS job to retrieve forecast fields"
    curdy=`date "+%d"` # today
    sed -e "s/DATE/${curyr}-${curmo}-${curdy}/" marsforecast.sh > marsforecast$curyr$curmo$curdy.sh
    ecjput ecgate marsforecast$curyr$curmo$curdy.sh

    c=1
    while [ $c = 1 ]
    do
        echo "wait for it to finish"
        sleep 60
        c=`ecjls|egrep -c 'INIT|WAIT|EXEC'`
    done
    sleep 15 # to give ECMWF time to finish copying the files
fi

for var in $ivars
do
    gribfile=forecast_${var}${curyr}-${curmo}-${curdy}.grb
    netcdffile=${gribfile%.grb}.nc
    if [ ! -f $netcdffile ]; then
        echo ecget $netcdffile
        while [ ! -s $netcdffile ]; do
            ecget $netcdffile
            [ ! -s $netcdffile ] && sleep 60
        done
        echo ecdelete $gribfile $netcdffile
        ecdelete $gribfile
        ecdelete $netcdffile
    fi
    mv $netcdffile aap.nc
    # shift time so that the 00, 06, 12 and 18 analyses are averaged
    cdo $cdoflags shifttime,3hour aap.nc noot.nc
    cdo $cdoflags daymean noot.nc aap.nc
    if [ 0 = 1 ]; then
        # shift time back from 21 to 12 UTC in order not to confuse the next program
        cdo $cdoflags shifttime,-9hour aap.nc $netcdffile
    else
        # somehow the time is already correct...
        mv aap.nc $netcdffile
    fi
    rm -f aap.nc noot.nc
    if [ $var = t2m -o $var = tmin -o $var = tmax ]; then
        cdo $cdoflags sub $netcdffile oper_t2m_bias.nc aap.nc
        mv aap.nc $netcdffile
    fi
    [ -f aap.nc ] && rm aap.nc
done 

for var in $cvars
do
    gribfile=forecast_${var}${curyr}-${curmo}-${curdy}.grb
    netcdffile=${gribfile%.grb}.nc
    if [ ! -f $gribfile ]; then
        echo ecget $gribfile
        while [ ! -s $gribfile ]; do
            ecget $gribfile
            [ ! -s $gribfile ] && sleep 60
        done
        echo ecdelete $gribfile $gribfile
        ecdelete $gribfile
        ecdelete $gribfile
    fi
    if [ $var = tmin -o $var = tmax ]; then
        if [ $var = tmin ]; then
            oper=daymin
        elif [ $var = tmax ]; then
            oper=daymax
        else
            echo "$0: error: unknown var $var"
            exit -1
        fi
        if [ force=true -o ! -s $netcdffile -o $netcdffile -ot $gribfile ]; then
            echo "converting $gribfile to netcdf"
            cdo $cdoflags copy $gribfile aap.nc
            # shift time so that the 06, 12, 18 and 24 values are averaged
            cdo $cdoflags shifttime,-3hour aap.nc noot.nc
            cdo $cdoflags $oper noot.nc aap.nc
            if [ 0 = 1 ]; then
                # shift time back from 21 to 12 UTC in order not to confuse the next program
                cdo $cdoflags shifttime,-9hour aap.nc $netcdffile
            else
                # the time is already at 12:00...
                mv aap.nc $netcdffile
            fi
            rm -f aap.nc noot.nc
            . ./gribcodes.sh
            ncrename -O -v var$par,$var $netcdffile aap.nc
            ncatted -O -a long_name,$var,a,c,"$long_name" \
                -a units,$var,a,c,"$units" \
                -a axis,lon,a,c,"x" -a axis,lat,a,c,"y" \
                -a title,global,a,c,"operational analysis" \
                aap.nc $netcdffile
            if [ $var = tmin -o $var = tmax ]; then
                cdo $cdoflags sub $netcdffile oper_t2m_bias.nc aap.nc
                mv aap.nc $netcdffile
            fi
            rm aap.nc
        fi
    elif [ $var = "tp" ]; then
        if [ force = true -o ! -s $netcdffile -o $netcdffile -ot $gribfile ]; then
            echo "Warning: $var forecasts not yet ready"
        fi
        [ -f aap.nc ] && rm aap.nc
        [ -f noot.nc ] && rm noot.nc
    fi
done

for var in $ivars $cvars
do
    files=""
    for date in $dates
    do
        [ -s oper_$var$date.nc ] && files="$files oper_$var$date.nc"
    done
    file=forecast_${var}${curyr}-${curmo}-${curdy}.nc
    if [ -s $file ]; then
        files="$files $file"
    fi
    echo "Getting erai_${var}_daily.nc from bvlclim"
    rsync -e ssh -avt oldenbor@bvlclim:climexp/ERA-interim/erai_${var}_daily.nc .
    echo cdo $cdoflags copy erai_${var}_daily.nc $files erai_${var}_daily_extended.nc
    cdo $cdoflags copy erai_${var}_daily.nc $files erai_${var}_daily_extended.nc
    $HOME/NINO/copyfiles.sh erai_${var}_daily_extended.nc
done

        
        
###$HOME/NINO/copyfiles.sh eraint_pme.nc
