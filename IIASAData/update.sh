#!/bin/bash
base=ftp://ftp-ipcc.fz-juelich.de/pub/emissions/gridded_netcdf
###wget -r -N $base/IPCC_species

# now it's time to a) add a lot of contributions and b) interpolate in time
# they are given on a 0.5\dg grid (720x360)
#
#
for rcp in "" RCP26 RCP45 RCP85
do
  case $rcp in
      "")   dir=IPCC_species; yr=1850; yrend=2000;rcp_="";;
      RCP*) dir=IPCC_species/$rcp; yr=2000; yrend=2100;rcp_=${rcp}_;;
  esac
  yr=$((yr-10))
  while [ $yr -lt $yrend ]
    do
    yr=$((yr+10))
    echo $yr $rcp
    for species in SO2 # ...
      do
      outfile=${rcp_}${species}_${yr}.nc
      if [ ! -s $outfile ]
	  then
	  i=0
	  use=""
	  for source in anthropogenic ships aircraft biomassburning
	    do
            # there are several versions, take the most recent one
	    if [ $source != biomassburning -o -n "$rcp" ]
		then
                if [ $source = aircraft -a -n "$rcp" ]
                    then
                    # no aircraft emissons in RCPs, keep 2000 values.
		    file=`ls -t $dir/../2000/IPCC_emissions_${species}_${source}_2000_0.5x0.5*.nc|tail -1`
                else
		    file=`ls -t $dir/$yr/IPCC_emissions_${rcp_}${species}_${source}_${yr}_0.5x0.5*.nc|tail -1`
                fi
	    else
	      # take 1850 up to 1870, 1900 for 1880 and 1890...
		if [ $yr -lt 1875 ]
		    then
		    yr1=1850
		elif [ $yr -lt 1900 ]
		    then
		    yr1=1900
		else
		    yr1=$yr
		fi
		file=`ls -t $dir/$yr1/IPCC_GriddedBiomassBurningEmissions_${species}_decadalmonthlymean${yr1}*.nc | tail -1`
	    fi
	    if [ -n "$file" -a -f "$file" ]
		then
		i=$((i+1))
		use="$use
use \"$file\""
		varlist=`ncdump -h $file | egrep 'emiss_|fire' | fgrep "(time," | sed -e 's/^ *//' -e 's/float//' -e 's/(.*$//'`
		echo $varlist
		vars=""
		for var in $varlist
		  do
		  if [ $i = 1 ]; then
		      if [ -z "$vars" ]
			  then
			  vars="${var}[d=$i]"
		      else
			  vars="$vars + ${var}[d=$i]"
		      fi
		  else
		      vars="$vars + ${var}[d=$i,gt=emiss_awb[d=1]@asn]"
		  fi
		done
		if [ $i = 1 ]
		    then
		    sum="let $species$i = $vars"
		else
		    if [ $source = aircraft ]
			then
                        # only the ground layer, we are interested in the ground emissions
			sum="$sum
let $species$i = $species$((i-1)) + 610*${varlist}[d=${i},k=1]"
		    else
			sum="$sum
let $species$i = $species$((i-1)) $vars"
		    fi
		fi
	    fi
	  done
	  cat > job.jnl <<EOF
$use
$sum
let $species = 1000000000000*$species$i
save/file="$outfile"/clobber $species
quit
EOF
          ferret -batch -memsize 300 -script job.jnl
	  [ ! -s $outfile ] && exit -1
	  ncatted -a units,$species,a,c,"ng/m2/s" -a long_name,$species,m,c,"total $species emissions at ground level" $outfile
      fi
    done
  done
  cdo copy ${rcp_}${species}_????.nc ${rcp_}${species}.nc
done
