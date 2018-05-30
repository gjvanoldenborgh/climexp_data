#!/usr/bin/python
########################################################
##
## Compute potential evaporation
## Following procedure from http://edis.ifas.ufl.edu/pdffiles/ae/ae45900.pdf
##

DIR = './'
TIME = 'd'
EXP = 'ERA-I'

## Input data required:
## rsns, rlns tasmin, tasmax, sfcwind, dps, tas, psl
## ERA-I GJ names
## rsns, rlns, tmin, tmax, wspd, tdew, t2m, sp

########################################################
import sys
input_variables = sys.argv
# this is either YYYY or YYYYMM
y = int(sys.argv[1])

import cdms2, numpy, os
# let's take the default - compressed netcdf4 files
###cdms2.setNetcdfShuffleFlag(0)
###cdms2.setNetcdfDeflateFlag(0)
###cdms2.setNetcdfDeflateLevelFlag(0)

# Step 2: Mean daily solar radiation (incoming)
file_rsns = DIR + 'rsns' + str(y) + '.nc'

file = cdms2.open(file_rsns)
slab_rsns = file('rsns')
file.close()

slab_rsns = slab_rsns / 10**6 * 86400  # W/m2 to MJ/m2/d

# Step 18: Net long wave radiation (outgoing)
file_rlns = DIR + 'rlns' + str(y) + '.nc'

file = cdms2.open(file_rlns)
slab_rlns = file('rlns') * -1  # positive down to positive up
file.close()

slab_rlns = slab_rlns / 10**6 * 86400  # W/m2 to MJ/m2/d

# Step 19: Net radiation
slab_netrad = (slab_rsns + slab_rlns)

#del slab_rsns, slab_rlns

# Step ??: Soil heat flux set to zero

# Step 1: mean daily temperature
file_tasmin = DIR + 'tmin' + str(y) + '.nc'
file_tasmax = DIR + 'tmax' + str(y) + '.nc'

file = cdms2.open(file_tasmin)
slab_tasmin = file('tmin') - 273.15  # K to C
file.close()
file = cdms2.open(file_tasmax)
slab_tasmax = file('tmax') - 273.15  # K to C
file.close()

slab_tmean = (slab_tasmin + slab_tasmax) / 2

# Step 3: Wind speed at 2 m
file_sfcwind = DIR + 'wspd' + str(y) + '.nc'

file = cdms2.open(file_sfcwind)
slab_sfcwind = file('wspd')
file.close()

slab_2mwind = slab_sfcwind * 4.87 / numpy.log(67.8 * 10 - 5.42)

del slab_sfcwind

# Step 10: Mean saturation vapour pressure
def sat_vap_pres(temp):
   frac = (17.27*temp)/(temp+237.3)
   et = 0.6108 * numpy.exp(frac)
   return et

etmax = sat_vap_pres(slab_tasmax)
etmin = sat_vap_pres(slab_tasmin)
slab_es = (etmax + etmin) /2

del etmax, etmin, slab_tasmax, slab_tasmin

# Step 11: Actual vapour pressure (based on RHmean, eq.21) 
file_dps = DIR + 'tdew' + str(y) + '.nc'
file_tas = DIR + 't2m' + str(y) + '.nc'

file = cdms2.open(file_dps)
slab_dps = file('tdew')
file.close()
file = cdms2.open(file_tas)
slab_tas = file('t2m')
file.close()

ea_mean = sat_vap_pres(slab_dps)
es_mean = sat_vap_pres(slab_tas)
rh_mean = ea_mean/es_mean

slab_ea = rh_mean * slab_es

del ea_mean, es_mean, rh_mean, slab_dps, slab_tas

# Step 4: Slope of saturation vapor pressure curve
top_frac = (17.27 * slab_tmean) / (slab_tmean + 237.3)
top = 4098 * ( 0.6108 * numpy.exp(top_frac) )
bot = ( slab_tmean + 237.3 )**2
 
slab_slope_satvappre = top / bot

del top_frac, top, bot

# Step 5: Atmospheric pressure
file_psl = DIR + 'sp' + str(y) + '.nc'

file = cdms2.open(file_psl)
slab_psl = file('sp') / 1000  # Pa to kPa
file.close()

# Step 6: Psychrometric constant
slab_psy_const = ( 1.013*10**-3 * slab_psl ) / (0.622 * 2.45)

del slab_psl

# FINAL: Evapotranspiration
Rn = slab_netrad	# mean: 6.5 MJ/m2/d = 75 W/m2
G = 0
T = slab_tmean		# mean: 5.7 C
u2 = slab_2mwind	# mean 4.5 m/s
es = slab_es		# mean: 1.6 kPa
ea = slab_ea		# mean 0.5 kPa
delta = slab_slope_satvappre	# mean: 0.10 
psy = slab_psy_const	# mean: 0.07 kPa/C

top = 0.408 * delta * ( Rn - G ) + psy * (900 / (T + 273.15)) * u2 * ( es - ea )
bot = delta + psy * (1 + 0.34 * u2)
slab_epot = top / bot
#keep in mm/dy
###slab_epot = slab_epot / 10**3

# Write to file
timeax = slab_tmean.getTime()
latax = slab_tmean.getLatitude()
lonax = slab_tmean.getLongitude()

slab_epot = cdms2.createVariable(slab_epot,axes=(timeax,latax,lonax))
slab_epot.id = 'evappot'
slab_epot.long_name = 'Potential evaporation, computed using Penman Monteith'
slab_epot.short_name = 'evappot'
slab_epot.units = 'mm/dy'

file_epot = DIR + 'evappot' + str(y) + '.nc'
file = cdms2.open(file_epot,'w')
file.write(slab_epot,typecode='f')
file.author = 'Geert Jan van Oldenborgh, KNMI'
file.experiment = 'ERA-Interim'
file.close()
print 'done', file_epot

os.system('ncatted -O -h -a Conventions,global,d,, '+file_epot)
os.system('ncatted -O -h -a code,evappot,d,, '+file_epot)
os.system('ncatted -O -h -a table,evappot,d,, '+file_epot)




