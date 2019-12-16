#!/bin/bash
if [ "$1" = force ]; then
    force=true
fi

# new merged dataset
echo "NCDC merged dataset"
base=https://www.ncei.noaa.gov/data/noaa-global-surface-temperature/v5/access/gridded/
###file=`curl $base | fgrep asc.gz | sed -e 's/.*href="//' -e 's/asc.gz".*$//'`
curl $base > index.html
file=`cat index.html | fgrep .nc | tail -n 1 | sed -e 's/^.*NOAA/NOAA/' -e 's/\.nc.*$/.nc/'`
if [ -z "$file" -o "$file" = ".nc" ]; then
    echo "$0: error: file=$file"
else
    echo "wget -N --no-check-certificate $base/$file"
    wget -N --no-check-certificate $base/$file
    newfile=`echo $file | sed -e 's/gridded.*$/gridded.nc/'`
    echo "mv $file $newfile"
    mv $file $newfile
    export file=$newfile
    ncatted -h -a source_url,global,a,c,"$base" $file
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh $file
fi

# GHCN-M v3 temperature
echo "GHCN-M v3 temperature"
base=ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/v3/grid/
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
		grads2nc temp_anom.ctl temp_anom.nc
        ncatted -h -a institution,global,a,c,"NOAA/NCEI" \
                -a source_url,global,a,c,"https://www.ncdc.noaa.gov/temp-and-precip/ghcn-gridded-products/" temp_anom.nc
        file=temp_anom.nc
	    . $HOME/climexp/add_climexp_url_field.cgi 
		$HOME/NINO/copyfiles.sh temp_anom.nc
	fi
fi

# ERSST v4,5
for version in v5 v4
do
    echo "ERSST $version"
    wget -q -N ftp://ftp.ncdc.noaa.gov/pub/data/cmb/ersst/$version/netcdf/ersst.$version.[12]*.nc
    new=true
    if [ $new = true ]; then
        rm ersst${version}_all.nc
        filelist=""
        for file in ersst.$version.[12]*.nc
        do
            date=${file#ersst.$version.}
            date=${date%.nc}
            filelist="$filelist $file"
        done
        cdo -r -f nc4 -z zip copy $filelist ersst${version}_all.nc
        # cdo does not do this right yet
        ncatted -h -a time_coverage_start,global,d,c,"" -a time_coverage_end,global,d,c,"" ersst${version}_all.nc
        # the time axis has minutes since 1-jan-1854 in a 360-day calendar WTF?!
        cdo settaxis,1854-01-01,0:00,1mon ersst${version}_all.nc aap.nc
        ncatted -O -a calendar,time,m,c,"standard" aap.nc ersst${version}_all.nc
        cdo selvar,sst ersst${version}_all.nc ersst${version}.nc
        file=ersst${version}.nc
	    . $HOME/climexp/add_climexp_url_field.cgi 
        cdo selvar,ssta ersst${version}_all.nc ersst${version}a.nc
        file=ersst${version}a.nc
	    . $HOME/climexp/add_climexp_url_field.cgi 
        $HOME/NINO/copyfilesall.sh ersst${version}.nc ersst${version}a.nc
        if [ $version = v5 ]; then
            . ./makenino.sh
            $HOME/NINO/copyfilesall.sh ersst_nino*.dat
            . ./makeiozm.sh
            $HOME/NINO/copyfilesall.sh dmi_ersst.dat seio_ersst.dat wtio_ersst.dat
            . ./makesiod.sh
            $HOME/NINO/copyfilesall.sh siod_ersst.dat esiod_ersst.dat wsiod_ersst.dat
            . ./update_amo.sh
            $HOME/NINO/copyfilesall.sh amo_ersst.dat amo_ersst_ts.dat
        fi
    fi
done

# old merged version, turns out to be uniofficial
base=http://www1.ncdc.noaa.gov/pub/data/ghcn/blended/
file=ncdc-merged-sfc-mntp
wget -q -N --no-check-certificate $base/$file.dat.gz
echo gunzipping $file.dat.gz 
cp $file.dat $file.dat.old
gunzip -c $file.dat.gz > $file.dat
cmp $file.dat $file.dat.old
if [ $? != 0 -o "$force" = true ]; then
    make ncdc2grads
    ./ncdc2grads $file.dat
    grads2nc t_anom.ctl ncdc-merged-sfc-mntp.nc
    ncatted -h -a title,global,m,c,"NOAA/NCEI Land and Ocean Temperature Anomalies" \
            -a institution,global,m,c,"NOAA/NCEI" \
            -a source_url,global,a,c,"https://www.ncdc.noaa.gov/temp-and-precip/ghcn-gridded-products/" ncdc-merged-sfc-mntp.nc
    file=ncdc-merged-sfc-mntp.nc
	. $HOME/climexp/add_climexp_url_field.cgi
	$HOME/NINO/copyfiles.sh ncdc-merged-sfc-mntp.nc
fi

# NCDC precip
yr=`date -d "1 month ago" +%Y`
base=http://www1.ncdc.noaa.gov/pub/data/ghcn/v2/grid/
file=grid_prcp_1900-current
wget -q -N $base/$file.dat.gz
cp $file.dat $file.dat.old
gunzip -c $file.dat.gz > $file.dat
cmp $file.dat $file.dat.old
if [ $? != 0 -o "$force" = true ]; then
	make ncdc2grads
	./ncdc2grads $file.dat
	grads2nc prcp_anom.ctl prcp_anom.nc
	grads -b -l <<EOF
sdfopen prcp_anom.nc
sdfopen cru_ts4.01.pre.clim_5.nc
set x 1 72
set dfile 2
set t 1 12
define clim = pre.2
modify clim seasonal
set dfile 1
set t 1 last
define pr = prcp.1 + clim
set sdfwrite prcp_total.nc
sdfwrite pr
quit
EOF
    for file in prcp_anom.nc prcp_total.nc; do
        ncatted -h -a institution,global,a,c,"NOAA/NCEI" \
            -a source_url,global,a,c,"https://www.ncdc.noaa.gov/temp-and-precip/ghcn-gridded-products/" $file
    	. $HOME/climexp/add_climexp_url_field.cgi
    done    
    ncatted -h -a units,pr,c,c,"mm/month" -a long_name,pr,c,c,"total precipitation" \
            -a comment,global,a,c,"Added CRU TS4 climatology to NOAA/NCEI anomalies" \
            -a institution,global,m,c,"KNMI Climate Explorer using data from NOAA/NCEI and UEA/CRU" prcp_total.nc
	$HOME/NINO/copyfiles.sh prcp_anom.nc prcp_total.nc
fi

echo "not retrieving v2 temperatures"
exit # no use retrieving the old ones, they are no longer updated.




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
