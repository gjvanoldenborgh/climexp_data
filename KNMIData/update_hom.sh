#!/bin/sh
mv tg_hom_mnd260.txt tg_hom_mnd260.txt.old
wget http://projects.knmi.nl/klimatologie/onderzoeksgegevens/homogeen_260/tg_hom_mnd260.txt
diff tg_hom_mnd260.txt.old tg_hom_mnd260.txt
if [ $? = 0 ]; then
  echo no changes
  mv tg_hom_mnd260.txt.old tg_hom_mnd260.txt
  exit
fi
./homtxt2dat < tg_hom_mnd260.txt  tr -s '
' > Tdebilt_hom.dat
$HOME/NINO/copyfiles.sh Tdebilt_hom.dat
