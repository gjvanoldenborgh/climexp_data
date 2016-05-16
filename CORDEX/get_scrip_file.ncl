; based on https://www.ncl.ucar.edu/Applications/Scripts/ESMF_all_6.ncl
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
    srcFileName  = "INFILE"
    srcGridName  = "OUTFILE"

;---Get data and lat/lon grid from CMIP5 Grid
    sfile       = addfile(srcFileName,"r")
    lat2d       = sfile->LAT
    lon2d       = sfile->LON
    
;----------------------------------------------------------------------
; Convert to SCRIP file.
;----------------------------------------------------------------------
    curvilinear_to_SCRIP(srcGridName,lat2d,lon2d,False)
end