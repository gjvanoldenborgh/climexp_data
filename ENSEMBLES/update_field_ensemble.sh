#!/bin/bash
set -x
if [ $HOST = bvlclim.knmi.nl ]; then
    cleanup=true
else
    cleanup=false
fi
force=false # true
update=true # false

# adjust with each version
version=v17.0e
# end date of official file if in the same year as the year of last month
enddate="" # "2017-08-31" # keep empty when shortening is not needed "2013-12-31"
# begin date of annual additions when in the previous year
nextdate="" # "2017-09-01" # "2016-09-01" # "2015-07-01" # keep empty when previous year is not needed

cdoflags="-r -f nc4 -z zip"
wgetflags="-N --no-check-certificate"

yr=`date -d "last month" "+%Y"`
for var in rr tg tn tx pp # rr tg tn tx pp # tg tn tx pp
do
  for res in 0.25 # 0.1 too big for my computers
  do
    base=http://www.ecad.eu/download/ensembles/data/Grid_${res}deg_reg_ensemble/
    file=${var}_ens_mean_${res}deg_reg_$version.nc
    wget $wgetflags -N $base/$file
    ubase=http://www.ecad.eu/download/ensembles/data/months/ens
    if [ -n "$nextdate" ]; then
        ufile1=${var}_${res}deg_day_$((yr-1))_grid_ensmean.nc
        wget $wgetflags -N $ubase/$ufile1
    fi
    ufile=${var}_${res}deg_day_${yr}_grid_ensmean.nc
    [ $update = true ] && wget $wgetflags -N $ubase/$ufile
    if [ ! -s $ufile ]; then
        echo "$0: error: something went wrong downloading $ubase/$ufile"
        exit -1
    fi
    outfile=${var}_${res}deg_reg_${version}u.nc
    if [ $force = true -o \( ! -s $outfile \) -o $ufile -nt $outfile ]; then
        if [ $update = true ]; then
            if [ -n "$nextdate" ]; then
                cdo $cdoflags seldate,$nextdate,$((yr-1))-12-31 $ufile1 ${var}_${res}deg_reg_$((yr-1)).nc
            fi
            # this gets the whole of the year
            if [ -n "$enddate" -a -z "$nextdate" ]; then
                endyr=`echo $enddate | cut -d '-' -f 1`
                endmo=`echo $enddate | cut -d '-' -f 2`
                endmo=${endmo#0}
                cdo $cdoflags seldate,${endyr}-$((endmo+1))-01,${yr}-12-31 $ufile aap.nc
            else
                endyr=$yr
                cdo $cdoflags copy $ufile aap.nc
            fi
            # truncate the part of the file without data
            get_index aap.nc 5 5 52 52 | tail -1 > aap.lastline
            yr=`cat aap.lastline | cut -b 1-4`
            mm=`cat aap.lastline | cut -b 5-6`
            dd=`cat aap.lastline | cut -b 7-8`
            cdo $cdoflags seldate,${endyr}-01-01,${yr}-${mm}-${dd} aap.nc ${var}_${res}deg_reg_$yr.nc

            rm -f $outfile
            use_python=false
            if [ -n "$nextdate" ]; then
                cdo $cdoflags copy $file ${var}_${res}deg_reg_$((yr-1)).nc ${var}_${res}deg_reg_$yr.nc $outfile
                [ $? != 0 ] && echo "something went wrong" && exit -1
            else
                cdo $cdoflags copy $file ${var}_${res}deg_reg_$yr.nc $outfile
                [ $? != 0 ] && echo "something went wrong" && exit -1
            fi
            if [ $res = 0.25 ]; then # reduce size under 2^31 elements (up to 2018)
            	cdo $cdoflags selindexbox,41,464,1,201 $outfile aap.nc
            	mv aap.nc $outfile
            fi
        else
            ln -s  ${var}_${res}deg_reg_${version}.nc $outfile
        fi
        if [ $var = rr ]; then
            ncatted -a units,rr,m,c,"mm/day" $outfile
        fi
        file=$outfile
        ncatted -h -a institution,global,a,c,"KNMI" -a contact,global,a,c,"eca@knmi.nl" \
                -a title,global,c,c,"E-OBS analyses $version" \
                -a source_url,global,a,c,"http://surfobs.climate.copernicus.eu//dataaccess/access_eobs.php" \
                -a References,global,a,m,"Haylock, M.R., N. Hofstra, A.M.G. Klein Tank, E.J. Klok, P.D. Jones, M. New. 2008: A European daily high-resolution gridded dataset of surface temperature and precipitation. J. Geophys. Res (Atmospheres), 113, D20119, doi:10.1029/2008JD10201" \
                $file
        . $HOME/climexp/add_climexp_url_field.cgi
        $HOME/NINO/copyfiles.sh $outfile
        if [ $res = 0.25 ]; then
            cdo $cdoflags monmean $outfile aap.nc
            cdo $cdoflags settaxis,1950-01-01,0:00,1mon aap.nc ${var}_${res}deg_reg_${version}u_mo.nc
            rm aap.nc
            $HOME/NINO/copyfiles.sh ${var}_${res}deg_reg_${version}u_mo.nc
            if [ $cleanup = true ]; then
                rsync $outfile zuidzee:NINO/ENSEMBLES/
                /bin/rm $outfile
                touch $outfile
            fi
        fi
        if [ $cleanup = true ]; then
            /bin/rm -f ${var}_${res}deg_reg_${version}.nc
            /bin/rm -f ${var}_${res}deg_reg_$yr.nc
        fi
    fi
  done
done

. ./merge_with_cru.sh
