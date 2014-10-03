#!/bin/sh
wget -O heat.nc 'http://cwcgom.aoml.noaa.gov/erddap/griddap/aomlTCHP.nc?heat[(2008-04-15T00:00:00Z):1:(2008-04-15T00:00:00Z)][(-50.0):1:(50.0)][(-180.0):1:(179.8)]'
###ncatted -a units,x,a,c,"degrees_east" -a units,y,a,c,"degrees_north" geert.nc -a units,time,m,c,"months since 1994-01-01" heat.nc 
