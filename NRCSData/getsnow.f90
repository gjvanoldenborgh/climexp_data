program getsnow

!   Geert Jan van Oldenborgh, KNMI, 2004.  Based on gettemp, gdcndata

    implicit none
    integer :: nn,nstate
    parameter(nn=200000,nstate=99)
    double precision :: pi
    parameter (pi  = 3.1415926535897932384626433832795d0)
    integer :: i,j,k,jj,kk,n,m,ldir,ifeet,ifac,nlist
    integer :: ic(nn),ielev(nn),nmin(0:48),ielevs(nn),ind(nn),nyr(nn) &
        ,yr1(nn),yr2(nn),nok,nl,npol
    real :: rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon,d &
    ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin,rlatmax
    double precision :: polygon(2,nn)
    character name(nn)*40,station*11,qcflag*1,stations(nn)*11 &
    ,state(nn)*25,ss(nn)*2,list(nn)*11
    character string*80,sname*40
    character dir*256,file*256
    logical :: lwrite
    logical,external :: isnumchar
!       Metadata.climexp contains the metadata...
!	 1- 7 Unique station identifier
!	18-19 State FIPS code (there is a numerical look up between state names
!             and a 2 digit integer. It's alphabetically sorted so 01 is
!             Alabama, 02 is Alaska, 11 is washington DC, 56 is Wyoming. At
!             the NRCS we have our own FIPS IDs for stations in canada, 96,
!             97, 98)
!	26-41 State name (longest one is british_columbia)
!	51-52 2 letter state abbreviation
!	61-68 latitude
!	74-82 Latitude
!	83-92 Elevation in feet, -9999 is missing
!	93-103 Elevation in meters, -999 is missing
!	107-  Station Name

    lwrite = .false. 
    if ( command_argument_count() < 1 ) then
        print '(a)','usage: getsnow lat lon [number] [min years]'// &
            '[minelev z1] [maxelev z2] | name'
        print *,'returns list of stations that satisy the criteria'
        print '(a)','       getsnow [station_id]'
        print *,'returns data of station station_id'
        stop
    endif
    call gdcngetargs(sname,slat,slon,slat1,slon1,n,nn,station &
        ,ifac,nmin,rmin,elevmin,elevmax,qcflag,list,nn,nlist,polygon,npol)
    if ( isnumchar(sname(1:1)) ) then
        station = sname
        sname = ' '
    end if
    call getenv('DIR',dir)
    if ( dir /= ' ' ) then
        ldir = len_trim(dir)
        dir(ldir+1:) = '/NRCSData/'
    else
        dir = '/usr/people/oldenbor/NINO/NRCSData/'
    endif
    ldir = len_trim(dir)
!   just the data?
    if ( station(1:1) /= '-' ) then
        write(file,'(4a)') dir(1:ldir),'data/',trim(station),'.dat'
        open(1,file=file,status='old')
     10 continue
        read(1,'(a)',end=20) file
        if ( isnumchar(file(1:1)) ) then
            write(*,'(a)') trim(file)
        else
            write(*,'(2a)') '# ',trim(file)
        end if
        goto 10
     20 continue
        close(1)
        goto 999
    endif
!   any minimum number of years requested?
    if ( station == '-1' ) then
        do i=1,nn
            dist(i) = 3e33
        enddo
    endif
    open(unit=1,file=dir(1:ldir)//'metadata.climexp.withyear', &
    status='old')

    i = 1
100 continue
    read(1,1001,end=200) stations(i),ic(i),state(i),ss(i) &
        ,rlat(i),rlon(i),ifeet,ielevs(i),name(i) &
        ,nyr(i),yr1(i),yr2(i)
1001 format(3x,a11,3x,i2,6x,a25,a2,f17.4,f13.4,i10,i11,3x,a40,3i5)
    if ( lwrite ) then
        print *,stations(i)
        print *,ic(i)
        print *,state(i)
        print *,ss(i)
        print *,rlat(i),rlon(i)
        print *,ifeet,ielevs(i)
        print *,name(i)
        print *,nyr(i),yr1(i),yr2(i)
    endif
!   note that some names are lowercase !
    call toupper(name(i))

!   check that we have enough years of data
    if ( nyr(i) < nmin(0) ) then
        if ( lwrite ) print *,'not enough years'
        goto 100
    endif

!       check elevation
    if ( ifeet > -998 .and. ielevs(i) < -998 ) then
        ielevs(i) = nint(ifeet*0.3048)
    endif
    if ( ielevs(i) > -998 ) then
        if ( ielevs(i) < elevmin .or. ielevs(i) > elevmax ) then
            if ( lwrite ) print *,'elevation outside range'
            goto 100
        endif
    elseif ( elevmin > -1000 .or. elevmax < 10000 ) then
        if ( lwrite ) print *,'elevation undefined',elevmin,elevmax
        goto 100
    endif

    if ( sname /= ' ' ) then
    !           look for a station with sname as substring
        if ( index(name(i),sname(1:len_trim(sname))) /= 0 ) then
            i = i + 1
            if ( i > nn ) then
                print *,'gettemp: error: too many stations (>',nn &
                ,')'
                print *,'         use a more specific substring'
                call abort
            endif
        endif
    elseif ( station == '-1' ) then
    !           put everything in list, sort later
        dlon = min(abs(rlon(i)-slon), &
        abs(rlon(i)-slon-360), &
        abs(rlon(i)-slon+360))
        dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
        i = i + 1
    elseif ( slat1 < 1e33 ) then
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
            if ( lwrite ) print *,'station #',i
            i = i + 1
            if ( i > nn ) then
                print *,'gettemp: error: too many stations (>',nn &
                ,')'
                print *,'         use a smaller region or demand'
                print *,'         more years of data'
                call abort
            endif
        endif
    elseif ( nlist > 0 ) then
        do j=1,nlist
            if ( stations(i) == list(j) ) then
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

    if ( sname == ' ' .and. station == '-1' .or. slat1 < 1e33 ) then
        call sortdist(i,n,dist,rlon,rlat,ind,rmin)
        if ( i < n ) n = i
    else
        n = i
    endif

!       output
    if ( n == 0 ) then
        print '(a)','Cannot locate station'
        stop
    endif
    if ( station(1:1) == '-' ) print '(a,i5,a)','Found ',n &
    ,' stations'
    if ( nlist > 0 ) then
        call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
    endif
    nok = 0
    do j=1,nn
        if ( station == '-1' .and. sname == ' ' &
         .or. slat1 < 1e33 ) then
            jj = ind(j)
            if ( jj == 0 ) go to 700
            if ( dist(jj) > 1e33 ) go to 700
        else
            jj = j
        endif
        nok = nok + 1
        if ( nok > n ) go to 800
        print '(a)' &
        ,'=============================================='
        print '(2a,a,a)',name(jj),'(',state(jj)(1:len_trim(state(jj))) &
        ,')'
        if ( ielevs(jj) > -998 ) then
            print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','coordinates: ' &
            ,rlat(jj),'N, ',rlon(jj),'E, ',ielevs(jj),'m'
        else
            print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','coordinates: ' &
            ,rlat(jj),'N, ',rlon(jj),'E, elevation unknown'
        endif
        do k=1,len_trim(name(jj))
            if ( name(jj)(k:k) == ' ' ) name(jj)(k:k) = '_'
        enddo
        print '(3a)','NRCS station code: ',stations(jj), &
        name(jj)(1:len_trim(name(jj)))
        print '(a,i4,a,i4,a,i4)','Found ',nyr(jj) &
        ,' years with data in ',yr1(jj),'-',yr2(jj)
        700 continue
    enddo
    800 continue
    print '(a)' &
    ,'=============================================='
    goto 999
    900 print *,'please give latitude in degrees N, not ',string
    call abort
    901 print *,'please give longitude in degrees E, not ',string
    call abort
    902 print *,'error reading state.codes',string
    call abort
    903 print *,'please give number of stations to find, not ',string
    call abort
    904 print *,'please give station ID or name, not ',string
    call abort
    999 continue
END PROGRAM
logical function isnumchar(char)
    character char*1
    if ( ichar(char) >= ichar('0') .and. ichar(char) <= ichar('9') ) then
        isnumchar = .true.
    else
        isnumchar = .false.
    end if
end function isnumchar

