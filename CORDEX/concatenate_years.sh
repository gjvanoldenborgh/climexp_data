#!/bin/sh
cwd=`pwd`
domain=EUR-11
case $domain in
  EUR-44) newgridfile=$domain/eobs_0.50deg_reg_grid_smaller.nc;;
  EUR-11) newgridfile=$domain/eobs_0.125deg_reg_grid_smaller.nc;;
  *) echo "unknown doamin $domain"; exit -1;;
esac
timescale="$3"
if [ -z "$timescale" ]; then
    echo "usage: $0 var exp day|mon|annual"
    exit -1
fi
echo "timescale=$timescale"
vars="$1"
[ $vars = all ] && vars="tas tasmin tasmax pr"
exps="$2"
[ $exps = all ] && exps="historical rcp26 rcp45 rcp85"
models=""
cdo="cdo -f nc4 -z zip -r"

for var in $vars
do

for exp in $exps
do

mkdir -p $domain/$timescale/$var
shortname=`echo $domain | tr -d '-'`
[ ! -L $shortname ] && ln -s $domain $shortname
ensfiles=""

list=`ls ethz/$domain/$exp/$timescale/$var/`
institutes=""
for dir in $list
do
	file=`basename $dir`
	institutes="$institutes $file"
done
###echo "institutes = $institutes"

for institute in $institutes
do
    list=`ls ethz/$domain/$exp/$timescale/$var/$institute/`
    gcms=""
    for dir in $list
    do
        file=`basename $dir`
        gcms="$gcms $file"
    done
    ###echo "gcms = $gcms"
    
    for gcm in $gcms
    do
    
        list=`ls ethz/$domain/$exp/$timescale/$var/$institute/$gcm/`
        rcms=""
        for dir in $list
        do
            file=`basename $dir`
            rcms="$rcms $file"
        done
        ###echo "rcms = $rcms"
    
        for rcm in $rcms
        do
#
#           concatenate
#
            list=`ls ethz/$domain/$exp/$timescale/$var/$institute/$gcm/$rcm/`
            rips=""
            for dir in $list
            do
                file=`basename $dir`
                rips="$rips $file"
            done
            ###echo "rips = $rips"
    
            for rip in $rips
            do
                echo "$domain/$exp/$timescale/$var/$institute/$gcm/$rcm/$rip"
                version=v1 # seems to be everywhere
                infiles=`echo ethz/$domain/$exp/$timescale/$var/$institute/$gcm/$rcm/$rip/*.nc | sort`
                if [ ${exp#rcp} != $exp ]; then
                    c=`ls $infiles | fgrep -c 200602`
                    if [ $c != 0 ]; then
                        extrafile=ethz/$domain/$exp/$timescale/$var/$institute/$gcm/$rcm/$rip/${var}_${domain}_${gcm}_${exp}_${rip}_${rcm}_${version}_mon_200601-200601_extra.nc
                        if [ ! -s $extrafile ]; then
                            echo "First month of RCP run is missing, approximating it from daily data 2-31 Jan 2006"
                            dayfile=ethz/$domain/$exp/day/$var/$institute/$gcm/$rcm/$rip/${var}_${domain}_${gcm}_${exp}_${rip}_${rcm}_${version}_day_20060102-*.nc
                            cdo seldate,2006-01-02,2006-01-31 $dayfile /tmp/aap.nc
                            cdo monmean /tmp/aap.nc $extrafile
                            describefield $extrafile
                            infiles="$extrafile $infiles"
                        fi
                    fi
                    c=`ls $infiles | fgrep -c 20060102`
                    if [ $c != 0 ]; then
                        extrafile=ethz/$domain/$exp/$timescale/$var/$institute/$gcm/$rcm/$rip/${var}_${domain}_${gcm}_${exp}_${rip}_${rcm}_${version}_day_20060101-20060101_extra.nc
                        if [ ! -s $extrafile ]; then
                            echo "First day of RCP run is missing,fill with undefs"
                            firstfile=`ls $infiles | head -1`
                            cdo seldate,2006-01-02 $firstfile /tmp/oneday.nc
                            cdo shifttime,-1day /tmp/oneday.nc /tmp/aap.nc
                            cdo divc,0. /tmp/aap.nc $extrafile
                            ls -l $extrafile
                            describefield $extrafile
                            infiles="$extrafile $infiles"
                        fi
                    fi
    				if [ $timescale = day ]; then
        				histfile=$domain/$timescale/$var/${var}_${domain}_${gcm}_historical_${rip}_${rcm}_${version}_${timescale}_1???????-2???????.nc
    	    		else
    		    		histfile=$domain/$timescale/$var/${var}_${domain}_${gcm}_historical_${rip}_${rcm}_${version}_${timescale}_1?????-2?????.nc
    			    fi
    			    if [ ! -s $histfile ]; then
    			        echo "$0: error: cannot find $histfile"
    			        echo "first run $0 $var historical $timescale"
    			        exit -1
    			    fi
                    firstfile=`ls $histfile | head -1`
    			else
                    firstfile=`ls $infiles | head -1`
                fi
                firstdate=${firstfile##*_${timescale}_}
                firstdate=${firstdate%%-*}
                lastfile=`ls $infiles | fgrep -v /tmp | tail -1`
                lastdate=2${lastfile##*-2}
                lastdate=${lastdate%.nc}
                c1=`echo $firstdate | wc -c`
                c2=`echo $lastdate | wc -c`
                if [ $timescale = day ]; then
                    expect=9
                else
                    expect=7
                fi
                if [ $c1 != $expect -o $c2 != $expect ]; then
                    ###echo "@@@ $firstdate,${firstdate%3?}"
                    ###echo "@@@ $lastdate,${lastdate%3?}"
                    if [ $expect = 7 -a $c1 = 9 ]; then
                        firstdate=${firstdate%01}
                        c1=`echo $firstdate | wc -c`
                    fi
                    if [ $expect = 9 -a $c1 = 11 ]; then
                        firstdate=${firstdate%??}
                        c1=`echo $firstdate | wc -c`
                    fi
                    if [ $expect = 7 -a $c2 = 9 ]; then
                        lastdate=${lastdate%3?} 
                        c2=`echo $lastdate | wc -c`
                    fi
                    if [ $expect = 9 -a $c2 = 11 ]; then
                        lastdate=${lastdate%??} 
                        c2=`echo $lastdate | wc -c`
                    fi
                fi
                if [ $c1 != $expect -o $c2 != $expect ]; then
                    echo "$0: error: something went wrong: firstdate,lastdate = $firstdate,$lastdate,$expect,$c1,$c2"
                    echo "firstfile = $firstfile"
                    echo "lastfile = $lastfile"
                    exit -1
                fi
				outfile=$domain/$timescale/$var/${var}_${domain}_${gcm}_${exp}_${rip}_${rcm}_${version}_${timescale}_${firstdate}-${lastdate}.nc
                if [ ! -s $outfile ]; then
                    doit=true
                else
                    doit=false
                    for infile in $infiles; do
                        [ ${infile#/tmp} = $infile -a $outfile -ot $infile ] && doit=true
                    done
                fi
                if [ ${exp#rcp} != $exp ]; then
                    if [ ! -s $histfile ]; then
                        echo "$0: error: cannot find historical file $histfile"
                        exit -1
                    fi
                    infiles="$histfile $infiles"
                    [ $outfile -ot $histfile ] && doit=true
                fi
                if [ $doit = true ]; then
                    [ -L $outfile ] && rm $outfile
                    echo $cdo copy $infiles $outfile
                    $cdo copy $infiles $outfile
                    if [ ! -s $outfile ]; then
                        echo "$0: error: something went wrong in cdo copy"
                        exit -1
                    fi
                    if [ ${exp#rcp} != $exp ]; then
                        # adjust the metadata to be that of the RCP run
						ncdump -h $firstfile | egrep -v '[0-9]\.[ 0-9]' > /tmp/metadata$$.cdl
						ncattedargs=`cat /tmp/metadata$$.cdl \
								| sed \
								-e '/{/,/global attributes/d' \
								-e '/licence/,/;$/d' \
								-e '/history/,/;$/d' \
								-e '/references/,/;$/d' \
								-e '/acknowledgements/,/;$/d' \
								-e '/forcing_note/,/;$/d' \
								-e '/}/d' \
								-e 's/^[ 	\t]*:/ -a /' \
								-e 's/ experiment_id = "/ experiment_id,global,o,c,"historical+/' \
								-e 's/ = "/,global,o,c,"/' \
								-e 's/time = /time,global,o,f,/' \
								-e 's/ = /,global,o,s,/' \
								-e 's/" ;/"/' \
								-e 's/ ;//' \
								| tr '\n' " "  `
                        ncattedargs="-h $ncattedargs $outfile"
                        echo "ncatted $ncattedargs" > /tmp/aap$$.sh
                        sh /tmp/aap$$.sh
                        if [ $? != 0 ]; then
                            echo "$0: something went wrong in running aap$$.sh "
                            cat /tmp/aap$$.sh
                            ###rm $outfile
                            exit -1
                        fi
                        rm /tmp/aap$$.sh /tmp/metadata$$.cdl
                    fi
                    # adjust the date to that of the newest ingredient
                    # still not waterproof but better than before
                    newestfile=""
                    for file in $infiles
                    do
                        if [ -z "$newestfile" -o $file -nt "$newestfile" ]; then
                            newestfile=$file
                        fi
                    done
                    echo "touch -r $newestfile $outfile"
                    touch -r $newestfile $outfile
                    # finally
                    describefield $outfile >& /tmp/d$$.txt
                    s=$?
                    c=`fgrep -c "irregular time axis" /tmp/d$$.txt`
                    if [ $timescale = "day" ]; then
                        n=`fgrep available /tmp/d$$.txt | cut -b 54-59`
                        norm=12500
                    elif [ $timescale = "mon" ]; then
                        n=`fgrep available /tmp/d$$.txt | cut -b 49-53`
                        norm=420
                    elif [ $timescale = "annual" ]; then
                        n=`fgrep available /tmp/d$$.txt | cut -b 42-46`
                        norm=45
                    else
                        echo "$0: error: unknown timescale $timescale"
                        exit -1
                    fi
                    n=${n% }
                    echo "s=$s,c=$c,n=$n"
                    if [ "$s" != 0 -o "$c" != 0 -o -z "$n" ]; then
                        cat /tmp/d$$.txt
                        rm	/tmp/d$$.txt
                        mv $outfile $outfile.wrong
                        echo "$0: something went wrong in constructing $outfile, status=$s, irregular time axis=$c, available=$n"
                        exit -1
                    fi
                    if [ "$n" != '****' -a "$n" -lt $norm ]; then
                        cat /tmp/d$$.txt
                        rm	/tmp/d$$.txt
                        mv $outfile $outfile.wrong
                        echo "$0: something went wrong in constructing $outfile, only $n time steps"
                        exit -1
                    fi
                    rm /tmp/d$$.txt
				fi # doit concatenate
#
#				interpolate to latlon
#
                doit=true
                if [ $timescale = day ]; then
                    if [ $firstdate -le 19510101 ]; then
                        firstdate=19510101
                        begindate=1951-01-01
                    else
                        doit=false
                    fi
                    if [ $lastdate = 20991130 ]; then
                        enddate=2099-11-30
                    elif [ $lastdate = 20991230 ]; then # 360-dy calendar
                        lastdate=20991230
                        enddate=2099-12-30
                    elif [ $lastdate -ge 20991231 ]; then
                        lastdate=20991231
                        enddate=2099-12-31
                    else
                        echo "not enough data: $firstdate,$lastdate"
                        doit=false
                    fi
                else
                    if [ $firstdate -le 195101 ]; then
                        firstdate=195101
                        begindate=1951-01-01
                    else
                        doit=false
                    fi
                    if [ $lastdate = 209911 ]; then
                        enddate=2099-11-20
                    elif [ $lastdate -ge 209912 ]; then
                        lastdate=209912
                        enddate=2099-12-31
                    else
                        echo "not enough data: $firstdate,$lastdate"
                        doit=false
                    fi
                fi
				latlonfile=${outfile%_*.nc}_${firstdate}-${lastdate}_latlon.nc
				if [ $doit = true -a -s $outfile -a \( ! -s $latlonfile -o $latlonfile -ot $outfile \) ]; then
                     if [ $var = pr -o ${var#rx} != $var ]; then
                        remap=remapcon
                        c=`fgrep -c vertices $outfile`
                        clon=`fgrep -c " lon(" $outfile`
                        clongitude=`fgrep -c " longitude(" $outfile`
                        if [ $clon != 0 ]; then
                            lon=lon
                            lat=lat
                        elif [ $clongitude != 0 ]; then
                            lon=longitude
                            lat=latitude
                        else
                            if [ $rcm = CNRM-ALADIN53 ]; then
                                lat_lon_grid=scripgrids/lat_lon_$rcm.nc
                                if [ ! -s $lat_lon_grid ]; then
                                    file=$domain/mon/tas/tas_EUR-44_CNRM-CERFACS-CNRM-CM5_historical_r1i1p1_CNRM-ALADIN53_v1_mon_195001-200512.nc
                                    if [ ! -s $file ]; then
                                        echo "$0: error: need a CNRM-ALADIN53 file to copy grid info from, but cannot find $file"
                                        exit -1
                                    fi
                                    ncks -O -v lat,lon $file $lat_lon_grid
                                fi
                                cdo merge $outfile $lat_lon_grid $outfile.tmp
                                ncatted -O -a ,Lambert_Conformal,d,, $outfile.tmp $outfile
                                rm $outfile.tmp
                            fi
                            lon=lon
                            lat=lat
                        fi
                    else
                        remap=remapbil
                        c=999
                        lon=lon
                        lat=lat
                    fi
                    tmpfile=/tmp/tmp$$.nc
                    echo "$cdo -seldate,$begindate,$enddate $outfile $tmpfile"
                    $cdo -seldate,$begindate,$enddate $outfile $tmpfile
                    [ -f $latlonfile ] && rm $latlonfile
                    if [ $c = 0 ]; then
                        # Vertices needed but not provided. Get them with NCL
                        mkdir -p scripgrids
                        gridfile=scripgrids/grid_${gcm}_${rcm}.nc
                        sed -e "s@INFILE@$tmpfile@" -e "s@OUTFILE@$gridfile@" -e "s@LAT@$lat@" -e "s@LON@$lon@" get_scrip_file.ncl > ${gcm}_${rcm}.ncl
                        ncl ${gcm}_${rcm}.ncl
                        if [ ! -s $gridfile ]; then
                            echo "$0: error: something went wrong in ${gcm}_${rcm}.ncl"
                            exit -1
                        fi
                        echo "$cdo $remap,$newgridfile $tmpfile $latlonfile"
                        $cdo $remap,$newgridfile -setgrid,$gridfile $tmpfile $latlonfile
                    else
                        echo "$cdo $remap,$newgridfile $tmpfile $latlonfile"
                        $cdo $remap,$newgridfile $tmpfile $latlonfile
                    fi
                    if [ ! -s $latlonfile ]; then
                        echo "$0: error: something went wrong in creating $latlonfile"
                        exit -1
                    fi
                    c=`ncdump -h $latlonfile | fgrep -c "lat(latitude, longitude)"`
                    if [ $c != 0 ]; then
                        cdo delvar,lon,lat $latlonfile $latlonfile.tmp
                        mv $latlonfile.tmp $latlonfile
                    fi
                    describefield $latlonfile
                    rm $tmpfile
                    echo "touch -r $outfile $latlonfile"
                    touch -r $outfile $latlonfile
                    nt=`ncdump -h $latlonfile | fgrep currently | sed -e 's/^.*[(]//' -e 's/ .*$//'`
                    if [ "$nt" != 1788 -a "$nt" != 1787 ]; then
                        echo "$0: error: $latlonfile has length $nt, removing"
                        echo `date` "$0: error: $latlonfile has length $nt, removing" >> remove.log
                        rm $latlonfile
                        exit -1
                    fi
                fi # interpolate?
                if [ -s $latlonfile ]; then
                    ensfiles="$ensfiles $latlonfile"
                fi
            done # rip
            
            # fixed files
            
            mkdir -p $domain/fx
            lsmask=$domain/fx/sftlf_${domain}_${gcm}_${exp}_r0i0p0_${rcm}_${version}_fx.nc
            latlonmask=${lsmask%.nc}_latlon.nc
            reallatlonmask=`echo $latlonmask | sed -e 's/sftlf/lsmask/g'`
            fxfile=`ls ethz/$domain/$exp/fx/sftlf/$institute/$gcm/$rcm/*/sftlf_${domain}_${gcm}_${exp}_*_${rcm}_${version}_fx.nc 2> /dev/null | head -1`
            if [ -n "$fxfile" -a -s "$fxfile" ]; then
                if [ ! -s $reallatlonmask -o $reallatlonmask -ot $fxfile ]; then
                    if [ ! -s "$lsmask" -o "$lsmask" -ot "$fxfile" ]; then
                        cp $fxfile $lsmask
                    fi
                    if [ ! -s $latlonmask -o $latlonmask -ot $lsmask ]; then
                        remap=remapbil
                        [ -f $latlonmask ] && rm $latlonmask
                        echo "$cdo $remap,$newgridfile $lsmask $latlonmask"
                        $cdo $remap,$newgridfile $lsmask $latlonmask
                        if [ ! -s $latlonmask ]; then
                            echo "$0: error: something went wrong in creating $latlonmask"
                            exit -1
                        fi
                    fi
                    if [ ! -s $reallatlonmask -o $reallatlonmask -ot $latlonmask ]; then
                        c=`ncdump $latlonmask | fgrep 'sftlf:units' | fgrep -c '%'`
                        if [ $c = 0 ]; then
                            cp $latlonmask $reallatlonmask
                        else
                            [ -f $reallatlonmask ] && rm $reallatlonmask
                            cdo divc,100 $latlonmask $reallatlonmask
                            ncatted -a units,sftlf,m,c,'1' $reallatlonmask
                        fi
                        masks=`ls $domain/fx/lsmask*.nc | fgrep -v _ave`
                        [ -f $domain/fx/lsmask_EUR-44_cordex_ave.nc ] && rm $domain/fx/lsmask_EUR-44_cordex_ave.nc
                        cdo ensavg $masks $domain/fx/lsmask_EUR-44_cordex_ave.nc
                    fi
                fi
            fi
        done # rcm
    done # gcm
done # institute

# make ensembles with symlinks

i=0
for file in $ensfiles
do
    iii=`printf %03i $i`
    ifile=$domain/$timescale/$var/${var}_${domain}_cordex_${exp}_${timescale}_$iii.nc
    [ -L $ifile ] && rm $ifile
    (cd $domain/$timescale/$var; ln -s `basename $file` `basename $ifile`)
    i=$((i+1))
done
if [ 1 = 0 -a -n "$ensfiles" ]; then
    avefile=$domain/$timescale/$var/${var}_${domain}_cordex_${exp}_${timescale}_ave.nc
    use_cdo=false
    if [ "$use_cdo" = true ]; then
        # get rid of too short run for average, otherwise cdo barfs
        ensfiles=`ls $ensfiles | fgrep -v 209911`
        [ -f $avefile ] && rm $avefile
        echo "cdo ensmean $ensfiles $avefile"
        cdo ensmean $ensfiles $avefile
        if [ ! -s $avefile ]; then
            echo "$0: error: cdo failed"
            exit -1
        fi
    else
        echo "averagefield_ensemble $domain/$timescale/$var/${var}_${domain}_cordex_${exp}_${timescale}_%%%.nc mean $avefile"
        echo yes | averagefield_ensemble $domain/$timescale/$var/${var}_${domain}_cordex_${exp}_${timescale}_%%%.nc mean $avefile
        if [ ! -s $avefile ]; then
            echo "$0: error: averagefield_ensemble failed"
            exit -1
        fi
    fi
fi

done # exp

done # var
