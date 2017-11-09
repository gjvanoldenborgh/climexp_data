program tenday2month
!
!   convert the Colorado U 10-daily altimetry time series into monthly means.
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
    yrbeg = 1993
    yrend = iarray(1)
    allocate(data(366,yrbeg:yrend))
    allocate(lvalid(366,yrbeg:yrend))
    allocate(mdata(12,yrbeg:yrend))
    data = 3e33

    call getarg(1,file)
    if ( file == ' ' ) then
        write(0,*) 'usage: tenday2month infile > outfile'
        call abort
    end if
    open(1,file=file,status='old')
    read(1,'(a)') string

!   print header

    i = index(file,'ED_') + 3
    j = index(file,'_AVISO') - 1
    region = file(i:j)
    if ( region == 'Global' ) region = 'whole world'
    do i=1,len(region)
        if ( region(i:i) == '_' ) region(i:i) = ' '
    end do
    write(6,'(5a)') '# sea level height averaged over the ',trim(region), &
    ' from <a href="https://www.aviso.altimetry.fr/en/data/products/', &
    'ocean-indicators-products/mean-sea-level/products-images.html"', &
    ' target="_new">AVISO</a>'
    write(6,'(a)') '# SSH [mm] Sea-level height'

!       read data

100 continue
    read(1,*,end=200) yrfrac,val
    yr = int(yrfrac)
    yrfrac = yrfrac - yr
    if ( leap(yr) == 1 ) then
        i = int(yrfrac*365)
        if ( i == 0 ) i = 1
        if ( i >= 60 ) i = i + 1
        data(i,yr) = 1000*val
    else
        i = int(yrfrac*366)
        if ( i == 0 ) i = 1
        data(i,yr) = 1000*val
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
                            call abort
                        end if
                        data(dy1,yr1) = &
                        (i*data(dy,yr) + (n-i)*data(dy0,yr0))/n
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
