#!/bin/bash

# convert the spread sheets of Ruud Noordhuis to my format. 
# first I saved them as csv in Excel.

# Lobith

# metadata. Hmm, not much
outfile=debiet_lobith.dat
cat > $outfile <<EOF
# Historical daily discharge data from Deltares
# history: :: 06-dec-2018 received from Ruurd.Noordhuis@deltares.nl
# discharge [m^3/s] discharge of the Rhine at Lobith
EOF

file1="debiet Lobith 1901-1915 tabel.csv"
# this file has a single column of values preceded by the date (twice)
# take rows with data, change seperator to space, change decimal comma to point
egrep '^[0-9]' "$file1" | tr ';,' ' .' | awk '{print $4 " " $3 " " $2 " " $5}' >> $outfile

file2="debiet Lobith 1950-2016 tabel.csv"
# this file first has monthly means, and next the data in the format column=yr, row=date
# should do this in python.
gfortran -fbounds-check -o table1950 table1950.f90
./table1950 "$file2" >> $outfile

# Eijsden

# metadata. Hmm, not much
outfile=debiet_eijsden.dat
cat > $outfile <<EOF
# Historical daily discharge data from Deltares
# history: :: 06-dec-2018 received from Ruurd.Noordhuis@deltares.nl
# discharge [m^3/s] discharge of the Meuse at Eijsden
EOF

# note that I added two time -999.9 at the end of the last two lines in th ecsv file by hand.
file2="debiet Eijsden 1950-2016 tabel.csv"
./table1950 "$file2" >> $outfile