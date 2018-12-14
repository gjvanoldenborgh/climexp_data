#!/bin/bash
if [ "$1" = force ]; then
    force=true
fi

files=""
for var in mean_temperature heat_content; do
    case $var in
        mean_temperature) ncvar=T_dC_mt;seriesvar=seas_T_dC;myvar=temp;;
        heat_content) ncvar=h18_hc;seriesvar=seas_h22;myvar=heat;;
        8) echo "$0: error: unknown var $var"; exit -1;;
    esac
    for depth in 100 700 2000; do
        if [ $var = heat_content -a $depth = 100 ]; then
            echo "$var not available for $depth"
        else
            ncfile=${var}_anomaly_0-${depth}_seasonal.nc
            echo "wget --no-check-certificate -q -N http://data.nodc.noaa.gov/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/NETCDF/heat_content/$ncfile"
            wget --no-check-certificate -q -N http://data.nodc.noaa.gov/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/NETCDF/heat_content/$ncfile
            # 2D field
            file=$myvar$depth.nc
            ncks -O -v $ncvar $ncfile seas_$file
            yearly2shorterfield seas_$file 12 offset_$file
            cdo shifttime,1mon offset_$file $file
            if [ $var = mean_temperature ]; then
                ncatted -a long_name,$ncvar,m,c,"mean temperature anomaly 0-${depth}m" $file
            else
                ncatted -a long_name,$ncvar,m,c,"ocean heat content anomaly 0-${depth}m" $file            
            fi
            . $HOME/climexp/add_climexp_url_field.cgi
            $HOME/NINO/copyfiles.sh $file
            
            for basin in WO NH SH AO NA SA PO NP SP IO NI SI; do
                case $basin in
                    WO) mybasin=global;;
                    NH) mybasin=nh;;
                    SH) mybasin=sh;;
                    AO) mybasin=Atlantic;;
                    NA) mybasin=North_Atlantic;;
                    SA) mybasin=South_Atlantic;;
                    PO) mybasin=Pacific;;
                    NP) mybasin=North_Pacific;;
                    SP) mybasin=South_Pacific;;
                    IO) mybasin=Indian;;
                    NI) mybasin=North_Indian;;
                    SI) mybasin=South_Indian;;
                    *) echo "$0: error: unknown basin $basin";exit -1;;
                esac
                seriesfile=$myvar${depth}_$mybasin
                ncks -O -v ${seriesvar}_$basin $ncfile seas_$seriesfile.nc
                yearly2shorter seas_$seriesfile.nc 12 > offset_$seriesfile.dat
                timeshift offset_$seriesfile.dat 1 > $seriesfile.dat
                ###rm seas_$seriesfile.nc offset_$seriesfile.dat
                files="$files $seriesfile.dat"
            done
        fi
    done
done
$HOME/NINO/copyfilesall.sh $files

exit

# old ascii versions

for var in MT HC
do
    case $var in
        MT) altvar=mt;myvar=temp;;
        HC) altvar=heat;myvar=temp;;
        *) ecjo "error huogiw7  f8pe"; exit -1;;
    esac

    for depth in 100 700 2000
    do
        if [ 0 = 0 ]; then
        for b in a i p w # basins
        do
            for season in 1-3 4-6 7-9 10-12
            do
                if [ $var = HC ]; then
                    wget -q -N ftp://ftp.nodc.noaa.gov/pub/data.nodc/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/DATA/basin/3month/h22-${b}0-${depth}m${season}.dat
                else
                    wget -q -N ftp://ftp.nodc.noaa.gov/pub/data.nodc/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/DATA/basin/3month_mt/T-dC-${b}0-${depth}m${season}.dat
                fi
            done
            if [ $var = HC ]; then
                wget -q -N http://data.nodc.noaa.gov/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/DATA/basin/pentad/pent_h22-${b}0-${depth}m.dat
            else
                wget -q -N http://data.nodc.noaa.gov/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/DATA/basin/pentad_mt/pent_T-dC-${b}0-${depth}m.dat
            fi
        done

        ./dat2dat $depth $var
        $HOME/NINO/copyfilesall.sh heat${depth}_*.dat temp${depth}_*.dat
        else
            echo "Skipping time series DEBUG"
        fi

        if [ $var = HC -a $depth = 100 ]; then
            echo "100m heat content not available"
        else
            yrnow=`date "+%Y"`
            ((yrnow=yrnow-1900))
            if [ $depth -lt 1000 ]; then
                yr=54
            else
                yr=104
            fi
            while [ $yr -lt $yrnow ]; do
                ((yr++))
                yy=`echo $yr | sed -e 's/^10/A/' -e 's/^11/B/' -e 's/^12/C/' -e 's/^13/D/'`
                for season in 01-03 04-06 07-09 10-12; do
                    if [ ! -s ${var}_0-${depth}_${yy}${yy}${season}.dat -o "$force" = true ]; then
                        echo "checking for $depth $yy $season"
                        wget -q -N --no-check-certificate http://data.nodc.noaa.gov/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/DATA/${altvar}_3month/${var}_0-${depth}_${yy}${yy}${season}.dat
                    fi
                done
            done
            make dat2grads
            ./dat2grads $depth $var
            grads2nc $myvar$depth.ctl $myvar$depth.nc
            file=$myvar${depth}.nc
            ncatted -h -a institution,global,m,c,"NODC" $file
            if [ $var = HC ]; then
                ncatted -h -a source_url,global,m,c,"https://www.nodc.noaa.gov/cgi-bin/OC5/3M_HEAT/heatdata.pl?time_type=3month$depth" $file
            . $HOME/climexp/add_climexp_url_field.cgi
            $HOME/NINO/copyfiles.sh $myvar$depth.nc
        fi
    done
done
