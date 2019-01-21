#!/bin/bash
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
(ssh zuidzee "cd NINO/NASAData; ./update.sh |& tee update.log")
(ssh zuidzee "cd NINO/NASAData; ./update_fields.sh |& tee update_fields.log")
echo @@@ NCDC
(cd NCDCData; ./update_indices.sh | 2>&1 tee update_indices.log)
(cd NCDCData; ./update_fields.sh | 2>&1 tee update_fields.log)
echo @@@ "NCEP (for weekly & daily data)"
(cd NCEPData; ./update_indices.sh  | 2>&1 tee update_indices.log)
echo @@@ CRU
(cd CRUData; ./update_indices.sh  | 2>&1 tee update_indices.log)
###(cd CRUData; ./update_fields.sh   | 2>&1 tee update_fields.log)
echo @@@ UKMO
(cd UKMOData; ./update_indices.sh | 2>&1 tee update_indices.log)
(cd UKMOData; ./update_fields.sh  | 2>&1 tee update_fields.log)
###(cd UKMOData; ./update_hadslp2.sh | 2>&1 tee update_hadslp2.log)
(cd UKMOData; ./update_amo.sh  | 2>&1 tee update_amo.log)
echo @@@ YorkData
(cd YorkData; ./update_indices.sh | 2>&1 tee update_indices.log)
(cd YorkData; ./update_fields.sh | 2>&1 tee update_fields.log)
echo @@@ NODC
(cd NODCData; ./update.sh | 2>&1 tee update.log )
echo @@@ JAMSTEC
(cd JAMSTECData; ./update.sh | 2>&1 tee update.log )
echo @@@ Rutgers
(ssh zuidzee "cd NINO/RutgersData; ./update.sh |& tee update.log")
(ssh zuidzee "cd NINO/RutgersData; ./update_fields.sh |& tee update.log")
echo @@@ MERRA
(ssh zuidzee "cd NINO/MERRA; ./update_fields.sh |& tee update_fields.log")

echo @@@ finished @@@
