program cet2dat

!   convert the Hadley Centre files into Climate Explorer format

    implicit none
    integer :: yr,mo,idatum(8)
    real :: val(13)
    character :: line*120,file*80

    call getarg(1,file)
    open(1,file=file,status='old')
    if ( file == 'cetml1659on.dat' ) then
        print '(a)','# CET [Celsius] monthly mean Central England Temperature'
    else if ( file == 'cetminmly1878on_urbadj4.dat' ) then
        print '(2a)','# CETmin [Celsius] monthly mean minimum Central England Temperature'
    else if ( file == 'cetmaxmly1878on_urbadj4.dat' ) then
        print '(2a)','# CETmax [Celsius] monthly mean maximum Central England Temperature'
    else
        write(0,*) 'error: unknown file ',trim(file)
        call abort
    endif
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

100 continue
    read(1,'(a)',end=800) line
    if ( line == ' ' .or. index(line,'DEGREES C') /= 0 ) goto 100
    if ( index(line,' JAN ') /= 0 ) then
        print '(a)','# from the <a href="http://hadobs.metoffice.gov.uk/hadcet/">UK Met Office Hadley Centre</a>'
        goto 100
    endif
    if ( line(1:1) /= ' ' ) then
        print '(2a)','# ',trim(line)
        goto 100
    endif
    read(line,*) yr,val
    do mo=1,13
        if ( val(mo) == -99.9 ) val(mo) = -999.9
    enddo
    print '(i4,13f7.1)',yr,val
    goto 100
800 continue
    close(1)
end program cet2dat
