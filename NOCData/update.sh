#!/bin/sh
[ "$1" = force ] && force=true
cp moc_transports.nc moc_transports.nc.old
wget -N http://www.rapid.ac.uk/rapidmoc/rapid_data/moc_transports.nc
cmp moc_transports.nc moc_transports.nc.old
if [ $? != 0 -o "$force" = true ]; then

	for var in moc_mar_hc10 t_therm10 t_aiw10 t_ud10 t_ld10 t_bw10 t_gs10 t_ek10 t_umo10
	do
		ncks -O -v $var moc_transports.nc $var.nc
		ncatted -a title,global,c,c,"Data from the <a href=\"http://www.noc.soton.ac.uk/rapidmoc/\">RAPID</a> programme" $var.nc 
		cdo daymean $var.nc ${var}_day.nc
		cdo monmean $var.nc ${var}_mon.nc
	done
	$HOME/NINO/copyfiles.sh *_day.nc *_mon.nc
else
	echo "no change in moc_transports.nc"
fi
