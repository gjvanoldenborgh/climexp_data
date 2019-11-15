#!/bin/bash

wget -N https://ndownloader.figshare.com/files/16807844
file=GRUN_v1_GSWP3_WGS84_05_1902_2014_ce.nc
cdo -r -f nc4 -z zip copy 16807844 $file
ncatted -h -a source_url,global,a,c,"https://figshare.com/articles/GRUN_Global_Runoff_Reconstruction/9228176" \
    -a references,global,m,c,"Ghiggi et al.,2019. GRUN: An observation-based global gridded runoff dataset from 1902 to 2014. ESS, https://doi.org/10.5194/essd-11-1655-2019" \
    -a doi,global,a,c,"doi:10.6084/m9.figshare.9228176.v1" \
    $file
. $HOME/climexp/add_climexp_url_field.cgi
$HOME/NINO/copyfiles.sh $file
