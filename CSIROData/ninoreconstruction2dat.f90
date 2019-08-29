program ninoreconstruction2dat
!
!   convert the file 
!   yr 3 val
!   yr 6 val
!   yr 9 val
!   yr 12 val
!   ...
!   to my convention for seasonal data
!
    implicit none
    integer :: col,yr,mo,oldyr
    real :: val3,val4,vals(4)
    character :: line*500,file*1023
    
    call get_command_argument(1,file)
    call get_command_argument(2,line)
    if ( line == ' ' ) then
        write(0,*) 'usage: ninoreconstruction2dat infile'
        call exit(-1)
    end if
    read(line,*) col
    open(1,file=trim(file),status='old')
    vals = -999.9
    oldyr = -1
    do
        read(1,'(a)',end=800) line
        if ( line(1:1) == '#' .or. line(2:2) == '#' .or. line(1:4) == 'Year' .or. line(1:2) == 'El' ) cycle
        read(line,*) yr,mo,val3,val4
        if ( mo == 12 ) then
            yr = yr + 1
            mo = 0
        end if
        if ( yr /= oldyr .and. oldyr /= -1 ) then
            print '(i4,4f9.3)',oldyr,vals
            vals = -999.9
        endif
        oldyr = yr
        mo = 1 + mo/3
        if ( col == 3 ) then
            vals(mo) = val3
        else if ( col == 4 ) then
            vals(mo) = val4
        else
            write(0,*) 'ninoreconstruction2dat: error: unknown value for col ',col
            call exit(-1)
        end if
    end do
800 continue
    if ( vals(1) /= -999.9 ) then
        print '(i4,4f9.3)',oldyr,vals
    end if
    close(1)
end program ninoreconstruction2dat
