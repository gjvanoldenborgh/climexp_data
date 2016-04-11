#!/bin/sh
export PATH=$PATH:$HOME/climexp/bin/
###dat2dat etmgeg_260_2001.dat
###for file in datafiles2/???/*.zip
###do
###  unzip -o $file
###done
# should get the list from a datafile - later
varlist="dd fg fh fn fx t1 sq qq dr pg px pn vn vx ng ug ux un ev dx dy tg tx tn rh"
stationlist="210 235 240 242 249 251 257 260 265 267 269 270 273 275 277 278 279 280 283 286 290 310 319 323 330 340 344 348 350 356 370 375 377 380 391"
for station in $stationlist
do
###    for var in DDVEC FG FHX FHN FXX TG TN TX T10N SQ SP Q DR RH PG PX PN VVN VVX NG UG UX UN EV24
###    do
###	if [ ! -s ${var}_$station.txt ]; then
###	    wget -O ${var}_$station.txt --post-data="start=19010101&vars=$var&stns=$station" http://projects.knmi.nl/klimatologie/daggegevens/getdata_dag.cgi
###	fi
###    done
    [ -f etmgeg_$station.txt ] && mv etmgeg_$station.txt etmgeg_$station.old
    echo -n "$station "
    wget -q -O etmgeg_$station.txt --post-data="start=19010101&vars=DDVEC:FG:FHX:FHN:FXX:TG:TN:TX:T10N:SQ:SP:Q:DR:RH:PG:PX:PN:VVN:VVX:NG:UG:UX:UN:EV24&stns=$station" http://projects.knmi.nl/klimatologie/daggegevens/getdata_dag.cgi
    c=`cat etmgeg_$station.txt | wc -c`
    if [ $c -lt 2000 ]; then
      echo "Something went wrong while retrieving etmgeg_$station.txt"
      ls l etmgeg_$station.txt etmgeg_$station.old
      mv etmgeg_$station.old etmgeg_$station.txt
    fi
done

###make dat2dat_all_new
curl http://www.knmi.nl/nederland-nu/weer/actueel-weer/extremen > tabel_opgetreden_extremen.html
./dat2dat_all_new
# remove empty files
for var in $varlist; do
    for station in $stationlist; do
        if [ -f $var$station.dat ]; then
            c=`fgrep -v '#' $var$station.dat | wc -l`
            if [ $c -lt 10 ]; then
                rm  $var$station.dat $var$station.gz
            fi
        fi
    done
done
./merge_hom tx DeBiltTx.v2.txt
./merge_hom tg DeBiltTg.v2.txt
./merge_hom tn DeBiltTn.v2.txt
./update_hourly.sh
for station in $stationlist
do
    if [ -f td$station.dat ]; then
        if [ -s pg$station.dat ]; then
            pres=pg$station.dat
        else
            pres=pg260.dat # use De Bilt instead
        fi
        compute_wetbulb tx$station.dat td$station.dat $pres | sed -e 's/wet bulb temperature/daily max of wet bulb temperature/' > tw$station.dat
        gzip -c tw$station.dat > tw$station.gz
    fi
done
$HOME/NINO/copyfiles.sh ?????.gz ?????.dat rd??????.gz list_??.txt
###make add_pluim
./add_pluim.sh
###./maketxt.sh

###make regen2dat
###./regen2dat
###./maketxt_rd.sh

./update_neerslag.sh
./labrijn2dat > labrijn.dat
./makecnt.sh

$HOME/NINO/copyfilesall.sh precip13stations.dat labrijn.dat cnt.dat tg260_mean12.dat
./extend_homogenised_precip.sh
