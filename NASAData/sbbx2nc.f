C sbbx2nc.f
C
C This program uses 2 input files:
C  the first contains        SURFACE AIR TEMPERATURE anomalies,
C  the second          OCEAN MIXED LAYER TEMPERATURE anomalies.
C
C It reads monthly anomalies for 8000 equal area subboxes, finds the
C anomaly with respect to 1951-1980 for a user-specified month/year.
C Whether ocean or land data are used depends on the flag IOCN.
C
C The results are replicated as a gridded netCDF data file whose
C resolution is determined by choice of parameter below.
C
C Both input files have the same structure:
C Record 1 starts with 8 integers I1-I8 and an 80-byte TITLE.
C All further records start with 7 integers N1-N7,
C             a real number R, followed by a data array (real*4).
C I1 or N1 is the length of the data array in the NEXT record.
C Unless its length is 0, each data-array contains a time series
C of monthly T-anomalies (C) starting with January of year I6 for
C one grid box. N2,N3,N4,N5 indicate the edges in .01 degrees of
C that grid box in the order: latitude of southern edge, latitude of
C northern edge, longitude of western edge, longit. of eastern edge.
C The world is covered with 8000 equal area grid boxes, so each
C file has 8001 records. I7 is the flag for miss data (9999).
C
C This program has been compiled using g77 on Mac OS X with the
C following command lines statements
C
C   g77 -c -I/usr/include sbbx2nc.f
C   g77 -w -o sbbx2nc sbbx2nc.o /usr/lib/libnetcdf.a
C
C This assumes you have installed the g77 FORTRAN compiler and UCAR's
C netCDF libraries, placing netcdf.inc in /usr/include and libnetcdf.a
C in /usr/lib . See
C http://www.unidata.ucar.edu/packages/netcdf/INSTALL.html for
C more about installing netCDF on your Unix or Unix-like platform.
C
C As written, this program generates a netCDF file containing data
C for 1991 through 2000, inclusive. You can change the time period
C by altering the values of IFYR and ILYR in the parameter statements
C immediately following.
C
C You can also alter the parameters IM and JM to achieve different
C gridding. IM is the number of longitude grid points, JM the number
C of latitude grid points.
C
C Please note that depending on your choices, the output file can be
C LARGE. A 10-year extraction of data at 1-1deg resolution will
C create a 31-MB netCDF file.
C
      program sbbx2nc
      
      include "netcdf.inc"

!!!      parameter (iocn = 0)      ! 0 no ocean, 1 ocean only, 2 land+ocean

      parameter (im   = 360)    ! lon. grid points, 360 = 1-deg resolution
      parameter (jm   = 180)    ! lat. grid points, 180 = 1-deg resolution
 
      parameter (ifyr = 1880, ilyr = 2013)   ! first, last years of output

      parameter (iyrx = ifyr-1)
      parameter (iyrs = ilyr-ifyr+1)
      parameter (ixt  = 12*iyrs)
      parameter (monmx = 12 * (2200-1700))
      parameter (iy1b=1951, iy2b=1980, navgb=iy2b+1-iy1b)  ! base period

      integer info(8),infoo(8)
      real  tin(monmx),  tav(monmx), tout(ixt*im*jm)
      real tino(monmx), tavo(monmx)

      character*80 title, titleo, string

      integer is, ncid
      integer latdim, londim, timedim
      integer latvar, lonvar, timevar, datavar
      integer shape(3)
      integer time(ixt)
      real lat(jm), lon(im), att_missing(1)

C
C Let's get started
C
        call getarg(1,string)
        read(string,*) iocn

                     rland =   100.  ! land&ocen is used, station reach 100 km
      if (iocn.eq.0) rland =  9999.  ! only land data are used
      if (iocn.eq.1) rland = -9999.  ! only ocean data are used

C
C Initialize the NC dataset.
C
      print *, 'Creating NC dataset...'
      is = nf_CREATE ('gistemp.nc', nf_CLOBBER, ncid)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,nf_global,'title',37,
     *     'GISTEMP Surface Temperature Analysis')
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,nf_global,'institution',40,
     *     'NASA Goddard Institute for Space Studies')
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,nf_global,'source',34,
     *     'http://data.giss.nasa.gov/gistemp/')
      if (is .ne. nf_noerr) call handle_err(is)

C
C Define the dimensions.
C
      print *, 'Defining dimensions...'
      is = nf_def_DIM(ncid, 'lat', jm, latdim)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_def_DIM(ncid, 'lon', im, londim)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_def_DIM(ncid, 'time', ixt, timedim)
      if (is .ne. nf_noerr) call handle_err(is)

C
C Define the coordinate variables.
C
      flatres = 180. / jm
	  fsouth =  -90. + 0.5 * flatres

      flonres = 360. / im
	  fwest  = -180. + 0.5 * flonres

      do 5020 J = 1, jm
        lat(J) = fsouth + (J - 1.) * flatres
 5020 continue

      do 5040 I = 1, im
        lon(I) = fwest  + (I - 1.) * flonres
 5040 continue

*      do 5060 iyy = 1, iyrs
*        iyr = iyrx + iyy
*        do 5060 imm = 1, 12
*          imoff = (iyy-1)*12 + imm
*          time(imoff) = iyr * 100 + imm
* 5060 continue
      do i=1,12*iyrs
        time(i) = i-1
      end do

      print *, 'Defining coordinate variables...'
      is = nf_def_var(ncid,'lat',nf_float,1,latdim,latvar)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,latvar,'long_name',8,'Latitude')
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,latvar,'units',13,'degrees_north')
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_def_var(ncid,'lon',nf_float,1,londim,lonvar)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,lonvar,'long_name',9,'Longitude')
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,lonvar,'units',12,'degrees_east')
      if (is .ne. nf_noerr) call handle_err(is)

      print *, 'Define time var'
      is = nf_def_var(ncid,'time',nf_int,1,timedim,timevar)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,timevar,'long_name',4,'time')
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,timevar,'units',23,'months since 1880-01-01')
      if (is .ne. nf_noerr) call handle_err(is)

C
C Define the variable.
C
      print *, 'Defining the temperature data variable...'
      shape(1) = londim
      shape(2) = latdim
      shape(3) = timedim
      is = nf_def_var(ncid,'tempanomaly',nf_float,3,shape,datavar)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,datavar,'long_name',19,'Temperature anomaly')
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_att_text(
     *     ncid,datavar,'units',7,'Celsius')
      if (is .ne. nf_noerr) call handle_err(is)

      att_missing(1) = 9999.0
      is = nf_put_ATT_real(
     *     ncid,datavar,'missing_value',
     *     nf_float,1,att_missing)
      if (is .ne. nf_noerr) call handle_err(is)

C
C Put the coordinate variables into the NC dataset
C
      print *, 'Writing the coordinate variables to the NC dataset'

      is = nf_enddef(ncid)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_var_real(ncid, latvar, lat)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_var_real(ncid, lonvar, lon)
      if (is .ne. nf_noerr) call handle_err(is)

      is = nf_put_var_int(ncid, timevar, time)
      if (is .ne. nf_noerr) call handle_err(is)

C
C Read the relevant parts of the header record.
C
      if (rland.ge.0.) then
         open (8, file='TS_DATA', form='unformatted',
     *         access='sequential')
         read (8) info, title
         write(6,*) title
         do i = 1, 8
           infoo(i)=info(i)   !  needed for land-only case
         end do
      end if
      if (rland.lt.9999.) then
         open (9, file='SST_DATA', form='unformatted',
     *         access='sequential')
         read (9) infoo, titleo
         write (6,*) titleo
         if (rland.lt.0.) then
           do i = 1, 8
             info(i) = infoo(i)
           end do
         end if
      end if

      mnow   = info(1)       ! length of first data record (months)
      monm   = info(4)       ! max length of time series (months)
      iyrbeg = info(6)       ! beginning of time series (calendar year)
      if ( iyrbeg.lt.1600 .or. iyrbeg.gt.2100 ) then
         write(0,*) 'sbbx2nc: error: corrupted input file SST_DATA'
         close(9,status='delete')
         call abort
      end if
      bad    = info(7)

      mnowo  = infoo(1)
      monmo  = infoo(4)
      iyrbgo = infoo(6)

C
C Initialize the output array, filling it with the bad/missing value.
C
      do 5100 I = 1, ixt*im*jm
        tout(I) = bad
 5100 continue

C
C Align land and ocean time series
C
      iyrbgc = min(iyrbgo, iyrbeg)    ! use earlier of the 2 start years

      i1tin  = 1 + 12 * (iyrbeg - iyrbgc)     ! land  offset in combined period
      i1tino = 1 + 12 * (iyrbgo - iyrbgc)     ! ocean offset in combined period
      monmc  = max(monm+i1tin-1,monmo+i1tino-1)  ! use later of the 2 ends
      print *,'iyrbeg,iyrbgc = ',iyrbeg,iyrbgc
      print *,'i1tin,i1tinoc = ',i1tin,i1tino
      print *,'monm,monmo    = ',monm,monmo
      print *,'monmc         = ',monmc
      iyrend = iyrbgc - 1 + monmc / 12        ! last calendar year of timeseries

C
C Loop over subboxes - find output data
C
      print *, 'Reading and gridding temperature data...'

      do 6100 n = 1,8000
        do 6050 m = 1,ixt ! monmc
          tin(m)  = bad     ! set all months to missing initially
          tino(m) = bad
 6050   continue
 
        dl = 9999.          ! in case only ocn data are read in


C**** read in time series TIN/tino of monthly means: land/ocean data

        if (rland.ge.0.) then
          call sread (8, tin(i1tin), mnow, lats, latn, lonw, lone,
     *                dl, next)
          mnow = next ! mnow/next: length of current/next time series
        end if

        if (rland.lt.9999.) then   !  read in ocean data
          call sread (9, tino(i1tino), mnowo, lats, latn, lonw, lone,
     *                dlo, nexto)
          mnowo = nexto
          wocn = 0.             ! weight for ocean data
          if (dl.gt.rland) wocn=1. ! dl:subbox_center->nearest station (km)
        end if

C
C At this point the 2 time series TIN,tino are all set and
C can be used to compute means, trends , etc. As an example,
C we find the requested anomaly:
C
        do 6090 iyy = 1, iyrs
          iyr = iyrx + iyy
        do 6090 imm = 1, 12
          imoff = (iyy-1)*12 + imm

C Find the mean over the base period
          tavb    = 0.
          tavbo   = 0.
          tav(1)  = bad
          tavo(1) = bad

C**** m1,m1b: Location in combined series of 1st month needed
          m1  = 12 * (iyr  - iyrbgc) + imm
          m1b = 12 * (iy1b - iyrbgc) + imm

          if (rland.ge.0.) then
C*            collect selected month for each base period year
            call avg(tin(m1b), 12, navgb,    1, bad, 1, tav)
C*            find mean over the base period for the selected month
            call avg(tav,   navgb,    1, navgb, bad, 1, tav)
          end if
      
          if (rland.lt.9999.) then  ! do same for ocean data
            call avg(tino(m1b), 12,navgb,    1, bad, 1, tavO)
            call avg(tavO,  navgb,    1, navgb, bad, 1, tavO)
          end if
      
          tavb  = tav(1)              ! tavb default: land value
          tavbo = tavo(1)

C
C Put the requested anomaly into tav(1), then tout(i,j)
C
          tav(1)  = bad
          tavo(1) = bad

          if (tavb.ne.bad) tav(1) = tin(m1)         ! tav(1): land value

          if (rland.lt.9999. .and. tavbo.ne.bad) tavo(1) = tino(m1)

          if (tav(1).eq.bad .or. rland.lt.0.) then   ! disregard land data
             tavb   = tavbo                          ! tavb: ocean value
             tav(1) = tavo(1)                        ! tav(1): ocean value
          end if

          if (tavo(1).ne.bad) then            ! switch tavb/tav(1) to
              tavb   = tavb   * (1.-wocn) + tavbo   * wocn  ! ocn value if appropriate
              tav(1) = tav(1) * (1.-wocn) + tavo(1) * wocn
          end if

C
C Replicate tav(1) at the appropriate places in the output array
C
          if (tav(1).ne.bad) then
             tav(1) = tav(1) - tavb
             call embed (tav, tout, im, jm, ixt,
     *                   lats, latn, lonw, lone, imoff)
          end if

 6090   continue

 6100 continue
C End of loop over subboxes

      print *, 'Writing the temperature data to the NC dataset...'
      is = nf_put_var_real(ncid, datavar, tout)
      if (is .ne. nf_noerr) call handle_err(is)


C
C Done. close the NC dataset.
C
      print *, 'Closing the NC dataset...'
      is = nf_close(ncid)
      if (is .ne. nf_noerr) call handle_err(is)

      stop
      end


C*********
C
      subroutine handle_err(is)
      integer is
      if (is .ne. nf_noerr) then
        print *, 'ERROR #', is
        stop '...Stopped...'
      endif
      end

C*********
C
      subroutine sread (ndisk,array,len, N1,N2,N3,N4, dstn,lnext)
      real array(len)
      read (ndisk) lnext, N1,N2,N3,N4, NR1,NR2, dstn, array
      return
      end

C*********
C
      subroutine avg (array, km, navg, lav, bad, lmin, dav)
      
      real array(km,navg), dav(navg)

      do 100 n = 1, navg
        sum   = 0.
        kount = 0
        do 50 L = 1, lav
          if (array(L,n).eq.bad) GO TO 50
          sum   = sum + array(L,n)
          kount = kount + 1
   50   continue
        dav(n) = bad
        if (kount.ge.lmin) dav(n) = sum / kount
  100 continue
      return
      end

C*********
C This program replicates the data onto a regular (finer) grid:
C The value in the given box of the input grid is copied to all
C output grid boxes whose centers lie in that box.
C
      subroutine embed (t, tout, im, jm, ixt,
     *                  lats, latn, lonw, lone, imonth)

      real tout(im,jm,ixt)

C Latitudes lats,latn and longitudes lonw,lone are in .01 degrees
C In tout J=1->jm corresponds to 90S->90N,
C         I=1->im corresponds to 180W->180E

      js = 1.5 + ((lats +  9000) * jm) / (18000)
      jn = 0.5 + ((latn +  9000) * jm) / (18000)

      iw = 1.5 + ((lonw + 18000) * im) / (36000)
      ie = 0.5 + ((lone + 18000) * im) / (36000)

      do 30 j = js, jn
        do 30 i = iw, ie
          tout(i,j,imonth) = t
   30 continue
   
      return
      end
C
C Done.
C
