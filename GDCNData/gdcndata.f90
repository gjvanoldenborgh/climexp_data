program gdcndata
!
!       get GHCN-D stations near a given coordinate, or with a given name,
!       or the data
!
    implicit none
    integer nn
    parameter(nn=200000)
    double precision pi
    parameter (pi = 3.1415926535897932384626433832795d0)
    integer i,j,k,jj,kk,n,ldir,nmin(0:48),yr,nok,nlist              &
 &        ,idates(18),iecd,ist,iwm,igsn
    integer iwmo(nn),firstyr(nn),lastyr(nn),nyr(nn),ind(nn)         &
 &       ,type,tmin,tmax,temp,prcp,mo,dy,ielev,vals(31)             &
 &       ,tminyr,tminmo,tmaxyr,tmaxmo,tminvals(31),tmaxvals(31)
    real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon      &
 &        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin             &
 &        ,rlatmax,val,elev(nn),distj
    character name(nn)*30,stations(nn)*11,elevflag(nn)*1,           &
 &       datasource*1,qcflag*1
    character station*11,id*11,list(nn)*11,id1*8,id2*8,wmo*5
    character flags1(31)*1,flags2(31)*1,flags3(31)*1,dummy1*1,      &
 &       dummy2*1,tminflags(31)*1,tmaxflags(31)*1
    character country(0:999)*50,cc(0:999)*2,elements(9)*4,element*4 &
 &       ,units(9)*10,uppercountry*50,longname(9)*60
    character string*200,line*500,sname*25
    character dir*256,command*1024
    logical lwrite
    integer iargc,llen,getcode
    data elements /'TMIN','TEMP','TMAX','PRCP','TAVE','TDIF','PRCP',&
 &       'SNOW','SNWD'/
    data units /'[Celsius]','[Celsius]','[Celsius]','[mm/day]',     &
 &       '[Celsius]','[Celsius]','[mm/day]','[mm/day]','[mm]'/
    data longname /'daily minimum temperature','daily mean temperature', &
        'daily maximum temperature','precipitation', &
        'average of minimum and maximum temperature', &
        'difference of maximum and minimum temperature', &
            'precipitation','snowfall','snow depth'/
!
!       11 character station ID (also letters!)
!       7 digit latitude [decimal degree]
!       8 digit longitude [decimal degree]
!       5 digit elevation [m]
!       1 character flag, 'E' if estimated
!       1 character data source, 'G' if GCOS data
!       30 character station name
!       5 character WMO station ID
!       8 character other ID
!       8 character other ID
!
    lwrite = .false.
    call getenv('LWRITE',string)
    call tolower(string)
    if ( string(1:1) == 't' ) lwrite = .true.
    if ( iargc() < 1 ) then
        print '(a)','usage: gdcn{tmin|tmax|prcp|snow|snwd} '//      &
 &            '[lat lon|name] [min years]'
        print *,'gives stationlist with years of data' 
        print '(a)','       gdcn{tmin|temp|tmax|prcp station_id'
        print *,'gives data station_id,'
        stop
    endif
    call getarg(0,string)
    if ( index(string,'gdcntemp') /= 0 ) then
        type = 2
    elseif ( index(string,'gdcntmin') /= 0 ) then
        type = 1
    elseif ( index(string,'gdcntmax') /= 0 ) then
        type = 3
    elseif ( index(string,'gdcntave') /= 0 ) then
        type = 5
    elseif ( index(string,'gdcntdif') /= 0 ) then
        type = 6
    elseif ( index(string,'gdcnprcpall') /= 0 ) then
        type = 4
    elseif ( index(string,'gdcnprcp') /= 0 ) then
        type = 7
    elseif ( index(string,'gdcnsnow') /= 0 ) then
        type = 8
    elseif ( index(string,'gdcnsnwd') /= 0 ) then
        type = 9
    else
        print *,'do not know which database to use when running as ' &
 &            ,string(1:llen(string))
        call exit(-1)
    endif
    call gdcngetargs(sname,slat,slon,slat1,slon1,n,nn,station,1      &
 &        ,nmin,rmin,elevmin,elevmax,qcflag,list,nn,nlist)
!       no monthly time information yet
    do i=1,48
        if ( nmin(i) /= 0 ) then
            nmin(0) = nmin(i)
            if ( station(1:1) == '-' ) then
                print *,'No monthly information yet, using years.'
            endif
        endif
    enddo
    if ( station == '-1' ) then
        do i=1,nn
            dist(i) = 3e33
        enddo
    endif
!
    if ( station(1:1) /= '-' ) then
        print '(2a)','# Searching for GHCND series nr ',station
    endif
    call getenv('DIR',dir)
    if ( dir /= ' ' ) then
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
    open(unit=1,file=dir(1:ldir)//'ghcnd-countries.txt',status='old')
10  continue
    i = i + 1
    read(1,'(a)',end=20) string
    cc(i) = string(1:2)
    country(i) = string(4:)
    goto 10
20  continue
    close(1)
    open(unit=1,file=dir(1:ldir)//'ghcnd2.inv.withyears',status='old')
    i = 1
100 continue
    read(1,1000,err=920,end=200) stations(i),rlat(i),rlon(i),ielev,     &
 &       elevflag(i),dummy1,datasource,dummy2,name(i),wmo,id1,id2,      &
 &       (idates(j),j=1,18)
1000 format(a11,f7.2,f8.2,i5,4a1,a30,a5,2a8,18i5)
    if ( lwrite ) then
        print *,'stations(',i,') = ',stations(i)
        print *,'rlat(i),rlon(i),ielev = ',rlat(i),rlon(i),ielev
        print *,'elevflag(i),dummy1,datasource,dummy2 = ',              &
 &           elevflag(i),dummy1,datasource,dummy2
        print *,'name(i) = ',name(i)
        print *,'wmo,id1,id2 = ',wmo,id1,id2
        print *,'idates = ',(idates(j),j=1,18)
    endif
    if ( wmo /= ' ' ) then
        read(wmo,'(i5)') iwmo(i)
    else
        iwmo(i) = -9999
    endif
!       convert to uppercase - not necessary..
!!!        call toupper(name(i))
!
!       check that we have enough years of data
    if ( type == 1 ) then
        nyr(i) = idates(1)
        firstyr(i) = idates(2)
        lastyr(i) = idates(3)
    elseif ( type == 3 ) then
        nyr(i) = idates(4)
        firstyr(i) = idates(5)
        lastyr(i) = idates(6)
    elseif ( type == 5 .or. type == 6 ) then
        nyr(i) = min(idates(1),idates(4))
        firstyr(i) = max(idates(2),idates(5))
        lastyr(i) = min(idates(3),idates(6))
    elseif ( type == 4 ) then
        nyr(i) = idates(7)
        firstyr(i) = idates(8)
        lastyr(i) = idates(9)
    elseif ( type == 7 ) then
        nyr(i) = idates(10)
        firstyr(i) = idates(11)
        lastyr(i) = idates(12)
    elseif ( type == 8 ) then
        nyr(i) = idates(13)
        firstyr(i) = idates(14)
        lastyr(i) = idates(15)
    elseif ( type == 9 ) then
        nyr(i) = idates(16)
        firstyr(i) = idates(17)
        lastyr(i) = idates(18)
    else
        print *,'error: unknown type ',type
        call exit(-1)
    endif
    if ( nyr(i) <= 0 ) goto 100
    if ( nmin(0) > 0 ) then
        if ( nyr(i) < nmin(0) ) goto 100
    endif
!
!   check elevation
    elev(i) = ielev
    if ( elev(i) < elevmin .or. elev(i) > elevmax ) goto 100
    if ( ielev <= -999 .and. (elevmin > -1e33 .or. elevmax < 1e33) ) goto 100
!
!   filter the relevant stations, note that order is non-trivial
    if ( nlist > 0 ) then
!       look for a station in the list
        do j=1,nlist
            if ( stations(i) == list(j) ) then
                call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax  &
 &                    ,rlon(i),rlat(i))
                i = i + 1
                exit
            endif
        enddo
    elseif ( sname /= ' ' ) then
!       look for a station with sname as substring
        k = getcode(stations(i)(1:2),cc)
        uppercountry = country(k)
        call toupper(uppercountry)
        if ( index(name(i),trim(sname)) /= 0 .or.    &
 &           sname(1:1) == '(' .and. index(uppercountry,trim(sname(2:))) /= 0 ) then
            i = i + 1
            if ( i > nn ) then
                print *,'Maximum ',nn,' stations'
                stop
            endif
        else
            goto 100
        endif
    elseif ( station(1:1) /= '-' ) then
        ! search for one station by ID
        if ( stations(i) == station  ) then
            i = i + 1
            goto 200
        endif
    elseif ( slat1 < 1e33 ) then
!       look for a station in the box
        if ( (slon1 > slon .and.                      &
 &            rlon(i) > slon .and. rlon(i) < slon1   &
 &            .or.                                     &
 &            slon1 < slon .and.                      &
 &            (rlon(i) < slon1 .or. rlon(i) > slon)  &
 &            ) .and. (                                &
 &            rlat(i) > min(slat,slat1) .and.         &
 &            rlat(i) < max(slat,slat1) )             &
 &            ) then
            dist(i) = 3e33
            do j=1,i-1
                dlon = min(abs(rlon(i)-rlon(j)),  &
 &                abs(rlon(i)-rlon(j)-360),   &
 &                abs(rlon(i)-rlon(j)+360))
                distj = (rlat(i)-rlat(j))**2 + (dlon*cos(rlat(i)/180*pi))**2
                dist(i) = min(dist(i),distj)
            end do
            if ( rmin > 1e33 .or. dist(i) >= rmin ) then
                n = i
                i = i + 1
                if ( i > nn ) then
                    print *,'Maximum ',nn,' stations'
                    stop
                endif
            end if
        endif
    elseif ( station == '-1' .and. sname == ' ' ) then
!       search closest
        dlon = min(abs(rlon(i)-slon),  &
 &            abs(rlon(i)-slon-360),   &
 &            abs(rlon(i)-slon+360))
        dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
        i = i + 1
    else
        print *,'internal error 31459263'
        call exit(-1)
    endif
    goto 100
!       
!   we read all interesting stations in memory
200 continue
    i = i - 1

    if ( nlist > 1 .or. station /= '-1' .or. sname /= ' ' .or. slat1 < 1e33 ) then
        n = i
    else
        call sortdist(i,n,dist,rlon,rlat,ind,rmin)
        if ( i < n ) n = i
    endif
!
!   output
    if ( n == 0 ) then
        print '(a)','Cannot locate station'
        stop
    endif
    if ( station(1:1) == '-' ) print '(a,i5,a)','Found ',n,' stations'
    if ( nlist > 0 ) then
        call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
    endif
    nok = 0
    do j=1,nn
        if ( nlist > 1 .or. station /= '-1' .or. sname /= ' ' .or. slat1 < 1e33 ) then
            jj = j
        else
            jj = ind(j)
            if ( jj == 0 ) goto 700
            if ( dist(jj) > 1e33 ) goto 700
        endif
        nok = nok + 1
        if ( nok > n ) goto 800
        if ( station(1:1) == '-' ) print '(a)'  &
 &            ,'=============================================='
        do k=1,llen(name(jj))
            if ( name(jj)(k:k) == ' ' ) name(jj)(k:k) = '_'
        enddo
        k = getcode(stations(jj)(1:2),cc)
        if ( station(1:1) == '-' ) then
            print '(4a)',name(jj),' (',trim(country(k)),')'
            if ( elevflag(jj) == 'E' ) then
                print '(a,f6.2,a,f7.2,a,f8.1,a)','coordinates: ',     &
 &                   rlat(jj),'N, ',rlon(jj),'E, ',elev(jj),'m (estimated)'
            else
                print '(a,f6.2,a,f7.2,a,f8.1,a)','coordinates: ',     &
 &                   rlat(jj),'N, ',rlon(jj),'E, ',elev(jj),'m'
            endif
            print '(a,a11,4a)','GHCN-D station code: ',stations(jj)   &
 &               ,' ',trim(name(jj))
            if ( iwmo(jj) /= -9999 ) then
                print '(a,i5)','WMO station: ',iwmo(jj)
            endif
        else
            print '(a,f6.2,a,f7.2,a,f8.1,8a)'                         &
 &               ,'# coordinates: ',rlat(jj),'N, ',rlon(jj),'E, '     &
 &               ,elev(jj),'m; GHCN-D station code: ',stations(jj)    &
 &               ,' ',trim(name(jj)),' ', trim(country(k))
            if ( iwmo(jj) /= -9999 ) then
                print '(a,i5)','# WMO station ',iwmo(jj)
            endif
        endif
        if ( station(1:1) == '-' ) then
            print '(a,i4,a,i4,a,i4)','Found ',nyr(jj)                 &
 &                ,' years of data in ',firstyr(jj),'-'               &
 &                ,lastyr(jj)
        else
            ! new-style metadata
            print '(a)','# institution :: NOAA/NCEI'
            print '(a)','# source_url :: https://catalog.data.gov/dataset/'// &
                'global-historical-climatology-network-daily-ghcn-daily-version-3'
            print '(a)','# source_doi :: https:doi.org/10.7289/V5D21VHZ'
            print '(a)','# contact_email :: ncdc.ghcnd@noaa.gov'
            print '(a)','# reference :: Matthew J. Menne, Imke Durre, Russell S. Vose, Byron E. Gleason, '// &
                'and Tamara G. Houston, 2012: An Overview of the Global Historical Climatology '// &
                'Network-Daily Database. J. Atmos. Oceanic Technol., 29, 897-910. doi:10.1175/JTECH-D-11-00103.1.'
            print '(a)','# license :: U.S. Government Work The non-U.S. data cannot be redistributed '//  &
                'within or outside of the U.S. for any commercial activities.'
            print '(2a)','# station_code :: ',stations(jj)
            print '(2a)','# station_name :: ',trim(name(jj))
            print '(2a)','# station_country :: ',trim(country(k))
            if ( iwmo(jj) /= -9999 ) then
                print '(a,i5)','# wmo_code :: ',iwmo(jj)
            end if
            print '(a,f7.2,a)','# latitude :: ',rlat(jj),' degrees_north'
            print '(a,f7.2,a)','# longitude :: ',rlon(jj),' degrees_east'
            print '(a,f8.1,a)','# elevation :: ',elev(jj),' m'
            write(dir(ldir+1:),'(3a,i10.10,a)') '/ghcnd/',stations(jj),'.dly.gz'
            ldir = llen(dir)
            write(string,'(6a)') '/tmp/gdcn_',stations(jj),'_',qcflag,'.dat'
            open(2,file=dir,status='old',err=940)
            close(2)
            command = 'gzip -d -c '//dir(1:ldir)//' > '//string(1:llen(string))
            if ( lwrite ) print *,trim(command)
            call mysystem(trim(command),i)
            if ( i /= 0 ) then
                write(0,*) 'gunzipping failed, error code =',i
                write(0,*) trim(command)
            endif
            open(2,file=string(1:llen(string)),status='old',err=940)
!               print header
            print '(10a)','# ',elements(type),' ',trim(units(type)),' ',trim(longname(type))
            if ( type == 7 ) then
                print '(a)','# excluding GTS observations'
            endif
            k = getcode(stations(jj),cc)
!               read and print data
600         continue
1001        format(a11,i4,i2,a4,31(i5,3a1))
            read(2,1001,end=690,err=930) id,yr,mo,element,(vals(i)        &
 &               ,flags1(i),flags2(i),flags3(i),i=1,31)
            if ( id /= stations(jj) ) then
                write(0,*)'gdcndata: error: inconsistent station ID:'     &
 &                   ,stations(jj),id
                call exit(-1)
            endif
            if ( type == 5 ) then
                if ( element == 'TMIN' ) then
                    tminvals = vals
                    tminflags = flags2
                    tminyr = yr
                    tminmo = mo
                else if ( element == 'TMAX' ) then
                    tmaxvals = vals
                    tmaxflags = flags2
                    tmaxyr = yr
                    tmaxmo = mo
                end if
                if ( tminyr == tmaxyr .and. tminmo == tmaxmo ) then
                    do i=1,31
                        if ( tminvals(i) /= -9999 .and.    &
 &                           tminflags(i) == ' ' .and.     &
 &                           tmaxvals(i) /= -9999 .and.    &
 &                           tmaxflags(i) == ' ' ) then
                            vals(i) = 5*(tminvals(i) + tmaxvals(i))
                        else
                            vals(i) = -9999
                        end if
                    end do
                    tminvals = -9999
                    tmaxvals = -9999
                    tminyr = -1
                    tmaxyr = -1
                    element = 'TAVE' ! so that the rest goes OK
                end if
            end if
            if ( element /= elements(type) ) goto 600
            do i=1,31
                if ( vals(i) == -9999 ) then
                    if ( lwrite ) print *,'missing data ',yr,mo,i
                    goto 650
                endif
!                    if ( index('FSXO543KEI ',flags2(i))  <            &
!     &                   index('FSXO543KEI ',qcflag) ) then
!                        if ( lwrite ) print *                          &
!     &                       ,'quality control flag not high enough: ' &
!     &                       ,flags2(i),qcflag,yr,mo,i
!                        goto 650
!                    endif
                if ( flags2(i)  /=  ' ' ) then
                    if ( lwrite ) print *,'quality control flag not blank ' &
 &                       ,flags2(i),yr,mo,i
                    goto 650
                endif
                if ( type == 7 .and. flags3(i) == 'S' ) then
                    if ( lwrite ) print *,'GTS-derived value'
                    goto 650
                endif
                if ( type == 1 ) then
                    val = vals(i)/10.
                elseif ( type == 3 ) then
                    val = vals(i)/10.
                elseif ( type == 4 .or. type == 7 ) then
                    if ( vals(i) < 9990 ) then
                        val = vals(i)/10.
                    else
                        goto 650
                    endif
                elseif ( type == 5 ) then
                    val = vals(i)/100.
                elseif ( type == 8 ) then
                    val = vals(i)
                elseif ( type == 9 ) then
                    val = vals(i)
                else
                    print *,'error: type cannot be ',type
                    call exit(-1)
                endif
2001               format(i5,2i3,f10.2)
                if ( lwrite ) then
                    print *,yr,mo,i,val,flags2(i)
                else
                    print 2001,yr,mo,i,val
                endif
650             continue
            enddo
            goto 600
690         continue
            if ( lwrite ) then
                close(2)
            else
                close(2,status='delete')
            endif
        endif
700     continue
    enddo
800 continue
    if ( station(1:1) == '-' ) print '(a)'                   &
 &        ,'=============================================='
    goto 999
900 print *,'please give latitude in degrees N, not ',string
    call exit(-1)
901 print *,'please give longitude in degrees E, not ',string
    call exit(-1)
902 print *,'error reading country.codes',string
    call exit(-1)
903 print *,'please give number of stations to find, not ',string
    call exit(-1)
904 print *,'please give station ID or name, not ',string
    call exit(-1)
920 print *,'error reading information, last station was ',stations(i),name(i)
    call exit(-1)
930 print *,'error reading data at/after line ',j,yr
    call exit(-1)
940 print *,'error: cannot locate data file ',dir(1:ldir)
    write(0,*)'error: cannot locate data file ',dir(1:ldir)
    call exit(-1)
999 continue
end program

integer function getcode(code,cc)
    implicit none
    character code*2,cc(0:999)*2
    integer k
    do k=1,999
        if ( code == cc(k) ) exit
    end do
    getcode = k
end function

