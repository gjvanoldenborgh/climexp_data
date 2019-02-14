#!/bin/bash
# to be ran on the 10th of each month

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

echo "@@@ University of Colorado (sealevel)"
(cd CUData; ./update_indices.sh | 2>&1 tee update.log)

echo "@@@ AVISO"
(cd AVISOData; ./update_indices.sh | 2>&1 tee update.log)

echo "@@@ other sea level indices"
(cd SiegenData; ./update.sh | 2>&1 tee update.log)
(cd CSIROData; ./update.sh | 2>&1 tee update.log)

###echo @@@ LOD  moved
###cd IERSData; ./update.sh | 2>&1 tee update.log)

echo @@@ sunspots
(cd SIDCData; ./update.sh | 2>&1 tee update.log)

echo @@@ solar radio flux
(cd SRMPData; ./update.sh | 2>&1 tee update.log)

echo @@@ Mauna Loa
(cd CDIACData; ./update.sh | 2>&1 tee update.log)

echo @@@ AOML
(cd AOMLData; ./update_indices.sh | 2>&1 tee update.log)

echo @@@ NOC
(cd NOCData; ./update.sh | 2>&1 tee update.log)

echo @@@ BAS
(cd BASData; ./update_indices.sh | 2>&1 tee update.log)

echo @@@ PMOD
(cd PMODData; ./update_indices.sh | 2>&1 tee update.log)

echo @@@ Rutgers
(cd RutgersData; ./update.sh | 2>&1 tee update.log)
(cd RutgersData; ./update_fields.sh | 2>&1 tee update.log)

echo @@@ UW
(cd UWData; ./update.sh | 2>&1 tee update.log)

echo @@@ GRACE
(cd GRACEData; ./update.sh | 2>&1 tee update.log)

echo @@@ MeteoSwiss
(cd MeteoSwissData; ./update.sh  | 2>&1 tee update.log )

echo @@@ WX
(cd WXData; ./update.sh  | 2>&1 tee update.log )

echo @@@ GPCC
(cd GPCCData; ./update.sh | 2>&1 tee update.log)

echo @@@ GPCP
(cd GPCPData; ./update.sh | 2>&1 tee update.log)

echo @@@ UMD/NOAA OLR
(cd UMDData; ./update.sh | 2>&1 tee update.log)

echo @@@ CHIRPS
(cd CHIRPSData; ./update_chirps.sh | 2>&1 tee update.log)

echo @@@ TEMIS
(cd TEMISData; ./update.sh | 2>&1 tee update.log)

echo @@@ NOAA OLR
(cd NOAAData; ./update.sh | 2>&1 tee update.log)

###echo @@@ Snow
###(cd SnowData; ./update.sh | 2>&1 tee update.log)

echo @@@ NSIDC
(cd NSIDCData; ./update_fields.sh | 2>&1 tee update_fields.log)
(cd NSIDCData; ./update_indices.sh | 2>&1 tee update_indices.log)

echo @@@ NCEP
(cd NCEPData; ./update_indices.sh | 2>&1 tee update_indices.log)
(cd NCEPData; ./update_fields.sh | 2>&1 tee update_field.log)
(cd NCEPData; ./update_ghcn_cams.sh | 2>&1 tee update_ghcn_cams.log)

###echo @@@ PSMSL
###(cd PSMSLData; ./update.sh | 2>&1 tee update.log)

echo @@@ TAO
(cd TAOData; ./update.sh | 2>&1 tee update.log)

echo @@@ BMRC
(cd BMRCData; ./update.sh | 2>&1 tee update.log)

echo @@@ NCDC
(cd NCDCData; ./update_indices.sh | 2>&1 tee update_indices.log)
(cd NCDCData; ./update_fields.sh | 2>&1 tee update_fields.log)

echo @@@ MBARI
(cd MBARIData; ./update.sh | 2>&1 tee update.log)

echo @@@ UCAR
(cd UCARData; ./update.sh | 2>&1 tee update.log)

echo @@@ COADS
(cd COADSData; ./update.sh | 2>&1 tee update.log)

echo @@@ ECA
(cd ECAData; ./update.sh | 2>&1 tee update.log)

echo @@@ E-OBS
(cd ENSEMBLES; ./update_field_ensemble.sh | 2>&1 tee update.log)

echo @@@ GHCN
(cd NCDCData; ./update_series_v2.sh | 2>&1 tee update_series.log)
(cd NCDCData; ./update_series.sh | 2>&1 tee update_series.log)

echo @@@ MSU
(cd UAHData; ./update_field.sh | 2>&1 tee update_field.log)

echo @@@ UMainz
(cd MainzData; ./update.sh  | 2>&1 tee update.log )

echo @@@ NCEP/NCAR reanalysis indices
(cd NCEPNCAR40; ./update_indices.sh | 2>&1 tee update_indices.log)

echo @@@ NCEP/NCAR reanalysis 2D
(cd NCEPNCAR40; ./update2d.sh | 2>&1 tee update2d.log)

echo @@@ NCEP/NCAR reanalysis 3D
(cd NCEPNCAR40; ./update3d.sh | 2>&1 tee update3d.log)

echo @@@ NCEP/NCAR daily
(cd NCEPNCAR40; ./update_daily.sh | 2>&1 tee update_daily.log)

if [ $HOST = pc160050.knmi.nl ]; then
    echo @@@ ERA-interim
    (cd ERA-interim; ./update_indices.sh | 2>&1 tee update_indices.log)
    (cd ERA-interim; ./update.sh | 2>&1 tee update.log)

    echo @@@ ERA5
    (cd ERA5; ./update_monthly.sh | 2>&1 tee update_monthly.log)
    (cd ERA5; ./update_daily.sh | 2>&1 tee update_daily.log)
fi

echo @@@ GHCN-D
(cd GDCNData; ./update.sh  | 2>&1 tee update.log )

echo @@@ SSMI
(cd SSMIData; ./update.sh | 2>&1 tee update.log)

echo @@@ NCEP daily SST
(cd NCEPData; ./update_sstoiv2_daily.sh | 2>&1 tee update_sstoiv2_daily.log)

echo @@@ PRISM
(cd PRISMData; ./update.sh | 2>&1 tee update.log)

###echo @@@ Berkeley
###(cd BerkeleyData; ./update.sh | 2>&1 tee update.log)

echo @@@ finished @@@
