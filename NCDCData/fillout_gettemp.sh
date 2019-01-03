#!/bin/sh
nrec_slp=0 #`wc -l < v2.slp`
nstat_slp=0 # `tail -1 v2.slp | cut -b 1-8`
nrec_prcp=0 # `wc -l < v2.prcp`
nstat_prcp=0 # `tail -1 v2.prcp | cut -b 1-8`
nrec_prcp_adj=0 # `wc -l < v2.prcp_adj`
nstat_prcp_adj=0 # `tail -1 v2.prcp_adj | cut -b 1-8`
nrec_mean=`wc -l < ghcnm/ghcnm.tavg.v3.qcu.dat`
nstat_mean=`tail -1 ghcnm/ghcnm.tavg.v3.qcu.dat | cut -b 1-8`
nrec_mean_adj=`wc -l < ghcnm/ghcnm.tavg.v3.qca.dat`
nstat_mean_adj=`tail -1 ghcnm/ghcnm.tavg.v3.qca.dat | cut -b 1-8`
nrec_min=`wc -l < ghcnm/ghcnm.tmin.v3.qcu.dat`
nstat_min=`tail -1 ghcnm/ghcnm.tmin.v3.qcu.dat | cut -b 1-8`
nrec_min_adj=`wc -l < ghcnm/ghcnm.tmin.v3.qca.dat`
nstat_min_adj=`tail -1 ghcnm/ghcnm.tmin.v3.qca.dat | cut -b 1-8`
nrec_max=`wc -l < ghcnm/ghcnm.tmax.v3.qcu.dat`
nstat_max=`tail -1 ghcnm/ghcnm.tmax.v3.qcu.dat | cut -b 1-8`
nrec_max_adj=`wc -l < ghcnm/ghcnm.tmax.v3.qca.dat`
nstat_max_adj=`tail -1 ghcnm/ghcnm.tmax.v3.qca.dat | cut -b 1-8`

for file in gettemp makeyeartempindex
do
  sed \
 -e "s/NREC_SLP/$nrec_slp/" \
 -e "s/NSTAT_SLP/$nstat_slp/" \
 -e "s/NREC_PRCP_ALL/$nrec_prcp/" \
 -e "s/NSTAT_PRCP_ALL/$nstat_prcp/" \
 -e "s/NREC_PRCP_ADJ/$nrec_prcp_adj/" \
 -e "s/NSTAT_PRCP_ADJ/$nstat_prcp_adj/" \
 -e "s/NREC_MEAN_ALL/$nrec_mean/" \
 -e "s/NSTAT_MEAN_ALL/$nstat_mean/" \
 -e "s/VERSION_MEAN_ALL/$version/" \
 -e "s/NREC_MEAN_ADJ/$nrec_mean_adj/" \
 -e "s/NSTAT_MEAN_ADJ/$nstat_mean_adj/" \
 -e "s/VERSION_MEAN_ADJ/$version/" \
 -e "s/NREC_MIN_ALL/$nrec_min/" \
 -e "s/NSTAT_MIN_ALL/$nstat_min/" \
 -e "s/VERSION_MIN_ALL/$version/" \
 -e "s/NREC_MIN_ADJ/$nrec_min_adj/" \
 -e "s/NSTAT_MIN_ADJ/$nstat_min_adj/" \
 -e "s/VERSION_MIN_ADJ/$version/" \
 -e "s/NREC_MAX_ALL/$nrec_max/" \
 -e "s/NSTAT_MAX_ALL/$nstat_max/" \
 -e "s/VERSION_MAX_ALL/$version/" \
 -e "s/NREC_MAX_ADJ/$nrec_max_adj/" \
 -e "s/NSTAT_MAX_ADJ/$nstat_max_adj/" \
 -e "s/VERSION_MAX_ADJ/$version/" \
 -e "s/DATE/$date/" \
   ${file}_in.f90 > $file.f90
  make $file
done

for file in gettempall getmin getminall getmax getmaxall
do
    rm $file
    ln -s gettemp $file
done

rm ghcnm/*withmonth
./makeyeartempindex

