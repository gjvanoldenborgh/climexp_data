!   support function common to getprpcp and gettemp
!   Geert Jan van Oldenborgh, KNMI, 1999-2000, 2019

    subroutine getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation &
        ,ifac,nmin,rmin,elevmin,elevmax,list,nl,nlist)
    implicit none
    character sname*(*)
    real :: slat,slon,slat1,slon1,rmin,elevmin,elevmax
    integer :: n,nn,istation,ifac,nmin(0:48),nl,list(nl),nlist

    integer :: i,j,mon,lsum,m
    double precision :: fstation
    character string*80
    integer :: iargc
    character months(12)*3
    data months /'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug' &
        ,'Sep','Oct','Nov','Dec'/

    sname = ' '
    slat1 = 3e33
    slon1 = 3e33
    rmin = 0
    elevmin = -3e33
    elevmax = +3e33
    nlist = 0
    do j=0,48
        nmin(j) = 0
    enddo
    mon = -1
    lsum = 1

    call get_command_argument(1,string)
    if ( command_argument_count() == 1 .and.  &
         ichar(string(1:1)) >= ichar('0') .and. &
         ichar(string(1:1)) <= ichar('9') ) then
        call readstation(string,istation,ifac)
        n = 1
    elseif ( string(1:4) == 'list' ) then
        call get_command_argument(2,string)
        print '(2a)','Reading stationlist from file ',trim(string)
        open(1,file=string,status='old')
     10 continue
        read(1,'(a)',end=20,err=20) string
        if ( string == ' ' ) go to 10
        if ( index(string(1:2),'#') /= 0 ) then
            read(string(3:),*,err=18) slon,slon1,slat,slat1
            print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,a)' &
                ,'Searching for stations in ',slat,'N:', &
                slat1,'N, ',slon,'E:',slon1,'E'
         18 continue
        else
            nlist = nlist + 1
            if ( nlist > nl ) then
                print *,'error: too many stations',nl
                call exit(-1)
            endif
            call readstation(string,list(nlist),ifac)
        endif
        goto 10
     20 continue
        n = 2
        istation = -1
        if ( nlist == 0 ) then
            print *,'could not locate any stations'
            call exit(0)
        endif
    else if ( ichar(string(1:1)) >= ichar('A') .and. ichar(string(1:1)) <= ichar('Z') .or. &
              ichar(string(1:1)) >= ichar('a') .and. ichar(string(1:1)) <= ichar('z') ) then
        sname = string
        istation = -1
        do i=1,len_trim(sname)
            if ( sname(i:i) == '+' ) sname(i:i) = ' '
        enddo
        call toupper(sname)
        print *,'Looking for stations with substring ',trim(sname)
        n = 0
    else
        istation = 0
        n = 10
        call get_command_argument(1,string)
        i = index(string,':')
        if ( i /= 0 ) then
            read(string(1:i-1),*,err=900) slat
            read(string(i+1:),*,err=900) slat1
            if ( slat1 < -90 .or. slat1 > 90 ) go to 900
            istation = -1
            n = 0
        else
            read(string,*,err=900) slat
        endif
        if ( slat < -90 .or. slat > 90 ) go to 900
        call get_command_argument(2,string)
        i = index(string,':')
        if ( i /= 0 ) then
            read(string(:i-1),*,err=901) slon
            if ( slon > 180 ) slon = slon-360
            if ( slon < -180 .or. slon > 180 ) go to 901
            read(string(i+1:),*,err=901) slon1
            if ( slon1 > 180 ) slon1 = slon1-360
            if ( slon1 < -180 .or. slon1 > 180 ) go to 901
            if ( abs(slon-slon1) < 1e-3 ) then
                slon = -180
                slon1 = 180
            endif
        else
            read(string,*,err=901) slon
            if ( slon > 180 ) slon = slon-360
            if ( slon < -180 .or. slon > 180 ) go to 901
        endif
        if ( slat1 < 1e33 .neqv. slon1 < 1e33 ) go to 905
        if ( command_argument_count() >= 3 ) then
            call get_command_argument(3,string)
            if (  index(string,'min') == 0 .and. &
            index(string,'elev') == 0 .and. &
            index(string,'dist') == 0 ) then
                read(string,*,err=903) n
                if ( n > nn ) then
                    print *,'recompile with nn larger'
                    call exit(-1)
                endif
                i = 4
            else
                i = 3
            endif
        100 continue
            if ( command_argument_count() >= i+1 ) then
                call get_command_argument(i,string)
                if ( index(string,'elevmin') /= 0 ) then
                    call get_command_argument(i+1,string)
                    read(string,*,err=907) elevmin
                elseif ( index(string,'elevmax') /= 0 ) then
                    call get_command_argument(i+1,string)
                    read(string,*,err=908) elevmax
                elseif ( index(string,'min') /= 0 ) then
                    call get_command_argument(i+1,string)
                    read(string,*,err=904) nmin(0)
                elseif ( index(string,'mon') /= 0 ) then
                    call get_command_argument(i+1,string)
                    read(string,*,err=904) mon
                    if ( mon < 0 .or. mon > 12 ) then
                        write(0,*) 'error: mon = ',12
                        write(*,*) 'error: mon = ',12
                        call exit(-1)
                    endif
                    if ( mon == 0 ) then
                        do m=1,12
                            nmin(m) = nmin(0)
                        enddo
                    else
                        nmin(mon) = nmin(0)
                    endif
                    nmin(0) = 0
                elseif ( index(string,'sum') /= 0 ) then
                    call get_command_argument(i+1,string)
                    read(string,*,err=904) lsum
                    if ( mon == -1 ) then
                        write(0,*) 'please specify mon and sum'
                        write(*,*) 'please specify mon and sum'
                        call exit(-1)
                    endif
                    if ( lsum > 4 .or. lsum < 1 ) then
                        write(0,*) 'error: 0 <= sum <= 4: ',lsum
                        write(*,*) 'error: 0 <= sum <= 4: ',lsum
                        call exit(-1)
                    endif
                    if ( lsum > 1 ) then
                        if ( mon == 0 ) then
                            do m=1,12
                                nmin(m+12*(lsum-1)) = nmin(m)
                                nmin(m) = 0
                            enddo
                        else
                            nmin(mon+12*(lsum-1)) = nmin(mon)
                            nmin(mon) = 0
                        endif
                    endif
                elseif ( index(string,'dist') /= 0 ) then
                    call get_command_argument(i+1,string)
                    read(string,*,err=906) rmin
                else
                    print *,'error: unrecognized argument: ',string
                    call exit(-1)
                endif
                i = i+2
                goto 100
            endif
        endif
        if ( n > 1 ) print '(a,i4,a)','Looking up ',n,' stations'
        if ( n > 1 .or. slat1 < 1e33 ) then
            if ( slat1 > 1e33 ) then
                print '(a,f6.2,a,f7.2,a)' &
                    ,'Searching for stations near ',slat,'N, ',slon,'E'
            else
                print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,a)' &
                    ,'Searching for stations in ',slat,'N:',slat1,'N, ',slon,'E:',slon1,'E'
            endif
            if ( elevmin > -1e33 ) then
                print '(a,f8.2,a)','Searching for stations higher than ',elevmin,'m'
            endif
            if ( elevmax < +1e33 ) then
                print '(a,f8.2,a)','Searching for stations lower than ',elevmax,'m'
            endif
            if ( mon == -1 ) then
                if ( nmin(0) > 0 ) print '(a,i4,a)', &
                    'Requiring at least ',nmin(0),' years with data'
            elseif ( mon == 0 ) then
                if ( lsum == 1 ) then
                    print '(a,i4,a)','Requiring at least ',nmin(1),' years with data in all months'
                else
                    print '(a,i4,a,i1,a)','Requiring at least ', &
                        nmin(1+(lsum-1)*12), &
                        ' years with data in all ',lsum &
                        ,'-month seasons'
                endif
            elseif ( mon > 0 ) then
                if ( lsum == 1 ) then
                    print '(a,i4,2a)','Requiring at least ', &
                    nmin(mon),' years with data in ' &
                    ,months(mon)
                else
                    print '(a,i4,4a)','Requiring at least ', &
                    nmin(mon+(lsum-1)*12), &
                    ' years with data in ',months(mon),'-', &
                    months(1+mod(mon+lsum-2,12))
                endif
            endif
            if ( rmin > 0 ) then
                print '(a,f8.2,a)','Requiring at least ',rmin &
                ,' degrees of separation'
            endif
        endif
    endif
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
999 continue
end subroutine getgetargs

subroutine getdata(type,iu,ii,n,nyr)

!   print precip data - convert data file from PSMSL

    implicit none
    character*(*) type
    integer :: iu,ii,n,nyr(0:48)
    integer :: i,yr,mo,slv
    real :: fyr
    character :: format*2,dir*1023,file*1023,line*80
    logical :: lwrite
    parameter (lwrite= .false. )

    if ( lwrite ) print *,'looking for station ',ii
    if ( type == 'slv' ) then
        print '(a)','# ssh [mm] sealevel'
    else
        print *,'unknown type ',type
        call exit(-1)
    endif
    if ( ii < 10 ) then
        format = 'i1'
    else if ( ii < 100 ) then
        format = 'i2'
    else if ( ii < 1000 ) then
        format = 'i3'
    else if ( ii < 10000 ) then
        format = 'i4'
    else
        format = 'i5'
    end if
    call getenv('DIR',dir)
    if ( dir == ' ' ) dir = '.'
    print '(a,'//format//',a)','# station_information :: http://www.psmsl.org/data/obtaining/stations/',ii,'.php'
    print '(a,'//format//',a)','# <a href="http://www.psmsl.org/data/obtaining/stations/',ii,'.php">station information</a>'
    write(file,'(2a,'//format//'a)') trim(dir),'/PSMSLData/rlr_monthly/data/',ii,'.rlrdata'
    open(iu,file=trim(file),status='old',err=901)
    do
        read(iu,'(f11.4,x,i6)',end=800) fyr,slv
        yr = int(fyr)
        mo = nint(12*(fyr-yr)+0.5)
        print '(i4.4,i2.2,i6)',yr,mo,slv-7000
    end do
800 continue
    close(iu)
    return
901 write(0,*) 'getsealev: error: cannot find file ',trim(file)
    call exit(-1)
end subroutine getdata

subroutine toupper(string)
    implicit none
    character string*(*)
    integer :: i
    do i=1,len(string)
        if (  ichar(string(i:i)) >= ichar('a') .and. &
        ichar(string(i:i)) <= ichar('z') ) then
            string(i:i) = char(ichar(string(i:i)) &
            - ichar('a') + ichar('A'))
        endif
    enddo
    if ( string == ' ' ) then
        string = 'UNKNOWN'
    endif
end subroutine toupper

subroutine tolower(string)
    implicit none
    character string*(*)
    integer :: i
    do i=1,len(string)
        if (  ichar(string(i:i)) >= ichar('A') .and. &
        ichar(string(i:i)) <= ichar('Z') ) then
            string(i:i) = char(ichar(string(i:i)) &
            - ichar('A') + ichar('a'))
        endif
    enddo
end subroutine tolower

subroutine sortdist(i,n,dist,rlon,rlat,ind,rmin)
    implicit none
    integer :: i,n,ind(i)
    real :: dist(i),rlat(i),rlon(i),rmin
    integer :: j,k,nok,jj,kk
    real :: dlon,d,pi
    parameter (pi  = 3.1415926535897932384626433832795d0)

!   make and sort index array
    call ffsort(dist,ind,i)
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
                        (dlon*cos((rlat(jj)+rlat(kk))/2/180*pi &
                        ))**2
                        if ( d < rmin**2 ) then
                            dist(kk) = 3e33
                        endif
                    endif
                enddo
            endif
        enddo
    else
        nok = n
    endif
    n = nok
end subroutine sortdist

subroutine readstation(string,istation,ifac)
    implicit none
    character*(*) string
    integer :: istation,ifac
    integer :: i,j
    real :: fstation
    j=1
 10 continue
    if ( string(j:j) == ' ' ) then
        j = j + 1
        goto 10
    endif
    if ( ifac == 1 ) then
        read(string(j:),*) istation
    else
        read(string(j:),*,err=904) fstation
        istation = nint(ifac*fstation)
        i = j + 3
        if ( string(i:i) == '.' ) i = j + 4
        j = ichar(string(i:i))
        if ( i >= ichar('a') .and. j <= ichar('z') ) then
            istation = istation + j - ichar('a')
        elseif ( i >= ichar('A') .and. j <= ichar('Z') ) then
            istation = istation + j - ichar('A')
        endif
    endif
    return
904 print *,'error reading station code'
    call exit(-1)
end subroutine readstation

    subroutine updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax,rlon,rlat &
    )
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
        if ( abs(rlon-rlonmin) < &
        abs(rlon-rlonmin-360) ) then
            rlonmin = min(rlonmin,rlon)
        else
            rlonmin = min(rlonmin,rlon-360)
        endif
        if ( abs(rlon-rlonmax) < &
        abs(rlon-rlonmax+360) ) then
            rlonmax = max(rlonmax,rlon)
        else
            rlonmax = max(rlonmax,rlon+360)
        endif
    endif
    end subroutine updatebox
!  #] updatebox:
!  #[ printbox:
    subroutine printbox(rlonmin,rlonmax,rlatmin,rlatmax)
    implicit none
    real :: rlonmin,rlonmax,rlatmin,rlatmax
    real :: r
    if ( rlonmax-rlonmin > 360 ) then
        rlonmax = rlonmax - 360
    endif
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
!  #] printbox:
