#!/bin/bash
export LANG=C
infile="$1"
vars="CO2_ERF Other_Well_mixed_GHG_ERF Tropospheric_O3_ERF Stratospheric_O3_ERF RFari total_aerosol_ERF \
land_use_change_ERF stratospheric_water_vapour_ERF black_carbon_snow_ERF Contrails_ERF Solar_ERF \
Volcanic_ERF Total_ERF Anthropogenic_total_ERF"
col=1
for var in $vars; do
    lvar=
    case $col in
        1) lvar="CO2 ERF";;
        2) lvar="other well-mixed greenhouse gases ERF";;
        3) lvar="tropospheric ozone ERF";;
        4) lvar="stratospheric ozone ERF";;
        5) lvar="aerosol-radiation intercations ERF";;
        6) lvar="total aerosol ERF";;
        7) lvar="Land Use Changes ERF";;
        8) lvar="stratospheric water vapour ERF";;
        9) lvar="black carbon on snow ERF";;
        10) lvar="Contrails ERF";;
        11) lvar="Solar ERF";;
        12) lvar="Volcanic ERF";;
        13) lvar="total ERF";;
        14) lvar="total anthropogenic ERF";;
        *) echo "unknown column $col";exit -1;;
    esac
    outfile=$var.dat
    cat > $outfile <<EOF
# $var [W/m2] $lvar
# from IPCC AR5, extended by Dessler and Foster, JGR, https://doi.org/10.1029/2018JD028481.
# contact :: P.M.Forster@leeds.ac.uk
# references :: Myhre, G., D. Shindell, F.-M. Bréon, W. Collins, J. Fuglestvedt, J. Huang, D. Koch, J.-F. Lamarque, D. Lee, B. Mendoza, T. Nakajima, A. Robock, G. Stephens, T. Takemura and H. Zhang, 2013: Anthropogenic and Natural Radiative Forcing. In: Climate Change 2013: The Physical Science Basis. Contribution of Working Group I to the Fifth Assessment Report of the Intergovernmental Panel on Climate Change [Stocker, T.F., D. Qin, G.-K. Plattner, M. Tignor, S.K. Allen, J. Boschung, A. Nauels, Y. Xia, V. Bex and P.M. Midgley (eds.)]. Cambridge University Press, Cambridge, United Kingdom and New York, NY, USA.
# references :: Dessler, A.E. and P.M. Forster, JGR,  https://doi.org/10.1029/2018JD028481
EOF
    if [ $var = CO2_ERF -o $var = Other_Well_mixed_GHG_ERF ]; then
        echo "# Forcing from CO2, N2O, and CH4 has been replaced by calculating new forcing time series using concentrations from https://www.esrl.noaa.gov/gmd/ccgg/trends/ with updated formulae to convert mixing ratios to forcing (Etminan et al., 2016)." >> $outfile
    fi
    if [ $var = Tropospheric_O3_ERF -o $var = Stratospheric_O3_ERF -o $var = RFari -o $var = total_aerosol_ERF ]; then
        echo "# references :: Myhre, G., Aas, W., Cherian, R., Collins, W., Faluvegi, G., Flanner, M., et al. (2017). Multi‐model simulations of aerosol and ozone radiative forcing due to anthropogenic emission changes during the period 1990–2015. Atmospheric Chemistry and Physics, 17( 4), 2709– 2720. https://doi.org/10.5194/acp‐17‐2709‐2017" >> $outfile
    fi
    if [ $var = Volcanic_ERF ]; then
        echo "# references :: Andersson, S. M., Martinsson, B. G., Vernier, J.‐P., Friberg, J., Brenninkmeijer, C. A. M., Hermann, M., et al. (2015). Significant radiative impact of volcanic aerosol in the lowermost stratosphere. Nature Communications, 6( 1), 7692. https://doi.org/10.1038/ncomms8692" >> $outfile
    fi
    if [ $var = Solar_ERF ]; then
        echo "# references :: Lean, J., Rottman, G., Harder, J., & Kopp, G. (2005). SORCE contributions to new understanding of global change and solar variability. Solar Physics, 230( 1‐2), 27– 53. https://doi.org/10.1007/s11207‐005‐1527‐2" >> $outfile
    fi
    echo "# climexp_url :: https://climexp.knmi.nl/getindices.cgi?LeedsData/$var" >> $outfile
    echo "# history :: converted from $infile on `date`" >> $outfile
    ((col++))
    egrep '^[12]' "$infile" | egrep -v '^20..,|http|onward' | cut -d ';' -f 1,$col | tr ',;' '. ' >> $outfile
    egrep '^20..,541' "$infile" | sed -e 's/,541096//' | cut -d ';' -f 1,$col | tr ',;' '. ' >> $outfile
done
$HOME/NINO/copyfilesall.sh *.dat