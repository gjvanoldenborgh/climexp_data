#!/bin/sh
base=ftp://tarot.sr.unh.edu/LU_harmonization/

if [ 1 = 0 ]; then
wget -N $base/LUHa.v1/LUHa_u2.v1.tgz
wget -N $base/LUHa.v1/LUHa_u2t1.v1.tgz

# RCP26
wget -N $base/LUHa.v1_future.v1/IMAGE/LUHa_u2.v1_image.v1.tgz
wget -N $base/LUHa.v1_future.v1/IMAGE/LUHa_u2t1.v1_image.v1.tgz

# RCP45
wget -N $base/LUHa.rc2_future.rc2/MiniCAM/LUHa_u2.rc2_minicam.rc2.tgz
wget -N $base/LUHa.rc2_future.rc2/MiniCAM/LUHa_u2t1.rc2_minicam.rc2.tgz

# RCP85
wget -N $base/LUHa.v1_future.v1/MESSAGE/LUHa_u2.v1_message.v1.tgz
wget -N $base/LUHa.v1_future.v1/MESSAGE/LUHa_u2t1.v1_message.v1.tgz

wget -N $base/LUHa.rc2_future.rc2/gicew.1700.txt

# historical - I do not have disk space to extract everything...
if [ ! -d updated_states_hist ]; then
    tar zxf LUHa_u2.v1.tgz updated_states/gcrop\* updated_states/gothr\* updated_states/gpast\* updated_states/gsecd\* updated_states/gurbn\*
    mv updated_states updated_states_hist
fi


# image (RCP26)
if [ ! -d updated_states_rcp26 ]; then
    tar zxf LUHa_u2.v1_image.v1.tgz updated_states/gcrop\* updated_states/gothr\* updated_states/gpast\* updated_states/gsecd\* updated_states/gurbn\*
    mv updated_states updated_states_rcp26
fi

# minicam (RCP45)
if [ ! -d updated_states_rcp45 ]; then
    tar zxf LUHa_u2.rc2_minicam.rc2.tgz updated_states/gcrop\* updated_states/gothr\* updated_states/gpast\* updated_states/gsecd\* updated_states/gurbn\*
    mv updated_states updated_states_rcp45
fi

# message (RCP85)
if [ ! -d updated_states_rcp85 ]; then
    tar zxf LUHa_u2.v1_message.v1.tgz updated_states/gcrop\* updated_states/gothr\* updated_states/gpast\* updated_states/gsecd\* updated_states/gurbn\*
    mv updated_states updated_states_rcp85
fi


for rcp in rcp26 rcp45 rcp85
do
  for type in gcrop gothr gpast gsecd gurbn
  do
    ./ascii2grads $type $rcp
  done
done

fi

for rcp in rcp26 rcp45 rcp85
do
  for type in gcrop gothr gpast gsecd gurbn
  do
    averagefieldspace ${rcp}_${type}_05.ctl 2 2 ${rcp}_${type}_10.ctl
    averagefieldspace ${rcp}_${type}_05.ctl 5 5 ${rcp}_${type}_25.ctl
  done
done
