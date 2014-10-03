#!/bin/sh
force=false
#
# HadSST3
#
version=3.1.0.0
base=http://www.metoffice.gov.uk/hadobs/hadsst3/data/HadSST.$version/
for region in globe nh sh tropics
do
    file=HadSST3_monthly_${region}_ts.txt
    cp $file $file.old
    echo "wget -q -N $base/$file"
    wget -q -N $base/$file
    diff $file $file.old
    if [ $? != 0 ]; then
        f=${file%.txt}.dat
	    cat > $f <<EOF
# HadSST $version $region averaged SST anomalies, median of ensemble
# source: <a href="http://www.metoffice.gov.uk/hadobs/hadsst3/data/download.html">Met Office</a>
# SSTa [K] $region SST anomalies
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
version=4.2.0.0
file=CRUTEM.${version}.global_${area}_monthly
cp $file $file.old
wget -q -N $base/$file
diff $file $file.old
if [ $? != 0 ]; then
	cat > crutem4_$safearea.dat <<EOF
# CRUTEM$version $name average
# <a href="http://www.metoffice.gov.uk/hadobs/crutem4/data/diagnostics/global/nh+sh/index.html" target="_new">Climatic Research Unit / Met Office Hadley Centre</a>
# error estimates not yet used
# Ta [Celsius] T2m land temperature averaged over $area
EOF
	cut -b 1-15 $file | tr '/' ' ' >> crutem4_$safearea.dat
	$HOME/NINO/copyfilesall.sh crutem4_$safearea.dat
fi
#
# HadCRUT4 ensembles
#
base=http://www.metoffice.gov.uk/hadobs/hadcrut4/data/current/time_series/
# should be the same as CRUTEM
###version=4.2.0.0
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
# Ta [Celsius] T2m/SST temperature averaged over $area
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
# Ta [Celsius] T2m/SST temperature averaged over $area
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
# Ta [Celsius] T2m/SST temperature averaged over $area
EOF
      cut -b 1-17 ${root}_$area.txt | tr '/' ' ' >> hadcrut4_$area.dat
      $HOME/NINO/copyfilesall.sh hadcrut4_$area.dat
  fi
done
#
# globally, hemispherically averaged temperatures
#
base=http://www.metoffice.com/hadobs/hadcrut3/diagnostics/
for area in gl sa nh sh tr ne se tm
do
  case $area in
  gl) url=$base/global/nh+sh/monthly
      name="global average";;
  sa) url=$base/global/simple_average/monthly
      name="simple average";;
  nh) url=$base/hemispheric/northern/monthly
      name="northern hemisphere";;
  sh) url=$base/hemispheric/southern/monthly
      name="southern hemisphere";;
  tr) url=$base/regional/30-30/monthly
      name="tropics";;
  ne) url=$base/regional/north_30n/monthly
      name="northern extratropics";;
  se) url=$base/regional/south_30s/monthly
      name="southern extratropics";;
  tm) url=$base/regional/60-60/monthly
      name="tropics and midlatitudes";;
  esac
  cp hadcrut3_$area.txt hadcrut3_$area.txt.old
  wget -q -O hadcrut3_$area.txt $url
  diff hadcrut3_$area.txt hadcrut3_$area.txt.old
  if [ $? != 0 ]; then
      cat > hadcrut3_$area.dat <<EOF
# HadCRUT3 diagnostic $name average
# <a href="http://www.metoffice.gov.uk/hadobs/hadcrut3/diagnostics" target="_new">Hadley Centre</a>
# error estimates not yet used
# Ta [Celsius]
EOF
      cut -b 1-14 hadcrut3_$area.txt | tr '/' ' ' >> hadcrut3_$area.dat
      $HOME/NINO/copyfilesall.sh hadcrut3_$area.dat
  fi
done
#
# old files
#
if [ 0 = 1 ]; then
cp land+sst_web.txt land+sst_web.txt.old
wget -q -N http://www.met-office.gov.uk/research/hadleycentre/CR_data/Annual/land+sst_web.txt
diff land+sst_web.txt land+sst_web.txt.old
if [ $? != 0 ];then
  mv Taveglobal2vOA.dat Taveglobal2vOA.dat.old
  cat > Taveglobal2vOA.dat <<EOF
# Globally average temperature, optimal averaging
# from the <a href="http://www.met-office.gov.uk/research/hadleycentre/obsdata/globaltemperature.html">Hadley Centre</a>
# Tglobal [Celsius]
#
#
EOF
  sed -e '1,/DATA/d' -e '/KEY/,$d' land+sst_web.txt | awk '{print $1 " " $2}' >> Taveglobal2vOA.dat
  $HOME/NINO/copyfiles.sh Taveglobal2vOA.dat
else
  echo "No change"
  mv land+sst_web.txt.old land+sst_web.txt
fi
fi # false
#
if [ 0 = 1 ]; then
cp HadCRUG.txt HadCRUG.txt.old
wget -N http://www.met-office.gov.uk/research/hadleycentre/CR_data/Monthly/HadCRUG.txt
./txt2dat
for file in *_yr.dat
do
  $HOME/NINO/copyfiles.sh $file `basename $file _yr.dat`.dat
done
fi
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
  echo '# from <a href="http://www.metoffice.gov.uk/hadobs/hadukp" target="_new">Hadley Centre</a>' > $outfile
  sed -e 's/-99.9/-999.9/g' -e 's/  0.0/-999.9/g' -e 's/^\([^ ]\)/# \1/' $file >> $outfile
  $HOME/NINO/copyfiles.sh $outfile

done
