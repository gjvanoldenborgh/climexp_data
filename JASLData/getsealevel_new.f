        program getsealevel
*
*       get sealvel stations near a given coordinate, or with a given name,
*       or the data
*
        implicit none
        integer nn
        parameter(nn=100)
	double precision pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
        integer i,j,k,n,m,ldir,istation,nyr,nmin
        integer iwmo(0:nn),imod(0:nn),ielevs(0:nn),firstyear(0:nn)
     +        ,lastyear(0:nn),ilat(2),ilon(2),ci(0:nn)
        real rlat(0:nn),rlon(0:nn),slat,slon,slat1,slon1,dist(0:nn)
     +        ,fstation
        character name(0:nn)*18,country(0:nn)*18
        character string*80,sname*18,version*1,ns*1,ew*1
        character dir*256
        integer iargc,llen
        external iargc,getarg,llen

c     iwmo=3 digit JASL station number
c     imod=1 letter modifier for independent series, translated to integer
c     name=18 character station name
c     country=18 character country name
c     dd-mmN=latitude in degrees.minutes, [NS]
c     dd-mmE=longitude in degrees.miutes, [EW]
c     first-last=first-last year for which there is data
c     ci=compelteness index, 100-missingpercentage
*
        
        if ( iargc().lt.1 ) then
            print '(a)','usage: getsealevel [lat lon|name] [min years]'
            print *,'gives stationlist with years of data' 
            print '(a)','       getpress station_id'
            print *,'gives historical sealevel heights station_id,'
            stop
        endif
        call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,10
     +        ,nmin)
        do i=1,n
            dist(i) = 3e33
        enddo
*
        if ( istation.eq.0 ) then
            print '(a,f6.2,a,f7.2,3a)','Searching for stations near '
     +            ,slat,'N, ',slon,'E in inventry.lis'
            if ( nmin.gt.1 ) print '(a,i4,a)','Requiring at least '
     +                ,nmin,' years of data'
        elseif ( istation.gt.0 ) then
            print '(a,i3.3,2a)','Searching for station nr '
     +                ,istation/10,char(mod(istation,10)+ichar('A')),
     +                ' in inventry.lis'
        endif
        open(unit=1,file=dir(1:ldir)//'inventry.lis',status='old')
*
  100   continue
*       there are many comment strings in the file.
*       the easiest way to skip them is to demand something at the end
        read(1,'(a)',end=200) string
        if ( string(77:79).eq.'   ' .or. string(77:79).eq.' CI' ) 
     +        goto 100
        read(string,1000,err=920) iwmo(0),version,name(0)
     +        ,country(0),ilat,ns,ilon,ew,firstyear(0),lastyear(0),ci(0)
 1000   format(i3.3,a1,11x,a18,a18,i2.2,1x,i2.2,a1,1x,i3.3,1x,i2.2,a1,1x
     +        ,i4.4,1x,i4.4,1x,i3)
*       convert to uppercase - stupid f77
        do i=1,len(name(0))
            if (  ichar(name(0)(i:i)).ge.ichar('a') .and.
     +            ichar(name(0)(i:i)).le.ichar('z') ) then
                name(0)(i:i) = char(ichar(name(0)(i:i)) - ichar('a') +
     +                ichar('A'))
            endif
        enddo
        rlat(0) = ilat(1) + ilat(2)/60.
        if ( ns.eq.'N' .or. ns.eq.'n' ) then
*           nothing
        elseif ( ns.eq.'S' .or. ns.eq.'s' ) then
            rlat(0) = -rlat(0)
        else
            write(0,*) 'getsealevel: error: ns = ',ns
            call abort
        endif
        rlon(0) = ilon(1) + ilon(2)/60.
        if ( ew.eq.'E' .or. ew.eq.'e' ) then
*           nothing
        elseif ( ew.eq.'W' .or. ew.eq.'w' ) then
            rlon(0) = -rlon(0)
        else
            write(0,*) 'getsealevel: error: e = ',ew
            call abort
        endif
        if (  ichar(version).ge.ichar('A') .and. 
     +        ichar(version).le.ichar('Z') ) then
            imod(0) = ichar(version) - ichar('A')
        elseif (  ichar(version).ge.ichar('a') .and. 
     +            ichar(version).le.ichar('z') ) then
            imod(0) = ichar(version) - ichar('a')
        else
            write(0,*) 'getsealevel: error: version = ',version
            call abort
        endif
        nyr = lastyear(0)-firstyear(0)+1
*
*       search closest
        if ( istation.eq.0 ) then
            dist(0) = (rlat(0)-slat)**2 + 
     +            ((rlon(0)-slon)*cos(slat/180*pi))**2
            do i=1,n
                if ( dist(0).lt.dist(i) ) goto 110
            enddo
            go to 100
        elseif ( istation.gt.0 ) then
            if ( iwmo(0).eq.istation/10 .and. 
     +           imod(0).eq.mod(istation,10) ) then
                i = 1
                goto 110
            else
                goto 100
            endif
        elseif ( sname.ne.' ' ) then
*           look for a station with sname as substring
            if ( index(name(0),sname(1:llen(sname))).ne.0 ) then
                n = n + 1
                if ( n.gt.nn ) then
                    print *,'Maximum ',nn,' stations'
                    stop
                endif
                i = n
            else
                goto 100
            endif
        elseif ( slat1.lt.1e33 ) then
*       look for a station in the box
            if ( (slon1.gt.slon .and. 
     +            rlon(0).gt.slon .and. rlon(0).lt.slon1
     +            .or.
     +            slon1.lt.slon .and.
     +            (rlon(0).lt.slon1 .or. rlon(0).gt.slon)
     +            ) .and. (
     +            rlat(0).gt.min(slat,slat1) .and.
     +            rlat(0).lt.max(slat,slat1) )
     +            ) then
                n = n + 1
                if ( n.gt.nn ) then
                    print *,'Maximum ',nn,' stations'
                    stop
                endif
                i = n
            else
                goto 100
            endif
        else
            print *,'internal error 31459263'
            call abort
        endif
  110   continue
*
*       check that we have enough years of data
        if ( nmin.gt.0 ) then
            if ( nyr*ci(0)/100..lt.nmin ) goto 100
***            print *,'OK'
        endif
*
*       insert in ordered list
***     print *,'Found closer station ',name(0),i
        do j=n,i+1,-1
            call moveit(n,j-1,j,dist,iwmo,imod,name,country,rlat
     +            ,rlon,firstyear,lastyear,ci)
        enddo
        call moveit(n,0,i,dist,iwmo,imod,name,country,rlat
     +        ,rlon,firstyear,lastyear,ci)
        if ( istation.le.0 ) goto 100
  200   continue
*
*       output
        do i=1,n
            if ( istation.le.0 ) print '(a)'
     +            ,'=============================================='
            print '(2a,a,a)',name(i),'(',country(i)(1:llen(country(i))),
     +            ')' 
            print '(a,f6.2,a,f7.2,a)','coordinates: ',rlat(i)
     +            ,'N, ',rlon(i),'E, '
*
            do j=1,llen(name(i))
                if ( name(i)(j:j).eq.' ' ) name(i)(j:j) = '_'
            enddo
            print '(a,i3.3,3a)','JASL station code: '
     +                ,iwmo(i),char(imod(i)+ichar('A')),' ',name(i)
            if ( istation.le.0 ) then
                print '(a,i4,a,i4,a,i4)','Found ',nint((lastyear(i)
     +                -firstyear(i)+1)*ci(i)/100.)
     +                ,' years of data in ',firstyear(i),'-',lastyear(i)
            else
                call getenv('DIR',dir)
                if ( dir.ne.' ' ) then
                    ldir = llen(dir)
                    dir(ldir+1:) = '/JASLData/data/'
                else
                    dir = '/usr/people/oldenbor/NINO/JASLData/data/'
                endif
                ldir = llen(dir)
                write(dir(ldir+1:),'(a,i3.3,2a)') 'm',iwmo(i)
     +                ,char(imod(i)+ichar('a')),'.dat'
                ldir = llen(dir)
                open(1,file=dir(1:ldir),status='old')
                read(1,'(a)') string
                print '(a)',string
                stop
            endif
        enddo
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
  999   continue
        end
*
        subroutine moveit(nn,i,j,dist,iwmo,imod,name,country,rlat,rlon
     +        ,firstyear,lastyear,ci)
*       
*       move record i to j
        implicit none
        integer nn,i,j
        integer iwmo(0:nn),imod(0:nn),firstyear(0:nn),lastyear(0:nn)
     +        ,ci(0:nn)
        real rlat(0:nn),rlon(0:nn),dist(0:nn)
        character name(0:nn)*18,country(0:nn)*18
*       
*       boring...
        iwmo(j) = iwmo(i)
        imod(j) = imod(i)
        firstyear(j) = firstyear(i)
        lastyear(j) = lastyear(i)
        ci(j) = ci(i)
        rlat(j) = rlat(i)
        rlon(j) = rlon(i)
        dist(j) = dist(i)
        name(j) = name(i)
        country(j) = country(i)
*
        end
