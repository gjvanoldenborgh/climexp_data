program gentime

!   generate time definition

    implicit none
    integer :: yr,nyear,i,j
    character :: string*80
    
    call get_command_argument(1,string)
    read(string,*) nyear
    print '(a)',' time = '
    i=0
    do
    if ( nyear-15*i > 15 ) then
           print '(15(i5,a))',(15*i+j,',', j=0,14)
        else
           print '(15(i5,a))',(15*i+j,',', j=0,nyear-15*i-2),nyear-1,';'
           exit
        end if
        i = i+1
    end do
end program gentime