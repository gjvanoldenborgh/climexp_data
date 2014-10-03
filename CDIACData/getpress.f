        program getpress
*
*       get pressure stations near a given coordinate, or with a given name,
*       or the data
*
        implicit none
        integer nn
        parameter(nn=2000)
	double precision pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,m,ldir,istation,nyr(0:48),nmin(0:48),nok
     +        ,nlist
        integer ic(nn),iwmo(nn),imod(nn),ielevs(nn),iwmo1(208),
     +        iwmo2(208),nflag,disc(nn),firstyear(nn),lastyear(nn)
     +        ,ind(nn),list(nn)
        real rlat(0:nn),rlon(0:nn),slat,slon,slat1,slon1,dist(nn)
     +        ,fstation,dlon,percmiss(nn),rmin,elevmin,elevmax,rlonmin
     +        ,rlonmax,rlatmin,rlatmax
        character name(nn)*25
        character*48 country(0:999)
        character string*80,sname*25,type*3
        character dir*256
        integer iargc,llen
        external iargc,getarg,llen

c     ic=3 digit country code; the first digit represents WMO region/continent
c     iwmo=5 digit WMO station number
c     imod=2 digit modifier; 000 means the station is probably the WMO
c          station; 001, etc. mean the station is near that WMO station
c     name=25 character station name
c     rlat=latitude in degrees.hundredths of degrees, negative = South of Eq.
c     rlon=longitude in degrees.hundredths of degrees, - = West
c     ielevs=station elevation in meters, missing is -999
c     first=first year for which there is data
c     last=last year --""--
c     missing=percentage missing data
c     disc=discontinuity?
*
        if ( iargc().lt.1 ) then
            print '(a)','usage: getpress lat lon [number] [min years]'
            print '(a)','       getpress [name|station_id]'
            print *,'gives historical pressure for station_id,'
            print *,'otherwise stationlist with years of data' 
            stop
        endif
        call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,10
     +        ,nmin,rmin,elevmin,elevmax,list,nn,nlist)
*       no monthly time information yet
        do i=1,48
            if ( nmin(i).ne.0 ) then
                nmin(0) = nmin(i)
                if ( istation.le.0 ) then
                    print *,'No monthly information yet, using years.'
                endif
            endif
        enddo
        if ( istation.eq.0 ) then
            do i=1,nn
                dist(i) = 3e33
            enddo
        endif
*
*       read countrycode from file (still use the NCDC file - easier)
        do j=0,999
            country(j) = ' '
        enddo
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = llen(dir)
            dir(ldir+1:) = '/NCDCData/'
        else
            dir = '/usr/people/oldenbor/NINO/NCDCData/'
        endif
        ldir = llen(dir)
        open(1,file=dir(1:ldir)//'country.codes',status='old')
        do k=1,208
            read(1,'(a)',end=30) string
            if ( string.eq.' ' ) goto 30
            read(string,'(i5,1x,i5,1x,i3)',err=902) i,j,m
            iwmo1(k) = i
            iwmo2(k) = j
            country(k) = string(18:)
        enddo
   30   continue
*
        i = index(dir,'NCDCData')
        if ( i.ne.0 ) then
            dir(i:)='CDIACData/'
            ldir = llen(dir)
        endif
        call getarg(0,string)
        if ( index(string,'sta').ne.0 ) then
            type = 'sta'
        elseif ( index(string,'sea').ne.0 ) then
            type = 'sea'
        else
            print *,'do not know which database to use when running as '
     +            ,string(1:llen(string))
            stop
        endif
        if ( n.gt.1 ) print '(a)','Opening press.'//type//'.data'
        open(unit=2,file=dir(1:ldir)//'press.'//type//'.data',status
     +            ='old',form='formatted',access='direct',recl=75)
        if ( istation.gt.0 ) then
            if ( mod(istation,10).eq.0 ) then
                print '(a,i5,3a)','Searching for station nr ',istation
     +                /10,' in press.',type,'.statinv'
            else
                print '(a,f7.1,a)','Searching for substation nr '
     +                ,istation/10.,' in press.'//type//'statinv'
            endif
        endif
        open(unit=1,file=dir(1:ldir)//'press.'//type//'.statinv'
     +        ,status='old')
*       
        i = 1
  100   continue
        read(1,1000,end=200) ic(i),iwmo(i),imod(i),name(i),rlat(i)
     +        ,rlon(i),ielevs(i),firstyear(i),lastyear(i),percmiss(i)
     +        ,disc(i)
 1000   format(i3.3,i5.5,i2.2,2x,a25,1x,f6.2,1x,f7.2,1x,i4,
     +        1x,i4,1x,i4,1x,f4.1,1x,i1)
        nyr(0) = lastyear(i)-firstyear(i)+1
*
*       check that we have enough years of data
        if ( nmin(0).gt.0 ) then
            if ( nyr(0)*(1-percmiss(i)/100).lt.nmin(0) ) goto 100
        endif
*
*       check elevation
        if ( ielevs(i).lt.elevmin .or. ielevs(i).gt.elevmax ) goto 100
        if ( ielevs(i).eq.-999 .and.
     +        (elevmin.gt.-1e33 .or. elevmax.lt.1e33) ) goto 100
*
*       search closest
        if ( istation.eq.0 ) then
            dlon = min(abs(rlon(i)-slon),
     +            abs(rlon(i)-slon-360),
     +            abs(rlon(i)-slon+360))
            dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
            i = i + 1
        elseif ( istation.gt.0 ) then
            if ( iwmo(i).eq.istation/10 .and. 
     +           imod(i).eq.mod(istation,10) ) then
                i = i + 1
                goto 200
            endif
        elseif ( sname.ne.' ' ) then
*           look for a station with sname as substring
            if ( index(name(i),sname(1:llen(sname))).ne.0 ) then
                i = i + 1
                if ( i.gt.nn ) then
                    print *,'Maximum ',nn,' stations'
                    stop
                endif
            endif
        elseif ( slat1.lt.1e33 ) then
*       look for a station in the box
            if ( (slon1.gt.slon .and. 
     +            rlon(i).gt.slon .and. rlon(i).lt.slon1
     +            .or.
     +            slon1.lt.slon .and.
     +            (rlon(i).lt.slon1 .or. rlon(i).gt.slon)
     +            ) .and. (
     +            rlat(i).gt.min(slat,slat1) .and.
     +            rlat(i).lt.max(slat,slat1) )
     +            ) then
                dist(i) = i
                n = i
                i = i + 1
                if ( i.gt.nn ) then
                    print *,'Maximum ',nn,' stations'
                    stop
                endif
            endif
        elseif ( nlist.gt.0 ) then
            do j=1,nlist
                if ( 10*iwmo(i)+imod(i).eq.list(j) ) then
                    call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax
     +                    ,rlon(i),rlat(i))
                    i = i + 1
                endif
            enddo
        else
            print *,'internal error 31459263'
            call abort
        endif
        goto 100
*       
*       we read all interesting stations in memory
  200   continue
        i = i - 1

        if ( istation.eq.0 .or. slat1.lt.1e33 ) then
            call sortdist(i,n,dist,rlon,rlat,ind,rmin)
        else
            n = i
        endif
*
*       output
        if ( istation.le.0 ) print '(a,i5,a)','Found ',n,' stations'
        if ( nlist.gt.0 ) then
            call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
        endif
        nok = 0
        do j=1,nn
            if ( istation.eq.0 .or. slat1.lt.1e33 ) then
                jj = ind(j)
                if ( dist(jj).gt.1e33 ) goto 700
            else
                jj = j
            endif
            nok = nok + 1
            if ( nok.gt.n ) goto 800
            if ( istation.le.0 ) print '(a)'
     +            ,'=============================================='
            do k=1,208
                if ( iwmo(jj).ge.iwmo1(k) .and. iwmo(jj).le.iwmo2(k) )
     +                goto 210
            enddo
            k = 0
  210       continue
            print '(2a,a,a)',name(jj),'(',country(k)(1:llen(country(k)))
     +            ,')' 
            print '(a,f6.2,a,f7.2,a,i4,a)','Coordinates: ',rlat(jj)
     +            ,'N, ',rlon(jj),'E, ',ielevs(jj),'m'
            call tidyname(name(jj),country(j))
            if ( imod(jj).eq.0 ) then
                print '(a,i5,2a)','WMO station code: ',iwmo(jj),' '
     +                ,name(jj)
            else
                print '(a,i5,a,i1,2a)',' Near WMO station code: '
     +                ,iwmo(jj),'.',imod(jj),' ',name(jj)
            endif
            if ( istation.le.0 ) then
                if ( disc(jj).ne.0 ) then
                    print '(a)','warning: big discontinuity'
                endif
                print '(a,i4,a,i4,a,i4)','Found ',nint((lastyear(jj)
     +                -firstyear(jj)+1)*(1-percmiss(jj)/100))
     +                ,' years of data in ',firstyear(jj),'-'
     +                ,lastyear(jj)
            else
                nflag = 1
                call getdata(type,2,(100000*ic(jj)+iwmo(jj))*10+imod(jj)
     +                ,nflag,nyr)
            endif
  700       continue
        enddo
  800   continue
        if ( istation.le.0 ) print '(a)'
     +        ,'=============================================='
        goto 999
  900   print *,'please give latitude in degrees N, not ',string
        call abort
  901   print *,'please give longitude in degrees E, not ',string
        call abort
  902   print *,'error reading country.codes',string
        call abort
  903   print *,'please give number of stations to find, not ',string
        call abort
  904   print *,'please give station ID or name, not ',string
        call abort
  999   continue
        end
