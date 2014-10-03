#!/usr/bin/python
# -*- coding: iso-8859-1 -*-

# version 20120907


# Copyright © 2012, Ronald van Haren <ronald@archlinux.org>.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the Licence, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


from shutil import copy as shcopy
from netCDF4 import Dataset as NetCDFFile
from netCDF4 import num2date, date2num
from numpy import delete as npdelete
from sys import argv

class mergeTimeSteps(object):
  '''
  A routine to merge netCDF files containing the same 
  variable in each file, but different, possibly overlapping
  timesteps in each file
  ''' 
  def __init__(self,filesArray):
    self.mainfile = filesArray[0]
    filesToAdd = filesArray[1:]
    self.copyMainFile() # copy mainfile to outputfile
    for idx,self.fileToAdd in enumerate(filesToAdd):
      self.timeVar1 = self.loadTimeField(self.outName)
      self.timeVar2 = self.loadTimeField(self.fileToAdd)
      dt1=num2date(self.timeVar1[:],units=self.timeVar1.units) # convert time to date
      self.dt2=num2date(self.timeVar2[:],units=self.timeVar2.units)
      self.idx_duplicates = self.return_indices_of_a(dt1,self.dt2) # find duplicate entries in mainfile
      self.mergeFiles() # merge the files, remove duplicates

  def loadTimeField(self,ncdffile):
    '''
    Load the time variable from the netCDF file
    '''
    ncfile = NetCDFFile(ncdffile,'r')
    try:
      timeVar = ncfile.variables['time']
    except NameError:
      timeVar = ncfile.variables['TIME']
    return timeVar

  def return_indices_of_a(self,a, b):
    '''
    Return indices of elements in 'a' that are also in 'b'
    '''
    b_set = set(b)
    return [i for i, v in enumerate(a) if v in b_set]

  def copyMainFile(self):
    '''
    Copy mainfile as a base for output file
    '''
    self.outName = self.mainfile[0:-3] + 'u.nc'
    shcopy(self.mainfile,self.outName)
    
  def mergeFiles(self):
    '''
    Do the actual merging of the fields and
    write results to disk
    '''
    ncfile1 = NetCDFFile(self.outName,'a')
    ncfile2 = NetCDFFile(self.fileToAdd,'r')
    # Merge the time variable
    self.timeVar2 = date2num(self.dt2,units=self.timeVar1.units)
    self.timeVar1 = npdelete(self.timeVar1,self.idx_duplicates) # delete duplicates from main file
    # modify the time variable in the netCDF file
    timeVar_new = ncfile1.variables['time']
    if ( min(self.timeVar2) - max(self.timeVar1) == 1 ):
      timeVar_new[len(self.timeVar1):] = self.timeVar2
    else:
      # Only support connecting timesteps for now
      raise ValueError("Timesteps don't connect")
    # create list of non-dimensional variables in netCDF file
    dimensions_set = set(ncfile1.dimensions.keys())
    variables = [x for x in ncfile1.variables.keys() if x not in dimensions_set]
    for idx in range(0,len(variables)): # loop over all non-dimensional variables
      variable = variables[idx]
      var_new = ncfile1.variables[variable]
      var2 = ncfile2.variables[variable][:]
      # use previously loaded self.timeVar1 (speed/memory) 
      var_new[len(self.timeVar1):] = var2[:] 
    ncfile1.close()
    ncfile2.close()

    
if __name__ == "__main__":
  if ( len(argv) < 3 ):
    raise ValueError("Number of input files must be at least 2")
  else:
    filesArray = argv[1:]
    for ncfile in filesArray: # chech if files are valid netCDF files
      try:
	NetCDFFile(ncfile,'r')
      except RuntimeError:
	print ncfile +" is not a valid netCDF file ... skipping"
	filesArray.remove(ncfile) # remove the file from list if not a valid netCDF file
  if ( len(filesArray) < 2 ):
    raise ValueError("Not enough valid input files left")
  else:
    mergeTimeSteps(filesArray)
