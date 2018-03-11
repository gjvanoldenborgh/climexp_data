program maunaloa2dat

!   convert the NOAA file to my onventions

    implicit none
    integer,parameter :: yrbeg=1953,yrend=2020
    integer :: yr,mo,idatum(8)
    real :: data(12,yrbeg:yrend),val,dum1
    character :: line*80,file1*100,file2*100

    call date_and_time(values=idatum)
    line = '# history :: retrieved and converted'
    write(line(len_trim(line)+2:),'(i4,a,i2.2,a,i2.2)') idatum(1),'-',idatum(2),'-',idatum(3)
    write(line(len_trim(line)+2:),'(i2,a,i2.2,a,i2.2)') idatum(5),':',idatum(6),':',idatum(7)

    call getarg(1,line)
    if ( line == 'mlo' ) then
        open(1,file='co2_mm_mlo.txt',status='old')
        open(2,file='maunaloa.dat',status='new')
        write(2,'(a)') '# monthly CO2 concentrations measured at Mauna Loa'
        write(2,'(a)') '# from Scripps and <a href="http://www.esrl.noaa.gov/gmd/ccgg/trends/">ESRL</a>'
        write(2,'(a)') '# co2 [ppm] Mauna Loa co2 concentration'
        write(2,'(a)') '# institution :: NOAA/ESRL and Scripps Institution of Oceanography, missing data interpolated at KNMI'
        write(2,'(a)') '# contact :: Pieter.Tans@noaa.gov'
        write(2,'(a)') '# references :: C.D. Keeling, R.B. Bacastow, A.E. Bainbridge, '// &
            'C.A. Ekdahl, P.R. Guenther, and L.S. Waterman, (1976), Atmospheric carbon '// &
            'dioxide variations at Mauna Loa Observatory, Hawaii, Tellus, vol. 28, 538-551'
        write(2,'(a)') '# source :: https://www.esrl.noaa.gov/gmd/ccgg/trends/data.html'
        write(2,'(a)') '# source_url :: ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_mlo.txt'
        write(2,'(a)') '# climexp_url :: https://climexp.knmi.nl/getindices.cgi?CDIACData/maunaloa_f'
    print '(a)',trim(line)
    else if ( line == 'gl') then
        open(1,file='co2_mm_gl.txt',status='old')
        open(2,file='co2.dat',status='new')
        write(2,'(a)') '# globally averaged marine surface CO2 concentration'
        write(2,'(a)') '# from <a href="http://www.esrl.noaa.gov/gmd/ccgg/trends/">ESRL</a>'
        write(2,'(a)') '# co2 [ppm] global marine co2 concentration'
        write(2,'(a)') '# institution :: NOAA/ESRL'
        write(2,'(a)') '# contact :: Ed.Dlugokencky@noaa.gov'
        write(2,'(a)') '# references :: A.P. Ballantyne, C.B. Alden, J.B. Miller, P.P. Tans, and '// &
            'J.W.C. White, (2012), Increase in observed net carbon dioxide uptake by land and oceans '// &
            'during the last 50 years, Nature 488, 70-72.'
        write(2,'(a)') '# source :: https://www.esrl.noaa.gov/gmd/ccgg/trends/global.html'
        write(2,'(a)') '# source_url :: ftp://aftp.cmdl.noaa.gov/products/trends/co2/co2_mm_gl.txt'
        write(2,'(a)') '# climexp_url :: https://climexp.knmi.nl/getindices.cgi?CDIACData/co2'
    else
        write(0,*) 'maunaloa2dat: error: specify mlo or gl'
        call exit(-1)
    end if
    data = 3e33
100 continue
    read(1,'(a)',end=200) line
    if ( line(1:1) == '#' ) goto 100
    read(line,*) yr,mo,dum1,val
    if ( yr < yrbeg ) then
        write(0,*) 'maunaloa2dat: error: yr < yrbeg: ',yr,yrbeg
        call exit(-1)
    endif
    if ( yr > yrend ) then
        write(0,*) 'maunaloa2dat: error: yr > yrend: ',yr,yrend
        call exit(-1)
    endif
    if ( mo < 1 .or. mo > 12 ) then
        write(0,*) 'maunaloa2dat: error: invalid month: ',mo
        call exit(-1)
    endif
    if ( val == -99.99 ) then
        val = -999.9
    elseif ( val < 300 .or. val > 500 ) then
        write(0,*) 'maunaloa2dat: error: suspect value: ',val
        call exit(-1)
    endif
    data(mo,yr) = val
    goto 100
200 continue
    call printdatfile(2,data,12,12,yrbeg,yrend)
end program maunaloa2dat
