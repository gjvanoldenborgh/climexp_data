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
echo "# T2m_land_anom [K] land-surface average temperature anomalies relative to 1951-1980" >> t2m_land_best.dat
fgrep -v '%' Complete_TAVG_complete.txt | fgrep -v ' 2010 ' \
    | cut -b 1-22 \
    | fgrep -v NaN >> t2m_land_best.dat
$HOME/NINO/copyfilesall.sh t2m_land_best.dat

wget -N http://berkeleyearth.lbl.gov/auto/Global/Land_and_Ocean_complete.txt
cat << EOF > t2m_land_ocean_best.dat
# Land temperature from <a href="http://www.berkeleyearth.org">Berkeley Dataset</a>, 
# ocean temperature reinterpolated from HadSST, temperature over sea ice extrapolated from land.
# T2m_anom [K] global mean temperature anomalies relative to 1951-1980
EOF
sed '/Sea Ice Temperature Inferred from Water Temperatures/,$d' Land_and_Ocean_complete.txt \
    | fgrep -v '%' \
    | cut -b 1-22 >> t2m_land_ocean_best.dat
$HOME/NINO/copyfilesall.sh t2m_land_ocean_best.dat

base=http://berkeleyearth.lbl.gov/auto/Global/Gridded/
for var in TAVG TMIN TMAX
do
	decade=1880
	new=false
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
	    decade=$((decade + 10))
	done
	if [ $new = true ]; then
    	cdo -r -f nc4 -z zip copy ${var}_Daily_LatLong1_[12]???.nc ${var}_Daily_LatLong1.nc
	    $HOME/NINO/copyfiles.sh ${var}_Daily_LatLong1.nc
	fi

    file=Complete_${var}_LatLong1.nc
	wget -N $base/$file
	case $var in
		TAVG) start="1750-01-01";;
		TMAX) start="1850-01-01";;
		TMIN) start="1850-01-01";;
		*) echo "$0: error: unknow var $var"; exit -1;;
	esac
	ncfile=${var}_LatLong1.nc
	if [ ! -s $newfile -o $newfile -ot $file ]; then
	    cdo -r -f nc4 -z zip settaxis,${start},0:0:0,1mon Complete_${var}_LatLong1.nc aap.nc
	    cdo -r -f nc4 -z zip selvar,temperature aap.nc $ncfile
	    rm aap.nc
    	$HOME/NINO/copyfiles.sh ${var}_LatLong1.nc
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


