#!/bin/sh
export PATH=/usr/local/free/bin:$HOME/climexp/bin:$PATH
firstfile=`ls -t ??_0.25deg_reg_v*eu.nc | head -1`
version=${firstfile#*_reg_}
version=${version%u.nc}
echo "version=$version"
daypath=/net/eobsdata/nobackup/users/besselaa/Data/Gridding/Daily/Rupdates/
cdo="cdo -r -f nc4 -z zip"

for res in 0.25 # 0.1 takes too much memory
do
    for var in rr tg tn tx;
    do
        file=${var}_${res}deg_reg_${version}u.nc
        if [ ! -s $file ]; then
            echo "Cannot find $file!"
            exit -1
        fi
        if [ ! -s $file.lastline -o $file.lastline -ot $file ]; then
            echo "get_index $file 5 5 52 52"
            get_index $file 5 5 52 52 | tail -1 > $file.lastline
        fi
        yr=`cat $file.lastline | cut -b 1-4`
        mm=`cat $file.lastline | cut -b 5-6 | tr ' ' '0'`
        dd=`cat $file.lastline | cut -b 7-8 | tr ' ' '0'`

        files=$file
        datenow=`date -d 'yesterday' +%Y%m%d`
        while [ $yr$mm$dd -lt $datenow ]; do
            files="$files $nextfile"
            mo=${mm#0}
            dy=${dd#0}
            ((dy++))
            case $mo in
                1|3|5|7|8|10|12) dpm=31;;
                4|6|9|11) dpm=30;;
                2)  if [ $((yr%4)) = 0 ]; then
                        dpm=29
                    else
                        dpm=28
                    fi;;
                *) echo "error nbhvgxwaq"; exit -1;;
            esac
            if [ $dy -gt $dpm ]; then
                ((dy=dy-dpm))
                ((mo++))
            fi
            if [ $mo -gt 12 ]; then
                ((mo=mo-12))
                ((yr++))
            fi
            mm=`printf %02i $mo`
            dd=`printf %02i $dy`
            file=${var}_day_${yr}${mm}${dd}_grid_ensmean.nc
            if [ ! -s $file -a -s $daypath/$file ]; then
                # we make it smaller to avoid a Fortran 2G limit
                $cdo selindexbox,41,464,1,201 $daypath/$file $file
            fi
            if [ -s $file ]; then
                lastfile=$file
            else
                echo "cannot find $file, exit"
                exit -1
                file=./${var}_${res}deg_undef_$yr$mm$dd.nc
                if [ ! -s $file ]; then
                    echo "cannot find $file, making it"
                    $cdo divc,0. $lastfile aap.nc
                    $cdo settaxis,${yr}-${mm}-${dd},0:00 aap.nc $file
                    rm aap.nc
                fi
            fi
            files="$files $file"
        done
        extfile=${var}_${res}deg_reg_${version}e.nc
        echo "$cdo copy $files $extfile"
        $cdo copy $files $extfile
        rsync -avt $extfile bhlclim:climexp/ENSEMBLES/
    done
done