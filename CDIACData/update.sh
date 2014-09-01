#!/bin/csh -f
make maunaloa2dat

cp co2_mm_mlo.txt co2_mm_mlo.txt.old
wget -N ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_mlo.txt
diff co2_mm_mlo.txt co2_mm_mlo.txt.old
if ( $status ) then
   echo "new file differs from old one"
   mv maunaloa.dat maunaloa.dat.old
   ./maunaloa2dat mlo
   fillin 3 maunaloa.dat > maunaloa_f.dat
else
   mv co2_mm_mlo.dat.old co2_mm_mlo.dat
endif
operate log maunaloa_f.dat > aap.dat
scaleseries 2.30258509299405 aap.dat > maunaloa_log.dat
$HOME/NINO/copyfilesall.sh maunaloa.dat maunaloa_f.dat maunaloa_log.dat

cp co2_mm_gl.txt co2_mm_gl.txt.old
wget -N ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_gl.txt
diff co2_mm_gl.txt co2_mm_gl.txt.old
if ( $status ) then
   echo "new file differs from old one"
   mv co2.dat co2.dat.old
   ./maunaloa2dat gl
else
   mv co2_mm_mlo.dat.old co2_mm_mlo.dat
endif
cp co2_annual.in co2_annual.dat
yearly2shorter co2_annual.dat 12 month 1 ave 12 > aap.dat
patchseries aap.dat co2.dat > co2_monthly.dat
daily2longer co2_monthly.dat 1 mean > co2_annual.dat
yearly2shorter co2_annual.dat 12 > co2_monthly.dat
operate log co2_monthly.dat > aap.dat
scaleseries 2.30258509299405 aap.dat > co2_log.dat
$HOME/NINO/copyfilesall.sh co2.dat co2_annual.dat co2_monthly.dat co2_log.dat

wget -N ftp://ftp.cmdl.noaa.gov/ccg/ch4/in-situ/mlo/mlo_01C0_mm.ch4
cat > maunaloa_ch4.dat <<EOF
# Methane concentrations from Mauna Loa via <a href="ftp://ftp.cmdl.noaa.gov/ccg/ch4/in-situ/README_insitu_ch4.html">ESRL/GMD</a>
# CH4 [ppb] methane concntration at Mauna Loa
EOF
egrep '^MLO' mlo_01C0_mm.ch4 | cut -b 5-20 >>  maunaloa_ch4.dat
$HOME/NINO/copyfilesall.sh maunaloa_ch4.dat
