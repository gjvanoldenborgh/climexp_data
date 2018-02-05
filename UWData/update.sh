#!/bin/sh
set -x
echo "Please download the file PIOMAS.vol.daily.1979.*.dat by hand from http://psc.apl.washington.edu/wordpress/research/projects/arctic-sea-ice-volume-anomaly/data/"
zfile=`ls -t PIOMAS.vol.daily.1979.*.dat.gz | head -1`
[ -s "$zfile" ] && gunzip -f $zfile
file=`ls -t PIOMAS.vol.daily.1979.*.dat | head -1`
if [ $file -nt piomas_dy.dat ]; then
	make piomas2dat
	./piomas2dat $file > piomas_dy.dat
	daily2longer piomas_dy.dat 12 mean > piomas_mo.dat
fi
$HOME/NINO/copyfilesall.sh piomas_??.dat

cp PDO.latest PDO.latest.old
wget -N http://research.jisao.washington.edu/pdo/PDO.latest
diff PDO.latest PDO.latest.old
if [ $? != 0 ]; then
    # metadata structured from the file dd 4-feb-2018
    cat > pdo.dat <<EOF
# PDO [1] Pacific Decadal Oscillation index
# from <a href="http://research.jisao.washington.edu/pdo/">JISAO</a>
# insitution :: University of Washington, JISAO
# author :: Nate Mantua
# contact :: nate.mantua@noaa.gov
# link :: http://research.jisao.washington.edu/pdo/
# source :: http://research.jisao.washington.edu/pdo/PDO.latest
# reference :: Zhang, Y., J.M. Wallace, D.S. Battisti, 1997: ENSO-like interdecadal variability: 1900-93. J. Climate, 10, 1004-1020. 
# reference :: Mantua, N.J. and S.R. Hare, Y. Zhang, J.M. Wallace, and R.C. Francis, 1997: A Pacific interdecadal climate oscillation with impacts on salmon production. BAMS, 78, 1069-1079.
# data_source :: UKMO Historical SST data set for 1900-81, Reynold's Optimally Interpolated SST (V1) for January 1982-Dec 2001, OI SST Version 2 (V2) beginning January 2002
# history :: retrieved at `date`
EOF
    egrep '^[12]' PDO.latest | tr -d '*' | sed -e 's/-9999/-999.9/' >> pdo.dat
    $HOME/NINO/copyfilesall.sh pdo.dat
fi

FORM_field=hadsst3
. $HOME/climexp/queryfield.cgi
series=`ls -t ~/NINO/UKMOData/hadcrut4*_ns_avg.dat | head -1`
echo y | subfieldseries ~/NINO/$file $series ./hadsst3-tglobal.ctl
rm eof1.???
eof ./hadsst3-tglobal.ctl 1 normalize varspace mon 1 ave 12 lon1 100 lon2 260 lat1 20 lat2 65 begin 1900 eof1.ctl
patternfield hadsst3-tglobal.ctl eof1.ctl eof1 1 > aap.dat
scaleseries 3 aap.dat > pdo_hadsst3.dat
$HOME/NINO/copyfilesall.sh pdo_hadsst3.dat

FORM_field=ersstv5a
. $HOME/climexp/queryfield.cgi
extend_series ~/NINO/NCDCData/ncdc_gl.dat > ncdc_gl1.dat
echo y | subfieldseries ~/NINO/$file ncdc_gl1.dat ./ersst-tglobal.ctl
rm eof1.???
eof ./ersst-tglobal.ctl 1 normalize varspace anom mon 1 ave 12 lon1 100 lon2 260 lat1 20 lat2 65 eof1.ctl
patternfield ersst-tglobal.ctl eof1.ctl eof1 1 > aap.dat
plotdat anom aap.dat > noot.dat
scaleseries -3.5 noot.dat > pdo_ersst.dat
$HOME/NINO/copyfilesall.sh pdo_ersst.dat
