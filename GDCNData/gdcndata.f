        program gdcndata
*
*       get GHCN-D stations near a given coordinate, or with a given name,
*       or the data
*
        implicit none
        integer nn
        parameter(nn=200000)
	double precision pi
	parameter (pi = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,ldir,nmin(0:48),yr,nok,nlist
     +        ,idates(18),iecd,ist,iwm,igsn
        integer iwmo(nn),firstyr(nn),lastyr(nn),nyr(nn),ind(nn)
     +        ,type,tmin,tmax,temp,prcp,mo,dy,ielev,vals(31)
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon
     +        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin
     +        ,rlatmax,val,elev(nn)
        character name(nn)*30,stations(nn)*11,elevflag(nn)*1,
     +       datasource*1,qcflag*1
        character station*11,id*11,list(nn)*11,id1*8,id2*8,wmo*5
        character flags1(31)*1,flags2(31)*1,flags3(31)*1,dummy1*1,
     +       dummy2*1
        character country(0:999)*50,cc(0:999)*2,elements(9)*4,element*4
     +       ,units(9)*10
        character string*200,line*500,sname*25
        character dir*256,command*1024
        logical lwrite
        integer iargc,llen,getcode
        data elements /'TMIN','TEMP','TMAX','PRCP','TAVE','TDIF','PRCP',
     +       'SNOW','SNWD'/
        data units /'[Celsius]','[Celsius]','[Celsius]','[mm/day]',
     +       '[Celsius]','[Celsius]','[mm/day]','[mm/day]','[mm]'/
c
c       11 character station ID (also letters!)
c       7 digit latitude [decimal degree]
c       8 digit longitude [decimal degree]
c       5 digit elevation [m]
c       1 character flag, 'E' if estimated
c       1 character data source, 'G' if GCOS data
c       30 character station name
c       5 character WMO station ID
c       8 character other ID
c       8 character other ID
c
        lwrite = .false.
        if ( iargc().lt.1 ) then
            print '(a)','usage: gdcn{tmin|tmax|prcp|snow|snwd} '//
     +            '[lat lon|name] [min years]'
            print *,'gives stationlist with years of data' 
            print '(a)','       gdcn{tmin|temp|tmax|prcp station_id'
            print *,'gives data station_id,'
            stop
        endif
        call getarg(0,string)
        if ( index(string,'gdcntemp').ne.0 ) then
            type = 2
        elseif ( index(string,'gdcntmin').ne.0 ) then
            type = 1
        elseif ( index(string,'gdcntmax').ne.0 ) then
            type = 3
        elseif ( index(string,'gdcntave').ne.0 ) then
            type = 5
        elseif ( index(string,'gdcntdif').ne.0 ) then
            type = 6
        elseif ( index(string,'gdcnprcpall').ne.0 ) then
            type = 4
        elseif ( index(string,'gdcnprcp').ne.0 ) then
            type = 7
        elseif ( index(string,'gdcnsnow').ne.0 ) then
            type = 8
        elseif ( index(string,'gdcnsnwd').ne.0 ) then
            type = 9
        else
            print *,'do not know which database to use when running as '
     +            ,string(1:llen(string))
            call abort
        endif
        call gdcngetargs(sname,slat,slon,slat1,slon1,n,nn,station,1
     +        ,nmin,rmin,elevmin,elevmax,qcflag,list,nn,nlist)
*       no monthly time information yet
        do i=1,48
            if ( nmin(i).ne.0 ) then
                nmin(0) = nmin(i)
                if ( station(1:1).eq.'-' ) then
                    print *,'No monthly information yet, using years.'
                endif
            endif
        enddo
        if ( station.eq.'-1' ) then
            do i=1,nn
                dist(i) = 3e33
            enddo
        endif
*
        if ( station(1:1).ne.'-' ) then
            print '(2a)','# Searching for GHCND series nr ',station
        endif
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = llen(dir)
            dir(ldir+1:) = '/GDCNData/'
        else
            dir = '/usr/people/oldenbor/NINO/GDCNData/'
        endif
        ldir = llen(dir)
        do i=0,0
            country(i) = 'unknown'
            cc(i) = '  '
        enddo
        i = 0
        open(unit=1,file=dir(1:ldir)//'ghcnd-countries.txt',
     +       status='old')
 10     continue
        i = i + 1
        read(1,'(a)',end=20) string
        cc(i) = string(1:2)
        country(i) = string(4:)
        goto 10
 20     continue
        close(1)
        open(unit=1,file=dir(1:ldir)//'ghcnd2.inv.withyears',
     +       status='old')
        i = 1
  100   continue
        read(1,1000,err=920,end=200) stations(i),rlat(i),rlon(i),ielev,
     +       elevflag(i),dummy1,datasource,dummy2,name(i),wmo,id1,id2,
     +       (idates(j),j=1,18)
 1000   format(a11,f7.2,f8.2,i5,4a1,a30,a5,2a8,18i5)
        if ( lwrite ) then
            print *,'stations(',i,') = ',stations(i)
            print *,'rlat(i),rlon(i),ielev = ',rlat(i),rlon(i),ielev
            print *,'elevflag(i),dummy1,datasource,dummy2 = ',
     +           elevflag(i),dummy1,datasource,dummy2
            print *,'name(i) = ',name(i)
            print *,'wmo,id1,id2 = ',wmo,id1,id2
            print *,'idates = ',(idates(j),j=1,18)
        endif
        if ( wmo.ne.' ' ) then
            read(wmo,'(i5)') iwmo(i)
        else
            iwmo(i) = -9999
        endif
*       convert to uppercase - not necessary..
***        call toupper(name(i))
*
*       check that we have enough years of data
        if ( type.eq.1 ) then
            nyr(i) = idates(1)
            firstyr(i) = idates(2)
            lastyr(i) = idates(3)
        elseif ( type.eq.3 ) then
            nyr(i) = idates(4)
            firstyr(i) = idates(5)
            lastyr(i) = idates(6)
        elseif ( type.eq.5 .or. type.eq.6 ) then
            nyr(i) = min(idates(1),idates(4))
            firstyr(i) = max(idates(2),idates(5))
            lastyr(i) = min(idates(3),idates(6))
        elseif ( type.eq.4 ) then
            nyr(i) = idates(7)
            firstyr(i) = idates(8)
            lastyr(i) = idates(9)
        elseif ( type.eq.7 ) then
            nyr(i) = idates(10)
            firstyr(i) = idates(11)
            lastyr(i) = idates(12)
        elseif ( type.eq.8 ) then
            nyr(i) = idates(13)
            firstyr(i) = idates(14)
            lastyr(i) = idates(15)
        elseif ( type.eq.9 ) then
            nyr(i) = idates(16)
            firstyr(i) = idates(17)
            lastyr(i) = idates(18)
        else
            print *,'error: unknown type ',type
            call abort
        endif
        if ( nyr(i).le.0 ) goto 100
        if ( nmin(0).gt.0 ) then
            if ( nyr(i).lt.nmin(0) ) goto 100
        endif
*
*       check elevation
        elev(i) = ielev
        if ( elev(i).lt.elevmin .or. elev(i).gt.elevmax ) goto 100
        if ( ielev.le.-999 .and.
     +        (elevmin.gt.-1e33 .or. elevmax.lt.1e33) ) goto 100
*
*       search closest
        if ( station.eq.'-1' .and. sname.eq.' ' ) then
            dlon = min(abs(rlon(i)-slon),
     +            abs(rlon(i)-slon-360),
     +            abs(rlon(i)-slon+360))
            dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
            i = i + 1
        elseif ( station(1:1).ne.'-' ) then
            if ( stations(i).eq.station  ) then
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
*           look for a station in the list
            do j=1,nlist
                if ( stations(i).eq.list(j) ) then
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

        if ( station.eq.'-1' .and. sname.eq.' ' 
     +       .or. slat1.lt.1e33 ) then
            call sortdist(i,n,dist,rlon,rlat,ind,rmin)
            if ( i.lt.n ) n = i
        else
            n = i
        endif
*
*       output
        if ( n.eq.0 ) then
            print '(a)','Cannot locate station'
            stop
        endif
        if ( station(1:1).eq.'-' ) print '(a,i5,a)','Found ',n
     +       ,' stations'
        if ( nlist.gt.0 ) then
            call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
        endif
        nok = 0
        do j=1,nn
            if ( station.eq.'-1' .and. sname.eq.' '
     +           .or. slat1.lt.1e33 ) then
                jj = ind(j)
		if ( jj.eq.0 ) goto 700
                if ( dist(jj).gt.1e33 ) goto 700
            else
                jj = j
            endif
            nok = nok + 1
            if ( nok.gt.n ) goto 800
            if ( station(1:1).eq.'-' ) print '(a)'
     +            ,'=============================================='
            do k=1,llen(name(jj))
                if ( name(jj)(k:k).eq.' ' ) name(jj)(k:k) = '_'
            enddo
            k = getcode(stations(jj)(1:2),cc)
            if ( station(1:1).eq.'-' ) then
                print '(4a)',name(jj),' (',
     +                country(k)(1:llen(country(k))),')'
                if ( elevflag(jj).eq.'E' ) then
                    print '(a,f6.2,a,f7.2,a,f8.1,a)','coordinates: ',
     +                   rlat(jj),'N, ',rlon(jj),'E, ',elev(jj),
     +                   'm (estimated)'
                else
                    print '(a,f6.2,a,f7.2,a,f8.1,a)','coordinates: ',
     +                   rlat(jj),'N, ',rlon(jj),'E, ',elev(jj),'m'
                endif
                print '(a,a11,4a)','GHCN-D station code: ',stations(jj)
     +               ,' ',name(jj)(1:llen(name(jj)))
                if ( iwmo(jj).ne.-9999 ) then
                    print '(a,i5)','WMO station: ',iwmo(jj)
                endif
            else
                print '(a,f6.2,a,f7.2,a,f8.1,8a)'
     +               ,'# coordinates: ',rlat(jj),'N, ',rlon(jj),'E, '
     +               ,elev(jj),'m; GHCN-D station code: ',stations(jj)
     +               ,' ',name(jj)(1:llen(name(jj))),' ',
     +               trim(country(k))
                if ( iwmo(jj).ne.-9999 ) then
                    print '(a,i5)','# WMO station ',iwmo(jj)
                endif
            endif
            if ( station(1:1).eq.'-' ) then
                print '(a,i4,a,i4,a,i4)','Found ',nyr(jj)
     +                ,' years of data in ',firstyr(jj),'-'
     +                ,lastyr(jj)
            else
                write(dir(ldir+1:),'(3a,i10.10,a)') '/ghcnd/',
     +               stations(jj),'.dly.gz'
                ldir = llen(dir)
                write(string,'(6a)') '/tmp/gdcn_',stations(jj),
     +               '_',qcflag,'.dat'
                open(2,file=dir,status='old',err=940)
                close(2)
                command = 'gzip -d -c '//dir(1:ldir)//' > '
     +                //string(1:llen(string))
                if ( lwrite ) print *,trim(command)
                call mysystem(trim(command),i)
                if ( i.ne.0 ) then
                    write(0,*) 'gunzipping failed, error code =',i
                    write(0,*) trim(command)
                endif
                open(2,file=string(1:llen(string)),status='old',err=940)
*               print header
!                print '(10a)','# ',elements(type),
!     +               ' GHCN-D V2.0 data with QC flag at least ',qcflag,
!     +               ' in ',units(type)
                print '(10a)','# ',elements(type),
     +               ' GHCN-D V2.0 data with QC in ',units(type)
                if ( type.eq.7 ) then
                    print '(a)','# excluding GTS observations'
                endif
                k = getcode(stations(jj),cc)
                print '(a)'
     +               ,'# The non-U.S. data cannot be redistributed '//
     +               'within or outside of the U.S. for any commercial '
     +               //'activities.'
*               read and print data
  600           continue
 1001           format(a11,i4,i2,a4,31(i5,3a1))
                read(2,1001,end=690,err=930) id,yr,mo,element,(vals(i)
     +               ,flags1(i),flags2(i),flags3(i),i=1,31)
                if ( id.ne.stations(jj) ) then
                    write(0,*)
     +                   'gdcndata: error: inconsistent station ID:'
     +                   ,stations(jj),id
                    call abort
                endif
                if ( element.ne.elements(type) ) goto 600
                do i=1,31
                    if ( vals(i).eq.-9999 ) then
                        if ( lwrite ) print *,'missing data ',yr,mo,i
                        goto 650
                    endif
!                    if ( index('FSXO543KEI ',flags2(i)) .lt.
!     +                   index('FSXO543KEI ',qcflag) ) then
!                        if ( lwrite ) print *
!     +                       ,'quality control flag not high enough: '
!     +                       ,flags2(i),qcflag,yr,mo,i
!                        goto 650
!                    endif
                    if ( flags2(i) .ne. ' ' ) then
                        if ( lwrite ) print *
     +                       ,'quality control flag not blank '
     +                       ,flags2(i),yr,mo,i
                        goto 650
                    endif
                    if ( type.eq.7 .and. flags3(i).eq.'S' ) then
                        if ( lwrite ) print *,'GTS-derived value'
                        goto 650
                    endif
                    if ( type.eq.1 ) then
                        val = vals(i)/10.
                    elseif ( type.eq.3 ) then
                        val = vals(i)/10.
                    elseif ( type.eq.4 .or. type.eq.7 ) then
			if ( vals(i).lt.9990 ) then
                            val = vals(i)/10.
			else
			    goto 650
			endif
                    elseif ( type.eq.5 ) then
                        write(0,*) 'tave not yet implemented'
                        call abort
                    elseif ( type.eq.8 ) then
                        val = vals(i)
                    elseif ( type.eq.9 ) then
                        val = vals(i)
                    else
                        print *,'error: type cannot be ',type
                        call abort
                    endif
 2001               format(i5,2i3,f10.2)
                    if ( lwrite ) then
                        print *,yr,mo,i,val,flags2(i)
                    else
                        print 2001,yr,mo,i,val
                    endif
 650                continue
                enddo
                goto 600
 690            continue
                if ( lwrite ) then
                    close(2)
                else
                    close(2,status='delete')
                endif
            endif
  700       continue
        enddo
  800   continue
        if ( station(1:1).eq.'-' ) print '(a)'
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
  920   print *,'error reading information, last station was ',
     +        stations(i),name(i)
        call abort
  930   print *,'error reading data at/after line ',j,yr
        call abort
  940   print *,'error: cannot locate data file ',dir(1:ldir)
        write(0,*)'error: cannot locate data file ',dir(1:ldir)
        call abort
  999   continue
        end

        integer function getcode(code,cc)
        implicit none
        character code*2,cc(0:999)*2
        integer k
        do k=1,999
            if ( code.eq.cc(k) ) exit
        end do
        getcode = k
        end

