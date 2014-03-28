      program ds570
      character nb*50,name*30
      nr=0
      write(6,*)' This code reads a basic WMSC file and outputs '
      write(6,*)'  a file of ID variables and standard parameters  ,'
      write(6,*)' It expects the input file as a directed input'
      write(6,*)'  ie a.out < data_ascii   '
      write(6,*)'  or if compressed, zcat data_ascii.Z |a.out '
      write(6,*)' The output could also be directed '
    5 read(5,'(a50)',end=90)nb
      nr=nr+1
c
      if(nb(1:1).ne.'0') go to 8
c
c process header info type 0
      read(nb,1001)nsta,iyr,imo,isrc,ishi,isid,ilat,ilon,iele,i7,i9
 1001 format(1x,i6,i4,i2,3i1,i4,i5,i4,i6,i9)
      xla=(float(ilat)-1000.)*.1
      xlo=(float(ilon)-2000.)*.1
	iele=iele-1000
      write(6,1011)nb(1:1),nsta,iyr,imo,xla,xlo,iele,isrc,ishi,isid,i7,
     *i9
 1011 format(1x,a1,1x,i6,i5,i3,f6.1,f7.1,i5,3i2,i7,i10)
C   nsta                WMO#
C   iyr                 year
C   imo                 month (1-12)
C   isrc                source of data
C   ishi                ship indicator
C   isid                source of ID
C   ilat / xlat         latitude
C   ilon / xlon         longitude
C   iele                elevation
C   i7                  721#
C   i9                  995#
      read(5,'(a50)',end=90)nb
      nr=nr+1
c process type 1 record which always follow type 0 record
      read(nb,2001)nsta,iyr,imo,name
 2001 format(1x,i6,i4,i2,a30)
C   name                name of station

      write(6,2002)nb(1:1),nsta,iyr,imo,name
 2002 format(1x,a1,1x,i6,i5,i3,1x,a30)
      go to 5
c
    8 continue
      if(nb(1:1).ne.'6') go to 12
c
c process data info type 6
      read(nb,1002)nsta,iyr,imo,islpi,islp,ippi,istp,iz,itemp,
     *iprec
 1002 format(1x,i6,i4,i2,i1,i5,i1,i5,i4,i4,i6)
C for details on variables see the format description
C   islpi               SLP indicator
C   islp                SLP (0.1 mb)
C   ippi                previous pressure indicator
C   istp                station pressure (0.1 mb)
C   iz                  height
C   itemp               temperature   (0.1C)
C   iprec               precipitation (0.1 mm)
C
c write basic station press, sea level pres, temp and precip data for analysis
      tmp=(float(itemp)-1000.)*.1
      pcp=float(iprec)*.1
      slp=float(islp)*.1
      stp=float(istp)*.1
      write(6,1003)nb(1:1),nsta,iyr,imo,islpi,slp,ippi,stp,tmp,pcp
 1003 format(1x,a1,1x,i6,i5,i3,i2,f7.1,i2,f7.1,f6.1,f9.1)
      go to 5
c
   12 continue
c ignore other types (2-5)
      if(nb(1:1).ne.'7') go to 5
c
c process additional data info type 7
      read(nb,1004)nsta,iyr,imo,itempd,mind,moist,moistd,ndp,ipcpd,iq,
     *nobs,isd,isp,isst,isstd
 1004 format(1x,i6,i4,i2,i4,i1,2i4,i2,i4,i1,i2,i3,3i4)
c for details on variables see the format description
c   itempd              temperature departure from normal (0.1C)
c   mind                moisture indicator
c   moist               moisture (% or 0.1 mb)
c   moistd              moisture departure from normal (% or 0.1 mb)
c   ndp                 # of days with precipitation .ge. 1 mm
c   ipcpd               precipitation departure from normal (mm)
c   iq                  quintile
c   nobs                number of observations per month
c   isd                 sunshine duration (hours)
c   isp                 sunshine percent of average (%)
c   isst                sea temperature (0.1C)
c   isstd               sea temperature departure from normal (0.1C)
c
c write basic temp and precip data for analysis
      tmpd=(float(itempd)-1000.)*.1
      ibias=100
      if(mind.eq.1) ibias=1000
      moistd=moistd-ibias
      ipcpd=ipcpd-2000
      sst=(float(isst)-1000.)*.1
      sstd=(float(isstd)-1000.)*.1
      write(6,1005)nb(1:1),nsta,iyr,imo,tmpd,mind,moist,moistd,ndp,
     *ipcpd,iq,nobs,isd,isp,sst,sstd
 1005 format(1x,a1,1x,i6,i5,i3,f6.1,i3,2i6,6i5,2f6.1)
      go to 5
c
   90 continue
      write(6,1000)nr
 1000 format(' end, records = ',i8)
      end
