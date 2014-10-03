#!/bin/sh
cp monthssn.dat monthssn.dat.old
wget -N http://sidc.oma.be/silso/DATA/monthssn.dat
mv sunspots.dat sunspots.dat.old
make convert
./convert
$HOME/NINO/copyfilesall.sh sunspots.dat
make sunspots2double
./sunspots2double > sunspots2.dat
$HOME/NINO/copyfilesall.sh sunspots2.dat

doit=false
yrnow=`date "+%Y"`
monow=`date "+%m"`
yr=1818
while [ $yr -le $yrnow ]
do
	cp dssn$yr.dat dssn$yr.dat.old
	wget -q -N http://sidc.oma.be/DATA/DAILYSSN/dssn${yr}.dat
	cmp dssn$yr.dat dssn$yr.dat.old
	if [ $? != 0 ]; then
		doit=true
	fi
	yr=$((yr+1))
done

if [ $doit = true ]; then
	echo "updating sunspots_daily.dat"
	cat <<EOF > sunspots_daily.dat
# sunspot [1] daily sunspot numbers
# from <a href="http://sidc.oma.be/">SIDC</a>
EOF
	yr=1818
	while [ $yr -le $yrnow ]
	do
		fgrep -v ' ?' dssn$yr.dat | cut -b 1-9,19-23 >> sunspots_daily.dat
		yr=$((yr+1))
	done
	$HOME/NINO/copyfiles.sh sunspots_daily.dat
fi