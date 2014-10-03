#!/bin/sh
base=http://www.metoffice.gov.uk/hadobs/hadukp/data
for region in EWP SEEP SWEP CEP NWEP NEEP SP SSP NSP ESP NIP
do

  # daily data
  file=Had${region}_daily_qc.txt
  wget $base/daily/$file
  outfile=`basename $file .txt`.dat
  ./dailyprcp2dat $file > $outfile
  $HOME/NINO/copyfiles.sh $outfile

  # monthly data
  file=Had${region}_monthly_qc.txt
  wget $base/monthly/$file
  outfile=`basename $file .txt`.dat
  echo '# from <a href="http://www.metoffice.gov.uk/hadobs/hadukp" target="_new">Hadley Centre</a>' > $outfile
  sed -e 's/-99.9/-999.9/g' -e 's/^\([^ ]\)/# \1/' $file >> $outfile
  $HOME/NINO/copyfiles.sh $outfile

done
