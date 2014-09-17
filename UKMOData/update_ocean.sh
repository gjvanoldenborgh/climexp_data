#!/bin/sh
set -x
# download the EN3 objective ocean analysis

base=http://www.metoffice.gov.uk/hadobs/en3/data/EN3_v2a
version=EN3_v2a

yr=1949
yrnow=`date -d "1 year ago" "+%Y"`
while [ $yr -lt $yrnow ]; do
    echo $((++yr))
    file=${version}_ObjectiveAnalyses_$yr.tar
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
    if [ $yr = $yrnow -o $yr = $((yrnow - 1)) -o \( ! -s EN3_v2a_ObjectiveAnalysis_${yr}01.nc.gz -a ! -s EN3_v2a_ObjectiveAnalysis_${yr}01.nc \) ]; then
		tar xf ${version}_ObjectiveAnalyses_$yr.tar
	fi
done

echo "Unzipping netcdf files"
for file in ${version}_ObjectiveAnalysis_??????.nc.gz
do
	f=${file%.gz}
	if [ ! -s $f -o $f -ot $file ]; then
		gunzip -f $file
	fi
done

echo "Extracting temperature and salinity"
doit_salt=false
doit_temp=false
for file in ${version}_ObjectiveAnalysis_??????.nc
do
    string=${file##*_}
    yr=${string%??.nc}
    mo=${string%.nc}
    mo=${mo#????}
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
	cdo -f nc4 -z zip copy temp_${version}_ObjectiveAnalysis_[12]?????.nc temp_${version}_ObjectiveAnalysis.nc
    $HOME/NINO/copyfiles.sh temp_${version}_ObjectiveAnalysis.nc
fi
if [ $doit_salt = true -o ! -s salt_${version}_ObjectiveAnalysis.nc ]; then
	cdo -f nc4 -z zip copy salt_${version}_ObjectiveAnalysis_[12]?????.nc salt_${version}_ObjectiveAnalysis.nc
	$HOME/NINO/copyfiles.sh salt_${version}_ObjectiveAnalysis.nc
fi

# SSS
infile=salt_EN3_v2a_ObjectiveAnalysis.nc
outfile=salt_EN3_v2a_ObjectiveAnalysis_5m.nc
if [ ! -s $outfile -o $outfile -ot $infile ]; then
	cdo sellevel,5.02159 $infile $outfile 
	$HOME/NINO/copyfiles.sh $outfile
fi

# integrated salinity
for depth in 400 700 1000 2000
do
	outfile=salt_EN3_v2a_ObjectiveAnalysis_sal${depth}.nc
	if [ ! -s $outfile -o $outfile -ot $infile ]; then
		ferret -memsize 500 <<EOF
use "${infile}"
let sal${depth} = salinity[z=0:${depth}@DIN]
save/file=${outfile}/clobber sal${depth}
quit
EOF
		ncatted -a units,SAL${depth},c,c,"psu m" $outfile
		$HOME/NINO/copyfiles.sh $outfile
	fi
done

# heat content
infile=temp_EN3_v2a_ObjectiveAnalysis.nc
for depth in 400 700 1000 2000
do
	outfile=temp_EN3_v2a_ObjectiveAnalysis_ohc${depth}.nc
	if [ ! -s $outfile -o $outfile -ot $infile ]; then
		ferret -memsize 500 <<EOF
use "${infile}"
let ohc${depth} = 1028*4186*temperature[z=0:${depth}@DIN]
save/file=${outfile}/clobber ohc${depth}
quit
EOF
		ncatted -a units,OHC${depth},c,c,"J/m2" $outfile
		$HOME/NINO/copyfiles.sh $outfile
	fi
done
