#!/bin/bash
# it is all very simple, really. FRom https://nsidc.org/support/faq/what-options-are-available-bulk-downloading-data-https-earthdata-login-enabled
wget="wget --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --keep-session-cookies --no-check-certificate --auth-no-challenge=on --reject "index.html*" -np -e robots=off"
###base=ftp://sidads.colorado.edu/pub/DATASETS/seaice/polar-stereo/bootstrap/final-gsfc/
base=https://daacdata.apps.nsidc.org/pub/DATASETS/nsidc0079_gsfc_bootstrap_seaice_v3/final-gsfc/
version=3.1 # to be updated by hand now, this is called progress
if [ "$1" != debug ]; then
    cwd=`pwd`
    for ns in north south
    do
        case $ns in
            north) h=n;;
            south) h=s;;
        esac
        mkdir -p $ns/monthly
        cd $ns/monthly
        yr=1978
        mo=11
        stillok=true
        while [ $stillok = true ]; do
            mm=`printf %02i $mo`
            if [ $yr -lt 1987 -o $yr = 1987 -a $mo -lt 8 ]; then
                sat=n07
            else
                sat=f08
            fi
            file=bt_${yr}${mm}_${sat}_v${version}_${h}.bin
            $wget --no-check-certificate -N $base/$ns/monthly/$file
            ((mo++))
            if [ $mo -gt 12 ]; then
                ((mo=mo-12))
                ((yr++))
            fi
            if [ ! -s $file ]; then
                stillok=false
            fi
        done
        cd $cwd
    done # ns
fi
make bootstrap2grads
./bootstrap2grads
for h in n s ; do
    file=conc_bt_$h.nc
    grads2nc ${file%nc}ctl $file
    ncatted -h -a source,global,c,c,"https://nsidc.org/data/nsidc-0079" \
        -a institution,global,m,c,"NSIDC, interpolated to lat/lon at KNMI" \
        -a version,global,c,c,$version \
        -a doi,global,c,c,"doi:10.5067/7Q8HCCWS4I0R" $file
    . $HOME/climexp/add_climexp_url_field.cgi
done
$HOME/NINO/copyfiles.sh conc_bt_*.nc
