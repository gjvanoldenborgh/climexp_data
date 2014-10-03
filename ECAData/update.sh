#!/bin/sh
force=false
[ "$1" = force ] && force=true
make txt2dat addyears
base=http://eca.knmi.nl/download
for element in tg tx tn pp rr sd cc
do
    # get data from eca server
    if [ -f ECA_blend_station_$element.txt ]; then
        cp ECA_blend_station_$element.txt ECA_blend_station_$element.txt.old 
    fi
    wget -q -N $base/ECA_blend_station_$element.txt
    if [ ! -s ECA_blend_station_$element.txt ]; then
        echo "download of ECA_blend_station_$element.txt failed"
        exit -1
    fi
    dos2unix -q ECA_blend_station_$element.txt
    chmod go+r ECA_blend_station_$element.txt
    if [ -f ECA_blend_$element.zip ]; then
        cp ECA_blend_$element.zip ECA_blend_$element.zip.old
    fi
    wget -q -N $base/ECA_blend_$element.zip
    if [ ! -s ECA_blend_$element.zip ]; then
        echo "download of ECA_blend_$element.zip failed"
        exit -1
    fi
    cmp ECA_blend_$element.zip ECA_blend_$element.zip.old
    if [ $? != 0 -o $force = true ]; then
        # unpack
        cd data
        unzip -o ../ECA_blend_$element.zip
        rm -f sources.txt stations.txt elements.txt
        rm -f ../years_$element.txt
        for file in *.txt
        do
            output=`../txt2dat $file`
            if [ -z "$output" ]; then
                echo "Something went wrong processing $file"
                exit -1
            fi
            number=`echo $output | cut -d ' ' -f 1`
            echo $output >> ../years_$element.txt
###         ls -l *$element$number.dat
            echo converted $file to $element$number.dat
            for b in b ""
            do
                if [ -f $b$element$number.dat ]
                then
                    gzip -f $b$element$number.dat
                else
                    echo "Something went wrong with $b$element$number.dat"
                fi
            done
            rm $file
        done
        cd ..
        ./addyears $element
        scp data/${element}*.dat.gz bhlclim:climexp/ECAData/data/
        scp data/b${element}*.dat.gz bhlclim:climexp/ECAData/data/
        $HOME/NINO/copyfiles.sh ECA_blend_station_$element.txt.withyears
        $HOME/NINO/copyfiles.sh ECA_nonblend_station_$element.txt.withyears
    fi
done
