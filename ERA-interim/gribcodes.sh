#!/bin/sh
fac=1
case $var in
    t2m) par=167; long_name="2m temperature"; units="K";;
    tmin) par=122; long_name="daily minimum of 2m temperature";units="K";;
    tmax) par=121; long_name="daily maximum of 2m temperature";units="K";;
    ts)  par=139; long_name="surface temperature"; units="K";;
    msl) par=151; long_name="mean sea-level pressure"; units="Pa";;
    z500) par=129; long_name="500hPa geopotential"; units="m2 s-2";;
    u10) par=165; long_name="10m zonal wind"; units="m/s";;
    v10) par=166; long_name="10m meridional wind"; units="m/s";;
    wspd) par=207; long_name="wind speed"; units="m/s";;
    tp)  par=228; long_name="precipitation"; units="mm/dy";fac=0.001;;
    evap) par=182; long_name="evaporation"; units="m/dy";fac=2;;
    ustrs) par=180; long_name="zonal wind stress"; units="N/m2";fac=172800;;
    vstrs) par=181; long_name="meridional wind stress"; units="N/m2";fac=172800;;
    lhtfl) par=147; long_name="latent heat flux"; units="J/dy/m2";fac=2;;
    shtfl) par=146; long_name="sensible heat flux"; units="J/dy/m2";fac=2;;
    ssr) par=176; long_name="surface solar radiation"; units="J/dy/m2";fac=2;;
    str) par=177; long_name="surface thermal radiation"; units="J/dy/m2";fac=2;;
*) echo "unknown var $var"; exit -1;;
esac
