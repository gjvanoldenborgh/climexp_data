#!/bin/sh
if [ -d /usr/local/free/bin ]; then
    export PATH=/usr/local/free/bin:$PATH
fi
export PATH=$HOME/climexp/bin:$PATH
wget="wget -q --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies"

# get the research / final run

version=05
yr=2014
mo=3
mm=03
dy=11
dd=11
base=http://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGDF.$version
nrtbase=http://gpm1.gesdisc.eosdis.nasa.gov/data/GPM_L3/GPM_3IMERGDL.$version
files=""
yrnow=`date +%Y`
mmnow=`date +%m`
ddnow=`date +%d`
pfile=$0
stillok=true
while [ -s $pfile ]; do   
    ((dy++))
    case $mo in
        1|3|5|7|8|10|12) dpm=31;;
        4|6|9|11) dpm=30;;
        2)  if [ $((yr%4)) = 0 ]; then
                dpm=29
            else
                dpm=28
            fi;;
        *) echo "$0: internal error mo=$mo"; exit -1;;
    esac
    if [ $dy -gt $dpm ]; then
        dy=1
        ((mo++))
    fi
    if [ $mo -gt 12 ]; then
        ((mo=mo-12))
        ((yr++))
    fi
    mkdir -p $yr
    mkdir -p p$yr
    mm=`printf %02i $mo`
    dd=`printf %02i $dy`
    dir=$yr/$mm
    file=3B-DAY.MS.MRG.3IMERG.${yr}${mm}${dd}-S000000-E235959.V${version}.nc4
    nrtfile=3B-DAY-L.MS.MRG.3IMERG.${yr}${mm}${dd}-S000000-E235959.V${version}.nc4
    pfile=p$yr/imerg_${yr}${mm}${dd}.nc
    pfile02=p$yr/imerg_${yr}${mm}${dd}_02.nc
    pfile05=p$yr/imerg_${yr}${mm}${dd}_05.nc
    ###echo "checking for file $yr/$file"
    if [ ! -s $yr/$file -a $stillok = true ]; then
        echo "$wget $base/$dir/$file"
        $wget $base/$dir/$file -O $yr/$file
        if [ -s $yr/$file ]; then
            echo "Downloaded $file"
            [ -f $pfile ] && rm $pfile
            [ -f $yr/$nrtfile ] && rm $yr/$nrtfile
        else
            echo "Cannot find final file $file, continuing with NRT data"
            stillok=false
        fi
    fi
    if [ $stillok = false ]; then
        if [ ! -s $yr/$nrtfile ]; then
            if [ ${yr}${mm}${dd} = 20160312 -o \
                 ${yr}${mm}${dd} = 20160323 ]; then
                echo "missing date ${yr}${mm}${dd}, setting to undef"
                cp undef.nc $yr/$nrtfile
            else
                echo "$wget $nrtbase/$dir/$file"
                $wget $nrtbase/$dir/$nrtfile -O $yr/$nrtfile
            fi
        fi
        if [ -s $yr/$nrtfile ]; then
            file=$nrtfile
        else
            echo "Cannot find NRT file $nrtfile"
            stillok=completelyfalse
        fi
    fi
    if [ -s $yr/$file ]; then
        if [ ! -s $pfile -o $pfile -ot $yr/$file ]; then
            cdo -r -f nc4 -z zip -selvar,precipitationCal -settaxis,${yr}-${mm}-${dd},12:00 $yr/$file aap$$.nc
            ncpdq -O -a time,lat,lon aap$$.nc $pfile
            rm aap$$.nc
            ncatted -a units,precipitationCal,m,c,"mm/dy" $pfile
        fi
        if [ ! -s $pfile02 ]; then
            averagefieldspace $pfile 2 2 $pfile02
        fi
        if [ ! -s $pfile05 ]; then
            averagefieldspace $pfile 5 5 $pfile05
        fi
        files="$files $pfile"
        files02="$files02 $pfile02"
        files05="$files05 $pfile05"
    fi
done

echo "Concatenating..."
###echo "cdo -r -f nc4 -z zip copy $files imerg_daily.nc"
file=imerg_daily_05.nc
cdo -r -f nc4 -z zip copy $files05 $file
ncatted -a intitution,m,c,"NASA, converted to CF conventions, merged and averaged at KNMI" $file
. $HOME/climexp/add_climexp_url_field.cgi
file=imerg_daily_02.nc
cdo -r -f nc4 -z zip copy $files02 $file
ncatted -a intitution,m,c,"NASA, converted to CF conventions, merged and averaged at KNMI" $file
. $HOME/climexp/add_climexp_url_field.cgi
file=imerg_daily.nc
cdo -r -f nc4 -z zip copy $files 
ncatted -a intitution,m,c,"NASA, converted to CF conventions and merged at KNMI" $file
. $HOME/climexp/add_climexp_url_field.cgi
rsync -avt imerg_daily*.nc bhlclim:climexp/GPMData/
