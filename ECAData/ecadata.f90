program eca

!   get ECA stations near a given coordinate, or with a given name, or the data

    implicit none
    integer,parameter :: nn=1000000
    double precision,parameter :: pi = 3.1415926535897932384626433832795d0
    integer :: i,j,k,ii,jj,kk,n,ldir,istation,nmin(0:48),yr,nok,nlist &
        ,ilat(3),ilon(3),idates(3),iecdold,isource
    integer :: iwmo(nn),iecd(nn),firstyr(nn),lastyr(nn),nyr(nn),ind(nn) &
        ,list(nn),tmin,tmax,temp,prcp,mo,dy,ielev,ndigit,statbuf(13)
    real :: rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon &
        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin &
        ,rlatmax,val,elev(nn)
    logical :: blend,lwrite
    character :: name(nn)*40,country(nn)*2,pmlon*1,pmlat*1,gsn(nn)*3 &
        ,el*3,elem*40,element*2,elin*2,wmo*6,units*10,longname*40
    character :: string*200,line*500,sname*25,history*1000
    character :: dir*256,format*20
    integer :: iargc,rindex
! 01- 05 STAID  : Location identifier (see file location.txt for more info.)
! 07- 12 SOUID  : Source identifier
! 14- 53 SOUNAME: Source name
! 55- 56 CN     : Country code (ISO3116 country codes)
! 58- 66 LAT    : Latitude in degrees:minutes:seconds (+: North, -: South)
! 68- 76 LON    : Longitude in degrees:minutes:seconds (+: East, -: West)
! 78- 81 HGTH   : Height in meters
!       3i5 yr1,yr2,nyr (added by addyear)
    lwrite = .false. 
    if ( iargc() < 1 ) then
        print '(a)','usage: eca{tmin|temp|tmax|prcp} [lat lon|name] [min years]'
        print '(a)','       gives stationlist with years of data'
        print '(a)','       eca{tmin|temp|tmax|prcp station_id'
        print '(a)','       gives data station_id'
        call exit(-1)
    end if
    call getarg(0,string)
    if ( index(string,'ecatemp') /= 0 ) then
        element = 'tg'
    else if ( index(string,'ecatmin') /= 0 ) then
        element = 'tn'
    else if ( index(string,'ecatmax') /= 0 ) then
        element = 'tx'
    else if ( index(string,'ecatave') /= 0 ) then
        element = 'tv'
    else if ( index(string,'ecatdif') /= 0 ) then
        element = 'td'
    else if ( index(string,'ecaprcp') /= 0 ) then
        element = 'rr'
    else if ( index(string,'ecapres') /= 0 ) then
        element = 'pp'
    else if ( index(string,'ecasnow') /= 0 ) then
        element = 'sd'
    else if ( index(string,'ecaclou') /= 0 ) then
        element = 'cc'
    else
        print *,'do not know which database to use when running as ',trim(string)
        call exit(-1)
    end if
    if ( element == 'rr' ) then
        units = '[mm/day]'
        longname = '24-hr summed precipittaion'
    else if ( element == 'pp' ) then
        units = '[mb]'
        longname = 'sea-level pressure'
    else if ( element == 'tg' ) then
        units = '[Celsius]'
        longname = 'daily mean temperature'
    else if ( element == 'tn' ) then
        units = '[Celsius]'
        longname = 'daily minimukm temperature'
    else if ( element == 'tx' ) then
        units = '[Celsius]'
        longname = 'daily maximum temperature'
    else if ( element == 'sd' ) then
        units = '[m]'
        longname = 'snow depth'
    else if ( element == 'cc' ) then
        units = '[1]'
        longname = 'cloud cover'
    end if
    i = rindex(string,'/')
    if ( string(i+1:i+4) == 'beca' ) then
        blend = .true. 
    else if ( string(i+1:i+3) == 'eca' ) then
        blend = .false. 
    else
        write(0,*) 'ecanew: error: called as ',string
        write(*,*) 'ecanew: error: called as ',string
        call exit(-1)
    end if
    call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,1 &
        ,nmin,rmin,elevmin,elevmax,list,nn,nlist)
!   no monthly time information yet
    do i=1,48
        if ( nmin(i) /= 0 ) then
            nmin(0) = nmin(i)
            if ( istation <= 0 ) then
                print *,'No monthly information yet, using years.'
            end if
        end if
    end do
    if ( istation == -1 ) then
        do i=1,nn
            dist(i) = 3e33
        end do
    end if

    call getenv('DIR',dir)
    if ( dir /= ' ' ) then
        ldir = len_trim(dir)
        dir(ldir+1:) = '/ECAData/'
    else
        dir = '/usr/people/oldenbor/NINO/ECAData/'
    end if
    ldir = len_trim(dir)
    if ( blend ) then
        write(line,'(4a)') dir(1:ldir),'ECA_blend_station_',element,'.txt.withyears'
    else
        write(line,'(4a)') dir(1:ldir),'ECA_nonblend_station_',element,'.txt.withyears'
    end if
    open(unit=1,file=trim(line),status='old')
!   skip headers
 10 continue
    read(1,'(a)') line
    if ( line(1:5) /= 'STAID' ) goto 10
    read(1,'(a)') string
    if ( string /= ' ' ) then
        print *,'ecadata: error: header has changed!'
        print *,string
    end if

    i = 1
    100 continue
    read(1,'(a)',err=920,end=200) line
    read(line,1000,err=101) iecd(i),name(i),country(i), &
        pmlat,ilat,pmlon,ilon,ielev,idates
1000 format(i5,1x,a40,1x,a2,1x, &
        a1,i2,1x,i2,1x,i2,1x, &
        a1,i2,1x,i2,1x,i2,1x, &
        i5,3i5)
    goto 102
!   they added stations with 3-digit longitude, try again with that format
101 continue
    read(line,1001,err=950) iecd(i),name(i),country(i), &
        pmlat,ilat,pmlon,ilon,ielev,idates
1001 format(i5,1x,a40,1x,a2,1x, &
        a1,i2,1x,i2,1x,i2,1x, &
        a1,i3,1x,i2,1x,i2,1x, &
        i5,x,3i5)
102 continue

!   regularize name - often has '-N' added to it
    k = len_trim(name(1))
    if ( name(i)(k-1:k-1) == '-' ) then
        name(i)(k-1:k) = ' '
    end if
    firstyr(i) = idates(1)
    lastyr(i) = idates(2)
    nyr(i) = idates(3)

!   check that we have enough years of data
!   for the time being, this does not take missing years into account
!   note that missing = -9999 gives firstyr,lastyr=0
    if ( nmin(0) > 0 ) then
        if ( nyr(i) < nmin(0) ) goto 100
    end if

!   check elevation
    elev(i) = ielev
    if ( elev(i) < elevmin .or. elev(i) > elevmax ) goto 100
    if ( ielev == -9999 .and. &
    (elevmin > -1e33 .or. elevmax < 1e33) ) goto 100

!   search closest
    rlon(i) = ilon(1) + (ilon(2) + ilon(3)/60.)/60.
    if ( pmlon == '-' ) then
        rlon(i) = -rlon(i)
    else if ( pmlon /= '+' ) then
        goto 100
    end if
    rlat(i) = ilat(1) + (ilat(2) + ilat(3)/60.)/60.
    if ( pmlat == '-' ) then
        rlat(i) = -rlat(i)
    else if ( pmlat /= '+' ) then
        goto 100
    end if
    if ( nlist > 0 ) then
!       look for a station in the list
        do j=1,nlist
            if ( iecd(i) == list(j) ) then
                if ( lwrite ) write(0,*) 'found station',i,j,iecd(i)
                call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax,rlon(i),rlat(i))
                i = i + 1
            end if
        end do
    else if ( istation == 0 ) then
        dlon = min(abs(rlon(i)-slon), &
                   abs(rlon(i)-slon-360), &
                   abs(rlon(i)-slon+360))
        dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
        i = i + 1
    else if ( istation > 0 ) then
        if ( iecd(i) == istation  ) then
            i = i + 1
            goto 200
        end if
    else if ( sname /= ' ' ) then
!       look for a station with sname as substring
        if ( index(name(i),trim(sname)) /= 0 .or. &
             sname(1:1) == '(' .and. sname(2:3) == country(i) ) then
            i = i + 1
            if ( i > nn ) then
                print *,'Maximum ',nn,' stations'
                call exit(-1)
            end if
        else
            goto 100
        end if
    else if ( slat1 < 1e33 ) then
!       look for a station in the box
        if ( (slon1 > slon .and. &
            rlon(i) > slon .and. rlon(i) < slon1  .or. &
            slon1 < slon .and. (rlon(i) < slon1 .or. rlon(i) > slon) &
            ) .and. ( &
            rlat(i) > min(slat,slat1) .and. &
            rlat(i) < max(slat,slat1) ) &
                ) then
            dist(i) = i
            n = i
            i = i + 1
            if ( i > nn ) then
                print *,'Maximum ',nn,' stations'
                call exit(-1)
            end if
        end if
    else
        print *,'internal error 31459263'
        call exit(-1)
    end if
    goto 100

!   we read all interesting stations in memory
200 continue
    i = i - 1

    if ( nlist == 0 .and. (istation == 0 .or. slat1 < 1e33) ) then
        call sortdist(i,n,dist,rlon,rlat,ind,rmin)
    else
        n = i
    end if
    if ( lwrite ) write(0,*) 'found ',n,' stations'

!   output
    if ( n == 0 ) then
        print '(a)','Cannot locate station'
        call exit(-1)
    end if
    if ( istation <= 0 ) print '(a,i5,a)','Found ',n,' stations'
    if ( nlist > 0 ) then
        call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
    end if
    nok = 0
    do j=1,n
        if (  nlist == 0 .and. (istation == 0 .or. slat1 < 1e33) ) then
            jj = ind(j)
            if ( jj == 0 ) goto 700
            if ( dist(jj) > 1e33 ) goto 700
        else
            jj = j
        end if
        nok = nok + 1
        if ( nok > n ) goto 800
        if ( istation <= 0 ) print '(a)','=============================================='
        do k=1,len_trim(name(jj))
            if ( name(jj)(k:k) == ' ' ) name(jj)(k:k) = '_'
        end do
        if ( istation <= 0 ) then
            print '(4a)',name(jj),' (',trim(country(jj)),')'
            print '(a,f6.2,a,f7.2,a,f8.1,a)','coordinates: ', &
                rlat(jj),'N, ',rlon(jj),'E, ',elev(jj),'m'
            print '(a,i10,4a)','ECA station code: ',iecd(jj) &
                ,' ',trim(name(jj))
        else
            print '(6a)','# ',element,' ',trim(units),' ',trim(longname)
            print '(a,f6.2,a,f7.2,a,f8.1,a,i10,10a)' &
                ,'# coordinates: ',rlat(jj),'N, ',rlon(jj),'E, ' &
                ,elev(jj),'m; ECA station code: ',iecd(jj) &
                ,' ',trim(name(jj)),' ',trim(country(jj))
        end if
        if ( istation <= 0 ) then
            print '(a,i4,a,i4,a,i4)','Found ',nyr(jj) &
                ,' years of data in ',firstyr(jj),'-' &
                ,lastyr(jj)
        else
            ! new-style metadata
            print '(a)','# institution :: KNMI'
            print '(a)','# source_url :: http://www.ecad.eu/'
            !!!print '(a)','# source_doi :: '
            print '(a)','# contact_email :: eca@knmi.nl'
            print '(a)','# reference :: Klein Tank et al. (2002) Daily dataset of 20th-century'// &
                'surface air temperature and precipitation series for the European Climate Assessment, '// &
                'Intern. J. Climatol. 22:1441-1453. doi:10.1002/joc.773'
            print '(a)','# license :: Data is strictly for non-commercial research and education only. '// &
                'See http://www.ecad.eu/documents/ECAD_datapolicy.pdf'
            ndigit = 1 + int(log10(1.0000001d0*iecd(jj)))
            write(format,'(a,i1,a)') '(a,i',ndigit,')'
            print format,'# station_code :: ',iecd(jj)
            print '(2a)','# station_name :: ',trim(name(jj))
            print '(2a)','# station_country :: ',trim(country(jj))
            print format,'# station_metadata :: http://www.ecad.eu/utils/stationdetail.php?stationid=',iecd(jj)
            print '(a,f7.2,a)','# latitude :: ',rlat(jj),' degrees_north'
            print '(a,f7.2,a)','# longitude :: ',rlon(jj),' degrees_east'
            print '(a,f8.1,a)','# elevation :: ',elev(jj),' m'
            
            if ( blend ) then
                write(dir(ldir+1:),'(2a,i6.6,a)') '/data/b',element, &
                    iecd(jj),'.dat.gz'
            else
                write(dir(ldir+1:),'(2a,i6.6,a)') '/data/',element, &
                    iecd(jj),'.dat.gz'
            end if
            call mystat(trim(dir),statbuf,i)
            call myctime(statbuf(10),string) ! last-modified time as an approximation to retrieval time
            print '(2a)','# timestamp :: ',trim(string)
            history = ' ' ! first program in the chain
            call extend_history(history)
            print '(2a)','# history :: ',trim(history)
            
            ldir = len_trim(dir)
            write(string,'(2a,i6.6,a)') '/tmp/',element,iecd(jj),'.dat'
            open(2,file=dir,status='old',err=940)
            close(2)
            call mysystem('gzip -d -c '//dir(1:ldir)//' > '//trim(string),i)
            if ( i /= 0 ) then
                write(0,*) 'gunzipping failed, error code =',i
                write(0,*) 'gzip -d -c '//dir(1:ldir)//' > '//trim(string)
            end if
            open(2,file=trim(string),status='old',err=940)
!           read and print file minus the first line
            read(2,'(a)',end=690,err=930) string
        600 continue
            read(2,'(a)',end=690,err=930) string
            print '(a)',trim(string)
            goto 600
        690 continue
            close(2,status='delete')
        end if
    700 continue
    end do
800 continue
    if ( istation <= 0 ) print '(a)','=============================================='
    goto 999
920 print *,'error reading information, last station was ', &
    country(i),name(i)
    call exit(-1)
930 print *,'error reading data at/after line ',j,yr
    call exit(-1)
940 print *,'error: cannot locate data file ',dir(1:ldir)
    write(0,*)'error: cannot locate data file ',dir(1:ldir)
    call exit(-1)
950 continue
    goto 100
    999 continue
end program eca

integer function rindex(string,pattern)
    implicit none
    character string*(*),pattern*(*)
    integer :: ls,lp,i
    ls = len(string)
    lp = len(pattern)
    if ( lp <= 0 .or. lp > ls ) then
        rindex = 0
        return
    end if
    do i=ls-lp+1,1,-1
        if ( string(i:i+lp-1) == pattern ) then
            rindex = i
            return
        end if
    end do
    rindex = 0
end function rindex
