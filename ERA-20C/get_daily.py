#!/usr/bin/python
###!/home/oldenbor/bin/python
import os
from datetime import datetime
from ecmwfapi import ECMWFDataServer
cdo = "cdo -r -R -b 32 -f nc4 -z zip"

def get_from_ecmwf(year,date,var,code,type,levtype,levelist,file,ncfile):
    """ retrieve daily data from ECMWF ERA-20C archive """
    
    if not os.path.isfile(file) or os.stat(file).st_size == 0:
        time = "06"
        if type == "an":
            if var == 'u10' or var == 'v10':
                step = "0/3/6/9/12/15/18/21"
            else:
                step = "0/6/12/18"
        elif type == "fc" and var == 'tmin' or var == 'tmax':
            time = "00:00:00/12:00:00"
            step = "6/12"
        elif type == "fc":
            step = "24"

        print "Retrieving " + file + " " + date
        dict = {'dataset'  : "era20c",
                'stream'   : "oper",
                'date'     : date,
                'time'     : time,
                'step'     : step,
                'levtype'  : levtype,
                'type'     : type,
                'class'    : "e2",
                'param'    : code,
                'grid'     : '64',
                'format'   : 'netcdf',
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
        elif var == "tmax":
            oper = "daymax"
        elif type == "fc":
            oper = ""
        else:
            oper = "daymean"

        if type == "an":
            command = cdo + " " + oper + " " + file + " " + " aap.nc; " \
                + cdo + " setname," + var + " aap.nc noot.nc; "\
                + cdo + " shifttime,-6hour noot.nc " + ncfile
        elif type == "fc":
            if var == "tmin" or var == "tmax":
                # shift -3 hr to get the 06, 12, 18 and 24 values in the correct day
                command = cdo + " -setname," + var + " -shifttime,-3hour " + file + \
                    " aap.nc; " + cdo + " -" + oper + " aap.nc noot.nc; " + cdo + \
                    " -shifttime,-9hour noot.nc " + ncfile
            elif var == 'tp' or var == 'evap':
                # do not shift -18 hr to get the 06:00 next day value in the correct day, cdo messes up the time axis
                # multiply by 1000 to get from m to mm
                command = cdo + " -setname," \
                    + var + " -mulc,1000 " + file + " " + ncfile
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

vars = [ "t2m", "msl", "z500", "evap", "tp", "u10", "v10" ]
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
    elif var == "u10":
        code = "165.128"
        type = "an"
        units = "m/s"
    elif var == "v10":
        code = "166.128"
        type = "an"
        units = "m/s"
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
    elif var == "z500":
        code = "129.128"
        type = "an"
        units = "m2 s-2"
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
    else:
        raise SystemExit("unknown var: " + var)

    firstyear = 1900
    lastyear = currentyear
    lastyear = 2010
    for year in range(firstyear, 1 + lastyear):

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
                            command = cdo + " -settaxis,%i-%s-01,12:00,1day "%(year,cmonth) + ncfile + " " + \
                                " aap.nc; mv aap.nc " + ncfile
                            print command
                            os.system(command)
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
                command = cdo + " -settaxis,%i-01-01,12:00,1day "%year + ncfile + " " + \
                    " aap.nc; mv aap.nc " + ncfile
                print command
                os.system(command)
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

    outfile = "era20c_" + var + "_daily.nc"
    if concatenate or os.path.isfile(file) == False:
        command = cdo + " copy " + ncfiles + " " + outfile
        print command
        os.system(command)
        command = "ncatted -a units," + var + ",m,c," + units + " " + outfile
        print command
        os.system(command)

    monthlyfile = outfile.replace("_daily","")
    if os.path.isfile(monthlyfile) == False:
        command = "cdo monmean {outfile} noot.nc; cdo settaxis,1900-01-01,0:00,1mon noot.nc {monthlyfile}".format(outfile=outfile, monthlyfile=monthlyfile)
        print command
        os.system(command)

# end of var loop