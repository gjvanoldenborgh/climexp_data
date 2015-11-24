#!/bin/sh
cp monthssn.dat monthssn.dat.old
###wget -N http://sidc.oma.be/silso/DATA/monthssn.dat
wget -N http://sidc.oma.be/silso/DATA/SN_m_tot_V2.0.txt
mv sunspots.dat sunspots.dat.old
make convert
./convert
$HOME/NINO/copyfilesall.sh sunspots.dat
make sunspots2double
./sunspots2double > sunspots2.dat
$HOME/NINO/copyfilesall.sh sunspots2.dat

wget -N http://sidc.oma.be/silso/DATA/SN_d_tot_V2.0.txt
echo "updating sunspots_daily.dat"
cat <<EOF > sunspots_daily.dat
# sunspot [1] daily sunspot numbers
# from <a href="http://sidc.oma.be/">SIDC</a>
EOF
fgrep -v ' -1 ' SN_d_tot_V2.0.txt | cut -b 1-10,20-24 >> sunspots_daily.dat
$HOME/NINO/copyfiles.sh sunspots_daily.dat
