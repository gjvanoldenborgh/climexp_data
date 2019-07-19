program getsealev

!   Get station and precipitation metadata near a given coordinate or with a given substring.
!   Get station data when called with a station ID.
!
!   Geert Jan van Oldenborgh, KNMI, 2000, 2019

    implicit none
    integer,parameter :: nn=4000
    double precision,parameter :: pi  = 3.1415926535897932384626433832795d0
    integer :: i,j,k,jj,n,ldir,istation,nmin(0:48),nok,nlist
    integer :: ii(nn),idum(3),nyr(nn),yr1(nn),yr2(nn),ind(nn),list(nn)
    real :: rlat(nn),rlon(nn),dist(nn),fmiss(nn),dlon,slat,slon &
        ,slat1,slon1,fdum,rmin,elevmin,elevmax,rlonmin,rlonmax &
        ,rlatmin,rlatmax
    character :: name(nn)*40,country(0:9999)*60,countryheader*60,ns,ew
    character :: string*80,sname*30
    character :: dir*256,line*132,scripturl*2000
    logical :: lwrite

    lwrite = .false. 
    if ( command_argument_count() < 1 ) then
        print *,'usage: getsealev station_id'
        print *,'       getsealev [string|lat lon] [min years]'
        print *,'gives historical sea level for station_id'
        print *,'or stationlist with years of data'
        stop
    endif
    call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,1,nmin &
        ,rmin,elevmin,elevmax,list,nn,nlist)
!       no monthly time information yet
    do i=1,48
        if ( nmin(i) /= 0 ) then
            nmin(0) = nmin(i)
            if ( istation <= 0 ) then
                print *,'No monthly information yet, using years.'
            endif
        endif
    enddo
!   not much sense to check for elevation
    if ( istation <= 0 ) then
        if ( elevmin > -1e33 ) print *,'Disregarding minimum elevation ',elevmin
        if ( elevmax < +1e33 ) print *,'Disregarding maximum elevation ',elevmax
    endif
    if ( istation == 0 ) then
        do i=1,nn
            dist(i) = 3e33
        enddo
    endif
    !!!print '(a)','# getsealev: searching nucat.dat'
    call getenv('DIR',dir)
    if ( dir /= ' ' ) then
        ldir = len_trim(dir)
        dir(ldir+1:) = '/PSMSLData/'
    else
        dir = '/home/oldenbor/climexp/PSMSLData/'
    endif
    ldir = len_trim(dir)
    if ( lwrite ) print *,'opeining ',dir(1:ldir)//'nucat.dat'
    open(unit=1,file=dir(1:ldir)//'nucat.dat',status='old')
!   skip header
    do i=1,4
        read(1,'(a)') line
    enddo
!   initialize country array
    country = ' '

    i = 1
100 continue
    read(1,'(a)',end=200) line
!   heuristics, hopefully they do not change the format
    if ( line == ' ' .or. line(1:4) == '  ID' ) go to 100
    if ( line(1:32) == ' ' ) then
        if ( lwrite ) print *,'reading country ',trim(line(33:))
        countryheader = line(38:)
    endif
    if ( line(112:) /= ' ' ) then ! RLR data only
!        i4     4 ID
!        i4     8 old ID (not used)
!        1x     9 ' '
!        a40   49 name
!        f11.6 60 degrees_north
!        x     61 ' '
!        a1    62 'N' or 'S'
!        f12.6 74 degrees_east
!        x     75 ' '
!        a1    76 'E' or 'W'
!        35x  111 '  SID FC GLO      Metric      PC'
!        i4   115 yr1
!        1x   116 '-'
!        i4   120 yr2
!        f7.2 127 PC
!        a1   128 '%'
        read(line,1000,err=930) ii(i),j,name(i),rlat(i),ns,rlon(i),ew,yr1(i),yr2(i),fmiss(i)
   1000 format(2i4,1x,a,f11.6,x,a,f12.6,x,a,35x,i4,1x,i4,f7.2)
    else
!       the docs tell us NEVER to use metric values for time series analysis
        goto 100
    endif
    if ( ns == 'S' ) then
        rlat(i) = -rlat(i)
    else if ( ns /= 'N' ) then
        write(0,*) 'getsealev: error: expecting N or S, not ;',ns
        call exit(-1)
    end if
    if ( ew == 'W' ) then
        rlon(i) = -rlon(i)
    else if ( ew /= 'E' ) then
        write(0,*) 'getsealev: error: expecting E or W, not ',ew
        call exit(-1)
    end if
    country(ii(i)) = countryheader

    nyr(i) = (yr2(i) - yr1(i) + 1)*fmiss(i)/100 ! rough approximation...
!   check that we have enough years of data
    if ( nmin(0) > 0 ) then
        if ( nyr(i) < nmin(0) ) go to 100
    endif

    if ( istation == 0 ) then
!       search closest
        dlon = min(abs(rlon(i)-slon),abs(rlon(i)-slon-360),abs(rlon(i)-slon+360))
        dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
        i = i + 1
    elseif ( istation > 0 ) then
!       look for a specific station
        if ( ii(i) == istation ) then
            i = i + 1
            goto 200
        endif
    elseif ( sname /= ' ' ) then
!       look for a station with sname as substring
        if ( index(name(i),trim(sname)) /= 0 ) then
            i = i + 1
        endif
    elseif ( slat1 < 1e33 ) then
!       look for a station in the box
        if ( (slon1 > slon .and. rlon(i) > slon .and. rlon(i) < slon1 .or. &
              slon1 < slon .and. (rlon(i) < slon1 .or. rlon(i) > slon) ) &
            .and. ( rlat(i) > min(slat,slat1) .and. rlat(i) < max(slat,slat1) ) ) then
            dist(i) = i
            n = i
            i = i + 1
        endif
    elseif ( nlist > 0 ) then
        do j=1,nlist
            if ( ii(i) == list(j) ) then
                call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax,rlon(i),rlat(i))
                i = i + 1
            endif
        enddo
    else
        print *,'internal error 31459263'
        call exit(-1)
    endif
    goto 100

!   we read all interesting stations in memory
200 continue
    i = i - 1

    if ( istation == 0 .or. slat1 < 1e33 ) then
        call sortdist(i,n,dist,rlon,rlat,ind,rmin)
    else
        n = i
    endif

!   output
    if ( istation <= 0 ) print '(a,i5,a)','Found ',n,' stations'
    if ( nlist > 0 ) then
        call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
    endif
    nok = 0
    do j=1,nn
        if ( istation == 0 .or. slat1 < 1e33 ) then
            jj = ind(j)
            if ( dist(jj) > 1e33 ) go to 700
        else
            jj = j
        endif
        nok = nok + 1
        if ( nok > n ) go to 800
        if ( istation <= 0 ) print '(a)','=============================================='
        do k=1,len_trim(name(jj))
            if ( name(jj)(k:k) == ' ' ) name(jj)(k:k) = '_'
        enddo
        if ( istation <= 0 ) then
            print '(5a)','# ',name(jj),' (',trim(country(ii(jj))),')'
            print '(a,f6.2,a,f7.2,a)','# coordinates: ',rlat(jj),'N, ',rlon(jj),'E'
            print '(a,i6,2a)','# Station code: ',ii(jj),' ',trim(name(jj))
            print '(a,i4,a,i4,a,i4,a,f5.1,a)','Found ',nyr(jj), &
                ' years with data in ',yr1(jj),'-',yr2(jj),' (' &
                ,fmiss(jj),'% complete)'
        else
            print '(a,i4,2a)','# <a href="http://www.gloss-sealevel.org/">GLOSS</a> station ',ii(jj),' ',trim(name(jj))
            print '(a)','# institution :: https://www.psmsl.org/'
            print '(a)','# source :: https://www.psmsl.org/data/obtaining/complete.php'
            print '(a,f7.2,a)','# latitude :: ',rlat(jj),' degrees_north'
            print '(a,f7.2,a)','# longitude :: ',rlon(jj),' degrees_east'
            call getenv('SCRIPTURL',scripturl)
            if ( scripturl /= ' ' ) then
                print '(2a)','# scripturl01 :: ',trim(scripturl)
            end if
            call getdata('slv',2,ii(jj),1,nmin)
        endif
    700 continue
    enddo
800 continue
    if ( istation <= 0 ) print '(a)','=============================================='
    goto 999
900 print *,'please give latitude in degrees N, not ',string
    call exit(-1)
901 print *,'please give longitude in degrees E, not ',string
    call exit(-1)
902 print *,'error reading iso-country-codes',string
    call exit(-1)
903 print *,'please give number of stations to find, not ',string
    call exit(-1)
904 print *,'please give minimum number of years, not ',string
    call exit(-1)
930 write(0,*)'error reading line ',line
    call exit(-1)
999 continue
end program getsealev

