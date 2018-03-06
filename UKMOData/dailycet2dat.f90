program dailycet2dat

!   convert the weird daily CET format to standard Climate Explorer format.

    implicit none
    integer :: yr,mo,dy,val(12),i,j,idatum(8)
    real :: data(31,12)
    character :: file*80,line*120

    call getarg(1,file)
    if ( file == 'cetdl1772on.dat' ) then
        print '(a)','# CET [Celsius] Central England Temperature'
    elseif ( file == 'cetmindly1878on_urbadj4.dat' ) then
        print '(a)','# CETmin [Celsius] Central England minimum temperature'
    elseif ( file == 'cetmaxdly1878on_urbadj4.dat' ) then
        print '(a)','# CETmax [Celsius] Central England maximum temperature'
    else
        write(0,*) 'unknown file ',trim(file)
        call abort
    endif
    print '(2a)','# <a href="http://hadobs.metoffice.com/hadcet" target="_new">Hadley Centre</a>'
    print '(a)','# institution :: UK Met Office / Hadley Centre'
    print '(a)','# source_url :: http://hadobs.metoffice.gov.uk/hadcet/data/download.html'
    print '(a)','# source :: https://www.metoffice.gov.uk/hadobs/hadcet/'
    print '(a)','# references :: Parker, D.E., T.P. Legg, and C.K. Folland. 1992. A new daily Central '// &
        'England Temperature Series, 1772-1991. Int. J. Clim., Vol 12, pp 317-342'
    call date_and_time(values=idatum)
    line = '# history :: retrieved and converted'
    write(line(len_trim(line)+2:),'(i4,a,i2.2,a,i2.2)') idatum(1),'-',idatum(2),'-',idatum(3)
    write(line(len_trim(line)+2:),'(i2,a,i2.2,a,i2.2)') idatum(5),':',idatum(6),':',idatum(7)
    print '(a)',trim(line)
    open(1,file=file,status='old')
100 continue
    read(1,*,end=800) yr,dy,val
    do mo=1,12
        if ( val(mo) /= -999 ) then
            data(dy,mo) = val(mo)/10.
        else
            data(dy,mo) = -999.9
        endif
    enddo
    if ( dy == 31 ) then
        do mo=1,12
            do dy=1,31
                if ( data(dy,mo) /= -999.9 ) then
                    print '(i4.4,2i2.2,f7.1)',yr,mo,dy,data(dy,mo)
                endif
            enddo
        enddo
    endif
    goto 100
800 continue
end program dailycet2dat
                    
