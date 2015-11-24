#!/bin/sh
#wget -N http://lasp.colorado.edu/data/sorce/tsi_data/TSI_TIM_Reconstruction.txt
#sed -e 's/Year   //' -e 's/2]/2] Total Solar Irradiance/' TSI_TIM_Reconstruction.txt | tr ';' '#' > TSI_TIM_Reconstruction.dat

make tenday2month
base=http://sealevel.colorado.edu/files/current/
for region in global \
    Pacific_Ocean Atlantic_Ocean Indian_Ocean \
    Adriatic_Sea Andaman_Sea Arabian_Sea Bay_of_Bengal Bering_Sea Carribean_Sea Gulf_of_Alaska Gulf_of_Mexico Indonesian_Throughflow Mediterranean_Sea Japan-East_Sea South_China_Sea Yellow_Sea Maldives
do
    for prefix in sl_ sl_ib_
    do
        file=$prefix$region.txt
        wget -N $base/$file
        ./tenday2month $file > `basename $file .txt`.dat
    done
done
$HOME/NINO/copyfiles.sh sl*.dat TSI_TIM_Reconstruction.dat
