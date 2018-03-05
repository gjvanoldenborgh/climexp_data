!
!       support functions common to getprpcp and gettemp
!       Geert Jan van Oldenborgh, KNMI, 1999-2000
!
subroutine getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation &
    ,isub,nmin,rmin,elevmin,elevmax,list,nl,nlist,yr1,yr2)
    implicit none
    character :: sname*(*)
    real :: slat,slon,slat1,slon1,rmin,elevmin,elevmax
    integer :: n,nn,istation,isub,nmin(0:48),nl,list(2,nl),nlist,yr1,yr2,narg

    integer :: i,j,mon,lsum,m
    double precision :: fstation
    character :: string*80,minnum*20
    integer :: iargc
    character :: months(12)*3
    data months /'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'/

    sname = ' '
    slat1 = 3e33
    slon1 = 3e33
    rmin = 0
    elevmin = -3e33
    elevmax = +3e33
    nlist = 0
    do j=0,48
        nmin(j) = 0
    end do
    mon = -1
    lsum = 1
    yr1 = 0
    yr2 = 3000
    narg = 9999

    call getarg(1,string)
    minnum = ''
    if ( iargc() == 3 ) call getarg(2,minnum)
    if ( iargc() == 1 .or. minnum(1:3) == 'min' .or. minnum(1:4) == 'elev' ) then
        if ( ichar(string(1:1)) >= ichar('0') .and. ichar(string(1:1)) <= ichar('9') ) then
            call readstation(string,istation,isub)
            n = 1
        else
            sname = string
            istation = -1
            do i=1,len_trim(sname)
                if ( sname(i:i) == '+' ) sname(i:i) = ' '
                if ( sname(i:i) == '_' ) sname(i:i) = ' '
            end do
            print *,'Looking for stations with substring ',trim(sname)
            n = 0
            narg = 2
        end if
    else if ( string(1:4) == 'list' ) then
        call getarg(2,string)
        print '(2a)','Reading stationlist from file ',trim(string)
        open(1,file=string,status='old')
     10 continue
        read(1,'(a)',end=20,err=20) string
        if ( string == ' ' ) goto 10
        if ( index(string(1:2),'#') /= 0 .or. index(string(1:2),'?') /= 0 ) then
            read(string(3:),*,err=18) slon,slon1,slat,slat1
            print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,a)','Searching for stations in ',slat,'N:', &
                slat1,'N, ',slon,'E:',slon1,'E'
         18 continue
        else
            nlist = nlist + 1
            if ( nlist > nl ) then
                print *,'error: too many stations',nl
                call exit(-1)
            end if
            call readstation(string,list(1,nlist),list(2,nlist))
        end if
        goto 10
     20 continue
        n = 2
        istation = -1
        if ( nlist == 0 ) then
            print *,'could not locate any stations'
            stop
        end if
    else
        istation = 0
        n = 10
        call getarg(1,string)
        i = index(string,':')
        if ( i /= 0 ) then
            read(string(:i-1),*,err=900) slat
            if ( slat < -90 .or. slat > 90 ) goto 900
            read(string(i+1:),*,err=900) slat1
            if ( slat1 < -90 .or. slat1 > 90 ) goto 900
            istation = -1
            n = 0
        else
            read(string,*,err=900) slat
            if ( slat < -90 .or. slat > 90 ) goto 900
        end if
        call getarg(2,string)
        i = index(string,':')
        if ( i /= 0 ) then
            read(string(:i-1),*,err=901) slon
            if ( slon > 180 ) slon = slon-360
            if ( slon < -180 .or. slon > 180 ) goto 901
            read(string(i+1:),*,err=900) slon1
            if ( slon1 > 180 ) slon1 = slon1-360
            if ( slon1 < -180 .or. slon1 > 180 ) goto 901
            if ( abs(slon-slon1) < 1e-3 ) then
                slon = -180
                slon1 = 180
            end if
        else
            read(string,*,err=901) slon
            if ( slon > 180 ) slon = slon-360
            if ( slon < -180 .or. slon > 180 ) goto 901
        end if
        if ( slat1 < 1e33 .neqv. slon1 < 1e33 ) goto 905
        if ( iargc() >= 3 ) then
            call getarg(3,string)
            if (  index(string,'min') == 0 .and. &
            index(string,'begin') == 0 .and. &
            index(string,'end') == 0 .and. &
            index(string,'elev') == 0 .and. &
            index(string,'dist') == 0 ) then
                read(string,*,err=903) n
                if ( n > nn ) then
                    print *,'recompile with nn larger'
                    call exit(-1)
                end if
                narg = 4
            else
                narg = 3
            end if
        end if
    end if
    i = narg
100 continue
    if ( iargc() >= i+1 ) then
        call getarg(i,string)
        if ( index(string,'elevmin') /= 0 ) then
            call getarg(i+1,string)
            read(string,*,err=907) elevmin
        else if ( index(string,'elevmax') /= 0 ) then
            call getarg(i+1,string)
            read(string,*,err=908) elevmax
        else if ( index(string,'min') /= 0 ) then
            call getarg(i+1,string)
            read(string,*,err=904) nmin(0)
        else if ( index(string,'mon') /= 0 ) then
            call getarg(i+1,string)
            read(string,*,err=904) mon
            if ( mon < 0 .or. mon > 12 ) then
                write(0,*) 'error: mon = ',12
                write(*,*) 'error: mon = ',12
                call exit(-1)
            end if
            if ( mon == 0 ) then
                do m=1,12
                    nmin(m) = nmin(0)
                end do
            else
                nmin(mon) = nmin(0)
            end if
            nmin(0) = 0
        else if ( index(string,'sum') /= 0 ) then
            call getarg(i+1,string)
            read(string,*,err=904) lsum
            if ( mon == -1 ) then
                write(0,*) 'please specify mon and sum'
                write(*,*) 'please specify mon and sum'
                call exit(-1)
            end if
            if ( lsum > 4 .or. lsum < 1 ) then
                write(0,*) 'error: 0 <= sum <= 4: ',lsum
                write(*,*) 'error: 0 <= sum <= 4: ',lsum
                call exit(-1)
            end if
            if ( lsum > 1 ) then
                if ( mon == 0 ) then
                    do m=1,12
                        nmin(m+12*(lsum-1)) = nmin(m)
                        nmin(m) = 0
                    end do
                else
                    nmin(mon+12*(lsum-1)) = nmin(mon)
                    nmin(mon) = 0
                end if
            end if
        else if ( index(string,'dist') /= 0 ) then
            call getarg(i+1,string)
            read(string,*,err=906) rmin
        else if ( index(string,'begin') /= 0 ) then
            call getarg(i+1,string)
            read(string,*,err=910) yr1
        else if ( index(string,'end') /= 0 ) then
            call getarg(i+1,string)
            read(string,*,err=911) yr2
        else
            print *,'error: unrecognized argument: ',string
            call exit(-1)
        end if
        i = i+2
        goto 100
    end if
    if ( n > 1 .and. nlist == 0 ) print '(a,i4,a)','Looking up ',n,' stations'
    if ( (n > 1 .or. slat1 < 1e33) .and. nlist == 0 ) then
        if ( slat1 > 1e33 ) then
            print '(a,f6.2,a,f7.2,a)' ,'Searching for stations near ',slat,'N, ',slon,'E'
        else
            print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,a)' &
            ,'Searching for stations in ',slat,'N:',slat1,'N, ',slon,'E:',slon1,'E'
        end if
        if ( elevmin > -1e33 ) then
            print '(a,f8.2,a)','Searching for stations higher than ',elevmin,'m'
        end if
        if ( elevmax < +1e33 ) then
            print '(a,f8.2,a)','Searching for stations lower than ',elevmax,'m'
        end if
        if ( mon == -1 ) then
            if ( nmin(0) > 0 ) print '(a,i4,a)','Requiring at least ',nmin(0),' years with data'
        else if ( mon == 0 ) then
            if ( lsum == 1 ) then
                print '(a,i4,a)','Requiring at least ',nmin(1),' years with data in all months'
            else
                print '(a,i4,a,i1,a)','Requiring at least ',nmin(1+(lsum-1)*12), &
                    ' years with data in all ',lsum,'-month seasons'
            end if
        else if ( mon > 0 ) then
            if ( lsum == 1 ) then
                print '(a,i4,2a)','Requiring at least ',nmin(mon),' years with data in ',months(mon)
            else
                print '(a,i4,4a)','Requiring at least ', nmin(mon+(lsum-1)*12), &
                    ' years with data in ',months(mon),'-',months(1+mod(mon+lsum-2,12))
            end if
        end if
        if ( yr1 > 0 ) then
            if ( yr2 < 3000 ) then
                print '(a,i4,a,i4)','Only considering the period ',yr1,'-',yr2
            else
                print '(a,i4)','Only considering the period starting in ',yr1
            end if
        else
            if ( yr2 < 3000 ) then
                print '(a,i4)','Only considering the period ending in ',yr2
            end if
        end if
        if ( rmin > 0 ) then
            print '(a,f8.2,a)','Requiring at least ',rmin,' degrees of separation'
        end if
    end if
    goto 999
900 print *,'please give latitude in degrees N, not ',string
    call exit(-1)
901 print *,'please give longitude in degrees E, not ',string
    call exit(-1)
903 print *,'please give number of stations to find, not ',string
    call exit(-1)
904 print *,'please give minimum number of years, not ',string
    call exit(-1)
905 print *,'please give range on both longitude and latitude'
    call exit(-1)
906 print *,'please give minimum distance between stations, ',string
    call exit(-1)
907 print *,'please give minimum elevation of station, ',string
    call exit(-1)
908 print *,'please give maximum elevation of station, ',string
    call exit(-1)
910 print *,'please give begin year ',trim(string)
    call exit(-1)
911 print *,'please give end year ',trim(string)
    call exit(-1)
999 continue
    end subroutine getgetargs

subroutine getdata(type,iu,ii,jj,n,nyr,nrec,nstat,yr1,yr2)

!   print precip data - use binary search to find the records in
!   the (sorted) direct access file v2.precip.beta.data open on unit iu
!
!   meaning of the parameters
!   type (in): string indicating the type of variable
!   iu (in): unit on whicgh the database is open
!   ii,jj (in): WMO id and modifier of the station for which data is searched
!   n (in): if 0: do not print data, only retrieve statistics
!           if 1: print data of the requested station
!           if >1: print a summary with the number of years and end points found
!   nyr(out): number of years with data
!   nrec(in): number of records in database
!   nstat(in): WMO number of last station in database
!   yr1,yr2 (in): restrict search to the time period yr1-yr2

    implicit none
    integer,parameter :: yrbeg=1500,yrend=2020
    character :: type*(*)
    integer :: iu,ii,jj,n,nyr(0:48),nrec,nstat,yr1,yr2
    integer :: i,j,k,kk,l,ilo,ihi,imi,i0,j0,yr,yrm1,firstyr,lastyr,prcp(24)
    real :: data(12,yrbeg:yrend)
    logical,parameter :: lwrite=.false.

    data = -999.9
    if ( lwrite ) print *,'looking for station ',ii,'.',jj,' in ',yr1,'-',yr2
    do j=0,48
        nyr(j) = 0
    end do
    ilo = 1
    j0 = 0
    yrm1 = -9999
    do j=1,24
        prcp(j) = -9999
    end do
    ihi = nrec
    if ( ii > nstat ) then
        print '(a)','Cannot locate any data.'
        goto 800
    end if
300 continue
    imi = (ilo+ihi)/2
    if ( lwrite ) print *,'reading record ',imi
    read(iu,1011,rec=imi) i0,j0,j,yr
1011 format(i8,i3,i1,i4)
    if ( lwrite ) print '(a,i10,i3,i5,i8,a,2i8,a)','Comparing with station ', &
        i0,j0,yr,imi,'(',ilo,ihi,')'
    if ( ii > i0 .or. ii == i0 .and. jj > j0 .or. &
         ii == i0 .and. jj == j0 .and. yr1 > yr ) then
        ilo = imi
    else if ( ii < i0 .or. ii == i0 .and. jj < j0 .or. &
              ii == i0 .and. jj == j0 .and. yr2 < yr ) then
        ihi = imi
    else
!       found a match - scan it
        if ( lwrite ) print *,'found match ',imi
        if ( n == 1 ) then
            if ( type == 'slp' ) then
                print '(a)','# SLP from v2.slp [mb]'
            else if ( type == 'prcp' ) then
                print '(a)','# prcp from v2.prcp_adj [mm/month]'
            else if ( type == 'prcpall' ) then
                print '(a)','# prcp from v2.prcp [mm/month]'
            else if ( type == 'temp' ) then
                print '(2a)','# temp from v2.mean_adj_nodup [Celsius]'
            else if ( type == 'tmin' ) then
                print '(2a)','# tmin from v2.min_adj_nodup [Celsius]'
            else if ( type == 'tmax' ) then
                print '(2a)','# tmax from v2.max_adj_nodup [Celsius]'
            else if ( type == 'tempall' ) then
                print '(2a)','# temp from v2.mean_nodup [Celsius]'
            else if ( type == 'tminall' ) then
                print '(2a)','# tmin from v2.min_nodup [Celsius]'
            else if ( type == 'tmaxall' ) then
                print '(2a)','# tmax from v2.max_nodup in [Celsius]'
            else if ( type == 'sea' ) then
                print '(2a)','# sealevelpressure from press.sea.data [mb]'
            else if ( type == 'sta' ) then
                print '(2a)','# stationpressure from press.sta.data [mb]'
            else if ( type == 'slv' ) then
                print '(2a)','# sealevel from psmsl.dat in [cm]'
            else if ( type == 'euslp' ) then
                print '(2a)','# sea-level-pressure from eurpres51.data in [mb]'
            else
                print *,'unknown type ',type
                call exit(-1)
            end if
        end if
        firstyr = +100000
        lastyr = -100000
        310 continue
        imi = imi - 1
        if ( imi > 0 ) then
            read(iu,1011,rec=imi) i0,j0,j,yr
        else
            i0 = -1
        end if
        if ( lwrite) print *,'read record ',imi,i0,j0,yr
        if ( i0 /= ii .or. j0 /= jj .or. yr < yr1 ) goto 319
        goto 310
    319 continue
        if ( lwrite ) print *,'found first ',i0,j0,yr
    320 continue
        imi = imi + 1
        do j=1,12
            prcp(j) = prcp(j+12)
        end do
        if ( imi <= nrec ) then
            read(iu,1012,rec=imi) i0,j0,j,yr,(prcp(j),j=13,24)
            1012 format(i8,i3,i1,i4,12i5)
        else
            i0 = -1
        end if
!       still the same station?
        if ( i0 /= ii .or. j0 /= jj .or. yr > yr2 ) then
            if ( lwrite ) print *,'found last ',i0,j0,yr
            if ( n > 1 ) print '(a,i4,a,i4,a,i4)','Found ',nyr(0), &
                ' years with data in ',firstyr,'-',lastyr
            if ( n == 1 ) then
                do firstyr=yrbeg,yrend
                    do j=1,12
                        if ( data(j,firstyr) /= -999.9 ) goto 400
                    end do
                end do
            400 continue
                do lastyr=yrend,yrbeg,-1
                    do j=1,12
                        if ( data(j,lastyr) /= -999.9 ) goto 410
                    end do
                end do
            410 continue
                do yr=firstyr,lastyr
                    print '(i5,12f7.1)',yr,(data(j,yr),j=1,12)
                end do
            end if
            goto 800
        end if
    
!           count number of valid months, 2,3,4-month seasons
    
        if ( yrm1 /= yr-1 ) then
            do j=1,12
                prcp(j) = -9999
            end do
        end if
        yrm1 = yr
        do j=1,12
            do k=0,3
                kk = j-k
                if ( kk <= 0 ) kk = kk+12
                kk = kk + k*12
                do l=0,k
                    if ( prcp(12+j-l) == -9999 .or. &
                    prcp(12+j-1) == -9998 .or. &
                    prcp(12+j-l) == -8888 ) goto 325
                end do
                nyr(kk) = nyr(kk) + 1
            325 continue
            end do
        end do
    
!       and the old measure - any year with valid months
    
        do j=13,24
            if ( prcp(j) /= -9999 .and. prcp(j) /= -8888 ) then
                nyr(0) = nyr(0) + 1
                firstyr = min(firstyr,yr)
                lastyr = max(lastyr,yr)
                goto 330
            end if
        end do
    330 continue
        if ( n == 1 ) then
            if ( yr < yrbeg .or. yr > yrend ) then
                write(0,*) 'disregarding year ',yr
            else
                do j=1,12
                    if ( prcp(j+12) /= -9999 ) then
                        if ( data(j,yr) == -999.9 ) then
                            if ( lwrite ) print *,'storing ',yr,j
                            data(j,yr) = prcp(j+12)/10.
                        else
                            write(0,'(a,i2.2,a,i4)') 'disregarding duplicate ',j,'.',yr
                        end if
                    end if
                end do
            end if
        end if
        goto 320
    end if
    if ( ihi-ilo > 1 ) then
        goto 300
    else
        if ( lwrite ) print *,'stop'
        if ( n > 0 ) print *,'getdata: cannot locate any data'
    end if
800 continue

end subroutine getdata

subroutine getdata3(type,iu,ii,jj,n,nyr,nrec,nstat,yr1,yr2,version)

!   print precip data - use binary search to find the records in
!   the (sorted) direct access file open on unit iu
!   meaning of the parameters
!   type (in): string indicating the type of variable
!   iu (in): unit on whicgh the database is open
!   ii,jj (in): WMO id and modifier of the station for which data is searched
!   n (in): if 0: do not print data, only retrieve statistics
!           if 1: print data of the requested station
!           if >1: print a summary with the number of years and end points found
!   nyr(out): number of years with data
!   nrec(in): number of records in database
!   nstat(in): WMO number of last station in database
!   yr1,yr2 (in): restrict search to the time period yr1-yr2

    implicit none
    integer,parameter :: yrbeg=1500,yrend=2050
    character :: type*(*),version*(*)
    integer :: iu,ii,jj,n,nyr(0:48),nrec,nstat,yr1,yr2
    integer :: i,j,k,kk,l,ilo,ihi,imi,i0,j0,yr,yrm1,firstyr,lastyr,prcp(24)
    real :: data(12,yrbeg:yrend)
    character :: element*4,flags(24)*3
    logical,parameter :: lwrite=.false.

    data = -999.9
    if ( lwrite ) print *,'looking for station ',ii,'.',jj,' in ',yr1,'-',yr2
    do j=0,48
        nyr(j) = 0
    end do
    ilo = 1
    j0 = 0
    yrm1 = -9999
    do j=1,24
        prcp(j) = -9999
    end do
    ihi = nrec
    if ( ii > nstat ) then
        print '(a)','Cannot locate any data.'
        goto 800
    end if
300 continue
    imi = (ilo+ihi)/2
    if ( lwrite ) print *,'reading record ',imi,iu
    read(iu,1011,rec=imi) i0,j0,yr
1011 format(i8,i3,i4)
    if ( lwrite ) print '(a,i10,i3,i5,i8,a,2i8,a)' &
        ,'Comparing with station ',i0,j0,yr,imi,'(',ilo,ihi,')'
    if ( ii > i0 .or. ii == i0 .and. jj > j0 .or. &
         ii == i0 .and. jj == j0 .and. yr1 > yr ) then
        ilo = imi
    else if ( ii < i0 .or. ii == i0 .and. jj < j0 .or. &
              ii == i0 .and. jj == j0 .and. yr2 < yr ) then
        ihi = imi
    else
!       found a match - scan it
        if ( lwrite ) print *,'found match ',imi
        if ( n == 1 ) then
            if ( type == 'temp' ) then
                print '(4a)','# tavg [Celsius] daily mean temperature (adjusted) ' &
                    ,'from GHCN-M ',trim(version)
            else if ( type == 'tmin' ) then
                print '(4a)','# tmin [Celsius] daily minimum temperature (adjusted) ' &
                    ,'from GHCN-M ',trim(version)
            else if ( type == 'tmax' ) then
                print '(4a)','# tmax [Celsius] daily maximum temperature (adjusted) ' &
                    ,'from GHCN-M ',trim(version)
            else if ( type == 'tempall' ) then
                print '(4a)','# tavg [Celsius] daily mean temperature (unadjusted) ' &
                    ,'from GHCN-M ',trim(version)
            else if ( type == 'tminall' ) then
                print '(4a)','# tmin [Celsius] daily minimum temperature (unadjusted) ' &
                    ,'from GHCN-M ',trim(version)
            else if ( type == 'tmaxall' ) then
                print '(4a)','# tmax [Celsius] daily maximum temperature (adjusted) ' &
                    ,'from GHCN-M ',trim(version)
            else
                print *,'unknown type ',type
                call exit(-1)
            end if
        end if
        firstyr = +100000
        lastyr = -100000
    310 continue
        imi = imi - 1
        if ( imi > 0 ) then
            read(iu,1011,rec=imi) i0,j0,yr
        else
            i0 = -1
        end if
        if ( lwrite) print *,'read record ',imi,i0,j0,yr
        if ( i0 /= ii .or. j0 /= jj .or. yr < yr1 ) goto 319
        goto 310
    319 continue
        if ( lwrite ) print *,'found first ',i0,j0,yr
    320 continue
        imi = imi + 1
        do j=1,12
            prcp(j) = prcp(j+12)
        end do
        if ( imi <= nrec ) then
            read(iu,1012,rec=imi) i0,j0,yr,element,(prcp(j),flags(j),j=13,24)
            if ( lwrite ) print 1012,i0,j0,yr,element,(prcp(j),flags(j),j=13,24)
       1012 format(i8,i3,i4,a4,12(i5,a3))
            if ( type(5:7) == 'all' ) then
                do j=13,24
                    if ( flags(j)(2:2) /= ' ' ) then
                        if ( lwrite ) print *,'QC flag = ',j,flags(j)(2:2),', set to undef'
                        prcp(j) = -9999
                    end if
                end do
            end if
        else
            i0 = -1
        end if
!       still the same station?
        if ( i0 /= ii .or. j0 /= jj .or. yr > yr2 ) then
            if ( lwrite ) print *,'found last ',i0,j0,yr
            if ( n > 1 ) print '(a,i4,a,i4,a,i4)','Found ',nyr(0), &
                ' years with data in ',firstyr,'-',lastyr
            if ( n == 1 ) then
                do firstyr=yrbeg,yrend
                    do j=1,12
                        if ( data(j,firstyr) /= -999.9 ) goto 400
                    end do
                end do
            400 continue
                do lastyr=yrend,yrbeg,-1
                    do j=1,12
                        if ( data(j,lastyr) /= -999.9 ) goto 410
                    end do
                end do
            410 continue
                do yr=firstyr,lastyr
                    print '(i5,12f7.1)',yr,(data(j,yr),j=1,12)
                end do
            end if
            goto 800
        end if
        if ( lwrite ) print *,'same station'
        if ( lwrite ) print *,'read yr = ',yr,(prcp(j),j=13,24)
    
!       count number of valid months, 2,3,4-month seasons

        if ( yrm1 /= yr-1 ) then
            do j=1,12
                if ( lwrite ) print *,'set previous year month ',j,' to undef'
                prcp(j) = -9999
            end do
        end if
        yrm1 = yr
        do j=1,12
            do k=0,3
                kk = j-k
                if ( kk <= 0 ) kk = kk+12
                kk = kk + k*12
                do l=0,k
                    if ( prcp(12+j-l) == -9999 .or. &
                         prcp(12+j-1) == -9998 .or. &
                         prcp(12+j-l) == -8888 ) goto 325
                end do
                nyr(kk) = nyr(kk) + 1
            325 continue
            end do
        end do
    
!       and the old measure - any year with valid months
    
        do j=13,24
            if ( prcp(j) /= -9999 .and. prcp(j) /= -8888 ) then
                nyr(0) = nyr(0) + 1
                firstyr = min(firstyr,yr)
                lastyr = max(lastyr,yr)
                goto 330
            end if
        end do
    330 continue

!       storing in data array

        if ( lwrite ) print *,'read yr = ',yr,(prcp(j),j=13,24)
        if ( n == 1 ) then
            if ( yr < yrbeg .or. yr > yrend ) then
                write(0,*) 'disregarding year ',yr
            else
                do j=1,12
                    if ( prcp(j+12) /= -9999 ) then
                        if ( data(j,yr) == -999.9 ) then
                            if ( lwrite ) print *,'storing ',yr,j
                            data(j,yr) = prcp(j+12)/100.
                        else
                            write(0,'(a,i2.2,a,i4)') 'disregarding duplicate ',j,'.',yr
                        end if
                    end if
                end do
            end if
        end if
        goto 320
    end if
    if ( ihi-ilo > 1 ) then
        goto 300
    else
        if ( lwrite ) print *,'stop'
        if ( n > 0 ) print *,'getdata: cannot locate any data'
    end if
800 continue

end subroutine getdata3

subroutine tidyname(name,country)

!   Get rid of country
!   Replace spaces by underscores

    implicit none
    character*(*) name,country
    integer :: i,j,len_trim
    character(5) :: c5

    c5 = country
    if ( len_trim(c5) > 3 ) then
        i = index(name(3:),trim(c5)) ! dont kill SINGAPORE...
        if ( i > 0 ) name(i+2:) = ' '
    end if
!   a few spacial cases
    i = index(name,'   ')
    if ( i > 0 ) name(i:) = ' '
    i = index(name,' USA')
    if ( i > 0 ) name(i:) = ' '
    i = index(name,' YEMEN')
    if ( i > 0 ) name(i:) = ' '
    i = index(name,' W.GERMANY')
    if ( i > 0 ) name(i:) = ' '

    do j=1,len_trim(name)
        if ( name(j:j) == ' ' ) name(j:j) = '_'
    end do

    end subroutine tidyname

subroutine toupper(string)
    implicit none
    character string*(*)
    integer :: i
    do i=1,len(string)
        if (  ichar(string(i:i)) >= ichar('a') .and. &
              ichar(string(i:i)) <= ichar('z') ) then
            string(i:i) = char(ichar(string(i:i)) - ichar('a') + ichar('A'))
        end if
    end do
    if ( string == ' ' ) then
        string = 'UNKNOWN'
    end if
end subroutine toupper

subroutine tolower(string)
    implicit none
    character string*(*)
    integer :: i
    do i=1,len(string)
        if (  ichar(string(i:i)) >= ichar('A') .and. &
              ichar(string(i:i)) <= ichar('Z') ) then
            string(i:i) = char(ichar(string(i:i)) - ichar('A') + ichar('a'))
        end if
    end do
end subroutine tolower

subroutine sortdist(i,n,dist,rlon,rlat,ind,rmin)
    implicit none
    integer :: i,n,ind(i)
    real :: dist(i),rlat(i),rlon(i),rmin
    integer :: j,k,nok,jj,kk
    real :: dlon,d,pi
    parameter (pi  = 3.1415926535897932384626433832795d0)

!   make and sort index array - Numerical recipes routine
    call indexx(i,dist,ind)
    if ( rmin > 0 ) then
!       discard stations that are too close together
        nok = 0
        do j=1,i
            jj = ind(j)
            if ( dist(jj) < 1e33 ) then
                nok = nok + 1
                if ( nok > n ) return
                do k=j+1,i
                    kk = ind(k)
                    if ( dist(kk) < 1e33 ) then
                        dlon = min(abs(rlon(jj)-rlon(kk)), &
                                   abs(rlon(jj)-rlon(kk)-360), &
                                   abs(rlon(jj)-rlon(kk)+360))
                        d = (rlat(jj)-rlat(kk))**2 + &
                            (dlon*cos((rlat(jj)+rlat(kk))/2/180*pi))**2
                        if ( d < rmin**2 ) then
                            dist(kk) = 3e33
                        end if
                    end if
                end do
            end if
        end do
    else
        nok = n
    end if
    n = nok
end subroutine sortdist


!  (C) Copr. 1986-92 Numerical Recipes Software +.-).
SUBROUTINE indexx(n,arr,indx)
    INTEGER :: n,indx(n),M,NSTACK
    REAL :: arr(n)
    PARAMETER (M=7,NSTACK=50)
    INTEGER :: i,indxt,ir,itemp,j,jstack,k,l,istack(NSTACK)
    REAL :: a
    do 11 j=1,n
        indx(j)=j
    11 END DO
    jstack=0
    l=1
    ir=n
    1 if(ir-l < M)then
        do 13 j=l+1,ir
            indxt=indx(j)
            a=arr(indxt)
            do 12 i=j-1,1,-1
                if(arr(indx(i)) <= a)goto 2
                indx(i+1)=indx(i)
            12 END DO
            i=0
            2 indx(i+1)=indxt
        13 END DO
        if(jstack == 0)return
        ir=istack(jstack)
        l=istack(jstack-1)
        jstack=jstack-2
    else
        k=(l+ir)/2
        itemp=indx(k)
        indx(k)=indx(l+1)
        indx(l+1)=itemp
        if(arr(indx(l+1)) > arr(indx(ir)))then
            itemp=indx(l+1)
            indx(l+1)=indx(ir)
            indx(ir)=itemp
        end if
        if(arr(indx(l)) > arr(indx(ir)))then
            itemp=indx(l)
            indx(l)=indx(ir)
            indx(ir)=itemp
        end if
        if(arr(indx(l+1)) > arr(indx(l)))then
            itemp=indx(l+1)
            indx(l+1)=indx(l)
            indx(l)=itemp
        end if
        i=l+1
        j=ir
        indxt=indx(l)
        a=arr(indxt)
        3 continue
        i=i+1
        if(arr(indx(i)) < a)goto 3
        4 continue
        j=j-1
        if(arr(indx(j)) > a)goto 4
        if(j < i)goto 5
        itemp=indx(i)
        indx(i)=indx(j)
        indx(j)=itemp
        goto 3
        5 indx(l)=indx(j)
        indx(j)=indxt
        jstack=jstack+2
        if(jstack > NSTACK)then
            write(0,*) 'indexx: error: NSTACK too small'
            call exit(-1)
        end if
        if(ir-i+1 >= j-l)then
            istack(jstack)=ir
            istack(jstack-1)=i
            ir=j-1
        else
            istack(jstack)=j-1
            istack(jstack-1)=l
            l=i
        end if
    end if
    goto 1
end SUBROUTINE indexx

subroutine readstation(string,istation,isub)
    implicit none
    character :: string*(*)
    integer :: istation,isub
    integer :: i,j,k
    j=1
 10 continue
    if ( string(j:j) == ' ' ) then
        j = j + 1
        goto 10
    end if
    k=j+1
 20 continue
    if ( string(k:k) /= ' ' ) then
        k = k + 1
        goto 20
    end if
    if ( index(string(j:k),'.') == 0 ) then
        read(string(j:k),*) istation
        isub = 0
    else
        i = j + index(string(j:),'.')
        read(string(j:i-2),*) istation
        j = ichar(string(i:i))
        if ( i >= ichar('a') .and. j <= ichar('z') ) then
            isub = j - ichar('a')
        else if ( i >= ichar('A') .and. j <= ichar('Z') ) then
            isub = j - ichar('A')
        else
            read(string(i:),*) isub
        end if
    end if
    return
end subroutine readstation

subroutine updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax,rlon,rlat)
    implicit none
    integer :: i
    real :: rlonmin,rlonmax,rlatmin,rlatmax,rlon,rlat
    if ( i == 1 ) then
        rlonmin = rlon
        rlonmax = rlon
        rlatmin = rlat
        rlatmax = rlat
    else
        rlatmin = min(rlatmin,rlat)
        rlatmax = max(rlatmax,rlat)
        if ( abs(rlon-rlonmin) < abs(rlon-rlonmin-360) ) then
            rlonmin = min(rlonmin,rlon)
        else
            rlonmin = min(rlonmin,rlon-360)
        end if
        if ( abs(rlon-rlonmax) < &
        abs(rlon-rlonmax+360) ) then
            rlonmax = max(rlonmax,rlon)
        else
            rlonmax = max(rlonmax,rlon+360)
        end if
    end if
end subroutine updatebox

subroutine printbox(rlonmin,rlonmax,rlatmin,rlatmax)
    implicit none
    real :: rlonmin,rlonmax,rlatmin,rlatmax
    real :: r
    if ( rlonmax-rlonmin > 360 ) then
        rlonmax = rlonmax - 360
    end if
!       add 10%
    r = rlatmax-rlatmin
    rlatmin = max(-90.,rlatmin-r/10)
    rlatmax = min(+90.,rlatmax+r/10)
    r = rlonmax-rlonmin
    rlonmin = rlonmin-r/10
    rlonmax = rlonmax+r/10
    print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,a)','Located stations in ' &
        ,rlatmin,'N:',rlatmax,'N, ',rlonmin,'E:',rlonmax,'E'
end subroutine printbox

!integer function llen(a)
!    character*(*) a
!    do 10 i=len(a),1,-1
!        if ( a(i:i) /= '?' .and. a(i:i) /= ' ' .and. a(i:i) /= char(0) ) goto 20
! 10 END DO
! 20 continue
!    llen = max(i,1)
!end function llen
            
