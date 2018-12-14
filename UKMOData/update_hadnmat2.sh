#!/bin/bash
root=http://www.metoffice.gov.uk/hadobs/hadnmat2/data/
version=2.0.1.0
file=HadNMAT.$version.nc
wget -N -q $root/$file
ncatted -a Title,global,a,c," version $version" \
        -a ancillary_variables,night_marine_air_temperature,d,c, \
        -a ancillary_variables,night_marine_air_temperature_anomaly,d,c, \
        -a institution,global,c,c,"UK Met Office Hadley Centre" \
        -a source_url,global,c,c,"http://hadobs.metoffice.gov.uk/hadnmat2/data/download.html" \
        $file
ncks -O -v night_marine_air_temperature $file HadNMAT2.nc
ncks -O -v night_marine_air_temperature_anomaly $file HadNMAT2a.nc
ncks -O -v large_scale_correlated_uncertainty $file HadNMAT2u.nc
for file in HadNMAT2.nc HadNMAT2?.nc; do
    . $HOME/climexp/add_climexp_url_field.cgi
done
$HOME/NINO/copyfiles.sh HadNMAT2.nc HadNMAT2a.nc HadNMAT2u.nc

