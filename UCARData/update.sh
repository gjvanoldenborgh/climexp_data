#!/bin/bash
[ "$1" = force ] && force=true
yr=`date -d "last month" +%Y`
mo=`date -d "last month" +%m`

# Trenberth monthly mean SLP (ds010.1)
wget --no-check-certificate --save-cookies cookie_file --post-data="email=oldenborgh@knmi.nl&passwd=rEjESwPQ&action=login" https://rda.ucar.edu/cgi-bin/login

set -x
mv ds010_1.ascii ds010_1.ascii.old
if [ "$compressed" = true ]; then
    wget --no-check-certificate --load-cookies cookie_file -O ds010_1.ascii.gz \
        https://rda.ucar.edu/cgi-bin/dattore/subgrid\?sd=189901\&ed=$yr$mo\&of=ascii\&c=gz\&t=monthly\&d=010.1\&i=molydata.bin\&if=slp
    c=`file ds010_1.ascii.gz | fgrep -c zip`
    if [ $c != 1 ]; then
        echo "$0: error: something went wrong"
        exit -1
    fi
    gunzip -c ds010_1.ascii.gz > ds010_1.ascii
else
    wget --no-check-certificate --load-cookies cookie_file -O ds010_1.ascii \
        https://rda.ucar.edu/cgi-bin/dattore/subgrid\?sd=189901\&ed=$yr$mo\&of=ascii\&c=none\&t=monthly\&d=010.1\&i=molydata.bin\&if=slp
fi
cmp ds010_1.ascii ds010_1.ascii.old
if [ $? != 0 -o "$force" = true ]; then
    make ascii2dat
    ./ascii2dat
    grads2nc ds010_1.ctl ds010_1.nc
    ncatted -h -a title,global,o,c,"Monthly Northern Hemisphere Sea-Level Pressure Grids" \
            -a description,global,a,c,"This dataset contains the longest continuous time series of monthly gridded
    Northern Hemisphere sea-level pressure data in the DSS archive. The 5-degree
    latitude/longitude grids, computed from the daily grids in ds010.0
    [http://rda.ucar.edu/datasets/ds010.0/], begin in 1899 and cover the
    Northern Hemisphere from 15N to the North Pole. The dataset continues to be
    updated regularly as new data become available.

    Each monthly grid is a simple average of all available daily grids for the
    month. Prior to 1955, there is one grid per day. From July 1962 on, there
    are two grids each day. In the interim period, the number of daily grids
    varies between one and two.

    The grids for the period 1899-1977 were inspected and many corrections were
    made by Kevin Trenberth of the Laboratory of Atmospheric Research at the
    University of Illinois at Champaign-Urbana, and these grids are included in
    this dataset. For more information about these corrections, see the July
    1980 issue of Monthly Weather Review." \
            -a institution,global,o,c,"NOAA/NCAR" \
            -a source_url,global,a,c,"https://rda.ucar.edu/datasets/ds010.1/" \
            -a reference,global,a,c,"K.E. Trenberth, and D.A. Paolino, 1980: The Northern Hemisphere sea level pressure data set: Trends, errors, and discontinuities. Mon. Wea. Rev., 108, 855-872. https://doi.org/10.1175/1520-0493(1980)108<0855:TNHSLP>2.0.CO;2" \
            ds010_1.nc
    file=ds010_1.nc
    . $HOME/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh ds010_1.nc
    ./make_snao.sh
fi
