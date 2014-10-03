#!/bin/ksh 
# 
# Retrieve_decode_grib      USER SUPPORT  DECEMBER 2009 - ECMWF 
# 
#   
# 
#       On ECGATE this shell-script: 
# 
#          - retrieves fields in GRIB format from MARS 
# 
#       This shell script produces the standard output file  
# 
#         Retrieve_decode_grib...out 
# 
#       containing the log of job execution.     
# 
#------------------------------- 
# setting options for LoadLeveler 
#------------------------------- 
# Options that are specified within the script file must precede the 
# first executable shell command in the file.  
# Each line of LoadLeveler keywords requires a leading #@. 
# There can be any number of blanks between the # and the @.   
# LoadLeveler keywords are not case sensitive. 
# These lines become active only when the script is submitted 
# using the "llsubmit" command.  
# All output is written to the submitting directory, by default.  


#@ shell           = /usr/bin/ksh 

        # Specifies the shell that parses the script. If not  
        # specified, your login shell will be used. 

#@ class           = normal 

        # Specifies that your job should be run in the class (queue) 
        # normal. 

#@ job_name        = era_update

        # Assigns the specified name to the request 

#@ output          = mars_output/marsoper.out 

        # Specifies the name and location of STDOUT. If not given, the 
        # default is /dev/null.  The file will be written in the 
        # submitting directory, by default.  

#@ error           = mars_output/marsoper.err 

        # Specifies the name and location of STDERR. If not given, the 
        # default is /dev/null.  The file will be written in the 
        # submitting directory, by default. 

#@ environment     = COPY_ALL 

        # Specifies that all environment variables from your shell 
        # should be used. You can also list individual variables which 
        # should be separated with semicolons. 

#@ notification = error  

        # Specifies that email should be sent in case the job failes.  
        # Other options include always, complete, start, and 
        # never. The default is notification = complete. 

#@ job_cpu_limit   = 00:05:00,00:05:00 

        # Specifies the total CPU time which can be used by all 
        # processes of a serial job step. In this job the hard limit 
        # is set to 1 min and the soft limit to 55 sec. Note: All 
        # limits are capped by those specified in the class. 

# #@ wall_clock_limit= 00:60:00,00:59:00 

        # Specifies that your job requires HH:MM:SS of wall clock 
        # time. 

#@ queue  
        # The queue statement marks the end of your LoadLeveler 
        # keyword definitions and places your job in the queue. At least  
        # one queue statement is mandatory. It must be the last keyword 
        # specified. Any keywords placed after this in the script are 
        # ignored by the current job step. 

#------------------------------- 
# setting environment variables 
#------------------------------- 

export PATH=/usr/local/bin:/bin:/usr/bin:.:.             
                                # Allows you to run any of your programs or 
                                # scripts held in the current directory (not  
                                # required if already done in your .user_profile  
                                # or .user_kshrc) 

export MARS_COMPUTE_FLAG=0
set -xv

#------------------------------- 
# commands to be executed 
#------------------------------- 

cd       # All the files created in this directory will be 
                        # deleted when the job terminates. 

#-------------------- 
# MARS  request 
#-------------------- 

list=LIST
date=DATE

# Retrieve the data from MARS to the target data file "grib_file". 

# instantaneous surface variables
for var in t2m msl z500
do

    file=$SCRATCH/oper_$var$date.grb
    if [ ! -s $file ]; then
        levtype=sfc
        case $var in
	        t2m)  par=167.128;;
            ts)   par=139.128;;
            msl)  par=151.128;;
            u10)  par=165.128;;
            v10)  par=166.128;;
            wspd) par=207.128;;
            z500) par=129.128;levtype=pl;levelist="levelist=500,";;
            *) "echo unknown var $var"; exit -1;;
        esac
        mars <<EOF
retrieve,
time=00:00:00/06:00:00/12:00:00/18:00:00,
date=$list,
levtype=$levtype,
stream=oper,
expver=1,
class=od,
type=an,
param=$par,
grid=128,
gaussian=regular,
$levelist
target="$file"
EOF
    fi # output file does not exist
done # instantaneous vars

# accumulated surface variables
for var in tp tmin tmax
do

    case $var in
        tp)    par=228.128;;
        evap)  par=182.128;;
        ustrs) par=180.128;;
        vstrs) par=181.128;;
        lhtfl) par=147.128;;
        shtfl) par=146.128;;
        ssr)   par=176.128;;
        str)   par=177.128;;
        tmin)  par=122.128;;
        tmax)  par=121.128;;
        *) "echo unknown var $var"; exit -1;;
    esac

    if [ $var = tmin -o $var = tmax ]; then
        file=$SCRATCH/oper_$var$date.grb
            mars <<EOF
retrieve,
step=6/12,
date=$list,
time=00:00:00/12:00:00,
levtype=sfc,
stream=oper,
expver=1,
class=od,
type=fc,
param=$par,
grid=128,
gaussian=regular,
target="$file"
EOF
    else
        # accumulated fluxes
        file=$SCRATCH/oper_${var}${date}_12.grb
        if [ ! -s $file ]; then
            mars <<EOF
retrieve,
step=12,
date=$list,
time=00:00:00,
levtype=sfc,
stream=oper,
expver=1,
class=od,
type=fc,
param=$par,
grid=128,
gaussian=regular,
target="$file"
EOF
        fi

        file=$SCRATCH/oper_${var}${date}_24.grb
        if [ ! -s $file ]; then
            mars <<EOF
retrieve,
step=12,
date=$list,
time=12:00:00,
levtype=sfc,
stream=oper,
expver=1,
class=od,
type=fc,
param=$par,
grid=128,
gaussian=regular,
target="$file"
EOF
        fi
    fi # accumulated
done # forecast vars

#------------------------------- 
# tidy up by deleting unwanted files 
#------------------------------- 
# This is done automatically when using . 

exit 0

# End of job
