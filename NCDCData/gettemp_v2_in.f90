program gettemp

!   Get temperature stations near a given coordinate or with a substring
!   Get temperature data when called with a station ID.
!   Call as gettmin, gettmax to search the min/max temperature databases

!   Geert Jan van Oldenborgh, KNMI, 1999-2000

    implicit none
    integer,parameter :: nn=21000,ncountry=233
    double precision,parameter :: pi=3.1415926535897932384626433832795d0
    integer :: i,j,k,jj,kk,n,m,ldir,istation,isub, &
        nyr(0:48),nyrmin(0:48),nyrmax(0:48),nmin(0:48),nok,nlist
    integer :: ic(nn),iwmo(nn),imod(nn),ielevs(nn),ielevg(nn) &
        ,ipop(nn),iloc(nn),itowndis(nn),icountry(0:ncountry),nflag &
        ,ind(nn),list(2,nn),nrec,nstat,yr1,yr2
    real :: rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon,d &
        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin,rlatmax
    character :: name(nn)*30,grveg(nn)*16,pop(nn)*1,topo(nn)*2,stveg(nn)*2
    character :: stloc(nn)*2,airstn(nn)*1
    character(48) :: country(0:999)
    character :: string*80,sname*30,type*7,file*1023,wmostring*12
    character :: dir*256,scripturl*2000
    logical :: lmin,enough,okstation,lwrite
    integer :: iargc

!     ic=3 digit country code; the first digit represents WMO region/continent
!     iwmo=5 digit WMO station number
!     imod=3 digit modifier; 000 means the station is probably the WMO
!          station; 001, etc. mean the station is near that WMO station
!     name=30 character station name
!     rlat=latitude in degrees.hundredths of degrees, negative = South of Eq.
!     rlon=longitude in degrees.hundredths of degrees, - = West
!     ielevs=station elevation in meters, missing is -999
!     ielevg=station elevation interpolated from TerrainBase gridded data set
!     pop=1 character population assessment:  R = rural (not associated
!         with a town of >10,000 population), S = associated with a small
!         town (10,000-50,000), U = associated with an urban area (>50,000)
!     ipop=population of the small town or urban area (needs to be multiplied
!         by 1,000).  If rural, no analysis:  -9.
!     topo=general topography around the station:  FL flat; HI hilly,
!         MT mountain top; MV mountainous valley or at least not on the top
!         of a mountain.
!     stveg=general vegetation near the station based on Operational
!         Navigation Charts;  MA marsh; FO forested; IC ice; DE desert;
!         CL clear or open;
!         not all stations have this information in which case: xx.
!     stloc=station location based on 3 specific criteria:
!         Is the station on an island smaller than 100 km**2 or
!            narrower than 10 km in width at the point of the
!            station?  IS;
!         Is the station is within 30 km from the coast?  CO;
!         Is the station is next to a large (> 25 km**2) lake?  LA;
!         A station may be all three but only labeled with one with
!             the priority IS, CO, then LA.  If none of the above: no.
!     iloc=if the station is CO, iloc is the distance in km to the coast.
!          If station is not coastal:  -9.
!     airstn=A if the station is at an airport; otherwise x
!     itowndis=the distance in km from the airport to its associated
!          small town or urban center (not relevant for rural airports
!          or non airport stations in which case: -9)
!     grveg=gridded vegetation for the 0.5x0.5 degree grid point closest
!          to the station from a gridded vegetation data base. 16 characters.
!     A more complete description of these metadata are available in
!       other documentation

    lwrite = .false. 
    if ( iargc() < 1 ) then
        print '(a)','usage: gettemp lat lon [number] [min years] [begin yr1] [end yr2]'
        print '(a)','       gettemp [name|station_id]'
        print *,'gives historical temperature for station_id or when'
        print *,'number=1, otherwise stationlist with years of data'
        call exit(-1)
    end if
    call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,isub &
        ,nmin,rmin,elevmin,elevmax,list,nn,nlist,yr1,yr2)
!   any minimum number of years requested?
    lmin = .false. 
    do i=0,48
        if ( nmin(i) > 0 ) lmin = .true. 
    end do
    do i=1,nn
        dist(i) = 3e33
    end do
    if ( istation > 0 ) then
        if ( isub == 0 ) then
            print '(a,i5,a)','# Searching for station nr ',istation, &
                ' in v2.temperature.inv'
        else if ( isub < 10 ) then
            print '(a,i5,a,i1,a)','# Searching for substation nr ' &
                ,istation,'.',isub,' in v2.temperature.inv'
        else
            print '(a,i5,a,i2,a)','# Searching for substation nr ' &
                ,istation,'.',isub,' in v2.temperature.inv'
        end if
    end if

!   read countrycode from file
    do j=0,999
        country(j) = ' '
    end do
    call getenv('DIR',dir)
    if ( dir /= ' ' ) then
        ldir = len_trim(dir)
        dir(ldir+1:) = '/NCDCData/'
    else
        dir = '/usr/people/oldenbor/NINO/NCDCData/'
    end if
    ldir = len_trim(dir)
    file = trim(dir)//'v2.country.codes'
    if ( lwrite ) print *,'opening ',trim(file)
    open(1,file=trim(file),status='old')
    do k=1,ncountry
        read(1,'(a)',end=30) string
        if ( string == ' ' ) goto 30
        read(string,'(i3)',err=902) icountry(k)
        country(k) = string(5:)
    end do
 30 continue

    call getarg(0,string)
    if ( index(string,'slp') /= 0 ) then
        if ( lmin ) then
            file = 'v2.slp.inv.withmonth'
        else
            file = 'v2.slp.inv'
        end if
    else if ( index(string,'prcpall') /= 0 ) then
        if ( lmin ) then
            file = 'v2.prcp.inv.withmonth'
        else
            file = 'v2.prcp.inv'
        end if
    else if ( index(string,'prcp ') /= 0 ) then
        if ( lmin ) then
            file = 'v2.prcp.adj.inv.withmonth'
        else
            file = 'v2.prcp.adj.inv'
        end if
    else
        if ( lmin ) then
            if ( index(string,'all ') /= 0 ) then
                file = 'v2.temperature.inv.withmonth'
            else
                file = 'v2.temperature_adj.inv.withmonth'
            end if
        else
            file = 'v2.temperature.inv'
        end if
    end if
    file = trim(dir)//file
    if ( lwrite ) print *,'opening ',trim(file)
    open(1,file=trim(file),status='old')
    if ( index(string,'getslp') /= 0 ) then
        type = 'slp'
        if ( n > 1 .or. lwrite ) print '(a)','Opening v2.slp'
        open(unit=2,file=dir(1:ldir)//'v2.slp',status='old', &
            form='formatted',access='direct',recl=77)
        nrec  = NREC_SLP
        nstat = NSTAT_SLP
    else if ( index(string,'getprcpall') /= 0 ) then
        type = 'prcpall'
        if ( n > 1 .or. lwrite ) print '(a)','Opening v2.prcp'
        open(unit=2,file=dir(1:ldir)//'v2.prcp',status='old', &
            form='formatted',access='direct',recl=77)
        nrec  = NREC_PRCP_ALL
        nstat = NSTAT_PRCP_ALL
    else if ( index(string,'getprcp') /= 0 ) then
        type = 'prcp'
        if ( n > 1 ) print '(a)','Opening v2.prcp_adj'
        open(unit=2,file=dir(1:ldir)//'v2.prcp_adj',status='old', &
            form='formatted',access='direct',recl=77)
        nrec  = NREC_PRCP_ADJ
        nstat = NSTAT_PRCP_ADJ
    else
        print *,'gettemp_v2: do not know which database to use '// &
        'when running as ',trim(string)
        call exit(-1)
    end if

    i = 1
100 continue
    if ( type(1:4) == 'prcp' .or. type(1:3) == 'slp' ) then
        if ( lmin ) then
            read(1,1001,end=200)ic(i),iwmo(i),imod(i),name(i), &
                rlat(i),rlon(i),ielevs(i),nyr,nyrmin,nyrmax
        else
            read(1,1001,end=200)ic(i),iwmo(i),imod(i),name(i), &
                rlat(i),rlon(i),ielevs(i)
        end if
   1001 format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4,147i4)
    else
        if ( lmin ) then
            read(1,1000,end=200)ic(i),iwmo(i),imod(i),name(i), &
                rlat(i),rlon(i),ielevs(i),ielevg(i), &
                pop(i),ipop(i),topo(i),stveg(i), &
                stloc(i),iloc(i),airstn(i),itowndis(i), &
                grveg(i),nyr,nyrmin,nyrmax
        else
            read(1,1000,end=200)ic(i),iwmo(i),imod(i),name(i), &
                rlat(i),rlon(i),ielevs(i),ielevg(i), &
                pop(i),ipop(i),topo(i),stveg(i), &
                stloc(i),iloc(i),airstn(i),itowndis(i), &
                grveg(i)
        end if
   1000 format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4, &
               1x,i4,a1,i5,3(a2),i2,a1,i2,a16,147i4)
    end if
!   note that some names are lowercase !
    call toupper(name(i))

!   check that we have enough years of data
    if ( lmin ) then
        call checknyr(type,nmin,nyr,nyrmin,nyrmax,enough)
        if ( .not. enough ) then
            if ( lwrite ) print *,'not enough data '
            goto 100
        end if
    end if

!   check elevation
    if ( ielevs(i) > -998 ) then
        if ( ielevs(i) < elevmin .or. ielevs(i) > elevmax ) goto 100
    else if ( type(1:4) /= 'prcp' .or. type(1:3) == 'slp' ) then
        if ( ielevg(i) < elevmin .or. ielevg(i) > elevmax ) goto 100
    end if

    okstation = .false. 
    if ( nlist > 0 ) then
        do j=1,nlist
            if ( iwmo(i) == list(1,j) .and. &
            imod(i) == list(2,j) ) then
                call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax,rlon(i),rlat(i))
                okstation = .true. 
                exit
            end if
        end do
    else if ( istation == 0 ) then
!       put everything in list, sort later
        dlon = min(abs(rlon(i)-slon), &
        abs(rlon(i)-slon-360), &
        abs(rlon(i)-slon+360))
        dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
        okstation = .true. 
    else if ( istation > 0 ) then
        if ( iwmo(i) == istation .and. &
        imod(i) == isub ) then
            i = i + 1
            goto 200
        end if
    else if ( sname /= ' ' ) then
!       look for a station with sname as substring
        if ( index(name(i),trim(sname)) /= 0 ) then
            okstation = .true. 
        else if ( sname(1:1) == '(' ) then
            do k=1,ncountry
                if ( ic(i) == icountry(k) ) goto 110
            end do
            k = 0
        110 continue
            if ( index(country(k),trim(sname(2:))) /= 0 ) then
                okstation = .true. 
            end if
        end if
    else if ( slat1 < 1e33 ) then
        if ( (slon1 > slon .and. rlon(i) > slon .and. rlon(i) < slon1 &
         .or. &
        slon1 < slon .and. (rlon(i) < slon1 .or. rlon(i) > slon) &
        ) .and. ( &
        rlat(i) > min(slat,slat1) .and. rlat(i) < max(slat,slat1) ) ) then
            dist(i) = i
            n = i
            okstation = .true. 
        end if
    else
        print *,'internal error 31459263'
        call exit(-1)
    end if

!   check range of years

    if ( okstation .and. ( yr1 > 0 .or. yr2 < 3000 ) ) then
        call getdata(type,2,100000*ic(i)+iwmo(i),imod(i),0,nyr,nrec,nstat,yr1,yr2)
        if ( lmin ) then
            call checknyr(type,nmin,nyr,nyr,nyr,enough)
        else
            enough = .true. 
        end if
        if ( .not. enough .or. nyr(0) < 1) then
            if ( lwrite ) print *,'not enough data ',enough,nyr(0)
            okstation = .false. 
        end if
    end if

    if ( okstation ) then
        i = i + 1
        if ( i > nn ) then
            print *,'gettemp: error: too many stations (>',nn,')'
            print *,'         use a more specific substring'
            call exit(-1)
        end if
    end if

    goto 100

!   we read all interesting stations in memory
200 continue
    i = i - 1

    if ( nlist > 1 .or. istation /= 0 .or. sname /= ' ' .or. slat1 < 1e33 ) then
        n = i
    else
        call sortdist(i,n,dist,rlon,rlat,ind,rmin)
        if ( i < n ) n = i
    end if

!   output
    if ( istation <= 0 ) print '(a,i7,a)','Found ',n,' stations'
    if ( nlist > 0 ) then
        call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
    end if
    nok = 0
    do j=1,nn
        if ( nlist > 1 .or. istation /= 0 .or. sname /= ' ' .or. slat1 < 1e33 ) then
            jj = j
        else
            jj = ind(j)
            if ( jj == 0 ) goto 700
            if ( dist(jj) > 1e33 ) goto 700
        end if
        nok = nok + 1
        if ( nok > n ) goto 800
        if ( istation <= 0 ) print '(a)','=============================================='
        do k=1,ncountry
            if ( ic(jj) == icountry(k) ) goto 210
        end do
        k = 0
    210 continue
        print '(3a,a,a)','# ',name(jj),'(',trim(country(k)),')'
        if ( type(1:4) == 'prcp' .or. type(1:3) == 'slp' ) then
            print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','# coordinates: ' &
                ,rlat(jj),'N, ',rlon(jj),'E, ',ielevs(jj),'m'
        else
            print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','# coordinates: ' &
                ,rlat(jj),'N, ',rlon(jj),'E, ',ielevs(jj) &
                ,'m (prob: ',ielevg(jj),'m)'
        end if
        call tidyname(name(jj),country(k))
        if ( imod(jj) == 0 ) then
            print '(a,i5,2a)','# WMO station code: ',iwmo(jj),' ' &
                ,name(jj)
            write(wmostring,'(i5)') iwmo(jj)
        else if ( imod(jj) < 10 ) then
            print '(a,i5,a,i1,2a)','# Near WMO station code: ' &
                ,iwmo(jj),'.',imod(jj),' ',name(jj)
            write(wmostring,'(i5,a,i1)') iwmo(jj),'.',imod(jj)
        else if ( imod(jj) < 100 ) then
            print '(a,i5,a,i2,2a)','# Near WMO station code: ' &
                ,iwmo(jj),'.',imod(jj),' ',name(jj)
            write(wmostring,'(i5,a,i2)') iwmo(jj),'.',imod(jj)
        else
            print '(a,i5,a,i3,2a)','# Near WMO station code: ' &
                ,iwmo(jj),'.',imod(jj),' ',name(jj)
            write(wmostring,'(i5,a,i3)') iwmo(jj),'.',imod(jj)
        end if
        do while ( wmostring(1:1) == ' ' )
            wmostring = wmostring(2:)
        end do
        if ( type(1:4) /= 'prcp' .and. type(1:3) /= 'slp' ) then
            if ( istation <= 0 ) then
                if ( pop(jj) == 'R' ) then
                    print '(a)','Rural station'
                else if ( pop(jj) == 'S' ) then
                    print '(a,i5,a)' &
                    ,'Associated with small town (pop.' &
                    ,ipop(jj)*1000,')'
                else if ( pop(jj) == 'U' ) then
                    print '(a,i8,a)' &
                    ,'Associated with urban area (pop.' &
                    ,ipop(jj)*1000,')'
                else
                    print '(2a)','Unknown population code ',pop(jj)
                end if
                string = 'Terrain: '
                if ( topo(jj) == 'FL' ) then
                    string(10:) = 'flat'
                else if ( topo(jj) == 'HI' ) then
                    string(10:) = 'hilly'
                else if ( topo(jj) == 'MT' ) then
                    string(10:) = 'mountain top'
                else if ( topo(jj) == 'MV' ) then
                    string(10:) = 'mountain valley'
                else
                    string(10:) = 'code '//topo(jj)
                end if
                if ( stveg(jj) == 'MA' ) then
                    string(26:) = 'marsh'
                else if ( stveg(jj) == 'FO' ) then
                    string(26:) = 'forest'
                else if ( stveg(jj) == 'IC' ) then
                    string(26:) = 'ice'
                else if ( stveg(jj) == 'DE' ) then
                    string(26:) = 'desert'
                else if ( stveg(jj) == 'CL' ) then
                    string(26:) = 'open'
                else if ( stveg(jj) /= 'xx' ) then
                    string(26:) = 'code '//stveg(jj)
                end if
                print '(2a)',string(1:32),grveg(jj)
                if ( stloc(jj) == 'IS' ) then
                    print'(a)','Station is located on a small island'
                else if ( stloc(jj) == 'CO' ) then
                    print'(a,i2,a)','Station is located at ',iloc(jj),'km from coast'
                else if ( stloc(jj) == 'LA' ) then
                    print'(a)','Station is located next to large lake'
                else if ( stloc(jj) /= 'no' ) then
                    print '(2a)','Unknown code ',stloc(jj)
                end if
            end if
        end if
        if ( istation <= 0 ) then
            nflag = 999
        else
            nflag = 1
            ! new-style metadata
            print '(a)','# institution :: NOAA/NCEI'
            print '(a)','# source_url :: https://www.ncdc.noaa.gov/ghcnm/v2.php'
            print '(a)','# contact_email :: NCDC.GHCNM@noaa.gov.'
            !!!print '(a)','# source_doi :: accessed DATE'
            print '(a)','# retrieved :: DATE'
            print '(a)','# references :: Peterson, T.C., and R.S. Vose, 1997: '// &
                'An overview of the Global Historical Climatology Network temperature database.'// &
                'Bulletin of the American Meteorological Society, 78 (12), 2837-2849'
            print '(2a)','# station_name :: ',trim(name(jj))
            print '(2a)','# station_country :: ',trim(country(k))
            print '(2a)','# station_code :: ',trim(wmostring)
            print '(a,f7.2,a)','# latitude :: ',rlat(jj),' degrees_north'
            print '(a,f7.2,a)','# longitude :: ',rlon(jj),' degrees_east'
            print '(a,i8,a)','# elevation :: ',ielevs(jj),' m'
            print '(4a)','# climexp_url :: https://climexp.knmi.nl/get',trim(type),'.cgi?WMO=',trim(wmostring)
            call getenv('SCRIPTURL',scripturl)
            if ( scripturl /= ' ' ) then
                print '(2a)','# scripturl01 :: ',trim(scripturl)
            end if
        end if
        call getdata(type,2,100000*ic(jj)+iwmo(jj),imod(jj),nflag,nyr,nrec,nstat,yr1,yr2)
    700 continue
    end do
800 continue
    if ( istation <= 0 ) print '(a)','=============================================='
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
999 continue
end program gettemp

subroutine checknyr(type,nmin,nyr,nyrmin,nyrmax,enough)
    implicit none
    integer :: nmin(0:48),nyr(0:48),nyrmin(0:48),nyrmax(0:48)
    character :: type*(*)
    logical :: enough
    integer :: j
    enough = .true. 
    if ( type(1:4) == 'temp' .or. type(1:4) == 'prcp' .or. type(1:3) == 'slp' ) then
        do j=0,48
            if ( nmin(j) > 0 ) then
                if ( nyr(j) < nmin(j) ) enough = .false. 
            end if
        end do
    else if ( type(1:4) == 'tmin' ) then
        do j=0,48
            if ( nmin(j) > 0 ) then
                if ( nyrmin(j) < nmin(j) ) enough = .false. 
            end if
        end do
    else if ( type(1:4) == 'tmax' ) then
        do j=0,48
            if ( nmin(j) > 0 ) then
                if ( nyrmax(j) < nmin(j) ) enough = .false. 
            end if
        end do
    else
        write(0,*) 'error: what is ',type,'?'
        call exit(-1)
    end if
end subroutine checknyr
