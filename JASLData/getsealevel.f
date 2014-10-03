        program getsealevel
*
*       get sealevel stations near a given coordinate, or with a given name,
*       or the data
*
        implicit none
        integer nn
        parameter(nn=500)
	double precision pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,m,ldir,istation,nyr,nmin(0:48),yr,
     +        idat(2,6),ilev(12),nok,nlist
        integer iwmo(nn),imod(nn),ielevs(nn),firstyear(nn)
     +        ,lastyear(nn),ilat(2),ilon(2),ci(nn),ind(nn),list(nn)
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn)
     +        ,fstation,dlon,rmin,elevmin,elevmax,rlonmin,rlonmax
     +        ,rlatmin,rlatmax
        character name(nn)*18,country(nn)*18
        character string*82,sname*18,version*1,ns*1,ew*1,v*1,nam*4
        character dir*256
        integer iargc,llen
        external llen

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
*
        if ( istation.gt.0 ) then
            print '(a,i3.3,2a)',
     +            '# Searching for JASL tide-gauge (sealevel) '//
     +           'station nr '
     +            ,istation/10,char(mod(istation,10)+ichar('A'))
     +            ,' in inventry.lis'
        endif
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = llen(dir)
            dir(ldir+1:) = '/JASLData/'
        else
            dir = '/usr/people/oldenbor/NINO/JASLData/'
        endif
        ldir = llen(dir)
        open(unit=1,file=dir(1:ldir)//'inventry.lis',status='old')
*
        i = 1
  100   continue
*       there are many comment strings in the file.
*       the easiest way to skip them is to demand something at the end
        read(1,'(a)',end=200) string
        if ( string(77:79).eq.'   ' .or. string(77:79).eq.' CI' ) 
     +        goto 100
        read(string,1000,err=920) iwmo(i),version,name(i)
     +        ,country(i),ilat,ns,ilon,ew,firstyear(i),lastyear(i),ci(i)
 1000   format(i3.3,a1,11x,a18,a18,i2.2,1x,i2.2,a1,1x,i3.3,1x,i2.2,a1,1x
     +        ,i4.4,1x,i4.4,1x,i3)
*       convert to uppercase
        call toupper(name(i))
        rlat(i) = ilat(1) + ilat(2)/60.
        if ( ns.eq.'N' .or. ns.eq.'n' ) then
*           nothing
        elseif ( ns.eq.'S' .or. ns.eq.'s' ) then
            rlat(i) = -rlat(i)
        else
            write(0,*) 'getsealevel: error: ns = ',ns
            call abort
        endif
        rlon(i) = ilon(1) + ilon(2)/60.
        if ( ew.eq.'E' .or. ew.eq.'e' ) then
*           nothing
        elseif ( ew.eq.'W' .or. ew.eq.'w' ) then
            rlon(i) = -rlon(i)
        else
            write(0,*) 'getsealevel: error: e = ',ew
            call abort
        endif
        if (  ichar(version).ge.ichar('A') .and. 
     +        ichar(version).le.ichar('Z') ) then
            imod(i) = ichar(version) - ichar('A')
        elseif (  ichar(version).ge.ichar('a') .and. 
     +            ichar(version).le.ichar('z') ) then
            imod(i) = ichar(version) - ichar('a')
        else
            write(0,*) 'getsealevel: error: version = ',version
            call abort
        endif
        nyr = lastyear(i)-firstyear(i)+1
*
*       check that we have enough years of data
        if ( nmin(0).gt.0 ) then
            if ( nyr*ci(i)/100..lt.nmin(0) ) goto 100
***            print *,'OK'
        endif
*
        if ( istation.eq.0 ) then
*       search closest
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
        if ( n.eq.0 ) then
            print '(a)','Cannot locate station'
            stop
        endif
        nok = 0
        if ( istation.le.0 ) print '(a,i5,a)','Found ',n,' stations'
        if ( nlist.gt.0 ) then
            call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
        endif
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
            print '(5a)','# ',name(jj),'(',trim(country(jj)),')'
            print '(a,f6.2,a,f7.2,a)','# coordinates: ',rlat(jj)
     +            ,'N, ',rlon(jj),'E, '
            print '(a,i3.3,3a)','# JASL station code: '
     +                ,iwmo(jj),char(imod(jj)+ichar('A')),' ',name(jj)
            if ( istation.le.0 ) then
                print '(a,i4,a,i4,a,i4)','Found ',nint((lastyear(jj)
     +                -firstyear(jj)+1)*ci(jj)/100.)
     +                ,' years of data in ',firstyear(jj),'-'
     +                ,lastyear(jj)
            else
                write(dir(ldir+1:),'(a,i3.3,2a)') '/data/m',iwmo(jj)
     +                ,char(imod(jj)+ichar('a')),'.dat'
                ldir = llen(dir)
                open(1,file=dir(1:ldir),status='old',err=940)
*               read and print header, identifying the units
                read(1,'(a)') string
                k = index(string,'MM')
                string(k:) = '[mm]'
                print '(2a)','# sealevel ',trim(string)
*               read and print data
  600           continue
                do k=1,12
                    ilev(k) = -9999
                enddo
  610           continue
 2000           format(i3,a1,1x,a4,1x,i4,1x,i1,1x,6(i6,i3))
                read(1,2000,end=700,err=930) k,v,nam,yr,kk,idat
                if ( k.ne.iwmo(jj) .or. v.ne.char(imod(jj)+ichar('A')) )
     +                then
                    write(0,*)
     +                    'getsealevel: error: inconsistent station ID:'
     +                    ,iwmo(jj),char(imod(jj)+ichar('A')),k,v
                    call abort
                endif
                if ( kk.lt.1 .or. kk.gt.2 ) then
                    write(0,*) 'getsealevel: error: expected [12] not '
     +                    ,kk
                    call abort
                endif
                do k=1,6
                    if ( idat(1,k) .ne. 9999 ) then
                        ilev(k+6*(kk-1)) = idat(1,k)
                    endif
                enddo
*               while-loop
                if ( kk.eq.2 ) then
 2001               format(i5,12i6)
                    print 2001,yr,ilev
                    goto 600
                else
                    goto 610
                endif                
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
  930   print *,'error reading data at/after line '
        print 2000,j,v,nam,yr,k,idat
        call abort
  940   print *,'error: cannot locate data file ',dir(1:ldir)
        call abort
  999   continue
        end
