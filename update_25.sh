#!/bin/bash
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
(cd RutgersData; ./update.sh | 2>&1 tee update.log)
(cd RutgersData; ./update_fields.sh | 2>&1 tee update.log)
echo "@@@ PSMSL on climexp.knmi.nl"
(ssh climexp.knmi.nl 'cd climexp_data/PSMSLData; ./update.sh | 2>&1 tee update.log')
###echo @@@ MERRA
###(cd MERRA; ./update_fields.sh | 2>&1 tee update_fields.log)

echo @@@ finished @@@
