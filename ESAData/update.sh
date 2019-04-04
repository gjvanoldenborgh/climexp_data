#!/bin/bash
version=fv02
versiondir=V2.0_20161205/
base=ftp://ftp.esa-sealevel-cci.org/SeaLevel-ECV/$versiondir
yr=1993
mo=0
files=""
ok=true
while [ $ok = true ]; do
    ((mo++))
    if [ $mo -gt 12 ]; then
        mo=1
        ((yr++))
    fi
    mm=`printf %02i $mo`
    file=ESACCI-SEALEVEL-L4-MSLA-MERGED-${yr}${mm}15000000-$version.nc.gz
    if [ ! -s $file ]; then
        wget -N $base/$file
    fi
    if [ ! -s $file ]; then
        ok=false
    else
        f=${file%.gz}
        if [ ! -s $f -o $f -ot $file ]; then
            gunzip -c $file > /tmp/$f
            cdo settaxis,${yr}-${mo}-15,0:00 /tmp/$f $f
        fi
        files="$files $f"
    fi
done

file=esacci_sla.nc
set -x
cdo -r -f nc4 -z zip copy $files $file
ncatted -h -a doi,global,a,c,"doi:10.5270/esa-sea_level_cci-IND_MSL_MERGED-1993_2015-v_2.0-201612" \
    -a time_coverage_start,global,d,c,"" \
    -a time_coverage_end,global,d,c,"" \
    $file
. $HOME/climexp/add_climexp_url_field.cgi

$HOME/NINO/copyfiles.sh $file