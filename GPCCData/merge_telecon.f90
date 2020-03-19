program merge_telecon
!
!   for some reason patternfield does not accept multiple months, so merge all
!
    implicit none
    integer,parameter :: yrbeg=1880,yrend=2030
    integer :: mo,yr
    real :: vals(12),data(12,yrbeg:yrend)
    logical :: lvalid(yrbeg:yrend)
    character :: line*50000,file*1023

    if ( command_argument_count().ne.12 ) then
        write(0,*) 'usage: merge_telecon file_jan file_feb ... file_dec'
        call exit(-1)
    end if
    data = 3e33
    lvalid = .false.
    do mo=1,12
        call get_command_argument(mo,file)
        open(1,file=trim(file),status='old')
        print '(2a)','# merging ',trim(file)
        do
            read(1,'(a)',end=800,err=800) line
            if ( line(1:1) == '#' .or. line(2:2) == '#' ) then
                if ( mo == 1 ) then
                    print '(a)',trim(line)
                endif
                cycle
            end if
            read(line,*,end=800,err=800) yr,vals
            if ( yr < yrbeg .or. yr > yrend ) then
                write(0,*) 'merge_telecon: errior: invalid yr ',yr
                call exit(-1)
            end if
            data(mo,yr) = vals(mo)
            if ( data(mo,yr) < 1e33 ) lvalid(yr) = .true.
            !!!print *,'@@@ data(',mo,yr,') = ',data(mo,yr)
        end do
800     continue
        close(1)
    end do
    do yr=yrbeg,yrend
        if ( lvalid(yr) ) then
            print '(i4,12f10.3)',yr,(data(mo,yr),mo=1,12)
        end if
    end do
end program