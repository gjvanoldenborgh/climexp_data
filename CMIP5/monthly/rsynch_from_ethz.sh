#!/bin/sh
types=LImon # "fx Amon Omon Lmon OImon Amon3D"
fvars="areacella areacello deptho orog sftlf sftof"
avars="tas tasmin tasmax pr evspsbl huss prw clwvi psl rlds rlus rlut rsds rsus rsdt rsut hfss hfls rldscs rlutcs rsdscs rsuscs rsutcs"
avars3d="ta zg"
ovars="tos sos zosga zossga zostoga msftmyz msftyyz msftmrhoz msftbarot mlotst"
oivars="sic"
lvars="mrso mrro mrros"
livars="snc"
models="ACCESS1-0 ACCESS1-3 bcc-csm1-1 bcc-csm1-1-m BNU-ESM CanESM2 CCSM4 CESM1-BGC CESM1-CAM5 CESM1-CAM5-1-FV2 CESM1-FASTCHEM CESM1-WACCM CMCC-CM CMCC-CMS CMCC-CESM CNRM-CM5 CSIRO-Mk3-6-0 EC-EARTH FGOALS-g2 FIO-ESM GFDL-CM3 GFDL-ESM2G GFDL-ESM2M GISS-E2-H GISS-E2-H-CC GISS-E2-R GISS-E2-R-CC HadGEM2-AO HadGEM2-CC HadGEM2-ES inmcm4 IPSL-CM5A-LR IPSL-CM5A-MR IPSL-CM5B-LR MIROC5 MIROC-ESM MIROC-ESM-CHEM MPI-ESM-LR MPI-ESM-MR MPI-ESM-P MRI-CGCM3 MRI-ESM1 NorESM1-M NorESM1-ME"
exps="historical rcp26 rcp45 rcp60 rcp85"

###find -L ethz > ethz/filelist.old
for exp in $exps
do
	for model in $models 
	do
		for type in $types
		do
			class=$type
			case $type in
				fx) vars=$fvars;;
				Amon) vars=$avars;;
				Amon3D) vars=$avars3d;class=Amon;;
				Omon) vars=$ovars;;
				Lmon) vars=$lvars;;
				OImon) vars=$oivars;;
				LImon) vars=$livars;;
				*) echo "$0: error: unknown type $type"; exit -1;;
			esac
			for var in $vars
			do
				dir=ethz/cmip5/$exp/${class}/$var/$model
				mkdir -p $dir
				echo "============= $exp $model $var ==============="
				RSYNC_PASSWORD=getdata rsync -vrlpt cmip5user@atmos.ethz.ch::cmip5-ar5-wg1/$exp/${class}/$var/$model/ $dir
			done
		done
	done
done
###find -L ethz > ethz/filelist.new
###diff ethz/filelist.old ethz/filelist.new
