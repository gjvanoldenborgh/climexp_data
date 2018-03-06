program dailyprcp2dat

!       convert the daily prcp format to standard Climate Explorer format.

    implicit none
    integer :: yr,mo,dy,i,j,idatum(8)
    real :: val(31)
    character file*80,line*1000

    call getarg(1,file)
    i = index(file,'Had') + 3
    j = i + index(file(i:),'_')
    if ( i == 3 .or. j == i ) then
        write(0,*) 'unknown file ',trim(file)
        call abort
    endif
    print '(3a)','# prcp [mm/dy] ',file(i:j-2),' precipitation'
    print '(2a)','# <a href="https://www.metoffice.gov.uk/hadobs/hadukp/" target="_new">Hadley Centre</a>'
    print '(a)','# institution :: UK Met Office / Hadley Centre'
    print '(a)','# source :: https://www.metoffice.gov.uk/hadobs/hadukp/'
    print '(a)','# references :: Alexander, L.V. and Jones, P.D. (2001) Updated precipitation series '// &
    'for the U.K. and discussion of recent extremes. Atmospheric Science Letters doi:10.1006/asle.2001.0025.'
    call date_and_time(values=idatum)
    line = '# history :: retrieved and converted'
    write(line(len_trim(line)+2:),'(i4,a,i2.2,a,i2.2)') idatum(1),'-',idatum(2),'-',idatum(3)
    write(line(len_trim(line)+2:),'(i2,a,i2.2,a,i2.2)') idatum(5),':',idatum(6),':',idatum(7)
    print '(a)',trim(line)
    open(1,file=file,status='old')
100 continue
    read(1,'(a)',end=800) line
    if ( line(1:1) /= ' ' .and. line(1:1) /= '1' .and. &
    line(1:1) /= '2' ) then
        if ( index(line,'Format') == 0 ) then
            print '(2a)','# ',trim(line)
        endif
        goto 100
    endif
    if ( line == ' ' ) goto 100
    val = -999.9
    read(line,*) yr,mo,val
    do dy=1,31
        if ( val(dy) >= 0 ) then
            print '(i4.4,2i2.2,f7.1)',yr,mo,dy,val(dy)
        endif
    enddo
    goto 100
800 continue
end program dailyprcp2dat
                    
