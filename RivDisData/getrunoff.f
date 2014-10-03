        program getrunoff
*
*       get sealvel stations near a given coordinate, or with a given name,
*       or the data
*
        implicit none
        integer nn
        parameter(nn=2000)
	double precision pi
	parameter (pi = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,ldir,istation,nmin(0:48),yr,nok,nlist
        integer iwmo(nn),ielev(nn),area(nn),firstyear(nn)
     +        ,lastyear(nn),nyr(nn),ind(nn),list(nn)
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon
     +        ,runoff(12),rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin
     +        ,rlatmax
        character name(nn)*20,country(nn)*20,river(nn)*20
        character string*80,sname*20
        character dir*256
        integer iargc,llen
        external iargc,getarg,llen

c     5 digit RivDis station number
c     lat,lon,ielev,area
c     firstyr,lastyr,nyr of data
c     20 Character country name
c     20 character station name
c     20 character river name
*
        if ( iargc().lt.1 ) then
            print '(a)','usage: getrunoff [lat lon|name] [min years]'
            print *,'gives stationlist with years of data' 
            print '(a)','       getrunoff station_id'
            print *,'gives historical runoff station_id,'
            stop
        endif
        call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,1
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
        if ( istation.gt.0 ) then
            print '(a,i5.5)',
     +            'Searching for RivDis runoff station nr ',istation
        endif
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = llen(dir)
            dir(ldir+1:) = '/RivDisData/'
        else
            dir = '/usr/people/oldenbor/NINO/RivDisData/'
        endif
        ldir = llen(dir)
        open(unit=1,file=dir(1:ldir)//'rivdis.index',status='old')
*
        i = 1
  100   continue
        read(1,1000,err=920,end=200) iwmo(i),rlat(i),rlon(i),ielev(i)
     +        ,area(i),firstyear(i),lastyear(i),nyr(i),country(i),
     +        name(i),river(i)
 1000   format(i5.5,2f8.2,i6,i8,3i5,x,a,x,a,x,a)
*       convert to uppercase
        call toupper(river(i))
        call toupper(name(i))
*
*       check that we have enough years of data
        if ( nmin(0).gt.0 ) then
            if ( nyr(i).lt.nmin(0) ) goto 100
        endif
*
*       check elevation
        if ( ielev(i).lt.elevmin .or. ielev(i).gt.elevmax ) goto 100
        if ( ielev(i).eq.-9999 .and.
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
            if ( iwmo(i).eq.istation  ) then
                i = i + 1
                goto 200
            endif
        elseif ( sname.ne.' ' ) then
*           look for a station with sname as substring
            if (  index(name(i),sname(1:llen(sname))).ne.0 .or.
     +            index(river(i),sname(1:llen(sname))).ne.0 ) then
                i = i + 1
                if ( i.gt.nn ) then
                    print *,'Maximum ',nn,' stations'
                    stop
                endif
            else
                goto 100
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
                if ( iwmo(i).eq.list(j) ) then
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
        if ( n.eq.0 ) then
            print '(a)','Cannot locate station'
            stop
        endif
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
            do k=1,llen(name(jj))
                if ( name(jj)(k:k).eq.' ' ) name(jj)(k:k) = '_'
            enddo
            do k=1,llen(river(jj))
                if ( river(jj)(k:k).eq.' ' ) river(jj)(k:k) = '_'
            enddo
            print '(6a)',name(jj),' on the ',river(jj),' (',
     +            country(jj)(1:llen(country(jj))),')' 
            print '(a,f6.2,a,f7.2,a,i6,a,i8,a)','coordinates: ',rlat(jj)
     +            ,'N, ',rlon(jj),'E, ',ielev(jj),'m, upstream area '
     +            ,area(jj),'km^2' 
            print '(a,i5.5,4a)','RivDis station code: ',iwmo(jj)
     +            ,' ',name(jj)(1:llen(name(jj))),'/',
     +            river(jj)(1:llen(river(jj)))
            if ( istation.le.0 ) then
                print '(a,i4,a,i4,a,i4)','Found ',nyr(jj)
     +                ,' years of data in ',firstyear(jj),'-'
     +                ,lastyear(jj)
            else
                write(dir(ldir+1:),'(3a,i5.5,a)') '/data/',
     +                country(jj)(1:llen(country(jj))),'/',iwmo(jj)
     +                ,'/data.txt'
                ldir = llen(dir)
***                print *,'opening ',dir(1:ldir)
                open(2,file=dir(1:ldir),status='old',err=940)
*               read and print (uninterpreted) header
                read(2,'(a)') string
                print '(a)',string
*               read and print data
  600           continue
                do k=1,12
                    runoff(k) = -9999
                enddo
                read(2,*,end=700,err=930) k,yr,runoff
                if ( k.ne.iwmo(jj) ) then
                    write(0,*)
     +                    'getrunoff: error: inconsistent station ID:'
     +                    ,iwmo(jj),k
                    call abort
                endif
                do k=1,12
                    if ( runoff(k).ge.0 ) goto 610
                enddo
                goto 600
  610           continue
 2001           format(i5,12f10.2)
                print 2001,yr,runoff
                goto 600
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
  920   print *,'error reading information from line ',string
        call abort
  930   print *,'error reading data at/after line ',j,yr,runoff
        call abort
  940   print *,'error: cannot locate data file ',dir(1:ldir)
        call abort
  999   continue
        end
