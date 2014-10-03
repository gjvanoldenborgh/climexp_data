#!/bin/sh
# define a IPO index as the first EOF of detrended SST over 50S-50N, 100-290E.

trend=$HOME/NINO/CDIACData/RCP45_CO2EQ_mo.dat
trendname="co2eq"

fullensemble=true

for model in hadsst3 hadisst1 ersstv3b
do
    case $model in
        hadsst*) xave=1;yave=1;;
        hadisst*) xave=4;yave=2;;
        ersst*) xave=2;yave=1;;
        *) echo "$0: error: unknown model $model"; exit -1;;
    esac
    for ave in 1 4 9
    do
	    echo "@@@@@ $model $ave @@@@"
        case $ave in
            1) ndiff=0;nooverlap="";lag=0;;
            4) ndiff=3;nooverlap="";lag=12;;
            9) ndiff=9;nooverlap="";lag=48;;
            *) echo "unknown ave $ave";exit -1;;
        esac
        minfac=25

	    # get detrended fields

        FORM_field=$model
        LSMASK=""
        . $HOME/climexp/queryfield.cgi
        file=$HOME/climexp/$file
	    regrfile=regr_sst_${model}_co2eq_annual_${ave}.nc
	    subfile=${model}-co2eq_annual_${ave}.ctl
	    if [ ! -s $regrfile ]; then
		    command="correlatefield $file $trend mon 1 ave 12 minfac $minfac $regrfile"
		    echo $command
		    $command
		    if [ ! -s $regrfile ]; then
		        echo "Something went wrong"
		        exit -1
		    fi
	    fi
	    if [ ! -s $subfile ]; then
		    command="correlatefield $file $trend ave 12 subtract $subfile"
		    echo $command
		    $command
    		if [ ! -s $subfile ]; then
	    	    echo "Something went wrong"
		        exit -1
		    fi
	    fi

	    # make EOFs

	    eoffile=eof_pac_${model}_${ave}.ctl
	    series=eof_pac_${model}_${ave}_01.dat
	    if [ ! -s $eoffile ]; then
	        if [ -z "$LSMASK" ]; then
	            lsmaskargs=""
	        else
	            lsmaskargs="lsmask sea $LSMASK"
	        fi
    		command="eof $subfile 1 $lsmaskargs normsd anomal mon 1 ave 12 lon1 100 lon2 290 lat1 -50 lat2 50 diff -$ndiff $nooverlap minfac $minfac normalize vartime xave $xave yave $yave $eoffile"
	    	echo $command
		    $command
    		if [ ! -s $eoffile ]; then
	    	    echo "Something went wrong"
		        exit -1
		    fi
	    else
		    echo "$eoffile already exists"
	    fi

	    # get sign correct

		nino34=$HOME/NINO/NCDCData/ersst_nino3.4.dat
	    [ -f aap.txt ] && rm aap.txt
	    command="correlate $series file $nino34 mon 1 ave 12 plot aap.txt"
	    echo $command
	    $command > /dev/null
	    if [ ! -s aap.txt ]; then
    		echo "Something went wrong"
	    	exit -1
	    fi
	    r=`cat aap.txt | awk '{print $3}'`
	    echo "r=$r"
	    sign=`echo $r | cut -b 1`
	    echo "sign=$sign"
	    if [ "$sign" = "-" ]; then
		    echo "flipping sign of $series"
		    scaleseries -1 $series > aap.dat
		    mv aap.dat $series
	    fi
	    if [ ${model#ersst} != $model ]; then
            cp $series $HOME/climexp/NCDCData
            (cd $HOME/climexp/NCDCData; $HOME/NINO/copyfiles.sh $series)
	    else
            $HOME/NINO/copyfiles.sh $series
	    fi
    
	    # plot EOF

	    plotit=false
	    if [ $plotit = true ]; then
	    plotfile=regr_eof_pac_${model}_${ave}.nc
	    if [ ! -s $plotfile -o $plotfile -ot $eoffile ]; then
	        [ -f /tmp/aap.ctl ] && rm /tmp/aap.ctl /tmp/aap.grd
		    filteryearfield lo box $ave $subfile minfac $minfac /tmp/aap.ctl
    		command="correlatefield /tmp/aap.ctl $series $lsmaskargs sea mon 1 ave 12 lag $lag $plotfile"
	    	echo $command
		    $command
    		[ $? != 0 ] && echo "$0: error in $command" && exit -1
	    fi
	    regreps=regr_eof_pac_${model}_${ave}.eps
	    grads -b -l <<EOF
sdfopen $plotfile
set lon 100 290
set lat -50 50
set grid off
set xlab off
set ylab off
set grads off
run danoprob regr 1 grfill 0 off 0 100 -0.4 0.4
print $regreps
EOF
        fi # plotit?
    done
done
