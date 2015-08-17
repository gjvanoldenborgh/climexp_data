#!/bin/sh

# ERSST v4
wget -q -N ftp://ftp.ncdc.noaa.gov/pub/data/cmb/ersst/v4/netcdf/ersst.v4.[12]*.nc
new=true
if [ $new = true ]; then
  rm ersstv4_all.nc
  filelist=""
  for file in ersst.v4.[12]*.nc
  do
    date=${file#ersst.v4.}
    date=${date%.nc}
    if [ 0 = 1 -a $date -ge 200801 ]; then
        newfile=${file%.nc}_patched.nc
            if [ ! -s $newfile -o $newfile -ot $file ]; then
            yyyy=${date%??}
            mm=${date#????}
            cdo settaxis,${yyyy}-${mm}-15,12:00,1mon $file $newfile
        fi
        filelist="$filelist $newfile"
    else
        filelist="$filelist $file"
    fi
  done
  cdo -r -f nc4 -z zip copy $filelist ersstv4_all.nc
  cdo selvar,sst ersstv4_all.nc ersstv4.nc
  cdo selvar,anom ersstv4_all.nc ersstv4a.nc
  $HOME/NINO/copyfilesall.sh ersstv4.nc ersstv4a.nc
  ./makenino.sh
  $HOME/NINO/copyfiles.sh ersst_nino*.dat
  ./makeiozm.sh
  $HOME/NINO/copyfiles.sh dmi_ersst.dat seio_ersst.dat wio_ersst.dat
  ./makesiod.sh
  $HOME/NINO/copyfiles.sh siod_ersst.dat esiod_ersst.dat wsiod_ersst.dat
  ./update_amo.sh
  $HOME/NINO/copyfiles.sh amo_ersst.dat amo_ersst_ts.dat
fi

# ERSST v3b
wget -q -N ftp://ftp.ncdc.noaa.gov/pub/data/cmb/ersst/v3b/ascii/ersst.[12]*.asc
new=true
if [ $new = true ]; then
  rm ersstv3b.???
  ./ersstv3b2dat
  $HOME/NINO/copyfiles.sh ersstv3b.???
fi

###force=true
# GHCN-M v3 temperature
base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/v3/grid/
version=3.2.1
file=grid-mntp-1880-current-v$version
file=grid-mntp-1880-current-v\?.\?.\?
wget -q -N $base/$file.dat.gz
# get the highest version number
file=`ls $file.dat.gz | sort | tail -1`
file=${file%.dat.gz}
gzip -t $file.dat.gz
if [ $? != 0 ]; then
	echo "Corrupt file $file, trying next one"
	file=`ls $file.dat.gz | sort | tail -2 | head -1`
	file=${file%.dat.gz}
	gzip -t $file.dat.gz
	if [ $? != 0 ]; then
		echo "Corrupt file $file, giving up"
		file=""
	fi
fi
if [ -n "$file" ]; then
	echo gunzipping $file.dat.gz
	cp $file.dat $file.dat.old
	gunzip -c $file.dat.gz > $file.dat
	cmp $file.dat $file.dat.old
	if [ $? != 0 -o "$force" = true ]; then
		make ncdc2grads
		./ncdc2grads $file.dat
		$HOME/NINO/copyfiles.sh temp_anom.dat temp_anom.ctl
	fi
fi

# merged datset
base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/blended
file=ncdc-merged-sfc-mntp
wget -q -N $base/$file.dat.gz
echo gunzipping $file.dat.gz 
cp $file.dat $file.dat.old
gunzip -c $file.dat.gz > $file.dat
cmp $file.dat $file.dat.old
if [ $? != 0 -o "$force" = true ]; then
  make ncdc2grads
  ./ncdc2grads $file.dat
  $HOME/NINO/copyfiles.sh t_anom.dat t_anom.ctl
fi

#
# NCDC precip
yr=`date -d "1 month ago" +%Y`
base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/v2/grid/
file=grid_prcp_1900-current
wget -q -N $base/$file.dat.gz
cp $file.dat $file.dat.old
gunzip -c $file.dat.gz > $file.dat
cmp $file.dat $file.dat.old
if [ $? != 0 ]; then
	make ncdc2grads
	./ncdc2grads $file.dat
	grads -b -l <<EOF
open prcp_anom.ctl
sdfopen cru_ts_3_10_01_pre_5_clim.nc
set t 1 last
set x 1 72
define pr = prcp.1 + mean.2(t=1)
set sdfwrite prcp_total.nc
sdfwrite pr
quit
EOF
	ncatted -a units,pr,c,c,"mm/month" -a long_name,pr,c,c,"total precipitation" prcp_total.nc
	$HOME/NINO/copyfiles.sh prcp_anom.dat prcp_anom.ctl prcp_total.nc
fi

echo "not retrieving v2 temperatures"
exit # no use retrieving the old ones, they are no longer updated.

# T2m
# old version
base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/v2/grid/
file=grid-mntp-1880-current-v2
wget -q -N $base/$file.dat.gz
gzip -t $file.dat.gz
if [ $? != 0 ]; then
	echo "Corrupt file $file"
else
	echo gunzipping
	cp $file.dat $file.dat.old
	gunzip -c $file.dat.gz > $file.dat
	cmp $file.dat $file.dat.old
	if [ $? != 0 ]; then
		make ncdc2grads
		./ncdc2grads $file.dat
		sed -e 's/temp_anom.dat/temp_anom_old.dat/' temp_anom.ctl > temp_anom_old.ctl
		rm temp_anom.ctl
		mv temp_anom.dat temp_anom_old.dat
		$HOME/NINO/copyfiles.sh temp_anom_old.dat temp_anom_old.ctl
	fi
fi

# merged SST/T2m dataset
# old version
base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/blended/usingGHCNMv2/
file=ncdc_blended_merg53v3b
wget -q -N $base/$file.dat.gz
echo gunzipping $file.dat.gz
cp $file.dat $file.dat.old
gunzip -c $file.dat.gz > $file.dat
cmp $file.dat $file.dat.old
if [ $? != 0 ]; then
  make ncdc2grads
  ./ncdc2grads $file.dat
  sed -e 's/t_anom.dat/t_anom_old.dat/' t_anom.ctl > t_anom_old.ctl
  rm t_anom.ctl
  mv t_anom.dat t_anom_old.dat
  $HOME/NINO/copyfiles.sh t_anom_old.dat t_anom_old.ctl
fi



# SSMI precip
#yr=`date +"%y"`
#yr1=`echo $((20$yr - 1)) | cut -b 3-4`
#file=PRE.$yr1
wget -q -N ftp://ftp.orbit.nesdis.noaa.gov/pub/corp/scsb/rferraro/ncdc/PRE.*
#file=PRE.$yr
#wget -q -N ftp://ftp.orbit.nesdis.noaa.gov/pub/corp/scsb/rferraro/ncdc/$file
./cat_pre.sh
size=`stat --format="%s" ssmi_1.dat`
nt=$(($size / (4*180*360)))
mv ssmi_1.ctl ssmi_1.ctl.old
cat > ssmi_1.ctl << EOF
DSET ^ssmi_1.dat
UNDEF -999.0
OPTIONS LITTLE_ENDIAN
XDEF 360 LINEAR 0.500000 1.0000
YDEF 180 LINEAR -89.500000 1.00000
TDEF $nt LINEAR 15JAN1987 1MO
ZDEF 1 LINEAR 0 1
VARS 1
pre 1 0 precipitation [mm/month]
ENDVARS
EOF
gzip -f ssmi_1.dat
$HOME/NINO/copyfiles.sh ssmi_1.*
