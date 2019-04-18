#!/bin/bash
# got file via email, some post-processing to make it acceptable.
export file=anzda5.nc
unzip anzda.nc.zip
# put axes in the right order
ncpdq -O -a time,lat,lon $file /tmp/$file
# define a sensible time axis, compress as well.
cdo -r -f nc4 -z zip settaxis,1500-06-01,0:00,1year /tmp/$file $file
# put the correct units on the lat-lon axes
ncatted -h -a units,lon,m,c,'degrees_east' -a units,lat,m,c,'degrees_north' $file
# add a title and contact
ncatted -h -a Title,global,a,c,"Reconstructed scPDSI for Australia/New Zealand Drought Atlas (ANZDA v1.0)" \
    -a contact,global,a,c,"j.palmer@unsw.edu.au" $file
# and add superfluous metadata
. $HOME/climexp/add_climexp_url_field.cgi
