#!/bin/bash
# obtain NOAA NDVI CDR, see https://data.nodc.noaa.gov/cgi-bin/iso?id=gov.noaa.ncdc:C00813
# and https://www.ncdc.noaa.gov/cdr/terrestrial/normalized-difference-vegetation-index
###set -x

if [ "$HOST" = pc160050.knmi.nl ]; then
    # new cdo...
    PATH=/usr/local/free/installed/cdo-1.9.5/bin:$PATH
fi

version=v005
yr=1981
yrnow=`date +%Y`
base=https://www.ncei.noaa.gov/data/avhrr-land-normalized-difference-vegetation-index/access
while [ $yr -lt $yrnow ]; do
    yrfile=ndvi_${version}_${yr}_01.nc
    if [ ! -s $yrfile ]; then
        mkdir -p ndvi_$yr
        cd ndvi_$yr
        wget -N --no-check-certificate -O index.html $base/$yr/
        files=`cat index.html | fgrep "AVHRR-Land_${version}" | sed -e 's/^.*AVHRR/AVHRR/' -e 's/\.nc.*$/.nc/'`
        for file in $files; do
            wget -N --no-check-certificate $base/$yr/$file
            if [ ! -s $file ]; then
                version=${version}-preliminary
            else
                cdo selname,NDVI $file ndviraw$file
                cdo selname,QA $file qa$file
                # for QA, the valid channel flag seems to have been applied already, I have to do the clouds myself
                # clouds are blanked out, cloudshadow points seem reasonable and have been kept for the time being
                cat <<EOF > view_layers.cdo
q = QA > 0 ? QA : QA + 65536;
EOF
i=0
                while [ $i -lt 4 ]; do
                    ((i++))
                    cat <<EOF >> view_layers.cdo
l${i} = q - 2*floor(q/2);
q = (q-l${i})/2;
EOF
                done
                cdo exprf,view_layers.cdo $file qa_layers.nc
                cdo selname,l2 qa_layers.nc clouds.nc
                cdo selname,l3 qa_layers.nc cloudshadows.nc
                cdo ifnotthen clouds.nc ndviraw$file ndvi$file
                rm ndviraw$file qa$file $file
            fi
        done
        cdo copy ndvi*.nc ndvi_${yr}_dy.nc
        # because of the cloud masking a few glimpses should be enough to get valid data
        ###daily2longerfield ndvi_${yr}_dy.nc 12 mean minfac 15 ndvi_${yr}_mo.nc
        # cdo only demands one valid point and does not attempt to read the 100GB in memory
        cdo -f nc4 -z zip monmean ndvi_${yr}_dy.nc ndvi_${yr}_mo.nc
        # my routine only demand 30% valid data, i.e., in this case 2 out of 4 pixels.
        averagefieldspace ndvi_${yr}_mo.nc 2 2 ../$yrfile
        ###cdo remapcon,r3600x1800 ndvi$file ${file}_01.nc
        rm *.nc
        cd ..
    fi
    ((yr++))
done