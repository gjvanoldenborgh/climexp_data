    program getprcp

!       Get station and precipitation metadata near a given coordinate,
!       or with a given substring.
!       Get station data when called with a station ID.

!       Geert Jan van Oldenborgh, KNMI, 1999-2000

    implicit none
    integer :: nn
    parameter(nn=21000)
    double precision :: pi
    parameter (pi  = 3.1415926535897932384626433832795d0)
    integer :: i,j,k,n,ldir,istation,nmin(0:48),nflag,nok,nyr(0:48),jj &
    ,kk,nlist
    integer :: ii(nn),ielev(nn),ind(nn),list(nn)
    real :: rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon &
    ,rmin,d,elevmin,elevmax,rlonmin,rlonmax,rlatmin,rlatmax
    character name(nn)*30,country(nn)*20
    character string*80,sname*30
    character dir*256
    logical :: lmin
    integer :: iargc,llen
    external llen

    if ( iargc() < 1 ) then
        print *,'usage: getprcp [string|station_id]'
        print *,'       getprcp lat[:lat] lon[:lon] [number] '// &
        '[min years] [dist degrees]'
        print *,'gives historical precipitation for station_id'
        print *,'otherwise stationlist'
        stop
    endif
    call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,1,nmin &
    ,rmin,elevmin,elevmax,list,nn,nlist)
    lmin = .false. 
    do i=0,48
        if ( nmin(i) > 0 ) lmin = .true. 
    enddo
    if ( istation == 0 ) then
        do i=1,nn
            dist(i) = 3e33
        enddo
    endif
    print '(a)','getprcp: searching v2.precip.beta.inv.withmonth'
    call getenv('DIR',dir)
    if ( dir /= ' ' ) then
        ldir = llen(dir)
        dir(ldir+1:) = '/NCDCData/'
    else
        dir = '/usr/people/oldenbor/NINO/NCDCData/'
    endif
    ldir = llen(dir)
    if ( lmin ) then
        open(unit=1,file=dir(1:ldir)//'v2.precip.beta.inv.withmonth' &
        ,status='old')
    else
        open(unit=1,file=dir(1:ldir)//'v2.precip.beta.inv' &
        ,status='old')
    endif
    open(unit=2,file=dir(1:ldir)//'v2.precip.beta.data',status='old' &
    ,form='formatted',access='direct',recl=75)

    i = 1
    100 continue
    if ( lmin ) then
        read(1,1000,end=200) ii(i),rlat(i),rlon(i),ielev(i),name(i) &
        ,country(i),nyr
    else
        read(1,1000,end=200) ii(i),rlat(i),rlon(i),ielev(i),name(i) &
        ,country(i)
    endif
    1000 format(i7,1x,f6.2,1x,f7.2,1x,i4,1x,a30,1x,a20,49i4)
!       note that some names are lowercase !
    call toupper(name(i))

!       check that we have enough years of data
    if ( lmin ) then
        do j=0,48
            if ( nmin(j) > 0 ) then
                if ( nyr(j) < nmin(j) ) goto 100
            endif
        enddo
    endif

!       check elevation
    if ( ielev(i) < elevmin .or. ielev(i) > elevmax ) goto 100
    if ( ielev(i) == -999 .and. &
    (elevmin > -1e33 .or. elevmax < 1e33) ) goto 100

    if ( istation == 0 ) then
    !           put everything in list, sort later
        dlon = min(abs(rlon(i)-slon), &
        abs(rlon(i)-slon-360), &
        abs(rlon(i)-slon+360))
        dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
        i = i + 1
    elseif ( istation > 0 ) then
    !           look for a specific station
        if ( ii(i) == istation ) then
            i = i + 1
            goto 200
        endif
    elseif ( sname /= ' ' ) then
    !           look for a station with sname as substring
        if ( index(name(i),sname(1:llen(sname))) /= 0 ) then
            i = i + 1
            if ( i > nn ) then
                print *,'getprcp: error: too many stations (>',nn &
                ,')'
                print *,'         use a more specific substring'
                call abort
            endif
        endif
    elseif ( slat1 < 1e33 ) then
    !       look for a station in the box
        if ( (slon1 > slon .and. &
        rlon(i) > slon .and. rlon(i) < slon1 &
         .or. &
        slon1 < slon .and. &
        (rlon(i) < slon1 .or. rlon(i) > slon) &
        ) .and. ( &
        rlat(i) > min(slat,slat1) .and. &
        rlat(i) < max(slat,slat1) ) &
        ) then
            dist(i) = i
            n = i
            i = i + 1
            if ( i > nn ) then
                print *,'getprcp: error: too many stations (>',nn &
                ,')'
                print *,'         use a smaller region or demand'
                print *,'         more years of data'
                call abort
            endif
        endif
    elseif ( nlist > 0 ) then
        do j=1,nlist
            if ( ii(i) == list(j) ) then
                call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax &
                ,rlon(i),rlat(i))
                i = i + 1
            endif
        enddo
    else
        print *,'internal error 31459263'
        call abort
    endif
    goto 100

!       we read all interesting stations in memory
    200 continue
    i = i - 1

    if ( istation == 0 .or. slat1 < 1e33 ) then
        call sortdist(i,n,dist,rlon,rlat,ind,rmin)
    else
        n = i
    endif

!       output
    if ( istation <= 0 ) print '(a,i5,a)','Found ',n,' stations'
    if ( nlist > 0 ) then
        call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
    endif
    nok = 0
    do j=1,nn
        if ( istation == 0 .or. slat1 < 1e33 ) then
            jj = ind(j)
            if ( dist(jj) > 1e33 ) goto 700
        else
            jj = j
        endif
        nok = nok + 1
        if ( nok > n ) goto 800
        if ( istation <= 0 ) print '(a)' &
        ,'=============================================='
        print '(4a)',name(jj),' (',country(jj)(:llen(country(i))) &
        ,')'
        print '(a,f6.2,a,f7.2,a,i5,a)','Coordinates: ',rlat(jj) &
        ,'N, ',rlon(jj),'E, ',ielev(jj),'m'
        call tidyname(name(jj),country(jj))
        print '(a,i5,2a)','Station code: ',ii(jj),' ',name(jj)
        if ( istation <= 0 ) then
            nflag = 999
        else
            nflag = 1
        endif
        call getdata('prcp',2,ii(jj),nflag,nyr)
        700 continue
    enddo
    800 continue
    if ( istation <= 0 ) print '(a)' &
    ,'=============================================='
    goto 999
    902 print *,'error reading iso-country-codes',string
    call abort
    999 continue
    END PROGRAM
