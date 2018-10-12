#!/bin/sh
wget -q -N --header="accept-encoding: gzip" --no-check-certificate http://www.metoffice.gov.uk/hadobs/hadslp2/data/hadslp2r.asc.gz
gunzip -c hadslp2r.asc.gz > hadslp2r.asc
wget -q -N --header="accept-encoding: gzip" --no-check-certificate http://www.metoffice.gov.uk/hadobs/hadslp2/data/hadslp2.0_acts.asc.gz
gunzip -c hadslp2.0_acts.asc.gz > hadslp2.0_acts.asc
###make hadslp2grads
make hadslp2grads
./hadslp2grads
rm hadslp2r.asc hadslp2.0_acts.asc
for ext in 2r 2_0; do
    grads2nc hadslp$ext.ctl hadslp$ext.nc
    ncatted -h -a institution,global,a,c,"UK Met Office Hadley Centre" \
            -a references,global,a,c,"Allan, R. and T. Ansell, 2006: A New Globally Complete Monthly Historical Gridded Mean Sea Level Pressure Dataset (HadSLP2): 1850–2004. J. Climate, 19, 5816–5842, doi:10.1175/JCLI3937.1" \
            -a soource_url,global,a,c,"https://www.metoffice.gov.uk/hadobs/hadslp2/data/download.html" \
            -a comment,global,a,c,"Data restrictions: for academic research use only. Data are Crown copyright see (www.opsi.gov.uk/advice/crown-copyright/copyright-guidance/index.htm)" \
            hadslp$ext.nc
    file=hadslp$ext.nc
    . ~/climexp/add_climexp_url_field.cgi
    $HOME/NINO/copyfiles.sh hadslp$ext.nc
done