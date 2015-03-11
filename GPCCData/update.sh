#!/bin/sh
wgetflags="--no-passive-ftp"
if [ `uname` == Darwin ]; then
    wgetflags=""
fi
thisyr=`date "+%Y"`
lastyr=$((thisyr-1))
for res in 10 25
do

	wget -q $wgetflags -N ftp://ftp-anon.dwd.de/pub/data/gpcc/gpcc${res}\*.zip
	wget -q $wgetflags -N ftp://ftp-anon.dwd.de/pub/data/gpcc/monitoring/gpcc${res}\*.zip
	if [ $res = 10 ]; then
		wget -q $wgetflags -N ftp://ftp-anon.dwd.de/pub/data/gpcc/first_guess/$lastyr/*.gz
		wget -q $wgetflags -N ftp://ftp-anon.dwd.de/pub/data/gpcc/first_guess/$thisyr/*.gz
		for file in gpcc_first_guess_??_????.gz
		do
			gunzip -c $file > `basename $file .gz`
		done
	fi

	yr=1985
	ready=false
	while [ $ready = false ]
	do
		yr=$((yr + 1))
		yy=`echo $yr | cut -b 3-4`
		if [ -s gpcc${res}$yy.zip ]; then
			file=gpcc${res}$yy.zip
		elif [ -s gpcc${res}$yr.zip ]; then
			file=gpcc${res}$yr.zip
		elif [ -s gpcc${res}${yr}_monitoring_v6.zip ]; then
			file=gpcc${res}${yr}_monitoring_v6.zip
		elif [ -s gpcc${res}${yr}_monitoring_v5.zip ]; then
			file=gpcc${res}${yr}_monitoring_v5.zip
		elif [ -s gpcc${res}${yr}_monitoring_v4.zip ]; then
			file=gpcc${res}${yr}_monitoring_v4.zip
		elif [ -s gpcc${res}${yr}_monitoring_v3.zip ]; then
			file=gpcc${res}${yr}_monitoring_v3.zip
		elif [ -s gpcc${res}${yr}_monitoring_v2.zip ]; then
			file=gpcc${res}${yr}_monitoring_v2.zip
		elif [ -s gpcc${res}${yr}_monitoring_v1.zip ]; then
			file=gpcc${res}${yr}_monitoring_v1.zip
		else
			ready=true
			file=""
		fi
		echo "file=$file"
		[ -n "$file" ] && unzip -u $file
	done
	./gauge2dat ${res}
	rm gpcc_${res}*_monitor_*
	sed -e "s/gpcc_${res}_mon.dat/gpcc_${res}_n1_mon.dat/" -e 's/dataset/dataset with at least 1 station in or next to grid box/' -e 's/3e33/-9.99e8/' -e 's/YREV//' gpcc_${res}_mon.ctl > gpcc_${res}_n1_mon.ctl
	case $res in
		10) nx=360;ny=180;;
		25) nx=144;ny=72;;
		*) echo error hcpinxwyiwo;exit -1;;
	esac
	size=`stat -c "%s" gpcc_${res}_mon.dat`
	nt=`echo $size/$nx/$ny/4 | bc`
	grads -b -l <<EOF
open gpcc_${res}_mon.ctl
open ngpcc_${res}_mon.ctl
set gxout fwrite
set x 1 $nx
set y 1 $ny
set t 1 $nt
set gxout fwrite
set fwrite gpcc_${res}_n1_mon.dat
d maskout(prcp.1,smth9(nprcp.2-0.1))
disable fwrite
quit
EOF
	grads2nc gpcc_${res}_mon.ctl aap.nc
	cdo -r -f nc4 -z zip copy aap.nc gpcc_${res}_mon.nc
	grads2nc gpcc_${res}_n1_mon.ctl aap.nc
	cdo -r -f nc4 -z zip copy aap.nc gpcc_${res}_n1_mon.nc
	grads2nc ngpcc_${res}_mon.ctl aap.nc
	cdo -r -f nc4 -z zip copy aap.nc ngpcc_${res}_mon.nc
	patchfield gpcc_V6_${res}.nc gpcc_${res}_mon.nc gpcc_${res}_combined.nc
	patchfield gpcc_V6_${res}_n1.nc gpcc_${res}_n1_mon.nc gpcc_${res}_n1_combined.nc
	$HOME/NINO/copyfilesall.sh gpcc_${res}_n1_mon.nc gpcc_${res}_mon.nc ngpcc_${res}_mon.nc gpcc_${res}_combined.nc
	###rm gpcc_${res}_mon.??? gpcc_${res}_n1_mon.??? ngpcc_${res}_mon.??? aap.nc
    
done

