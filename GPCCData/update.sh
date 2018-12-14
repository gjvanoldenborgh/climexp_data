#!/bin/bash
version=2018
###set -x
debug=false
if [ "$1" = debug ]; then
    debug=true
fi
force=false
if [ "$1" = force ]; then
    force=true
fi
if [ $HOST = bvlclim.knmi.nl ]; then
    wgetflags="--no-passive-ftp"
fi
if [ `uname` = Darwin ]; then
    wgetflags=""
fi
thisyr=`date "+%Y"`
lastyr=$((thisyr-1))

# monthly data

base=ftp://ftp.dwd.de/pub/data/gpcc/full_data_${version}
for res in 25 10 05 025
do
    if [ $force = true -o ! -s downloaded_v${version}_${res} ]; then
        gpccfile=full_data_monthly_v${version}_${res}.nc
        wget -q -N $wgetflags $base/$gpccfile.gz
        gunzip -c $gpccfile.gz > $gpccfile
        ncatted -h -a doi,global,a,c,"10.5676/DWD_GPCC/FD_M_V${version}_$res" $gpccfile
        cdo -r -f nc4 -z zip selvar,precip $gpccfile gpcc_$res.nc
        cdo -r -f nc4 -z zip selvar,numgauge $gpccfile ngpcc_$res.nc
        cdo -r -f nc4 -z zip ifthen ngpcc_${res}.nc gpcc_${res}.nc gpcc_${res}_n1.nc
        rm $gpccfile
        $HOME/NINO/copyfiles.sh gpcc_$res.nc ngpcc_$res.nc gpcc_${res}_n1.nc
        date > downloaded_v${version}_${res}
    fi
done

for res in 25 10
do
    base=ftp://ftp.dwd.de/pub/data/gpcc/monitoring_v6
    yr=1982
    files=""
    ffiles=""
    doit=false
    stillok=true
    echo "Updating the $res monitoring analysis"
    while [ $yr -le $thisyr ]; do
        for mo in 01 02 03 04 05 06 07 08 09 10 11 12; do
            file=monitoring_v6_${res}_${yr}_$mo.nc
    	    if [ $debug = false -o stillok = true ]; then
    	        if [ ! -s $file.gz ]; then
    	            echo "wget -q $wgetflags -N $base/$yr/$file.gz"
        	        wget -q $wgetflags -N $base/$yr/$file.gz
        	        if [ -s $file.gz ]; then
        	            echo "Downloaded $file.gz"
        	        else
        	            echo "Cannot find $file.gz"
        	            stillok=false
        	        fi
        	    fi
    	    fi
    	    if [ -s $file.gz -a \( ! -s $file -o $file -ot $file.gz \) ]; then
    	        gunzip -c $file.gz > tmp$file
                cdo -r -f nc4 -z zip settaxis,${yr}-${mo}-01,0:00,1mon tmp$file $file
                rm tmp$file
    	    fi
    	    if [ -s $file ]; then
    	        files="$files $file"
        	    if [ $file -nt gpcc_${res}_mon_all.nc ]; then
        	        doit=true
    	        fi
    	    fi
    	done
    	yr=$((yr+1))
	done
	stillok=true
	if [ $res = 10 ]; then
        echo "Updating the $res first guess analysis"
        base=ftp://ftp.dwd.de/pub/data/gpcc/first_guess
	    for yr in $lastyr $thisyr; do
            for mo in 01 02 03 04 05 06 07 08 09 10 11 12; do
	            if [ ! -s monitoring_v6_${res}_${yr}_$mo.nc ]; then
	                file=first_guess_monthly_${yr}_$mo.nc
            	    if [ $debug = false -a $stillok = true ]; then
            	        if [ ! -s $file.gz ]; then
                	        ###echo "wget -N ftp://ftp-anon.dwd.de/pub/data/gpcc/first_guess/$yr/$file.gz"
                    		wget -q $wgetflags -N $base/$yr/$file.gz
                    		if [ -s $file.gz ]; then
                    		    echo "Downloaded $file.gz"
                    		else
                	    	    echo "Cannot find $file.gz"
                		        stillok=false
                		    fi
                		fi
        		    fi
        		    if [ -s $file.gz -a \( ! -s $file -o $file -ot $file.gz \) ]; then
    			        gunzip -c $file.gz > tmp$file
    			        cdo -r -f nc4 -z zip copy tmp$file $file
    			        rm tmp$file
    			    fi
    			    if [ -s $file ]; then
    			        ffiles="$ffiles $file"
                	    if [ $file -nt gpcc_${res}_mon_all.nc ]; then
            	            doit=true
    	                fi
    			    fi
    			fi
    		done
		done
	fi

	if [ $doit = true -o "$force" = true ]; then
	    ###set -x
	    echo "Making gpcc_${res}_mon.nc"
        cdo -r -f nc4 -z zip copy $files gpcc_${res}_mon_all.nc
        ncatted -a units,lat,m,c,"degrees_north" gpcc_${res}_mon_all.nc
        cdo -r -f nc4 -z zip selvar,p gpcc_${res}_mon_all.nc gpcc_${res}_mon.nc
        cdo -r -f nc4 -z zip selvar,s gpcc_${res}_mon_all.nc gpcc_${res}_n_mon.nc
        if [ $res = 10 ]; then
            cdo -r -f nc4 -z zip copy $ffiles gpcc_${res}_first_all.nc
            ncatted -a units,lat,m,c,"degrees_north" gpcc_${res}_first_all.nc
            cdo -r -f nc4 -z zip selvar,p gpcc_${res}_first_all.nc gpcc_${res}_first.nc
            cdo -r -f nc4 -z zip selvar,s gpcc_${res}_first_all.nc gpcc_${res}_n_first.nc
            cdo -r -f nc4 -z zip copy gpcc_${res}_mon.nc gpcc_${res}_first.nc aap.nc
            mv aap.nc gpcc_${res}_mon.nc
            cdo -r -f nc4 -z zip copy gpcc_${res}_n_mon.nc gpcc_${res}_n_first.nc aap.nc
            mv aap.nc gpcc_${res}_n_mon.nc
        fi
        ncrename -v p,precip gpcc_${res}_mon.nc
        ncrename -v s,numgauge gpcc_${res}_n_mon.nc
        cdo -r -f nc4 -z zip ifthen gpcc_${res}_n_mon.nc gpcc_${res}_mon.nc gpcc_${res}_n1_mon.nc
        for file in gpcc_${res}_n_mon.nc gpcc_${res}_mon.nc gpcc_${res}_n1_mon.nc; do
            if [ $res = 10 ]; then
                ncatted -h -a title,global,a,c," combined with the GPCC first guess product" \
                        -a institution,global,a,c," and KNMI (merging)" \
                        -a geospatial_lat_resolution,global,a,f,1.0 \
                        -a geospatial_lon_resolution,global,a,f,1.0 \
                        -a geospatial_lon_units,global,a,c,"degrees_east" \
                        -a geospatial_lat_units,global,a,c,"degrees_north" $file
                ncatted -h -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" $file
            else
                ncatted -h -a geospatial_lat_resolution,global,a,f,2.5 \
                        -a geospatial_lon_resolution,global,a,f,2.5 \
                        -a geospatial_lon_units,global,a,c,"degrees_east" \
                        -a geospatial_lat_units,global,a,c,"degrees_north" $file
            fi
            . $HOME/climexp/add_climexp_url_field.cgi
        done
        $HOME/NINO/copyfilesall.sh gpcc_${res}_n_mon.nc gpcc_${res}_mon.nc gpcc_${res}_n1_mon.nc
	    echo "Making gpcc_${res}_combined.nc"
        cdo -r -f nc4 -z zip seldate,2017-01-01,2100-12-31 gpcc_${res}_mon.nc gpcc_${res}_mon1.nc
        cdo -r -f nc4 -z zip copy gpcc_${res}.nc gpcc_${res}_mon1.nc gpcc_${res}_combined.nc 
        cdo -r -f nc4 -z zip seldate,2017-01-01,2100-12-31 gpcc_${res}_n1_mon.nc gpcc_${res}_n1_mon1.nc
        cdo -r -f nc4 -z zip copy gpcc_${res}.nc gpcc_${res}_n1_mon1.nc gpcc_${res}_n1_combined.nc 
        for file in gpcc_${res}*combined.nc; do
            if [ $res = 10 ]; then
                ncatted -h -a title,global,a,c," combined with the GPCC monitoring and first guess product" \
                        -a institution,global,a,c," and KNMI (merging)" \
                        -a geospatial_lat_resolution,global,a,f,1.0 \
                        -a geospatial_lon_resolution,global,a,f,1.0 \
                        -a geospatial_lon_units,global,a,c,"degrees_east" \
                        -a geospatial_lat_units,global,a,c,"degrees_north" $file
            else
                ncatted -h -a title,global,a,c," combined with the GPCC monitoring product" \
                        -a institution,global,a,c," and KNMI (merging)" \
                        -a geospatial_lat_resolution,global,a,f,2.5 \
                        -a geospatial_lon_resolution,global,a,f,2.5 \
                        -a geospatial_lon_units,global,a,c,"degrees_east" \
                        -a geospatial_lat_units,global,a,c,"degrees_north" $file
            fi
            ncatted -h -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" $file
            . $HOME/climexp/add_climexp_url_field.cgi
        done
        $HOME/NINO/copyfilesall.sh gpcc_${res}*combined.nc
        ###set +x
    fi
done

# daily data

echo "Checking for new data in the full dataset"
root=ftp://ftp-anon.dwd.de/pub/data/gpcc/full_data_daily_V${version}
[ "$debug" != true ] && wget -q $wgetflags -N $root/full_data_daily_\*.nc.gz
for file in full_data_daily_*.nc.gz; do
    f=${file%.gz}
    if [ ! -s $f -o $f -ot $file ]; then
        gunzip -c $file > aap.nc
        cdo -r -f nc4 -z zip copy aap.nc $f
    fi
done

echo "Updating the first guess dataset"
root=ftp://ftp-anon.dwd.de/pub/data/gpcc/first_guess_daily
yr=2014
while [ $yr -le $thisyr ]; do
    [ "$debug" != true ] && wget -q $wgetflags -N $root/$yr/\*.nc.gz
    yr=$((yr+1))
done
for file in first_guess_daily*.nc.gz
do
    f=${file%.gz}
    if [ ! -s $f -o $f -ot $file ]; then
        gunzip -c $file > aap.nc
        cdo -r -f nc4 -z zip copy aap.nc $f
        ncatted -h -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" $f
    fi
done

if [ ! -s gpcc_full_daily.nc ]; then
    doit=true
else
    doit=false
fi
yr=1988
file=full_data_daily_v${version}_$yr.nc
files=""
while [ -s $file ]; do
    if [ gpcc_full_daily.nc -ot $file ]; then
        doit=true
    fi
    files="$files $file"
    yr=$((yr+1))
    file=full_data_daily_v${version}_$yr.nc
done
if [ $doit = true -o "$force" = true ]; then
    echo "Making gpcc_full_daily.nc"
    cdo -r -f nc4 -z zip copy $files gpcc_full_daily_all.nc
    # cdo does not adjust time_coverage_start/end :-(
    ncatted -h -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" gpcc_full_daily_all.nc
    cdo -r -f nc4 -z zip selvar,precip gpcc_full_daily_all.nc gpcc_full_daily.nc
    cdo -r -f nc4 -z zip selvar,numgauge gpcc_full_daily_all.nc gpcc_full_daily_n.nc
    cdo -r -f nc4 -z zip ifthen gpcc_full_daily_n.nc gpcc_full_daily.nc gpcc_full_daily_n1.nc
    ncatted -h -a long_name,prcp,m,c,"precipitation in grid boxes with gauges" -a title,global,m,c,"GPCC full data daily v$version" gpcc_full_daily_n1.nc
fi
for file in gpcc_full_daily.nc gpcc_full_daily_n.nc gpcc_full_daily_n1.nc; do
    ncatted -h -a source_url,global,c,c,"ftp://ftp-anon.dwd.de/pub/data/gpcc/html/download_gate.html" $file
    . $HOME/climexp/add_climexp_url_field.cgi
done
$HOME/NINO/copyfilesall.sh gpcc_full_daily.nc gpcc_full_daily_n.nc gpcc_full_daily_n1.nc

mo=1
mm=`printf %02i $mo`
ffiles=""
doit=false
file=first_guess_daily_$yr$mm.nc
while [ -s $file ]; do
    if [ ! -s gpcc_combined_daily.nc -o gpcc_combined_daily.nc -ot $file ]; then
        doit=true
    fi
    ffiles="$ffiles $file"
    mo=$((mo+1))
    if [ $mo -gt 12 ]; then
        mo=1
        yr=$((yr+1))
    fi
    mm=`printf %02i $mo`
    file=first_guess_daily_$yr$mm.nc
done
if [ $doit = true -o "$force" = true ]; then
    echo "Making gpcc_combined_daily.nc"
    cdo -r -f nc4 -z zip copy $ffiles gpcc_firstguess_daily_all.nc
    cdo -r -f nc4 -z zip selvar,p gpcc_firstguess_daily_all.nc gpcc_firstguess_daily.nc
    ncrename -v p,precip gpcc_firstguess_daily.nc
    cdo -r -f nc4 -z zip selvar,s gpcc_firstguess_daily_all.nc gpcc_firstguess_daily_n.nc
    ncrename -v s,numgauge gpcc_firstguess_daily_n.nc
    cdo -r -f nc4 -z zip ifthen gpcc_firstguess_daily_n.nc gpcc_firstguess_daily.nc gpcc_firstguess_daily_n1.nc
    cdo -r -f nc4 -z zip copy gpcc_full_daily.nc gpcc_firstguess_daily.nc gpcc_combined_daily.nc
    ncatted -h -a title,global,m,c,"GPCC full data daily v$version, extended with first guess" gpcc_combined_daily.nc
    cdo -r -f nc4 -z zip copy gpcc_full_daily_n.nc gpcc_firstguess_daily_n.nc gpcc_combined_daily_n.nc
    ncatted -h -a title,global,m,c,"GPCC full data daily v$version, extended with first guess" gpcc_combined_daily_n.nc
    cdo -r -f nc4 -z zip copy gpcc_full_daily_n1.nc gpcc_firstguess_daily_n1.nc gpcc_combined_daily_n1.nc
    ncatted -h -a title,global,m,c,"GPCC full data daily v$version, extended with first guess" gpcc_combined_daily_n1.nc
    for file in gpcc_combined_daily.nc gpcc_combined_daily_n.nc gpcc_combined_daily_n1.nc; do
        # cdo does not adjust these yet, recompute myself
        ncatted -h -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" $file
        . $HOME/climexp/add_climexp_url_field.cgi
    done
fi
$HOME/NINO/copyfiles.sh gpcc_combined_daily.nc gpcc_combined_daily_n.nc gpcc_combined_daily_n1.nc

make merge_telecon
. ./merge_telecon.sh gpcc