        program getsealev
*
*       Get station and precipitation metadata near a given coordinate,
*       or with a given substring.
*       Get station data when called with a station ID.
*
*       Geert Jan van Oldenborgh, KNMI, 2000
*
        implicit none
        integer nn
        parameter(nn=4000)
	double precision pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,n,ldir,istation,nmin(0:48),nok,nlist
        integer ii(nn),idum(3),nyr(nn),yr1(nn),yr2(nn),ind(nn),list(nn)
        real rlat(nn),rlon(nn),dist(nn),fmiss(nn),dlon,slat,slon
     +        ,slat1,slon1,fdum,rmin,elevmin,elevmax,rlonmin,rlonmax
     +        ,rlatmin,rlatmax
        character name(nn)*40,country(0:999)*20,clat*8,clon*8,ac*3,fc*3
        character string*80,sname*30
        character dir*256,line*132
        logical lwrite
        integer iargc
*       
        lwrite = .FALSE.
        if ( iargc().lt.1 ) then
            print *,'usage: getsealev station_id'
            print *,'       getsealev [string|lat lon] [min years]'
            print *,'gives historical sea level for station_id'
            print *,'or stationlist with years of data' 
            stop
        endif
        call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,1,nmin
     +        ,rmin,elevmin,elevmax,list,nn,nlist)
*       no monthly time information yet
        do i=1,48
            if ( nmin(i).ne.0 ) then
                nmin(0) = nmin(i)
                if ( istation.le.0 ) then
                    print *,'No monthly information yet, using years.'
                endif
            endif
        enddo
*       not much sense to check for elevation
        if ( istation.le.0 ) then
            if ( elevmin.gt.-1e33 ) print *
     +            ,'Disregarding minimum elevation ',elevmin
            if ( elevmax.lt.+1e33 ) print *
     +            ,'Disregarding maximum elevation ',elevmax
        endif
        if ( istation.eq.0 ) then
            do i=1,nn
                dist(i) = 3e33
            enddo
        endif
        print '(a)','# getsealev: searching nucat.dat'
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = len_trim(dir)
            dir(ldir+1:) = '/PSMSLData/'
        else
            dir = '/usr/people/oldenbor/NINO/PSMSLData/'
        endif
        ldir = len_trim(dir)
        if ( lwrite ) print *,'opeining ',dir(1:ldir)//'nucat.dat'
        open(unit=1,file=dir(1:ldir)//'nucat.dat',status='old')
*       skip header
        do i=1,4
            read(1,'(a)') line
        enddo
*       initialize country array
        do i=0,999
            country(i) = ' '
        enddo
*       reformatted data file
        if ( lwrite ) print *,'opeining ',dir(1:ldir)//'psmsl.mydat'
        open(unit=2,file=dir(1:ldir)//'psmsl.mydat',status='old'
     +        ,form='formatted',access='direct',recl=85)
*
        i = 1
  100   continue
        read(1,'(a)',end=200) line
*       heuristics, hopefully they do not change the format
        if ( line.eq.' ' .or. line(2:5).eq.'Code' ) goto 100
        if ( line(2:6).eq.'ERROR' .or. index(line,'<<<<<<<<<<<').ne.0 )
     +       goto 100
        if ( line(1:30).eq.' ' ) then
            if ( lwrite ) print *,'reading country ',trim(line(31:))
            if ( line(31:33).eq.'A  ' ) then
                k = 999
            else
                read(line(31:),'(i3)') k
            endif
            if ( country(k).eq.' ' ) then
                country(k) = line(36:)
            else
                write(0,*) 'getsealev: error: read countrycode twice '
     +                ,country(k),line
                call abort
            endif
            goto 100
        endif
*       change code for Antarctica from A to 999
        if ( line(2:4).eq.'A  ' ) then
            line(2:4) = '999'
        endif
        if ( line(2:4).eq.'150' .or. line(2:4).eq.'140' ) then
*       Netherlands are OK without RLR, some of Germany too (take all)
            read(line,1000,err=930) ii(i),name(i),clat,clon,ac,fc,nyr(i)
     +            ,yr1(i),yr2(i),fmiss(i)
        elseif ( line(95:).ne.' ' ) then
            read(line,1000,err=930) ii(i),name(i),clat,clon,ac,fc,idum
     +            ,fdum,nyr(i),yr1(i),yr2(i),fmiss(i)
 1000       format(i7,1x,a,a,1x,a,2a3,4x,i4,1x,i4,1x,i4,f5.1,i4,1x,i4,1x
     +            ,i4,f5.1)
        else
*       the docs tell us NEVER to use metric values for time series
*       analysis (except in the Netherlands and some German stations)
            goto 100
        endif
*
*       check that we have enough years of data
        if ( nmin(0).gt.0 ) then
            if ( nyr(i).lt.nmin(0) ) goto 100
        endif
*
        call latlon(clat,clon,rlat(i),rlon(i))
        if ( istation.eq.0 ) then
*
*           search closest
            dlon = min(abs(rlon(i)-slon),
     +            abs(rlon(i)-slon-360),
     +            abs(rlon(i)-slon+360))
            dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
            i = i + 1
        elseif ( istation.gt.0 ) then
*           look for a specific station
            if ( ii(i).eq.istation ) then
                i = i + 1
                goto 200
            endif
        elseif ( sname.ne.' ' ) then
*           look for a station with sname as substring
            if ( index(name(i),trim(sname)).ne.0 ) then
                i = i + 1
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
            endif
        elseif ( nlist.gt.0 ) then
            do j=1,nlist
                if ( ii(i).eq.list(j) ) then
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
            do k=1,len_trim(name(jj))
                if ( name(jj)(k:k).eq.' ' ) name(jj)(k:k) = '_'
            enddo
            print '(5a)','# ',name(jj),' (',trim(country(ii(jj)/1000
     +            )),')' 
            print '(a,f6.2,a,f7.2,a)','# coordinates: ',rlat(jj)
     +            ,'N, ',rlon(jj),'E'
            print '(a,i6,2a)','# Station code: ',ii(jj),' ',name(jj)
            if ( istation.le.0 ) then
                print '(a,i4,a,i4,a,i4,a,f5.1,a)','Found ',nyr(jj),
     +                ' years with data in ',yr1(jj),'-',yr2(jj),' ('
     +                ,fmiss(jj),'% missing)'
            else
                call getdata('slv',2,ii(jj),1,nmin)
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
  902   print *,'error reading iso-country-codes',string
        call abort
  903   print *,'please give number of stations to find, not ',string
        call abort
  904   print *,'please give minimum number of years, not ',string
        call abort
  930   write(0,*)'error reading line ',line
        call abort
  999   continue
        end

      SUBROUTINE LATLON(CLAT,CLON,ALAT,ALON)
C
      SAVE
C
C CLAT AND CLON ARE 8 BYTE CHARACTERS CONTAINING LAT AND LON
C E.G. ' 51 44 N' OR '123 33 E'
C ALAT AND ALON ARE LAT (RANGE +90 TO -90 NORTH POSITIVE)
C       AND LON (RANGE 0 TO 360 EAST - no, -180 - 180
C
      CHARACTER*8 CLAT,CLON
      CHARACTER*1 CH(8),CC
C
      READ(CLAT,901) CH
  901 FORMAT(8A1)
      IF(CH(1).NE.' '.OR.CH(4).NE.' '.OR.CH(7).NE.' '.OR.
     &  (CH(8).NE.'N'.AND.CH(8).NE.'S')) THEN
       WRITE(6,*) 
     & ' ILLEGAL FORMAT IN S/R LATLON: CLAT =',CLAT
       STOP
      ENDIF
C
      READ(CLON,901) CH
      IF(CH(4).NE.' '.OR.CH(7).NE.' '.OR.
     &  (CH(8).NE.'W'.AND.CH(8).NE.'E')) THEN
       WRITE(6,*)
     & ' ILLEGAL FORMAT IN S/R LATLON: CLON =',CLON
       STOP
      ENDIF
C
      READ(CLAT,902) II,JJ,CC
  902 FORMAT(2I3,1X,A1)
      ALAT = FLOAT(II) + FLOAT(JJ)/60.
      IF(CC.EQ.'S') ALAT = - ALAT
C
      READ(CLON,902) II,JJ,CC
      ALON = FLOAT(II) + FLOAT(JJ)/60.
***      IF(CC.EQ.'W') ALON = 360. - ALON
      IF(CC.EQ.'W') ALON = - ALON
C
      RETURN
      END
