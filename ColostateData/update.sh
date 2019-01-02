#!/bin/sh
# http://www.atmos.colostate.edu/~davet/ao/Data/ao_index.html
wget -q -N http://www.atmos.colostate.edu/ao/Data/AO_TREN_NCEP_Jan1899Current.ascii
###wget -q -N http://www.atmos.colostate.edu/ao/Data/AO_SATindex_JFM_Jan1851March1997.ascii
sed -e 's/NaN/-999.9/' AO_TREN_NCEP_Jan1899Current.ascii > AO_TREN_NCEP_Jan1899Current.ascii.fixed
gfortran -o colo2dat colo2dat.f90 $HOME/climexp_numerical/$PVM_ARCH/climexp.a
./colo2dat
patchseries ao_slp.dat $HOME/climexp_data/NCEPData/cpc_ao.dat regr > ao_slp_ext.dat
$HOME/NINO/copyfiles.sh ao_slp_ext.dat