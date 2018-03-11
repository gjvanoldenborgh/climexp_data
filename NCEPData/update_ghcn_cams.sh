#!/bin/sh
if [ "$1" = force ]; then
	force=true
fi
doit=false
mv ghcn_cams_0.5_grb.ctl ghcn_cams_0.5_grb.ctl.old
wget -q ftp://ftp.cpc.ncep.noaa.gov/wd51yf/GHCN_CAMS/ghcn_cams_0.5_grb.ctl
for file in \
  ghcn_cams_1948_cur.grb \
  ghcn_cams_1948_cur_2.5.grb
#  ghcn_cams_1948_cur_t126.grb \
#  ghcn_cams_1948_cur_t62.grb
do
  cp $file.idx $file.idx.old
  wget -q -N ftp://ftp.cpc.ncep.noaa.gov/wd51yf/GHCN_CAMS/$file.idx
  cmp $file.idx $file.idx.old
  if [ $? = 0 -a "$force" != true ]
  then
    mv $file.idx.old $file.idx
  else
    mv $file $file.old
    wget -q -N ftp://ftp.cpc.ncep.noaa.gov/wd51yf/GHCN_CAMS/$file
    doit=true
  fi
done
if [ $doit = true ]; then
# stupid hack - hope it keeps working
###size=`wc -c ghcn_cams_1948_cur.grb | cut -b 1-10`
###nt=$(($size / 192014))
# it seems they updated the TDEF statement to a good one
nt=`fgrep -i tdef ghcn_cams_0.5_grb.ctl | awk '{print $2}'`
echo nt=$nt
###nt=`fgrep -i tdef ghcn_cams_0.5_grb.ctl | cut -b 5-8`
for res in 05 25
do
    case $res in
        05) name="";d=0.5;nx=720;ny=360;x1=0.25;y1=-89.75;;
        25) name="_2.5";nx=144;ny=73;d=2.5;x1=0;y1=-90.00;;
        *) echo error 79534;exit -1;;
    esac
    sed -e "s/ghcn_cams_1948_cur/ghcn_cams_1948_cur$name/" \
        -e "s/xdef 720 /xdef $nx /" -e "s/ydef 360 /ydef $ny /" \
        -e "s/ 0.25/ $x1/" -e "s/ -89.75/ $y1/" \
        -e "s/ 0.5/ $d/" \
        -e "s/tdef 1000/tdef $nt/" \
            ghcn_cams_0.5_grb.ctl > aap.ctl
    grads -l -b <<EOF | fgrep -v Wrote 2>&1
open aap.ctl
set t 1 $nt
set x 1 $nx
set gxout fwrite
set fwrite ghcn_cams_$res.grd
d tmp2m-273.15
quit
EOF
    cat > ghcn_cams_$res.ctl <<EOF
DSET ^ghcn_cams_$res.grd
TITLE GHCN/CAMS 2m analysis (Fan and van den Dool)
OPTIONS LITTLE_ENDIAN
EOF
    fgrep def aap.ctl | sed -e 's/9.999E+20/-9.99e+08/' >> ghcn_cams_$res.ctl
    cat >> ghcn_cams_$res.ctl <<EOF
VARS 1
tmp2m 0 99 2m temperature [Celsius]
ENDVARS
EOF
    # convert to netcdf, add metadata
    grads2nc ghcn_cams_$res.ctl ghcn_cams_$res.nc
    ncatted -h -a institution,global,m,c,"NOAA/CPC" \
            -a reference,global,a,c,"Fan, Y., and H. van den Dool (2008), A global monthly land surface air temperature analysis for 1948 – present, J. Geophys. Res., 113, D01103, doi:10.1029/2007JD008470" \
            -a source_url,global,a,c,"ftp://ftp.cpc.ncep.noaa.gov/wd51yf/GHCN_CAMS/" \
            -a contact,global,a,c,"Emily.Becker@noaa.gov" ghcn_cams_$res.nc
    file=ghcn_cams_$res.nc
    . $HOME/climexp/add_climexp_url_field.cgi
done


if [ ! -s ghcn_cams_10.nc -o ghcn_cams_10.nc -ot ghcn_cams_1948_cur.grb ]; then
  echo "generating the 1.0 degree version myself"
  rm ghcn_cams_10.*
  echo "Constructing 1x1 version"
  $HOME/climexp/bin/averagefieldspace ghcn_cams_05.ctl 2 2 ghcn_cams_10.nc
fi
echo "Copying to climexp"
rsync -e ssh ghcn_cams_??.nc bhlclim:climexp/NCEPData/
fi
