#!/bin/sh
for var in MT HC
do
    case $var in
        MT) altvar=mt;;
        HC) altvar=heat;;
        *) ecjo "error huogiw7  f8pe"; exit -1;;
    esac

    for depth in 100 700 2000
    do
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

        if [ $var = HC -a $depth = 100 }; then
            echo "100m heat content not available"
        else
            cp ${var}_0-${depth}-3month.tar.gz ${var}_0-${depth}-3month.tar.gz.old
            wget -q -N ftp://ftp.nodc.noaa.gov/pub/data.nodc/woa/DATA_ANALYSIS/3M_HEAT_CONTENT/DATA/${altvar}_3month/${var}_0-${depth}-3month.tar.gz
            cmp ${var}_0-${depth}-3month.tar.gz ${var}_0-${depth}-3month.tar.gz.old
            if [ $? != 0 ]; then
              tar zxf ${var}_0-${depth}-3month.tar.gz
              make dat2grads
              ./dat2grads $depth $var
              $HOME/NINO/copyfiles.sh heat${depth}.???
            fi
        fi
    done
done