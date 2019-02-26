#!/bin/sh
# make the old P13 index of daily precip in the Netherlands from the stations:
# Dit is het lijstje van de L13 neerslag stations:
# KNMI-neerslagstations
#         009 Den Helder / 025 De Kooy
#         011 West Terschelling
#         139 Groningen
#         144 Ter Apel
#         222 Hoorn
#         328 Heerde
#         438 Hoofddorp
#         550 De Bilt
#         666 Winterswijk
#         737 Kerkwerve
#         745 Axel / 770 Westdorpe
#         828 Oudenbosch
#         961 Roermond

patchseries rr009.dat rr025.dat none > rr009025.dat
patchseries rr745.dat rr770.dat none > rr745770.dat
averageseries const rr009.dat rr009025.dat rr139.dat rr144.dat rr222.dat rr328.dat rr438.dat rr550.dat \
    rr666.dat rr737.dat rr745770.dat rr828.dat rr961.dat >  precip13stations.dat
dat2nc precip13stations.dat p "P13" precip13stations.nc
scp precip13stations.dat precip13stations.nc bhlclim:climexp/KNMIData/
scp precip13stations.dat precip13stations.nc oldenbor@climexp-test.knmi.nl:climexp/KNMIData/
