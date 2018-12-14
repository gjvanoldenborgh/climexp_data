#!/bin/bash
download=true
if [ "$1" = nodownload ]; then
    download=false
fi

# RSS data

base=ftp://ftp.remss.com/msu/data/netcdf
for version in V3_3 V4_0
do
    for layer in TLT # tmt tts tls
    do
        for anom in "" _Anom
        do
            infile=rss_Tb${anom}_Maps_ch_${layer}_${version}.nc
            [ "$download" != false -o ! -s $infile ] && wget -q -N --user=oldenborgh@knmi.nl --password=oldenborgh@knmi.nl $base/$infile
            file=`echo rss_$layer${anom}_$version.nc | tr '[:upper:]' '[:lower:]'`
            ncks -O -v brightness_temperature $infile $file
            ncrename -v brightness_temperature,$layer -v months,time -d months,time $file
            # does not work due to a bug in ncrename
            ###ncrename -a REFERENCES,references -a HISTORY,history -a INSTITUTION,institution -a TITLE,title $file
            ncatted -a units,longitude,m,c,"degrees_east" -a units,latitude,m,c,"degrees_north" $file
            . $HOME/climexp/add_climexp_url_field.cgi
            $HOME/NINO/copyfiles.sh $file
        done
    done
done
get_index $file 0 360 -90 90 > rss_tlt_gl.dat
get_index $file 0 360 -90  0 > rss_tlt_sh.dat
get_index $file 0 360   0 90 > rss_tlt_nh.dat
$HOME/NINO/copyfilesall.sh rss_tlt_??.dat

exit

yr=`date +%Y`
mo=`date +%m`
if [ -f downloaded_$yr$mo ]; then
  echo "Already downloaded TMI this month"
  exit
fi

base=ftp://ftp.discover-earth.org/sst/daily

# TMI only

echo checking old data
wget -q -N $base/tmi/tmi.fusion.1998.???.v0?.gz
wget -q -N $base/tmi/tmi.fusion.1999.???.v0?.gz
wget -q -N $base/tmi/tmi.fusion.2000.???.v0?.gz
wget -q -N $base/tmi/tmi.fusion.2001.???.v0?.gz
wget -q -N $base/tmi/tmi.fusion.2002.???.v0?.gz

# TMI + AMSRE combined

echo retrieving new data
wget -q -N $base/tmi_amsre/tmi_amsre.fusion.*.v02.gz
# it sometimes fails, try again
wget -q -N $base/tmi_amsre/tmi_amsre.fusion.*.v02.gz
# it sometimes fails, try again
wget -q -N $base/tmi_amsre/tmi_amsre.fusion.*.v02.gz

#make dat2dat
echo converting to GrADS
./dat2dat

echo copying to climexp
$HOME/NINO/copyfiles.sh ssmi_sst.ctl ssmi_sst.grd

date > downloaded_$yr$mo
