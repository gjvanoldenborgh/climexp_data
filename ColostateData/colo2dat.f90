program colo2dat

!       convert the gnuplot-like AO index files from
!       http://www.atmos.colostate.edu/ao/Data/ao_index.html
!       to my .dat format

    implicit none
    integer :: year,month,yrbeg,yrend
    parameter(yrbeg=1700,yrend=2020)
    real :: ao(12,yrbeg:yrend),yrmo

    open(1,file='AO_TREN_NCEP_Jan1899Current.ascii.fixed',status='old')
    call makeabsent(ao,12,yrbeg,yrend)
    do year=1899,yrend
        do month=1,12
            read(1,*,end=200,err=200) ao(month,year)
        enddo
    enddo
    print *,'Increase yrend!'
    call abort
200 continue
    if ( year < 2000 ) then
        write(0,*) 'something went wrong, only read up to ',year,month
        call exit(-1)
    end if
    close(1)
    open(1,file='ao_slp.dat')
    write(1,'(a)') '# <a href="http://www.atmos.colostate.edu/ao/Data/ao_index.html">'// &
        'Arctic Oscillation</a> index based on SLP'
    write(1,'(a)') '# Index values 1899-Dec1957 are based on data described in Trenberth and Paolino (1980).'
    write(1,'(a)') '# Index values Jan1958 to current are from the NCEP/NCAR Reanalysis'
    write(1,'(a)') '# source :: http://www.atmos.colostate.edu/ao/Data/AO_TREN_NCEP_Jan1899Current.ascii'
    write(1,'(a)') '# contact :: Hyun-kyung.Kim@noaa.gov'
    write(1,'(a)') '# reference :: Thompson and Wallace, J.Clim, 2000, '// &
        'https://doi.org/10.1175/1520-0442(2000)013%3C1000:AMITEC%3E2.0.CO;2'
    write(1,'(a)') '# AO [1] Arctic Oscillation index based on SLP'
    call printdatfile(1,ao,12,12,yrbeg,yrend)
    close(1)

end program colo2dat
