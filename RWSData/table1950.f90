program table1950
!
!   convert the csv file with years in column and dates in rows to my format
!
    implicit none
    integer,parameter :: yrbeg=1950,yrend=2016
    integer :: dy,mo,yr,i,j,dpm(12)
    real :: data(31,12,yrbeg:yrend)
    character :: file*1023,string*1023
    data dpm /31,29,31,30,31,30,31,31,30,31,30,31/
    
    call get_command_argument(1,file)
    if ( file == ' ' ) then
        write(0,*) 'usage: table1950 infile.csv'
        call exit(-1)
    end if
    open(1,file=trim(file),status='old')
    string = ' '
    do while ( string(1:6) /= ';;1950' )
        read(1,'(a)') string
    end do
    mo = 1
    dy = 1
    data = 3e33
    do
        read(1,'(a)',end=800) string
        do j=1,len(string)-1
            if ( string(j:j) == ',' ) string(j:j) = '.'
            if ( string(j:j+1) == ';;' ) then
                string(j+7:) = string(j+1:)
                string(j+1:j+6) = '-999.9'
            end if
            if ( string(j:j) == ';' ) string(j:j) = ' '
        end do
        !!!write(0,*) 'reading data from ',trim(string)
        if ( dy == 1 ) then
            read(string,*) i,j,(data(dy,mo,yr),yr=yrbeg,yrend)
        else
            read(string,*) j,(data(dy,mo,yr),yr=yrbeg,yrend)          
        end if
        if ( i /= mo ) then
            write(0,*) 'error: mo /= i: ',mo,i
            call exit(-1)
        end if
        if ( j /= dy ) then
            write(0,*) 'error: dy /= j: ',dy,j
            call exit(-1)
        end if
        dy = dy + 1
        if ( dy > dpm(mo) ) then
            dy = 1
            mo = mo + 1
        end if
    end do

800 continue
    do yr=yrbeg,yrend
        do mo=1,12
            do dy = 1,dpm(mo)                
                print '(i4,2i3,f10.2)',yr,mo,dy,data(dy,mo,yr)
            end do
         end do
    end do
end program table1950
