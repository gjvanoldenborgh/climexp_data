#!/usr/bin/python
###!/home/oldenbor/bin/python
# the above line does not work on the Mac, but it is the only way to run python on the servers.
import os
import subprocess
from datetime import datetime
from ecmwfapi import ECMWFDataServer

def get_from_ecmwf(date,var,type,file,ncfile):
    """ retrieve monthly data from ECMWF ERA-interim archive """
    
    if not os.path.isfile(file) or os.stat(file).st_size == 0:
        print "Retrieving " + file + " " + date
        dataset = "era20cm"
        stream = "edmo"
        dict = {'dataset' : dataset,
                'stream'  : stream,
                'expver'  : '1',
                'date'    : date,
                'number'  : "0/1/2/3/4/5/6/7/8/9",
                'levtype' : "sfc",
                'type'    : "fc", # curiously all variables seem to have this
                'class'   : "em",
                'param'   : code,
                'format'  : 'netcdf',
                'target'  : file  }
        if levtype == "pl":
            if var == "t" or var == "u":
                levellist = '1000/925/850/700/600/500/400/300/250/200/150/100/70/50/30/20/10'
            else:
                levellist = '850/700/500/300/200'
            dict.update({ 'levtype': levtype, \
                          'levellist' : levellist, \
                          'grid' : '64' })
        dict.update({ 'grid' : '64' })
        print dict
        server.retrieve(dict)

    if not os.path.isfile(file) or os.stat(file).st_size == 0:
        return False

    mtime = os.stat(file).st_mtime

    if not os.path.isfile(ncfile):
        ncmtime = 0.
    else:
        ncmtime = os.stat(ncfile).st_mtime

    if mtime > ncmtime:
        # use months as units to keep time simple, get rid of scalefactor/offset, compress
        command = cdo + " -settaxis," + date[0:4] + "-" + date[4:6] + "-15,0:00,1mon " + file + " " + ncfile
        print command
        os.system(command)

        if levtype == "pl":
            text = subprocess.check_output("describefield " + ncfile, shell=True, stderr=subprocess.STDOUT)
            ###print text
            for line in text.splitlines():
                if line.startswith("Z axis"):
                    words = line.split()
                    ###print "words[5] = " + words[5]
                    ###print "words[6] = " + words[6]
                    if float(words[5]) > float(words[6]):
                        command = cdo + " invertlev " + ncfile + " aap.nc"
                        print command
                        os.system(command)
                        os.rename("aap.nc",ncfile)
                    
    return True


server = ECMWFDataServer()

currentyear = datetime.now().year
currentmonth = datetime.now().month
cdo = "cdo -r -R -b 32 -f nc4 -z zip "

vars = [ "t2m", "ts", "msl", "u10", "v10", "wspd", "ci", "snd", "sst", 
         "tp", "evap", "ustrs", "vstrs", "lhtfl", "shtfl", "ssr", "str", 
         "z", "t", "u", "v", "w", "q" ]
vars = [ "evap", "wspd", "ci", "ssr", "snd", "tp", "t2m" ]
for var in vars:
    ncfiles = ""
    concatenate = False
    datavar = var
    levtype = ""
    factor = 1
    if var == "t2m":
        long_name = "2m temperature"
        code = "167.128"
        type = "an"
        units = "K"
    elif var == "ts":
        long_name = "surface temperature"
        code = "139.128"
        type = "an"
        units = "K"
    elif var == "msl":
        long_name = "mean sea-level pressure"
        code = "151.128"
        type = "an"
        units = "Pa"
    elif var == "u10":
        long_name = "10m zonal wind"
        code = "165.128"
        type = "an"
        units = "m/s"
    elif var == "v10":
        long_name = "10m meridional wind"
        code = "166.128"
        type = "an"
        units = "m/s"
    elif var == "wspd":
        long_name = "wind speed"
        code = "207.128"
        type = "an"
        units = "m/s"
    elif var == "ci":
        long_name = "sea ice cover"
        code = "31.128"
        type = "an"
        units = "1"
    elif var == "snd":
        long_name = "snow depth"
        code = "141.128"
        type = "an"
        units = "m"
    elif var == "sst":
        long_name = "sea surface temperature"
        code = "34.128"
        type = "an"
        units = "K"
    elif var == "tp":
        long_name = "total precipitation"
        code = "228.128"
        type = "fc"
        units = "mm/dy"
        factor = 1000
    elif var == "ls":
        long_name = "large-scale precipitation"
        code = "142.128"
        type = "fc"
        units = "mm/dy"
        factor = 1000
    elif var == "cp":
        long_name = "convective precipitation"
        code = "143.128"
        type = "fc"
        units = "mm/dy"
        factor = 1000
    elif var == "evap":
        long_name = "evaporation"
        code = "182.128"
        type = "fc"
        units = "mm/dy"
        factor = -1000
    elif var == "ustrs":
        long_name = "zonal wind stress"
        code = "180.128"
        type = "fc"
        units = "Pa"
        factor = 1./(24*60*60)
    elif var == "vstrs":
        long_name = "meridional wind stress"
        code = "181.128"
        type = "fc"
        units = "Pa"
        factor = 1./(24*60*60)
    elif var == "ssr":
        long_name = "net surface solar radiation"
        code = "176.128"
        type = "fc"
        units = "W/m2"
        factor = 1./(24*60*60)
    elif var == "str":
        long_name = "net surface thermal radiation"
        code = "177.128"
        type = "fc"
        units = "W/m2"
        factor = 1./(24*60*60)
    elif var == "lhtfl":
        long_name = "latent heat flux"
        code = "147.128"
        type = "fc"
        units = "W/m2"
        factor = 1./(24*60*60)
    elif var == "shtfl":
        long_name = "sensible heat flux"
        code = "146.128"
        type = "fc"
        units = "W/m2"
        factor = 1./(24*60*60)
    elif var == "z":
        long_name = "geopotential height"
        code = "129.128"
        type = "an"
        units = "m2/s2"
        levtype = "pl"
    elif var == "t":
        long_name = "temperature"
        code = "130.128"
        type = "an"
        units = "K"
        levtype = "pl"
    elif var == "u":
        long_name = "zonal wind"
        code = "131.128"
        type = "an"
        units = "m/s"
        levtype = "pl"
    elif var == "v":
        long_name = "meridional wind"
        code = "132.128"
        type = "an"
        units = "m/s"
        levtype = "pl"
    elif var == "w":
        long_name = "vertical velocity"
        code = "135.128"
        type = "an"
        units = "Pa/s"
        levtype = "pl"
    elif var == "q":
        long_name = "humidity"
        code = "133.128"
        type = "an"
        units = "kg/kg"
        levtype = "pl"
    else:
        raise SystemExit("unknown var: " + var)

    firstyear = 1900
    lastyear = 2011
    for year in range(firstyear, lastyear):

        if year == currentyear or ( year == currentyear-1 and currentmonth < 4):
            if year == currentyear-1:
                maxmonth = 1 + 12
            else:
                maxmonth = 1 + currentmonth - 1
            for month in range(1, maxmonth):
                if month < 10:
                    cmonth = '0' + str(month)
                else:
                    cmonth = str(month)
                file = datavar + str(year) + cmonth + '_mo.nc3'
                ncfile = var + str(year) + cmonth + '_mo.nc'
                date = str(year) + cmonth + '01'
                try:
                    c = get_from_ecmwf(date,var,type,file,ncfile)
                    if c:
                        concatenate = True
                        ncfiles = ncfiles + " " + ncfile
                except RuntimeError:
                    print "OK, dat was het"
                    break
            # end of months loop
        else:
            file = datavar + str(year) + '_mo.nc3'
            ncfile = var + str(year) + '_mo.nc'
            date = str(year) + '0101/' + str(year) + '0201/' + \
                   str(year) + '0301/' + str(year) + '0401/' + \
                   str(year) + '0501/' + str(year) + '0601/' + \
                   str(year) + '0701/' + str(year) + '0801/' + \
                   str(year) + '0901/' + str(year) + '1001/' + \
                   str(year) + '1101/' + str(year) + '1201'
            c = get_from_ecmwf(date,var,type,file,ncfile)
            if c:
                concatenate = True
            ncfiles = ncfiles + " " + ncfile

            # clean up the old monthly files if they exist
            for month in range(1,13):
                if month < 10:
                    cmonth = '0' + str(month)
                else:
                    cmonth = str(month)
                file = datavar + str(year) + cmonth + '_mo.nc3'
                if os.path.exists(file):
                    os.remove(file)
                file = datavar + str(year) + cmonth + '_mo.nc'
                if os.path.exists(file):
                    os.remove(file)
    
        ###print "concatenate = " + str(concatenate)    
    # end of years loop

    outfile = "erai20c_" + var + ".nc"
    if concatenate or os.path.isfile(file) == False:
        command = cdo + " copy " + ncfiles + " " + outfile
        print command
        os.system(command)

        command = "ncatted -a title,global,a,c,\"ERA-interim reanalysis from http://apps.ecmwf.int/datasets/\" " + outfile
        print command
        os.system(command)

        if var == 'tp' or var == 'evap':
            command = "ncatted -a units," + var + ",a,m,mm/dy " + outfile
            print command
            os.system(command)

        if factor != 1:
            command = cdo + " mulc," + str(factor) + " " + outfile + " noot.nc; mv noot.nc " + outfile
            print command
            os.system(command)

        if levtype == 'pl':
            levellist = [ 850, 700, 500, 300, 200 ]
            for level in levellist:
                levelfile = "era20c_" + var + str(level) + ".nc"
                command = "cdo sellevel," + str(level) + "00. " + outfile + " " + levelfile
                print command
                os.system(command)
            if var == "t" or var == "u":
                zonfile = "era20c_" + var + "zon.nc"
                command = "cdo zonmean " + outfile + " " + zonfile
                print command
                os.system(command)

    if var == "evap":
        command = cdo + " sub era20c_tp.nc era20c_evap.nc era20c_pme.nc"
        print command
        os.system(command)

# end of var loop
