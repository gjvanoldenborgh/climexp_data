#!/bin/sh

base=http://www.metoffice.gov.uk/hadobs/hadex2/data/
for var in TXx TNx TXn TNn TN10p TX10p TN90p TX90p Rx1day Rx5day R95p R99p
do
    case $var in
        TX10p) units="%";long_name="Percentage of days when TX &lt; 10th percentile";;
        TX90p) units="%";long_name="Percentage of days when TX &gt; 90th percentile";;
        TN10p) units="%";long_name="Percentage of days when TN &lt; 10th percentile";;
        TN90p) units="%";long_name="Percentage of days when TN &gt; 90th percentile";;
        TXx) units="Celsius";long_name="Maximum value of daily maximum temperature";;
        TXn) units="Celsius";long_name="Minimum value of daily maximum temperature";;
        TNx) units="Celsius";long_name="Maximum value of daily minimum temperature";;
        TNn) units="Celsius";long_name="Minimum value of daily minimum temperature";;
        Rx1day) units="mm/dy";long_name="Maximum 1-day precipitation amount";;
        Rx5day) units="mm/5dy";long_name="Maximum 5-day precipitation amount";;
        R95p) units="mm/yr";long_name="Precipitation on very wet days";;
        R99p) units="mm/yr";long_name="Precipitation on extremely wet days";;
        *) echo "$0: error: vcywugbckljewbv"; exit -1;;
    esac
    file=H2_${var}_1901-2010_RegularGrid_global_3.75x2.5deg_LSmask.nc
    wget -q -N $base/$file
    newfile=HadEX2_${var}_ann.nc
    if [ ! -s $newfile -o $newfile -ot $file ]; then
        cdo -r -f nc4 -z zip selvar,Ann $file $newfile
        ncrename -v Ann,$var $newfile
        ncatted -h -a long_name,${var},a,c,"$long_name" -a Title,global,d,c,"" \
                -a units,${var},a,c,"$units" -a title,global,a,c,"HadEX2 analysis" \
                -a source_url,global,a,c,"https://www.metoffice.gov.uk/hadobs/hadex2/" \
                -a reference,global,a,c,"Donat, M.G., et al. (2012), Updated analyses of temperature and precipitation extreme indices since the beginning of the twentieth century: The HadEX2 dataset, JGR Atmospheres, doi:10.1002/jgrd.50150" \
                    $newfile
        file=$newfile
        ncatted -h -a climexp_url,global,c,c,"https://climexp.knmi.nl/select.cgi?hadex2_ann_${var}" $newfile
    fi
    c=`ncdump -h $file | fgrep -c 'float Jan'`
    if [ $c != 0 ]; then
        newfile=HadEX2_${var}_mo.nc
        if [ ! -s $newfile -o $newfile -ot $file ]; then
            mon=0
            while [ $mon -lt 12 ]; do
                mon=$((mon+1))
                case $mon in
                    1) month=Jan;;
                    2) month=Feb;;
                    3) month=Mar;;
                    4) month=Apr;;
                    5) month=May;;
                    6) month=Jun;;
                    7) month=Jul;;
                    8) month=Aug;;
                    9) month=Sep;;
                    10) month=Oct;;
                    11) month=Nov;;
                    12) month=Dec;;
                esac
                mm=`printf %02i $mon`
                cdo -r -f nc4 -z zip selvar,$month $file aap.nc
                cdo -r -f nc4 -z zip settaxis,1901-${mm}-01,0:00:00,1year aap.nc aap_$month.nc
                ncrename -v ${month},$var aap_$month.nc
                ncatted -h -a long_name,${var},a,c,"$long_name" -a units,${var},a,c,"$units" \
                        -a title,global,a,c,"HadEX2 analysis" \
                        -a source_url,global,a,c,"https://www.metoffice.gov.uk/hadobs/hadex2/" \
                        -a reference,global,a,c,"Donat, M.G., et al. (2012), Updated analyses of temperature and precipitation extreme indices since the beginning of the twentieth century: The HadEX2 dataset, JGR Atmospheres, doi:10.1002/jgrd.50150" \
                            aap_$month.nc
            done
            cdo -r -f nc4 -z zip mergetime aap_???.nc $newfile
            ncatted -h -a climexp_url,global,c,c,"https://climexp.knmi.nl/select.cgi?hadex2_${var}" $newfile
            rm -f aap*.nc
        fi
    fi
done
$HOME/NINO/copyfiles.sh HadEX2*.nc
