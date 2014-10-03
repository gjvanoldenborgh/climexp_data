        program maunaloa2dat
*
*       convert the NOAA file to my onventions
*
        implicit none
        integer yrbeg,yrend
        parameter (yrbeg=1953,yrend=2020)
        integer yr,mo
        real data(12,yrbeg:yrend),val,dum1
        character line*80,file1*100,file2*100
        
        call getarg(1,line)
        if ( line.eq.'mlo' ) then
            open(1,file='co2_mm_mlo.txt',status='old')
            open(2,file='maunaloa.dat',status='new')
            write(2,'(a)') '# monthly CO2 concentrations measured at '//
     +           'Mauna Loa'
            write(2,'(a)') '# from Scripps and '//
     +           '<a href="http://www.esrl.noaa.gov/gmd/ccgg/trends/">'/
     +           /'ESRL</a>'
        else if ( line.eq.'gl') then
            open(1,file='co2_mm_gl.txt',status='old')
            open(2,file='co2.dat',status='new')
            write(2,'(a)')
     +           '# globally averaged marine surface CO2 concentration'
            write(2,'(a)') '# from '//
     +       '<a href="http://www.esrl.noaa.gov/gmd/ccgg/trends/">'//
     +       'ESRL</a>'
        else
            write(0,*) 'maunaloa2dat: error: specify mlo or gl'
            call abort
        end if
        write(2,'(a)') '# co2 [ppm] co2 concentration'
        data = 3e33
 100    continue
        read(1,'(a)',end=200) line
        if ( line(1:1).eq.'#' ) goto 100
        read(line,*) yr,mo,dum1,val
        if ( yr.lt.yrbeg ) then
            write(0,*) 'maunaloa2dat: error: yr < yrbeg: ',yr,yrbeg
            call abort
        endif
        if ( yr.gt.yrend ) then
            write(0,*) 'maunaloa2dat: error: yr > yrend: ',yr,yrend
            call abort
        endif
        if ( mo.lt.1 .or. mo.gt.12 ) then
            write(0,*) 'maunaloa2dat: error: invalid month: ',mo
            call abort
        endif
        if ( val.eq.-99.99 ) then
            val = -999.9
        elseif ( val.lt.300 .or. val.gt.500 ) then
            write(0,*) 'maunaloa2dat: error: suspect value: ',val
            call abort
        endif
        data(mo,yr) = val
        goto 100
 200    continue
        call printdatfile(2,data,12,12,yrbeg,yrend)
        end
