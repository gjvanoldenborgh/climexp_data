program tenday2month
!
!   convert the JPL 10-daily altimetry time series into monthly means.
!
    implicit none
    integer :: i,j,n,dy,mo,yr,dy0,mo0,yr0,dy1,mo1,yr1,iarray(8),yrbeg,yrend
    real*8 :: yrfrac
    real :: val
    real,allocatable :: data(:,:),mdata(:,:)
    logical,allocatable :: lvalid(:,:)
    character file*256,region*40,string*256
    integer,external :: leap
    logical :: lwrite
            
    lwrite = .false. 
    call date_and_time(values=iarray)
    yrbeg = 2002
    yrend = iarray(1)
    allocate(data(366,yrbeg:yrend))
    allocate(lvalid(366,yrbeg:yrend))
    allocate(mdata(12,yrbeg:yrend))
    data = 3e33

    call getarg(1,file)
    if ( file == ' ' ) then
        write(0,*) 'usage: tenday2month infile > outfile'
        call exit(-1)
    end if
    open(1,file=trim(file),status='old')
    do
        read(1,'(a)') string
        if ( index(string,'Header_End') /= 0 ) goto 10 
    end do
 10 continue

!   print header

    i = index(file,'_') - 1
    region = file(1:i)
    write(6,'(5a)') '# mass of ',trim(region), &
        ' from <a href="https://climate.nasa.gov/vital-signs/ice-sheets/"', &
        ' target="_new">NASA/JPL</a> measured by GRACE'
    write(6,'(a)') '# institution :: NASA/JPL'
    write(6,'(a,i4,a,i2.2,a,i2.2,a)') '# references :: Wiese, D. N., D.-N. Yuan, C. Boening, F. W. Landerer,'// &
    ' and M. M. Watkins (2016) JPL GRACE Mascon Ocean, Ice, and Hydrology Equivalent'// &
    'HDR Water Height RL05M.1 CRI Filtered Version 2., Ver. 2., PO.DAAC, CA, USA. Dataset '// &
    'accessed [',iarray(1),'-',iarray(2),'-',iarray(3),'] at http://dx.doi.org/10.5067/TEMSC-2LCR5'
    write(6,'(3a)') '# source :: ftp://podaac-ftp.jpl.nasa.gov/allData/tellus/L3/mascon/RL05/JPL/'// &
        'CRI/mass_variability_time_series/'//trim(file)
    write(6,'(a,i4,a,i2.2,a,i2.2)') '# history :: downloaded and converted to climexp conventions on ', &
        iarray(1),'-',iarray(2),'-',iarray(3)
    write(6,'(a)') '# mass [Gt] mass of '//trim(region)

!   read data

100 continue
    read(1,*,end=200) yrfrac,val
    yr = int(yrfrac)
    yrfrac = yrfrac - yr
    if ( leap(yr) == 1 ) then
        i = int(yrfrac*365)
        if ( i == 0 ) i = 1
        if ( i >= 60 ) i = i + 1
        data(i,yr) = val
    else
        i = int(yrfrac*366)
        if ( i == 0 ) i = 1
        data(i,yr) = val
    endif
    goto 100
200 continue

!   interpolate

    dy0 = -1
    do yr=yrbeg,yrend
        do dy=1,366
            if ( data(dy,yr) < 1e30 ) then
                if ( lwrite ) print *,'found valid data ',dy,yr
                if ( dy0 > 0 ) then
                    n = 366*(yr-yr0) + (dy-dy0)
                    do i=1,n-1
                        dy1 = dy0 + i
                        call normon(dy1,yr0,yr1,366)
                        if ( data(dy1,yr1) < 1e30 ) then
                            write(0,*)'error:',dy1,yr1,data(dy1,yr1)
                            call exit(-1)
                        end if
                        data(dy1,yr1) = (i*data(dy,yr) + (n-i)*data(dy0,yr0))/n
                    end do
                end if
                dy0 = dy
                yr0 = yr
            end if
        end do
    end do

!   average to monhly

    lvalid = .true. 
    call allday2period(data,366,366,lvalid,mdata,12,12,yrbeg,yrend, &
        'mea',' ',-1000.,0.8,0,'ssh','mm',lwrite)

!   write out

    call printdatfile(6,mdata,12,12,yrbeg,yrend)

!   that's it folks

end program tenday2month
