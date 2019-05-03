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
    -a contact,global,a,c,"j.palmer@unsw.edu.au" \
    -a references,global,a,c,"Palmer, J., E. R. Cook, C. S. M. Turney, K. Allen, P. Fenwick, B. I. Cook, A. O'Donnell, J. Lough, P. Grierson, and P. Baker (2015), Drought variability in the eastern Australia and New Zealand summer drought atlas (ANZDA, CE 1500-2012) modulated by the Interdecadal Pacific Oscillation, Environ. Res. Lett., 10(12), 124002-13, doi:10.1088/1748-9326/10/12/124002" \
    -a source,global,a,c,"https://www1.ncdc.noaa.gov/pub/data/paleo/treering/reconstructions/australia/palmer2015pdsi/readme-palmer2015anzda.txt" \
    $file
# and add superfluous metadata
. $HOME/climexp/add_climexp_url_field.cgi
