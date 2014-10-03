#!/bin/sh

###base=ftp://sidads.colorado.edu/pub/DATASETS/seaice/polar-stereo/bootstrap/final-gsfc/
base=ftp://sidads.colorado.edu/pub/DATASETS/nsidc0079_gsfc_bootstrap_seaice/final-gsfc/
for ns in north south
do
    wget -r -N -nH --cut-dirs=5 $base/$ns/monthly
done # ns

make bootstrap2grads
./bootstrap2grads
$HOME/NINO/copyfiles.sh conc_bt_*
