#!/bin/sh
force=false
#
# HadSST3
#
version=3.1.1.0
base=http://www.metoffice.gov.uk/hadobs/hadsst3/data/HadSST.$version/diagnostics
for region in globe nh sh tropics
do
    file=HadSST.${version}_monthly_${region}_ts.txt
    cp $file $file.old
    echo "wget -q -N $base/$file"
    wget -q -N $base/$file
    diff $file $file.old
    if [ $? != 0 ]; then
        # only change filename for major updates
        f=HadSST3_monthly_${region}_ts.dat
	    cat > $f <<EOF
# HadSST $version $region averaged SST anomalies, median of ensemble
# source: <a href="http://www.metoffice.gov.uk/hadobs/hadsst3/data/download.html">Met Office</a>
# SSTa [K] HadSST.$version $region SST anomalies
# institution :: UK Met Office / Hadley Centre
# source_url :: $base/$file
# source :: https://www.metoffice.gov.uk/hadobs/hadsst3/
# references :: Kennedy J.J., Rayner, N.A., Smith, R.O., Saunby, M. and Parker, D.E. (2011b). Reassessing biases and other uncertainties in sea-surface temperature observations since 1850 part 1: measurement and sampling errors. J. Geophys. Res., 116, D14103, doi:10.1029/2010JD015218\\n Kennedy J.J., Rayner, N.A., Smith, R.O., Saunby, M. and Parker, D.E. (2011c). Reassessing biases and other uncertainties in sea-surface temperature observations since 1850 part 2: biases and homogenisation. J. Geophys. Res., 116, D14104, doi:10.1029/2010JD015220
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl?UKMOData/$f
EOF
        cat $file | tr '/' ' ' | cut -b 1-17 >> $f
        $HOME/NINO/copyfiles.sh $f
	fi
done
#
# CRUTEM4
#
base=http://www.metoffice.gov.uk/hadobs/crutem4/data/diagnostics/global/nh+sh/
area="n+s"
safearea=ns
name="NH+SH"
version=4.5.0.0
file=CRUTEM.${version}.global_${area}_monthly
cp $file $file.old
wget -q -N $base/$file
diff $file $file.old
if [ $? != 0 ]; then
	cat > crutem4_$safearea.dat <<EOF
# CRUTEM$version $name average
# <a href="https://www.metoffice.gov.uk/hadobs/crutem4/" target="_new">Climatic Research Unit / Met Office Hadley Centre</a>
# error estimates not yet used
# Ta [Celsius] CRUTEM.${version} global T2m land temperature
# institution :: University of East Angli / Climatic Research Unit and UK Met Office / Hadley Centre
# source_url :: $base/$file
# source :: https://www.metoffice.gov.uk/hadobs/crutem4/
# references :: Jones, P. D., D. H. Lister, T. J. Osborn, C. Harpham, M. Salmon, and C. P. Morice (2012), Hemispheric and large-scale land surface air temperature variations: An extensive revision and an update to 2010, J. Geophys. Res., 117, D05127, doi:10.1029/2011JD017139
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl?UKMOData/crutem4_$safearea.dat
EOF
	cut -b 1-15 $file | tr '/' ' ' >> crutem4_$safearea.dat
	$HOME/NINO/copyfilesall.sh crutem4_$safearea.dat
fi
#
# HadCRUT4 ensembles
#
base=http://www.metoffice.gov.uk/hadobs/hadcrut4/data/current/time_series/
# should be the same as CRUTEM
###version=4.3.0.0
root=HadCRUT.${version}.monthly
for area in ns_avg nh sh 30S_30N
do
	case $area in
		ns_avg) name="global (NNH+SH)/2 average";;
		nh) name="northern hemisphere";;
		sh) name="southern hemisphere";;
		30S_30N) name="tropics (30S-30N)";;
	esac
	cp ${root}_$area.txt ${root}_$area.txt.old
	wget -q -N $base/${root}_$area.txt
	diff ${root}_$area.txt ${root}_$area.txt.old
	if [ $? != 0 ]; then
		cat > hadcrut4_$area.dat <<EOF
# HadCRUT$version $name average
# <a href="http://www.metoffice.gov.uk/hadobs/hadcrut4/data/current/download.html" target="_new">Met Office Hadley Centre</a>
# error estimates not yet used
# Ta [Celsius] HadCRUT.$version T2m/SST $name temperature
# institution :: UK Met Office / Hadley Centre
# source_url :: $base/${root}_$area.txt
# source :: https://www.metoffice.gov.uk/hadobs/hadcrut4/
# references :: Morice, C. P., J. J. Kennedy, N. A. Rayner, and P. D. Jones (2012), Quantifying uncertainties in global and regional temperature change using an ensemble of observational estimates: The HadCRUT4 dataset, J. Geophys. Res., 117, D08101, doi:10.1029/2011JD017187.
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl?UKMOData/hadcrut4_$area.dat
EOF
		cut -b 1-17 ${root}_$area.txt | tr '/' ' ' >> hadcrut4_$area.dat
		$HOME/NINO/copyfilesall.sh hadcrut4_$area.dat
  	fi
	cp ${root}_${area}_realisations.zip ${root}_${area}realisations.zip.old
	wget -q -N $base/${root}_${area}_realisations.zip
	cmp ${root}_${area}_realisations.zip ${root}_${area}_realisations.zip.old
	if [ $? != 0 -o $force = true ]; then
		unzip -o ${root}_${area}_realisations.zip
		# get rid of weird names
		[ -f HadCRUT.${root}_${area}.1.txt ] && rename HadCRUT.HadCRUT HadCRUT HadCRUT.HadCRUT*
		i=0
		while [ $i -lt 100 ]; do
			i=$((i+1))
			if [ $i -le 10 ]; then
				ens=0$((i-1))
			else
				ens=$((i-1))
			fi
			cat > hadcrut4_${area}_$ens.dat <<EOF
# HadCRUT$version $name average ensemble $i
# <a href="http://www.metoffice.gov.uk/hadobs/hadcrut4/data/current/download.html" target="_new">Met Office Hadley Centre</a>
# error estimates not covered by ensemble not yet used
# Ta [Celsius] HadCRUT.$version T2m/SST $name temperature
# institution :: UK Met Office / Hadley Centre
# source_url :: $base/${root}_${area}_realisations.zip
# source :: https://www.metoffice.gov.uk/hadobs/hadcrut4/
# references :: Morice, C. P., J. J. Kennedy, N. A. Rayner, and P. D. Jones (2012), Quantifying uncertainties in global and regional temperature change using an ensemble of observational estimates: The HadCRUT4 dataset, J. Geophys. Res., 117, D08101, doi:10.1029/2011JD017187.
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl?UKMOData/hadcrut4_${area}_%%.dat
EOF
			cut -b 1-17 ${root}_${area}.$i.txt | tr '/' ' ' >> hadcrut4_${area}_$ens.dat
			rm ${root}_${area}.$i.txt
		done
		$HOME/NINO/copyfiles.sh hadcrut4_${area}_$ens.dat
	fi
done
#
# globally, hemispherically averaged temperatures
#
for area in ns_avg nh sh 30S_30N
do
	case $area in
		ns_avg) name="global (NNH+SH)/2 average";;
		nh) name="northern hemisphere";;
		sh) name="southern hemisphere";;
		30S_30N) name="tropics (30S-30N)";;
	esac
	cp ${root}_$area.txt ${root}_$area.txt.old
	wget -q -N $base/${root}_$area.txt
	diff ${root}_$area.txt ${root}_$area.txt.old
	if [ $? != 0 ]; then
		cat > hadcrut4_$area.dat <<EOF
# HadCRUT4 $name average
# <a href="http://www.metoffice.gov.uk/hadobs/hadcrut4/data/download.html" target="_new">Met Office Hadley Centre</a>
# error estimates not yet used
# Ta [Celsius] HadCRUT.$version T2m/SST $name temperature
# institution :: UK Met Office / Hadley Centre
# source_url :: $base/${root}_$area.txt
# source :: https://www.metoffice.gov.uk/hadobs/hadcrut4/
# references :: Morice, C. P., J. J. Kennedy, N. A. Rayner, and P. D. Jones (2012), Quantifying uncertainties in global and regional temperature change using an ensemble of observational estimates: The HadCRUT4 dataset, J. Geophys. Res., 117, D08101, doi:10.1029/2011JD017187.
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl?UKMOData/hadcrut4_$area.dat
EOF
      cut -b 1-17 ${root}_$area.txt | tr '/' ' ' >> hadcrut4_$area.dat
      $HOME/NINO/copyfilesall.sh hadcrut4_$area.dat
  fi
done
#
# CETs
#
cp cetml1659on.dat cetml1659on.dat.old
wget -q -N http://www.metoffice.gov.uk/hadobs/hadcet/cetml1659on.dat
./cet2dat cetml1659on.dat > cet.dat
$HOME/NINO/copyfiles.sh cet.dat

cp cetminmly1878on_urbadj4.dat cetminmly1878on_urbadj4.dat.old
wget -q -N http://www.metoffice.gov.uk/hadobs/hadcet/cetminmly1878on_urbadj4.dat
./cet2dat cetminmly1878on_urbadj4.dat > cet_min.dat
$HOME/NINO/copyfiles.sh cet_min.dat

cp cetmaxmly1878on_urbadj4.dat cetmaxmly1878on_urbadj4.dat.old
wget -q -N http://www.metoffice.gov.uk/hadobs/hadcet/cetmaxmly1878on_urbadj4.dat
./cet2dat cetmaxmly1878on_urbadj4.dat > cet_max.dat
$HOME/NINO/copyfiles.sh cet_max.dat

cp cetdl1772on.dat cetdl1772on.dat.old
wget -q -N http://www.metoffice.gov.uk/hadobs/hadcet/cetdl1772on.dat
./dailycet2dat cetdl1772on.dat > daily_cet.dat
$HOME/NINO/copyfiles.sh daily_cet.dat

cp cetmindly1878on_urbadj4.dat cetmindly1878on_urbadj4.dat.old
wget -q -N http://www.metoffice.gov.uk/hadobs/hadcet/cetmindly1878on_urbadj4.dat
./dailycet2dat cetmindly1878on_urbadj4.dat > daily_cet_min.dat
$HOME/NINO/copyfiles.sh daily_cet_min.dat

cp cetmaxdly1878on_urbadj4.dat cetmaxdly1878on_urbadj4.dat.old
wget -q -N http://www.metoffice.gov.uk/hadobs/hadcet/cetmaxdly1878on_urbadj4.dat
./dailycet2dat cetmaxdly1878on_urbadj4.dat > daily_cet_max.dat
$HOME/NINO/copyfiles.sh daily_cet_max.dat

# precipitation
base=http://www.metoffice.gov.uk/hadobs/hadukp/data
for region in EWP SEEP SWEP CEP NWEP NEEP SP SSP NSP ESP NIP
do
  # daily data
  file=Had${region}_daily_qc.txt
  cp $file $file.old
  wget -q -N $base/daily/$file
  outfile=`basename $file .txt`.dat
  ./dailyprcp2dat $file > $outfile
  $HOME/NINO/copyfiles.sh $outfile

  # monthly data
  file=Had${region}_monthly_qc.txt
  cp $file $file.old
  wget -q -N $base/monthly/$file
  outfile=`basename $file .txt`.dat
  cat > $outfile <<EOF
# From <a href="http://www.metoffice.gov.uk/hadobs/hadukp" target="_new">Hadley Centre</a>
# prcp [mm/month] UKP $region precipitation
# institution :: UK Met Office / Hadley Centre
# source_url :: $base/monthly/$file
# source :: https://www.metoffice.gov.uk/hadobs/hadukp/
# references :: Morice, C. P., J. J. Kennedy, N. A. Rayner, and P. D. Jones (2012), Quantifying uncertainties in global and regional temperature change using an ensemble of observational estimates: The HadCRUT4 dataset, J. Geophys. Res., 117, D08101, doi:10.1029/2011JD017187
# history :: retrieved `date`
# climexp_url :: https://climexp.knmi.nl?UKMOData/$outfile
EOF
  sed -e 's/-99.9/-999.9/g' -e 's/  0.0/-999.9/g' -e 's/^\([^ ]\)/# \1/' $file >> $outfile
  $HOME/NINO/copyfiles.sh $outfile

done
