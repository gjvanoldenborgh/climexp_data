#!/bin/sh
if [ $HOST != bvlclim.knmi.nl ]; then
  echo "Are you sure you want to run this script on $HOST?"
  read yesno
  if [ $yesno != yes -a $yesno != y ]; then
    exit
  fi
else
  scp -q gjvo@shell.xs4all.nl:WWW/ip.txt $HOME/etc/ip2.txt
fi
echo @@@ GISS
(cd NASAData; ./update.sh | 2>&1 tee update.log)
(cd NASAData; ./update_fields.sh | 2>&1 tee update_fields.log)
echo @@@ NCDC
(cd NCDCData; ./update_indices.sh | 2>&1 tee update_indices.log)
(cd NCDCData; ./update_fields.sh | 2>&1 tee update_fields.log)
echo @@@ "NCEP (for weekly & daily data)"
(cd NCEPData; ./update_indices.sh  | 2>&1 tee update_indices.log)
echo @@@ CRU
(cd CRUData; ./update_indices.sh  | 2>&1 tee update_indices.log)
(cd CRUData; ./update_fields.sh   | 2>&1 tee update_fields.log)
echo @@@ UKMO
(cd UKMOData; ./update_indices.sh | 2>&1 tee update_indices.log)
(cd UKMOData; ./update_fields.sh  | 2>&1 tee update_fields.log)
###(cd UKMOData; ./update_hadslp2.sh | 2>&1 tee update_hadslp2.log)
(cd UKMOData; ./update_amo.sh  | 2>&1 tee update_amo.log)
(cd CRUData; ./merge_crutem3_hadsst2.sh | 2>&1 tee update_merge.log)
echo @@@ YorkData
(cd YorkData; ./update_indices.sh | 2>&1 tee update_indices.log)
(cd YorkData; ./update_fields.sh | 2>&1 tee update_fields.log)
echo @@@ NODC
(cd NODCData; ./update.sh | 2>&1 tee update.log )
###echo @@@TRMM
###(cd TRMMData; ./update.sh | 2>&1 tee update.log)

echo @@@ finished @@@
