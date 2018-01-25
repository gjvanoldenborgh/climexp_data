#!/usr/bin/python
# run on zuidzee
import os
from datetime import datetime
from ecmwfapi import ECMWFDataServer
cdo = "cdo -r -R -b 32 -f nc4 -z zip"

def get_from_ecmwf(year,date,var,code,type,levtype,levelist,file,ncfile):
    """ retrieve daily data from ECMWF ERA-interim archive """
    
    if not os.path.isfile(file) or os.stat(file).st_size == 0:
        if type == "an":
            time = "00:00:00/06:00:00/12:00:00/18:00:00"
            step = "0"
        elif type == "fc" and var == 'u10' or var == 'v10':
            time = "00:00:00/06:00:00/12:00:00/18:00:00"
            step = "0/3"
        elif type == "fc" and var == 'tmin' or var == 'tmax':
            time = "00:00:00/12:00:00"
            step = "6/12"
        elif type == "fc":
            time = "00:00:00/12:00:00"
            step = "12"

        print "Retrieving " + file + " " + date
        dict = {'dataset'  : "interim",
                'stream'   : "oper",
                'date'     : date,
                'time'     : time,
                'step'     : step,
                'levtype'  : levtype,
                'type'     : type,
                'class'    : "ei",
                'param'    : code,
                'grid'     : '128',
                'gaussian' : 'regular',
                'target'   : file }
        if levtype == "pl":
            dict['levelist'] = levelist
        print dict
        server.retrieve(dict)

    if not os.path.isfile(file) or os.stat(file).st_size == 0:
        return False

    mtime = os.stat(file).st_mtime
    if os.path.isfile(ncfile) == False:
        ncmtime = 0.
    else:
        ncmtime = os.stat(ncfile).st_mtime

    if  mtime > ncmtime:
        if var == "tmin":
            oper = "daymin"
        elif var == "tmax" or var == "tdew":
            oper = "daymax"
        elif var == "u10" or var == "v10":
            oper = "daymean"
        elif type == "fc":
            oper = "daysum"
        else:
            oper = "daymean"

        if type == "an":
            command = cdo + " -setname," + var + " -" + oper + " " + file + " " + " aap.nc; " + cdo + " -shifttime,-6hour aap.nc " + ncfile
        elif type == "fc":
            if var == "tmin" or var == "tmax":
                # shift -3 hr to get the 06, 12, 18 and 24 values in the correct day
                command = cdo + " -setname," + var + " -shifttime,-3hour " + file + \
                    " aap.nc; " + cdo + " -" + oper + " aap.nc noot.nc; " + cdo + \
                    " -shifttime,-9hour noot.nc " + ncfile
            elif var == "u10" or var == "v10":
                # shift -1 hr to get the 00, 03, ... 21 values in the correct day
                command = cdo + " -setname," + var + " -shifttime,1hour " + file + \
                    " aap.nc; " + cdo + " -" + oper + " aap.nc noot.nc; " + cdo + \
                    " -shifttime,-9hour noot.nc " + ncfile
            elif var == 'tp' or var == 'evap':
                # shift -6 hr to get both the 12:00 and 24:00 values in the correct day
                # multiply by 1000 to get from m to mm
                command = cdo + " -setname," \
                    + var + " -shifttime,-6hour " + file + " aap.nc; " + cdo + \
                    " -daysum -mulc,1000 aap.nc noot.nc; " + cdo + \
                    " -shifttime,-6hour noot.nc " + ncfile
            elif var == 'rsds' or var == 'rsns' or var == 'rlns':
                # shift -6 hr to get both the 12:00 and 24:00 values in the correct day
                # dicide by 60*60*24 to get from J/day/m2 to W/m2.
                command = cdo + " -setname," \
                    + var + " -shifttime,-6hour " + file + " aap.nc; " + cdo + \
                    " -daysum -divc,86400 aap.nc noot.nc; " + cdo + \
                    " -shifttime,-6hour noot.nc " + ncfile
            else:
                print "error: cannot handle var %s" % var
                sys.exit(-1)
        else:
            raise SystemExit("unknown type = " + type)

        print command
        os.system(command)
        if os.path.exists('aap.nc'):
            os.remove('aap.nc')

    return True


server = ECMWFDataServer()

currentyear = datetime.now().year
currentmonth = datetime.now().month

vars = [ "t2m", "tmin", "tmax", "tdew","tp", "evap", "rsds", "rsns", "rlns", "msl", "u10", "v10", "sp", "z500", "t500", "q500" ]
for var in vars:
    ncfiles = ""
    concatenate = False
    datavar = var
    levtype = "sfc"
    levelist = ""
    if var == "t2m":
        code = "167.128"
        type = "an"
        units = "K"
    elif var == "tdew":
        code = "168.128"
        type = "an"
        units = "K"
    elif var == "tmin":
        code = "202.128"
        type = "fc"
        units = "K"
    elif var == "tmax":
        code = "201.128"
        type = "fc"
        units = "K"
    elif var == "msl":
        code = "151.128"
        type = "an"
        units = "Pa"
    elif var == "sp":
        code = "134.128"
        type = "an"
        units = "Pa"
    elif var == "z500":
        code = "129.128"
        type = "an"
        units = "m2 s-2"
        levelist = "500"
        levtype = "pl"
    elif var == "t500":
        code = "130.128"
        type = "an"
        units = "K"
        levelist = "500"
        levtype = "pl"
    elif var == "q500":
        code = "133.128"
        type = "an"
        units = "kg/kg"
        levelist = "500"
        levtype = "pl"
    elif var == "tp":
        code = "228.128"
        type = "fc"
        units = "mm/dy"
    elif var == "evap":
        code = "182.128"
        type = "fc"
        units = "mm/dy"
    elif var == "rsds":
        code = "169.128"
        type = "fc"
        units = "W/m2"
    elif var == "rsns":
        code = "176.128"
        type = "fc"
        units = "W/m2"
    elif var == "rlns":
        code = "177.128"
        type = "fc"
        units = "W/m2"
    elif var == "u10":
        code = "165.128"
        type = "fc"
        units = "m/s"
    elif var == "v10":
        code = "166.128"
        type = "fc"
        units = "m/s"
    else:
        raise SystemExit("unknown var: " + var)

    firstyear = 1979
    lastyear = 1 + currentyear
    for year in range(firstyear, lastyear):

        if year == currentyear or ( year == currentyear-1 and currentmonth < 4):
            if year == currentyear:
                lastmonth = 1 + currentmonth - 1
            else:
                lastmonth = 1 + 12
            for month in range(1, lastmonth):
                if month < 10:
                    cmonth = '0' + str(month)
                else:
                    cmonth = str(month)
                file = datavar + str(year) + cmonth + '.grib'
                ncfile = var + str(year) + cmonth + '.nc'
                dpm = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
                if year%4 == 0:
                    dpm[2] = 29
                else:
                    dpm[2] = 28
                date = str(year) + cmonth + '01/to/' + str(year) + cmonth + str(dpm[month])
                try:
                    c = get_from_ecmwf(year,date,var,code,type,levtype,levelist,file,ncfile)
                    if c:
                        concatenate = True
                    if os.path.exists(ncfile) and os.path.getsize(ncfile) > 100:
                        ncfiles = ncfiles + " " + ncfile
                except RuntimeError:
                    print "OK, dat was het"
                    break
            # end of months loop
        else:
            file = datavar + str(year) + '.grib'
            ncfile = var + str(year) + '.nc'
            date = str(year) + '0101/to/' + str(year) + '1231'
            c = get_from_ecmwf(year,date,var,code,type,levtype,levelist,file,ncfile)
            if c:
                concatenate = True
            if os.path.exists(ncfile) and os.path.getsize(ncfile) > 100:
                ncfiles = ncfiles + " " + ncfile

            # clean up the old monthly files if they exist
            for month in range(1,13):
                if month < 10:
                    cmonth = '0' + str(month)
                else:
                    cmonth = str(month)
                file = datavar + str(year) + cmonth + '.grib'
                if os.path.exists(file):
                    os.remove(file)
                file = datavar + str(year) + cmonth + '.nc'
                if os.path.exists(file):
                    os.remove(file)
                
        ###print "concatenate = " + str(concatenate)   
    # end of years loop

    outfile = "erai_" + var + "_daily.nc"
    if concatenate or os.path.isfile(outfile) == False:
        command = cdo + " copy " + ncfiles + " " + "/tmp/" + outfile
        print command
        os.system(command)

        command = "ncatted -a units," + var + ",a,c," + units + " /tmp/" + outfile
        print command
        os.system(command)
        command = "ncatted -a units," + var + ",m,c," + units + " /tmp/" + outfile
        print command
        os.system(command)

        command = "mv /tmp/" + outfile + " " + outfile
        print command
        os.system(command)

    if var == 'tmax' or var == 'tmin':
        monthlyfile = outfile.replace("_daily","")
        command = "cdo monmean {outfile} {monthlyfile}".format(outfile=outfile, monthlyfile=monthlyfile)
        print command
        os.system(command)

# end of var loop
