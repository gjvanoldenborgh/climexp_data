program cable2dat

!   convert the Florida current estimates from
!   http://www.aoml.noaa.gov/phod/floridacurrent/data_access.php
!   to a climexp file

    implicit none
    integer :: yrbeg,yrend,idatum(8)
    parameter(yrbeg=1982,yrend=2020)
    integer :: yyyy,yr,mo,dy
    real :: current
    character(80) :: line,file

    print '(a)','# Florida_current [Sv] Florida Current Transport estimates'
    print '(a)','# from calibrated cable voltages'
    print '(a)','# <a href="http://www.aoml.noaa.gov/phod/floridacurrent/data_access.php">NOAA/AOML</a>'
    print '(a)','# institution :: NOAA/AOML'
    print '(a)','# contact :: Christopher.Meinen@noaa.gov'
    print '(a)','# source :: http://www.aoml.noaa.gov/phod/floridacurrent/data_access.php'
    print '(a)','# source_url :: http://www.aoml.noaa.gov/phod/floridacurrent/'
    call date_and_time(values=idatum)
    line = '# history :: retrieved from NOAA/AOML and converted'
    write(line(len_trim(line)+2:),'(i4,a,i2.2,a,i2.2)') idatum(1),'-',idatum(2),'-',idatum(3)
    write(line(len_trim(line)+2:),'(i2,a,i2.2,a,i2.2)') idatum(5),':',idatum(6),':',idatum(7)
    print '(a)',trim(line)
    print '(a)','# climexp_url :: https://climexp.knmi.nl/getindices.cgi?WMO=AOMLData/FC_daily'
    do yr=yrbeg,yrend
        if ( yr < 2000 ) then
            write(file,'(a,i4,a)') 'FC_cable_transport_',yr,'.asc'
        else
            write(file,'(a,i4,a)') 'FC_cable_transport_',yr,'.dat'
        endif
        write(0,'(2a)') 'opening file ',trim(file)
        open(1,file=file,status='old',err=800)
    100 continue
        read(1,'(a)',err=900,end=800) line
        if (line(1:1) == '%' ) goto 100
        if ( index(line,'NaN') /= 0 ) goto 100
        print '(a)',trim(line)
        goto 100
    800 continue
    enddo
    goto 999
900 write(0,*) 'error reading data file ',trim(file)
    call exit(-1)
999 continue
end program cable2dat