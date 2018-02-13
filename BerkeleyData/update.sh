#!/bin/sh
yr=`date +%Y`
mo=`date +%m`
if [ -f downloaded_$yr$mo -a "$force" != true ]; then
  echo "Already downloaded Berkely data this month"
  exit
fi

wget -N http://berkeleyearth.lbl.gov/auto/Global/Complete_TAVG_complete.txt
fgrep "Berkeley Dataset" Complete_TAVG_complete.txt | tr '%' "#" | \
	sed -e 's@Berkeley Dataset@<a href="http://www.berkeleyearth.org">Berkeley Dataset</a>@' > t2m_land_best.dat
echo 
cat >> t2m_land_best.dat <<EOF
# institution :: Berkeley Earth Surface Temperature Project
# source_url :: https://berkeleyearth.org/data/
# history :: retrieved `date`
# T2m_land_anom [K] land-surface average temperature anomalies relative to 1951-1980"
EOF
fgrep -v '%' Complete_TAVG_complete.txt | fgrep -v ' 2010 ' \
    | cut -b 1-22 \
    | fgrep -v NaN >> t2m_land_best.dat
$HOME/NINO/copyfilesall.sh t2m_land_best.dat

wget -N http://berkeleyearth.lbl.gov/auto/Global/Land_and_Ocean_complete.txt
cat << EOF > t2m_land_ocean_best.dat
# Land temperature from <a href="http://www.berkeleyearth.org">Berkeley Dataset</a>, 
# ocean temperature reinterpolated from HadSST, temperature over sea ice extrapolated from land.
# institution :: Berkeley Earth Surface Temperature Project
# source_url :: https://berkeleyearth.org/data/
# history :: retrieved `date`
# T2m_anom [K] global mean temperature anomalies relative to 1951-1980
EOF
echo "# comment :: "`sed -e '/The reported data is broken into two sections/,$d' Land_and_Ocean_complete.txt \
    | fgrep '%' | sed -e 's/^% //' | tr -d '\n'`  >> t2m_land_ocean_best.dat
sed -e '/Sea Ice Temperature Inferred from Water Temperatures/,$d' Land_and_Ocean_complete.txt \
    | fgrep -v '%' \
    | cut -b 1-22 >> t2m_land_ocean_best.dat
$HOME/NINO/copyfilesall.sh t2m_land_ocean_best.dat

base=http://berkeleyearth.lbl.gov/auto/Global/Gridded/
for var in TAVG TMIN TMAX
do
	decade=1880
	new=false
    fullnew=false
	while [ $decade -le 2010 ]; do
	    file=Complete_${var}_Daily_LatLong1_${decade}.nc
	    wget -N $base/$file
	    newfile=${var}_Daily_LatLong1_${decade}.nc
	    if [ ! -s $newfile -o $newfile -ot $file ]; then
	        new=true
    	    cdo -r -f nc4 -z zip settaxis,${decade}-01-01,0:0:0,1day Complete_${var}_Daily_LatLong1_${decade}.nc aap.nc
	        cdo -r -f nc4 -z zip selvar,temperature aap.nc $newfile
	        rm aap.nc
	    fi
        climfile=${var}_Daily_LatLong1_clim.nc
        if [ ! -s ${var}_Daily_LatLong1_clim.nc ]; then
            cdo selvar,climatology $file aap.nc
            ncrename -v lev,time -d lev,time aap.nc
            cdo -r settaxis,1951-01-01,00:00,1day aap.nc $climfile
	        rm aap.nc
        fi
        fullfile=${var}_Daily_LatLong1_${decade}_full.nc
        if [ ! -d $fullfile -o $fullfile -ot $newfile ]; then
            fullnew=true
            echo "cdo -r -f nc4 -z zip add $newfile $climfile $fullfile"
            cdo -r -f nc4 -z zip add $newfile $climfile $fullfile
            ncatted -a long_name,temperature,m,c,"Air Surface Temperature" $fullfile
        fi
	    decade=$((decade + 10))
	done
	if [ ! -s ${var}_Daily_LatLong1.nc -o $new = true ]; then
    	file=${var}_Daily_LatLong1.nc
    	echo "cdo -r -f nc4 -z zip copy ${var}_Daily_LatLong1_[12]???.nc $file"
    	cdo -r -f nc4 -z zip copy ${var}_Daily_LatLong1_[12]???.nc $file
    	ncrename -v temperature,$var $file
    	ncatted -h -a source_url,global,a,c,"http://berkeleyearth.org/data/" $file
    	. $HOME/climexp/add_climexp_url_field.cgi
	    $HOME/NINO/copyfiles.sh $file
	fi
	if [ ! -s ${var}_Daily_LatLong1_full.nc -o $fullnew = true ]; then
    	file=${var}_Daily_LatLong1_full.nc
    	echo "cdo -r -f nc4 -z zip copy ${var}_Daily_LatLong1_[12]???_full.nc $file"
    	cdo -r -f nc4 -z zip copy ${var}_Daily_LatLong1_[12]???_full.nc $file
    	ncrename -v temperature,$var $file
    	ncatted -h -a source_url,global,a,c,"http://berkeleyearth.org/data/" $file
    	. $HOME/climexp/add_climexp_url_field.cgi
	    $HOME/NINO/copyfiles.sh $file
	fi

    file=Complete_${var}_LatLong1.nc
	wget -N $base/$file
	ncfile=${var}_LatLong1.nc
	if [ ! -s $ncfile -o $ncfile -ot $file ]; then
	    ncatted -a units,time,m,c,"years since 0000-01-01 00:00" $file aap.nc
	    cdo -r -f nc4 -z zip selvar,temperature aap.nc $ncfile
	    rm aap.nc
	    file=${var}_LatLong1.nc
    	ncatted -h -a source_url,global,a,c,"http://berkeleyearth.org/data/" $file
    	. $HOME/climexp/add_climexp_url_field.cgi
    	$HOME/NINO/copyfiles.sh $file
	fi
	
done

for var in txx tnn
do
    case $var in
        txx) basevar=TMAX;oper=max;;
        tnn) basevar=TMIN;oper=min;;
        *) echo "$0: unknown var $var"; exit -1;;
    esac
    echo "Computing $var"
    daily2longerfield Complete_${basevar}_LatLong1.nc 1 $oper minfac 75 berkeley_$var.nc
    $HOME/NINO/copyfiles.sh berkeley_$var.nc
done

date > downloaded_$yr$mo

exit

# these are the unadjusted station series
for var in TAVG TMIN TMAX
do
	cd $var
	wget -N http://download.berkeleyearth.org/downloads/$var/LATEST%20-%20Quality%20Controlled.zip
	if [ ! -s data.txt -o data.txt -ot "LATEST - Quality Controlled.zip" ]; then
		unzip "LATEST - Quality Controlled.zip"
	fi
	cd ..
done


