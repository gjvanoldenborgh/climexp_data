#!/bin/sh
for file in *stn.nc; do
    echo $file
    mv $file $file.bak
    cdo setctomiss,-999 $file.bak $file
done