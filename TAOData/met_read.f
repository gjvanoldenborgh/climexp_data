      program met_read
c
c This program reads TAO anonymous FTP ascii format met files
c   for example 8n110w.met. It creates real time series arrays
c   which are evenly spaced in time of latitude (rlat), longitude (rlon), 
c   zonal and meridional wind (uwnd and vwnd), relative humidity (rh), 
c   air temperature (airt), and sea surface temperature (sst). 
c
c   Also created are integer arrays of quality for lat-lon position 
c   (iqpos), wind speed (iqspd), wind direction (iqdir), airt (iqairt), 
c   and sst (iqsst).
c
c You can easily adapt this program to your needs.
c
c Programmed by Dai McClurg, NOAA/PMEL/OCRD, April 1999
c
      integer nt
      parameter(nt = 10000)
c
      integer n, m
c
      integer nblock, nn, nday, n1, n2
c
      integer idate(nt)
      integer iqpos(nt), iqspd(nt), iqdir(nt)
      integer iqrh(nt), iqsst(nt), iqairt(nt)
c
      real rlat(nt), rlon(nt), uwnd(nt), vwnd(nt)
      real rh(nt), sst(nt), airt(nt)
      real flag
c
      real depuwnd, depvwnd, deprh, depsst, depairt
c
      character infile*80, header*132, ns*1, ew*1
      character*132 line, line2
c
c .......................................................................
c
      write(*,*) ' Enter the input met file name '
      read(*,'(a)') infile
c
      open(1,file=infile,status='old',form='formatted')
c 
c Read total number of days and blocks of data.
c
      read(1,10) nday, nblock
   10 format(49x,i5,6x,i3)
c
      write(*,*) nday, nblock
c
c Read the missing data flag
c
      read(1,20) flag
   20 format(59x,f6.1)
c
      write(*,*) flag
c
c  Initialize data arrays to flag and quality arrays to 5.
c
      do n = 1, nt
        rlat(n) = flag
        rlon(n) = flag
        uwnd(n) = flag
        vwnd(n) = flag
        rh(n)   = flag
        airt(n) = flag
        sst(n)  = flag
        iqpos(n) = 5
        iqspd(n) = 5
        iqdir(n) = 5
        iqrh(n)   = 5
        iqairt(n) = 5
        iqsst(n)  = 5
      enddo
c
c Read the data. Convert south latitudes to negative, and west longitudes
c   to east longitudes greater than 180.
c
      do m = 1, nblock
        read(1,30) n1, n2, nn
        read(1,'(a)') line
        line2 = line(25:55)
        read(line2,*) depuwnd, depvwnd, deprh, depairt, depsst
        read(1,'(a)') header
        do n = n1, n2
          read(1,60) idate(n), rlat(n), ns, rlon(n), ew, uwnd(n), 
     .                  vwnd(n), rh(n), airt(n), sst(n),
     .                   iqpos(n), iqspd(n), iqdir(n), 
     .                   iqrh(n), iqairt(n), iqsst(n)
          if(ns .eq. 'S' .and. rlat(n) .ne. flag) rlat(n) = -rlat(n)
          if(ew .eq. 'W' .and. rlon(n) .ne. flag) 
     .        rlon(n) = 360.0 - rlon(n)
        enddo
      enddo
c
   30 format(50x,i6,3x,i6,x,i6)
   50 format(5f6.0)
   60 format(x,i8,x,f6.2,a1,f7.2,a1,3f6.1,2f6.2,x,6i1)
c
      close(1)
c
c Now write out the data and quality arrays to the standard output. 
c
      write(*,*) depuwnd, depvwnd, deprh, depairt, depsst
c
      do n = 1, nday
        write(*,70) idate(n), rlat(n), rlon(n), uwnd(n), 
     .                  vwnd(n), rh(n), airt(n), sst(n),
     .                   iqpos(n), iqspd(n), iqdir(n), 
     .                   iqrh(n), iqairt(n), iqsst(n), n
c
      enddo
c
   70 format(x,i8,x,f6.2,f7.2,3f6.1,2f6.2,x,6i1,i7)
c
      end
      
