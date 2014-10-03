        program getusrunoff
*
*       get HCDN runoff stations near a given coordinate, or with a given name,
*       or the data
*
        implicit none
        integer nn
        parameter(nn=2000)
	double precision pi
	parameter (pi = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,ldir,istation,nmin(0:48),yr,ilat,ilon,ncom
     +        ,nok,nlist,mo,dy
        integer iwmo(nn),firstyear(nn),lastyear(nn)
     +        ,nyr(nn),huc(nn),ind(nn),list(nn)
        real rlat(nn),rlon(nn),area(nn),slat,slon,slat1,slon1
     +        ,dist(nn),dlon,runoff(12,2),elev(nn),rmin,rlonmin,rlonmax
     +        ,rlatmin,rlatmax,r,elevmin,elevmax,drunoff(31,12)
        character name(nn)*48,state(nn)*2,ts*1,per*1,ew*1,ns*1
     +        ,wyear(115)*1,dailyval(12)*8
        character string*80,sname*20
        character dir*256,program*255
        integer iargc,llen
        external iargc,getarg,llen
*
*
        call getarg(0,program)
        if ( iargc().lt.1 ) then
            print '(a)','usage: getusrunoff [lat lon|name] [n] '//
     +           '[min years] [elevmin elev] [elevmax elev] '//
     +           '[dist mindist]'
            print *,'gives stationlist with years of data' 
            print '(a)','       getusrunoff station_id'
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
            do i=1,n
                dist(i) = 3e33
            enddo
        endif
*
        if ( istation.gt.0 ) then
            print '(a,i8.8)',
     +           '# Searching for HCDN runoff station nr ',istation
        endif
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = llen(dir)
            dir(ldir+1:) = '/HCDNData/'
        else
            dir = '/usr/people/oldenbor/NINO/HCDNData/'
        endif
        ldir = llen(dir)
        open(unit=1,file=dir(1:ldir)//'hcdn/stations.dat',status='old')
        open(unit=2,file=dir(1:ldir)//'hcdn/wyears.dat',status='old')
        open(unit=3,file=dir(1:ldir)//'hcdn/comments.dat',status='old')
*       
        i = 1
  100   continue
        read(1,1000,err=920,end=200) iwmo(i),name(i),huc(i),area(i),ts
     +        ,per,ncom,state(i),ilat,ns,ilon,ew,elev(i)
 1000   format(i8.8,1x,a48,1x,i8,1x,f8.0,1x,2a,1x,i2,4x,a,5x,i6,a,1x,
     +		i7,a,f8.2)
        read(2,1001,err=920,end=200) k,nyr(i),wyear
 1001   format(i8.8,1x,i3,1x,115a1)
*       no data?
        if ( ts.eq.'N' .or. per.eq.'N' ) goto 100
*       convert elev, area to m, km^2
        elev(i) = elev(i)*0.3048
        area(i) = area(i)*2.590
*       convert latlon
        rlat(i) = ilat/10000 
     +        + (mod(ilat,10000)/100)/60. 
     +        + mod(ilat,100)/3600.
        if ( ns.eq.'N' ) then
*           OK
        elseif ( ns.eq.'S' ) then
            rlat(i) = -rlat(i)
        else
            write(0,*) 'error: expected N or S, not ',ns
            call abort
        endif
        rlon(i) = ilon/10000 
     +        + (mod(ilon,10000)/100)/60. 
     +        + mod(ilon,100)/3600.
        if ( ew.eq.'E' ) then
*           OK
        elseif ( ew.eq.'W' ) then
            rlon(i) = -rlon(i)
        else
            write(0,*) 'error: expected E or W, not ',ew
            call abort
        endif
        do yr=1874,1988
            if ( wyear(yr-1873).eq.'*' ) then
                firstyear(i) = yr
                goto 101
            endif
        enddo
  101   continue
        do yr=1988,1874,-1
            if ( wyear(yr-1873).eq.'*' ) then
                lastyear(i) = yr
                goto 102
            endif
        enddo
  102   continue
*       convert to uppercase
        call toupper(name(i))
*
*       check that we have enough years of data
        if ( nmin(0).gt.0 ) then
            if ( nyr(i).lt.nmin(0) ) goto 100
        endif
*
*       check elevation
        if ( elev(i).lt.elevmin .or. elev(i).gt.elevmax ) goto 100
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
            if (  index(name(i),sname(1:llen(sname))).ne.0 ) then
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
                if ( jj.eq.0 ) goto 700
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
            print '(5a)','# ',name(jj),' (',state(jj),')' 
            print '(a,f6.2,a,f7.2,a,f8.2,a,f10.0,a)','# coordinates: ',
     +		rlat(jj) ,'N, ',rlon(jj),'E, ',elev(jj),
     +		'm, upstream area ',area(jj),'km^2' 
            print '(a,i8.8,4a)','# HCDN station code: ',iwmo(jj)
     +            ,' ',name(jj)(1:llen(name(jj)))
            if ( istation.le.0 ) then
                print '(a,i4,a,i4,a,i4)','Found ',nyr(jj)
     +                ,' years of data in ',firstyear(jj),'-'
     +                ,lastyear(jj)
*               get comments from comment file.  could be done smarter
                rewind(3)
  300           continue
                read(3,3000,end=320) k
 3000           format(i8,i3,1x,a)
                if ( k.eq.iwmo(jj) ) then
***                    print '(a)','<small>'
  310               continue
                    read(3,3000,end=320) kk,k,string
                    if ( kk.eq.iwmo(jj) ) then
                        print '(a)',string(1:llen(string))
                        goto 310
                    else
***                        print '(a)','</small>'
                        goto 320
                    endif
                endif
                goto 300
  320           continue
            elseif ( index(program,'daily').eq.0 ) then
                write(dir(ldir+1:),'(a,i2.2,a,i8.8,a)')
     +                'hcdn/ascii/monthlya/region',huc(jj)/1000000,
     +                '/',iwmo(jj),'.amm'
                ldir = llen(dir)
***                print '(2a)','file ',dir(1:ldir)
                print '(a)','# runoff converted to [m3/s]'
                open(2,file=dir(1:ldir),status='old',err=940)
                do k=1,12
                    runoff(k,1) = -9999
                enddo
*               Read and print data.  Note the use of water years.
  600           continue
                read(2,*,end=610,err=930) istation,yr,(runoff(k,2),
     +			k=1,12)
*               convert to m^3/s
                do k=1,12
                    runoff(k,2) = 0.02832*runoff(k,2)
                enddo
                if ( istation.ne.iwmo(jj) ) then
                    write(0,*)
     +                    'getusrunoff: error: inconsistent station ID:'
     +                    ,iwmo(jj),istation
                    call abort
                endif
 2001           format(i5,12f10.3)
                print 2001,yr-1,(runoff(k,1),k=4,12),(runoff(k,2),k=1,3)
                do k=1,12
                    runoff(k,1) = runoff(k,2)
                enddo
                goto 600
  610           continue
                print 2001,yr,(runoff(k,1),k=4,12),-9999.,-9999.,-9999.
            else                ! daily data
                write(dir(ldir+1:),'(a,i2.2,a,i8.8,a)')
     +                'hcdn/ascii/dailya/region',huc(jj)/1000000,
     +                '/',iwmo(jj),'.adv'
                ldir = llen(dir)
***                print '(2a)','file ',dir(1:ldir)
                print '(a)','# runoff converted to [m3/s]'
                open(2,file=dir(1:ldir),status='old',err=940)
*               Read and print data.  Note the use of water years.
  650           continue
                do mo=1,12
                    do dy=1,31
                        drunoff(dy,mo) = 3e33
                    enddo
                enddo
                do dy=1,31
                    read(2,'(i8,1x,i4,1x,i2,1x,12a8)',end=660,err=930)
     +                    istation,yr,i,dailyval
                    if ( i.ne.dy ) then
                        write(0,*) program,':error: expected day
     +                        ',dy,' but got ',i
                        call abort
                    endif
                    if ( istation.ne.iwmo(jj) ) then
                        write(0,*) program
     +                        ,': error: inconsistent station ID:'
     +                        ,iwmo(jj),istation
                        call abort
                    endif
                    do mo=1,12
                        if ( dailyval(mo).ne.' ' ) then
                            read(dailyval(mo),*) drunoff(dy,mo)
                            drunoff(dy,mo) = 0.02832*drunoff(dy,mo)
                        endif
                    enddo
                enddo
 2002           format(i5,i3,i3,f10.3)
                do mo=1,3
                    do dy=1,31
                        if ( drunoff(dy,mo).lt.1e33 ) then
                            print 2002,yr-1,mo+9,dy,drunoff(dy,mo)
                        endif
                    enddo
                enddo
                do mo=4,12
                    do dy=1,31
                        if ( drunoff(dy,mo).lt.1e33 ) then
                            print 2002,yr,mo-3,dy,drunoff(dy,mo)
                        endif
                    enddo
                enddo
                goto 650
  660           continue
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
