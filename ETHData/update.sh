#!/bin/sh
cdo="cdo -f nc4 -z zip"
download=$1
set -x
if [ "$download" = download ]; then
    wget -q -r -nH --cut-dirs=1 -N ftp://friend:data4you@data.iac.ethz.ch/CLM_Sarah_Sjoukje/
fi
for kind in cru era; do
    case $kind in
        cru) dir=i.e122.ICRU.hcru_hcru.WFDEI-io120.001;calender="";;
        era) dir=i.e122.ICRU.f09_g16.ERA_2016_spinup-io120.001;calender=365_day;;
    esac
    vars=`ls $dir`
    for var in $vars; do
        case $var in
            RAIN|ET|ETp|SNOW)
                outfile=${var}_${kind}_clm.nc
                fac=86400
                units="mm/s"
                newunits="mm/dy"
                xdir=.
                case $var in
                    RAIN) lvar="atmospheric rain";;
                    ET) lvar="evapotransporation";;
                    ETp) lvar="potential et (Priestley Taylor)";;
                    SNOW) lvar="atmospheric snow";;
                    *) echo "$0: error: unknown var $var";exit -1;;
                esac
                ;;
            SOILLIQ) 
                outfile=${var}_${kind}_clm.nc
                fac=""
                units="kg/m^2"
                lvar="soil liquid water"
                xdir=soillev
                ;;
        esac
        if [ -n "$outfile" -a ! -s "$outfile" ]; then
            $cdo copy $dir/$var/$xdir/*.nc $outfile.tmp
            $cdo settaxis,1979-01-15,0:00,1mon $outfile.tmp $outfile # grads cannot handle "seconds since"...
            ncatted -h -a units,lon,c,c,"degrees_east" -a units,lat,c,c,"degrees_north" \
                -a long_name,$var,c,c,"$lvar" -a units,$var,c,c,"$units" \
                -a institution,global,c,c,"ETHZ" -a contact,global,c,c,"mathias.hauser@env.ethz.ch" \
                -a experiment,global,c,c,"$dir" -a title,global,c,c,"CLM output" $outfile
            if [ -n "$fac" ]; then
                $cdo mulc,$fac $outfile $outfile.tmp
                mv $outfile.tmp $outfile
                ncatted -h -a units,$var,m,c,"$newunits" $outfile
            fi
            if [ -n "$calendar" ]; then
                ncatted -h -a calendar,time,m,c,"$calendar" $outfile
            fi
            if [ $var = SOILLIQ ]; then
                soil01file=${var}_${kind}_clm_01.nc
                ncks -O -d lev,0 $outfile $soil01file
                ncatted -h -a long_name,$var,a,c," 0-10cm" $soil01file
                soil1file=${var}_${kind}_clm_1.nc
                ncks -O -d lev,1 $outfile $soil1file
                $cdo add $soil1file $soil01file $soil1file.tmp
                mv $soil1file.tmp $soil1file
                ncatted -h -a long_name,$var,a,c," 0-1m" $soil1file
            fi
        fi
    done
done
