#!/bin/sh
set -x
# download the EN4 objective ocean analysis

base=http://www.metoffice.gov.uk/hadobs/en4/data/en4-2-0/
version=EN.4.2.0
mem=500

yr=1899
yrnow=`date "+%Y"`
while [ $yr -lt $yrnow ]; do
    echo $((++yr))
    file=${version}.analyses.g10.$yr.zip
    # the server is really slow, assume we have a complete set except for the last two years...
	if [ $yr = $yrnow -o $yr = $((yrnow - 1)) -o ! -s $file ]; then
	    wget -N $base/$file
    	if [ ! -s $file ]; then # as I said, the server is slow; try again
			wget -N $base/$file
			if [ ! -s $file ]; then
				echo "Something went wrong retrieving $base/$file"
				exit -1
			fi
		fi
    fi
    if [ $yr = $yrnow -o $yr = $((yrnow - 1)) -o ! -s $version.f.analysis.g10.${yr}01.nc ]; then
		unzip -u -o $file
	fi
done

echo "Extracting temperature and salinity"
doit_salt=false
doit_temp=false
for file in $version.f.analysis.g10.??????.nc
do
    string=${file##*analysis.g10.}
    yr=${string%??.nc}
    mo=${string%.nc}
    mo=${mo#????}
    echo $yr $mo
    if [ ! -s temp_$file -o $file -nt temp_$file ]; then
		ncks -O -v temperature $file aap.nc
		cdo -f nc4 -z zip -r settaxis,${yr}-${mo}-01,0:00,1mon aap.nc temp_$file
		doit_temp=true
    fi
    if [ ! -s salt_$file -o $file -nt salt_$file ]; then
		ncks -O -v salinity $file aap.nc
		cdo -f nc4 -z zip -r settaxis,${yr}-${mo}-01,0:00,1mon aap.nc salt_$file
		doit_salt=true
    fi
done

echo "Concatenating"
if [ $doit_temp = true -o ! -s temp_${version}_ObjectiveAnalysis.nc ]; then
	cdo -f nc4 -z zip copy temp_${version}.f.analysis.g10.[12]?????.nc temp_${version}_ObjectiveAnalysis.nc
    $HOME/NINO/copyfiles.sh temp_${version}_ObjectiveAnalysis.nc
fi
if [ $doit_salt = true -o ! -s salt_${version}_ObjectiveAnalysis.nc ]; then
	cdo -f nc4 -z zip copy salt_${version}.f.analysis.g10.[12]?????.nc salt_${version}_ObjectiveAnalysis.nc
	$HOME/NINO/copyfiles.sh salt_${version}_ObjectiveAnalysis.nc
fi

# SSS
infile=salt_${version}_ObjectiveAnalysis.nc
outfile=salt_${version}_ObjectiveAnalysis_5m.nc
if [ ! -s $outfile -o $outfile -ot $infile ]; then
	cdo sellevel,5.02159 $infile $outfile 
	$HOME/NINO/copyfiles.sh $outfile
fi

nt=`describefield salt_${version}_ObjectiveAnalysis.nc 2>&1 | fgrep months | awk '{print $8}' | tr -d '()'`

# integrated salinity
for depth in 400 700 1000 2000
do
	outfile=salt_${version}_ObjectiveAnalysis_sal${depth}.nc
	if [ ! -s $outfile -o $outfile -ot $infile ]; then
		ferret -memsize $mem <<EOF
use "${infile}"
let sal${depth} = salinity[z=0:${depth}@DIN,l=1:700]
save/file=${outfile}/clobber sal${depth}
let sal${depth} = salinity[z=0:${depth}@DIN,l=701:$nt]
save/file=${outfile}/append sal${depth}
quit
EOF
		ncatted -a units,SAL${depth},c,c,"psu m" $outfile
		$HOME/NINO/copyfiles.sh $outfile
	fi
done

# heat content
infile=temp_${version}_ObjectiveAnalysis.nc
for depth in 400 700 1000 2000
do
	outfile=temp_${version}_ObjectiveAnalysis_ohc${depth}.nc
	if [ ! -s $outfile -o $outfile -ot $infile ]; then
		ferret -memsize $mem <<EOF
use "${infile}"
let ohc${depth} = 1028*4186*temperature[z=0:${depth}@DIN,l=1:700]
save/file=${outfile}/clobber ohc${depth}
let ohc${depth} = 1028*4186*temperature[z=0:${depth}@DIN,l=701:$nt]
save/file=${outfile}/append ohc${depth}
quit
EOF
		ncatted -a units,OHC${depth},c,c,"J/m2" $outfile
		$HOME/NINO/copyfiles.sh $outfile
	fi
done
