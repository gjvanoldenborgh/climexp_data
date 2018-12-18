#!/bin/sh
# Maue's ACE series
#
wget -q -N http://wx.graphics/tropical/global_ace.dat
for region in nepac natl wpac nio nh sh global; do
    case $region in
        nepac) col=2;name="Northeast Pacific";;
        natl) col=3;name="North Atlantic";;
        wpac) col=4;name="West Pacific";;
        nio) col=5;name="North Indian Ocean";;
        nh) col=6;name="Northern Hemisphere";;
        sh) col=7;name="Southern Hemisphere";;
        global) col=8;name="whole globe";;
        *) echo "$0: error: unknown region $region";exit -1;;
    esac
    cat > ace_$region.dat <<EOF
# Maue Tropical Accumulated Cycone Energy
# references :: Maue, 2011. Recent historically low global tropical cyclone activity, GRL, 38, L14803, doi:10.1029/2011GL047711
# references :: <a href="http://policlimate.com/tropical/maue_2011gl047711-readme.txt">aux.mat.</a>
# source :: <a href="http://wx.graphics/tropical/">wx.graphics</a>
# source_url :: http://wx.graphics/tropical/global_ace.dat
# ACE [10^4 kn^2] Accumulated Cycone Energy for the $name
EOF
    tail -n +5 global_ace.dat | cut  -d "	" -f 1,$col > aap.dat
    sed -e "s@\(..\)/\(..\)/\(....\)@\3\1\2@" aap.dat >> ace_$region.dat
done
$HOME/NINO/copyfiles.sh ace_*.dat