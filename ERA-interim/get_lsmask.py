#!/usr/bin/python
import os
from ecmwf import ECMWFDataServer

gribfile = "lsmask07.grib"
ncfile = "lsmask07.nc"
server = ECMWFDataServer(
       'http://data-portal.ecmwf.int/data/d/dataserver/',
       'dcfc953bfdbde1efa4ee2f513887eade',
       'oldenborgh@knmi.nl'
    )

server.retrieve({
			   	'dataset' : "interim_full_invariant",
			   	'stream'  : "oper",
			    'date'    : "1989-01-01",
		    	'time'    : "12:00:00",
			    'step'    : "0",
			   	'levtype' : "sfc",
			   	'type'    : "an",
			   	'class'   : "ei",
		    	'param'   : "172.128",
				'target'  : gribfile
				  })

command = "cdo -r -R -b 32 -f nc4 -z zip -settaxis,2000-01-01,0:00,1mon " + gribfile + " " + ncfile
os.system(command)
