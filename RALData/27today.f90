program convert27today
!
!   convert the 27-day values to very approximate daily values to be averaged into monthly values in the next step
!
    implicit none
    integer,parameter :: yrbeg=1600,yrend=2050
    integer ::dy,yr,k,j,ii
    real :: yrfrac,val,data(366,yrbeg:yrend),data1(366,yrbeg:yrend)
    character :: file*1023,string*80

    call get_command_argument(1,file)
    if ( file == ' ' ) then
        write(0,*) 'usage: 27today file'
        call exit(-1)
    end if
    open(1,file=trim(file),status='old')
    data = 3e33
    do
        read(1,'(a)',end=800) string
        if ( string == ' ' ) cycle
        if ( string(1:1) == '%' ) cycle
        if ( index(string,'NaN') /= 0 ) cycle
        read(string,*) yrfrac,val
        yr = int(yrfrac)
        dy = int(1 + 366*(yrfrac-yr))
        !!!write(0,*) 'data(',dy,yr,') = ',val
        data(dy,yr) = val
    end do
800 continue
    close(1)
    data1 = 3e33
    do yr=yrbeg,yrend
        do dy=1,366
            if ( data(dy,yr) < 1e33 ) then
                do k=-13,13
                    j = dy + k
                    call normon(j,yr,ii,366)
                    if ( ii < yrbeg .or. ii > yrend ) cycle
                    if ( k /= 0 .and. data(j,ii) /= 3e33 ) then
                        write(0,*) 'error: expecting NaN at ',yr,dy,k,j,ii,data(j,ii)
                    end if
                    data1(j,ii) = data(dy,yr)
                end do
            end if
        end do
    end do
    call printdatfile(6,data1,366,366,yrbeg,yrend)
end program convert27today

