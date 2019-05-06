#!/usr/bin/python
import cdsapi
import os
from datetime import datetime

c = cdsapi.Client()

currentyear = datetime.now().year
currentmonth = datetime.now().month

var = 'satellite-sea-level-global'
firstyear = 1993
lastyear = 1 + currentyear
days = ['01','02','03','04','05','06','07','08','09','10','11','12','13','14','15',
        '16','17','18','19','20','21','22','23','24','25','26','27','28','29','30',
        '31']
months = ['01','02','03','04','05','06','07','08','09','10','11','12']
for year in range(firstyear, lastyear):
    if year == currentyear or year == currentyear - 1:
        if year == currentyear:
            lastmonth = 1 + currentmonth - 1
        else:
            lastmonth = 1 + 12
        for month in range(1, lastmonth):
            if month < 10:
                cmonth = '0' + str(month)
            else:
                cmonth = str(month)
            file = var + "_" + str(year) + cmonth + '.zip'
            if not os.path.isfile(file) or os.stat(file).st_size == 0:
                print "Retrieving " + file
                try:
                    c.retrieve(var, 
                        {'variable':'all',
                         'format':'zip',
                         'year':str(year),
                         'month':cmonth,
                         'day':days
                        },
                        file)
                except:
                    print "OK, dat was het"
                    break
        # end of months loop
    else:
        file = var + "_" + str(year) + '.zip'
        if not os.path.isfile(file) or os.stat(file).st_size == 0:
            print "Retrieving " + file
            c.retrieve(var, 
                        {'variable':'all',
                         'format':'zip',
                         'year':str(year),
                         'month':months,
                         'day':days
                        },
                        file)

            # clean up the old monthly files if they exist
            for month in range(1,13):
                if month < 10:
                    cmonth = '0' + str(month)
                else:
                    cmonth = str(month)
                file = var + str(year) + cmonth + '.zip'
                if os.path.exists(file):
                    os.remove(file)
# end of loop over years
