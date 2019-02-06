#!/bin/sh

# CO2

make maunaloa2dat
cp co2_mm_mlo.txt co2_mm_mlo.txt.old
wget -N ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_mlo.txt
diff co2_mm_mlo.txt co2_mm_mlo.txt.old
if [ $? != 0 -o "$1" = force ]; then
   echo "new file differs from old one"
   mv maunaloa.dat maunaloa.dat.old
   ./maunaloa2dat mlo
   fillin 3 maunaloa.dat > maunaloa_f.dat
else
   mv co2_mm_mlo.dat.old co2_mm_mlo.dat
fi
operate log maunaloa_f.dat > maunaloa_ln.dat
scaleseries 2.30258509299405 maunaloa_ln.dat > maunaloa_log.dat
$HOME/NINO/copyfilesall.sh maunaloa.dat maunaloa_f.dat maunaloa_log.dat

cp co2_mm_gl.txt co2_mm_gl.txt.old
wget -N ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_gl.txt
diff co2_mm_gl.txt co2_mm_gl.txt.old
if [ $? != 0 -o "$1" = force ]; then
   echo "new file differs from old one"
   mv co2.dat co2.dat.old
   ./maunaloa2dat gl
else
   mv co2_mm_mlo.dat.old co2_mm_mlo.dat
fi

if [ ! -s law2006.txt ]; then
    wget --no-check-certificate https://www1.ncdc.noaa.gov/pub/data/paleo/icecore/antarctica/law/law2006.txt
    cat > co2_annual.in <<EOF
# Spline fits to the Law Dome firn and ice core records and the Cape Grim record 0001-2004. October 2008.
# co2 [ppm] CO2 concentration
# institution :: CSIRO Marine and Atmospheric Research via NCEI
# authors :: MacFarling Meure, C.; Etheridge, D.M.; Trudinger, C.; Steele, P.; Langenfelds, R.L.; van Ommen, T.D.; Smith, A.M.; Elkins, J.
# contact :: david.etheridge@csiro.au
# references :: Etheridge, D.M., L.P. Steele, R.L. Langenfelds, R.J. Francey, J.-M. Barnola, and V.I. Morgan.  1996. Natural and anthropogenic changes in atmospheric CO2 over the last 1000 years from air in Antarctic ice and firn. Journal of Geophysical Research, 101, 4115-4128.
# source_url :: https://www1.ncdc.noaa.gov/pub/data/paleo/icecore/antarctica/law/law2006.txt
# source :: https://www.ncdc.noaa.gov/paleo-search/study/9959
# description :: Law Dome ice core (DSS, DE08 and DE08-2), firn air (DSSW20K), and Cape Grim instrumental (deseasonalised archive, insitu and flask) records of CO2 concentrations for the past 2000 years.
# history :: retrieved from NCEI `date`
# climexp_url :: http://climexp.knmi.nl/getindices.cgi?CDIACData/co2_monthly
EOF
    cat law2006.txt | sed -e '1,/YearAD/d' -e '/CO2 by Core/,$d' | cut -b 1-4,42-48 >> co2_annual.in
fi
cp co2_annual.in co2_annual.dat
yearly2shorter co2_annual.dat 12 month 1 ave 12 > co2_annual_12.dat
patchseries co2.dat co2_annual_12.dat bias > co2_annual_12_combined.dat
patchseries co2_annual_12_combined.dat maunaloa.dat bias > co2_reallymonthly.dat
daily2longer co2_reallymonthly.dat 1 mean > co2_annual.dat
yearly2shorter co2_annual.dat 12 > co2_monthly.dat
operate log co2_monthly.dat > co2_ln.dat
scaleseries 2.30258509299405 co2_ln.dat > co2_log.dat
$HOME/NINO/copyfilesall.sh co2.dat co2_annual.dat co2_monthly.dat co2_log.dat

# CH4

wget -N ftp://aftp.cmdl.noaa.gov/products/trends/ch4/ch4_mm_gl.txt
cat > ch4_monthly.dat <<EOF
# Global marine CH4 concentrations from <a href="https://www.esrl.noaa.gov/gmd/ccgg/trends_ch4/#global">ESRL/GMD</a>
# CH4 [ppb] methane concntration
# institution :: NOAA/ESRL
# source :: https://www.esrl.noaa.gov/gmd/ccgg/trends_ch4/#global
# source_url ::  ftp://aftp.cmdl.noaa.gov/products/trends/ch4/ch4_mm_gl.txt
# contact :: ed.dlugokencky@noaa.gov
# references :: Dlugokencky, E. J., L. P. Steele, P. M. Lang, and K. A. Masarie (1994), The growth rate and distribution of atmospheric methane, J. Geophys. Res., 99, 17,021– 17,043, doi:10.1029/94JD01245.
# history :: retrieved `date`
# climexp_url :: ttp://climexp.knmi.nl/getindices.cgi?CDIACData/ch4_monthly
EOF
cat ch4_mm_gl.txt | sed -e '1,/# year/d' | cut -b 3-6,12-14,34-43 >>  ch4_monthly.dat

if [ ! -s ch4_annual.in ]; then
    cat > ch4_annual.in <<EOF
# Spline fits to the Law Dome firn and ice core records and the Cape Grim record 0001-2004. October 2008.
# ch4 [ppb] CH4 concentration
# institution :: CSIRO Marine and Atmospheric Research via NCEI
# authors :: MacFarling Meure, C.; Etheridge, D.M.; Trudinger, C.; Steele, P.; Langenfelds, R.L.; van Ommen, T.D.; Smith, A.M.; Elkins, J.
# contact :: david.etheridge@csiro.au
# references :: Etheridge, D.M., L.P. Steele, R.L. Langenfelds, R.J. Francey, J.-M. Barnola, and V.I. Morgan.  1996. Natural and anthropogenic changes in atmospheric CO2 over the last 1000 years from air in Antarctic ice and firn. Journal of Geophysical Research, 101, 4115-4128.
# source_url :: https://www1.ncdc.noaa.gov/pub/data/paleo/icecore/antarctica/law/law2006.txt
# source :: https://www.ncdc.noaa.gov/paleo-search/study/9959
# description :: Law Dome ice core (DSS, DE08 and DE08-2), firn air (DSSW20K), and Cape Grim instrumental (deseasonalised archive, insitu and flask) records of CO2 concentrations for the past 2000 years.
# history :: retrieved from NCEI `date`
# climexp_url :: http://climexp.knmi.nl/getindices.cgi?CDIACData/ch4_annual
EOF
    cat law2006.txt | sed -e '1,/YearAD/d' -e '/CO2 by Core/,$d' | cut -b 1-14 >> ch4_annual.in
fi
daily2longer ch4_monthly.dat 1 mean > ch4_annual_modern.dat
patchseries ch4_annual_modern.dat ch4_annual.in bias > ch4_annual.dat

$HOME/NINO/copyfilesall.sh ch4_monthly.dat ch4_annual.dat

# emissions (update by hand every year...)

if [ ! -s global_co2_emissions.dat ]; then

# wget -N https://data.icos-cp.eu/licence_accept?ids=%5B%22-OrQ3afxxWEwG-LMJDyfVRot%22%5D
# convert "historucal budget" to csv
    for type in fossil landuse emissions; do
        cat > global_co2_$type.dat <<EOF
# Global CO2 $type from <a href="http://www.globalcarbonproject.org/carbonbudget/17/data.htm">Global Carbon Project</a>
# CO2 [MtC/yr] global CO2 $type
# institution :: Global Carbon Project
# source :: http://www.globalcarbonproject.org/carbonbudget/17/data.htm
# source_url :: https://data.icos-cp.eu/licence_accept?ids=%5B%22-OrQ3afxxWEwG-LMJDyfVRot%22%5D
# doi :: https://doi.org/10.18160/GCP-2017
# references :: Le Quéré et al. (2017) https://doi.org/10.5194/essd-2017-123.
# history :: retrived `date`
# climexp_url ::  http://climexp.knmi.nl/getindices.cgi?CDIACData/global_co2_$type
EOF
    done
    egrep '^[12]' Global_Carbon_Budget_2017v1.2.csv | sed -e 's/;;/;0.;/g' | cut -d ';' -f 1,2 | tr ',;' '. ' | fgrep -v 1750 >> global_co2_fossil.dat
    egrep '^[12]' Global_Carbon_Budget_2017v1.2.csv | sed -e 's/;;/;0.;/g' | cut -d ';' -f 1,3 | tr ',;' '. ' | fgrep -v 1750 >> global_co2_landuse.dat
    normdiff global_co2_fossil.dat global_co2_landuse.dat full full add | fgrep -v '#' >> global_co2_emissions.dat

    cumul global_co2_emissions.dat > aap.dat
    scaleseries 0.001 aap.dat > noot.dat
    sed -e 's/# CO2/# cumCO2/' -e 's@MtC/yr@GtC@' -e 's/global/cumulative global/' noot.dat > cum_global_co2_emissions.dat
    $HOME/NINO/copyfilesall.sh *global_co2*.dat

fi