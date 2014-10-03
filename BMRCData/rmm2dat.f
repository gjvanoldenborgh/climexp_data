        program rmm2dat
*
*       convert the rmm1rmm2.txt to climexp statndard dat files
*
        implicit none
        integer yr,mo,dy,i
        real rmm1,rmm2
        character line*100
*
        open(1,file='rmm1rmm2.txt',status='old')
        open(2,file='rmm1.dat',status='unknown')
        open(3,file='rmm2.dat',status='unknown')
        write(2,'(2a)') '# MJO index RMM1 from ',
     +       '<a href="http://www.bom.gov.au/bmrc/clfor/'//
     +           'cfstaff/matw/maproom/RMM/index.htm">BMRC</a>'
        read(1,'(a)') line
        do i=2,3
            write(i,'(2a)') '# ',trim(line)
        enddo
        read(1,'(a)') line
 100    continue
        read(1,*,end=800,err=900) yr,mo,dy,rmm1,rmm2
        if ( abs(rmm1).lt.900 ) then
            write(2,'(i5,2i3,f10.5)') yr,mo,dy,rmm1
        endif
        if ( abs(rmm2).lt.900 ) then
            write(3,'(i5,2i3,f10.5)') yr,mo,dy,rmm2
        endif
        goto 100
 800    continue
        goto 999
 900    write(0,*) 'rmm2dat: error reading rmm1rmm2.txt'
        call abort
 999    continue
        close(1)
        close(2)
        close(3)
        end
