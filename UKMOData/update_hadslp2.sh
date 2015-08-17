#!/bin/sh
wget -q -N --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadslp2/data/hadslp2r.asc.gz
gunzip -c hadslp2r.asc.gz > hadslp2r.asc
wget -q -N --header="accept-encoding: gzip" http://www.metoffice.gov.uk/hadobs/hadslp2/data/hadslp2.0_acts.asc.gz
gunzip -c hadslp2.0_acts.asc.gz > hadslp2.0_acts.asc
###make hadslp2grads
./hadslp2grads
$HOME/NINO/copyfiles.sh hadslp2r.ctl hadslp2r.grd
$HOME/NINO/copyfiles.sh hadslp2_0.ctl hadslp2_0.grd
rm hadslp2r.asc hadslp2.0_acts.asc
