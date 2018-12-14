#!/bin/sh
nrec_slp=`wc -l < v2.slp`
nstat_slp=`tail -1 v2.slp | cut -b 1-8`
nrec_prcp=`wc -l < v2.prcp`
nstat_prcp=`tail -1 v2.prcp | cut -b 1-8`
nrec_prcp_adj=`wc -l < v2.prcp_adj`
nstat_prcp_adj=`tail -1 v2.prcp_adj | cut -b 1-8`
nrec_mean=`wc -l < v2.mean_nodup`
nstat_mean=`tail -1 v2.mean_nodup | cut -b 1-8`
nrec_mean_adj=`wc -l < v2.mean_adj_nodup`
nstat_mean_adj=`tail -1 v2.mean_adj_nodup | cut -b 1-8`
nrec_min=`wc -l < v2.min_nodup`
nstat_min=`tail -1 v2.min_nodup | cut -b 1-8`
nrec_min_adj=`wc -l < v2.min_adj_nodup`
nstat_min_adj=`tail -1 v2.min_adj_nodup | cut -b 1-8`
nrec_max=`wc -l < v2.max_nodup`
nstat_max=`tail -1 v2.max_nodup | cut -b 1-8`
nrec_max_adj=`wc -l < v2.max_adj_nodup`
nstat_max_adj=`tail -1 v2.max_adj_nodup | cut -b 1-8`

for file in gettemp_v2 makeyearprecindex_v2 makeyearslpindex_v2
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
 -e "s/NREC_MEAN_ADJ/$nrec_mean_adj/" \
 -e "s/NSTAT_MEAN_ADJ/$nstat_mean_adj/" \
 -e "s/NREC_MIN_ALL/$nrec_min/" \
 -e "s/NSTAT_MIN_ALL/$nstat_min/" \
 -e "s/NREC_MIN_ADJ/$nrec_min_adj/" \
 -e "s/NSTAT_MIN_ADJ/$nstat_min_adj/" \
 -e "s/NREC_MAX_ALL/$nrec_max/" \
 -e "s/NSTAT_MAX_ALL/$nstat_max/" \
 -e "s/NREC_MAX_ADJ/$nrec_max_adj/" \
 -e "s/NSTAT_MAX_ADJ/$nstat_max_adj/" \
 -e "s/DATE/$date/" \
   ${file}_in.f90 > $file.f90
  make $file
done

for file in getslp getprcp getprcpall
do
  rm $file
  ln -s gettemp_v2 $file
done

rm v2.prcp.adj.inv.withmonth v2.prcp.inv.withmonth
./makeyearprecindex_v2
rm v2.slp.inv.withmonth
./makeyearslpindex_v2

