#!/home/oldenbor/bin/python
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
            elif var == 'tp' or var == 'evap':
                # shift -6 hr to get both the 12:00 and 24:00 values in the correct day
                # multiply by 1000 to get from m to mm
                command = cdo + " -setname," \
                    + var + " -shifttime,-6hour " + file + " aap.nc; " + cdo + \
                    " -daysum -mulc,1000 aap.nc noot.nc; " + cdo + \
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

vars = [ "t2m", "tmin", "tmax", "tdew", "msl", "sp", "z500", "tp", "evap" ]
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
    if concatenate or os.path.isfile(file) == False:
        command = cdo + " copy " + ncfiles + " " + outfile
        print command
        os.system(command)

        command = "ncatted -a units," + var + ",a,c," + units + " " + outfile
        print command
        os.system(command)

    if var == 'tmax' or var == 'tmin':
        monthlyfile = outfile.replace("_daily","")
        command = "cdo monmean {outfile} {monthlyfile}".format(outfile=outfile, monthlyfile=monthlyfile)
        print command
        os.system(command)

# end of var loop