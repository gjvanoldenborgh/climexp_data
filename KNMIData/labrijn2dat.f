        program labrijn2dat
*
*       put the labrijn series into my format
*
        implicit none
        integer yr,mo,i,j,retval
        real val(12)
        character line*255
        integer system
*
        open(1,file='LABRIJN.txt',status='old')
 100    continue
        read(1,'(a)') line
        if ( line(1:4).ne.'1706' ) goto 100
        print '(a)','# the "Labrijn series" 1706-2000 by '//
     +       'A.F.V. van Engelen and J.W. Nellestijn'
        print '(a)','# Monthly means of the airtemperature '//
     +       'in De Bilt, Netherlands.'
        print '(a)','# Component observational series: '//
     +       'Delft/Rijnsburg (1706-1734), Zwanenburg '//
     +       '(1735-1800 & 1811-1848), Haarlem (1801-1810) '//
     +       'and Utrecht (1849-1897) reduced to De Bilt '//
     +       'and De Bilt (1898-present)'
        print '(a)','# (c) Copyright KNMI De Bilt, Netherlands, 1995.'
        print '(a)','# tair [Celsius]'
 200    continue
        read(line,*) yr,val
        if ( yr.eq.2001 ) goto 800
        print '(i4,12f7.1)',yr,val/10
 210    continue
        read(1,'(a)') line
        if ( line.eq.' ' .or. line(1:5).eq.',,,,,' ) goto 210
        do i=1,len(line)
            if ( line(i:i).eq.'"' .or. line(i:i).eq.'''' )
     +           line(i:i) = ' '
        enddo
        goto 200
 800    continue
        close(1)
        retval = system('/usr/people/oldenbor/climexp/bin/'//
     +       'daily2longer tg260.dat 12 mean > /tmp/aap.dat')
        open(1,file='/tmp/aap.dat')
 810    continue
        read(1,'(a)') line
        if ( line(1:5).ne.' 2000' ) goto 810
 820    continue
        read(1,'(a)',end=999) line
        write(*,'(a)') trim(line)
        goto 820
 999    continue
        end

