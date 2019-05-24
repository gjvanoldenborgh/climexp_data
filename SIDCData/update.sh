#!/bin/sh
cp monthssn.dat monthssn.dat.old
###wget -N http://sidc.oma.be/silso/DATA/monthssn.dat
file=SN_m_tot_V2.0.txt
wget -N http://sidc.oma.be/silso/DATA/$file
c=`file $file | fgrep -c gzip`
if [ $c = 1 ]; then
    mv $file $file.gz
    gunzip $file.gz
fi
mv sunspots.dat sunspots.dat.old
make convert
./convert
$HOME/NINO/copyfilesall.sh sunspots.dat
###make sunspots2double
###./sunspots2double > sunspots2.dat
###$HOME/NINO/copyfilesall.sh sunspots2.dat

file=SN_d_tot_V2.0.txt
wget -N http://sidc.oma.be/silso/DATA/$file
c=`file $file | fgrep -c gzip`
if [ $c = 1 ]; then
    mv $file $file.gz
    gunzip $file.gz
fi
echo "updating sunspots_daily.dat"
cat <<EOF > sunspots_daily.dat
# sunspot [1] daily sunspot numbers
# from <a href="http://sidc.oma.be/">SIDC</a>
# institution :: WDC-SILSO, Royal Observatory of Belgium, Brussels
# source :: http://sidc.oma.be/silso/home
# source_url :: http://sidc.oma.be/silso/DATA/SN_m_tot_V2.0.txt
# contact :: silso.info@oma.be
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl/getindices.cgi?SIDCData/sunspots_daily
EOF
fgrep -v ' -1 ' SN_d_tot_V2.0.txt | cut -b 1-10,20-24 >> sunspots_daily.dat
$HOME/NINO/copyfiles.sh sunspots_daily.dat
