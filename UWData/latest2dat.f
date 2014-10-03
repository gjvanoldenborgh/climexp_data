        program lastest2dat
!       convert the file PDO.latsest to my format .dat file
        implicit none
        integer i,j,yr
        real val(12)
        character line*255

        open(1,file='PDO.latest')
        open(2,file='pdo.dat')
        write(2,'(a)') '# PDO index of Nate Mantua, '//
     +       '<a href="http://jisao.washington.edu/pdo/" '//
     +       'target="_new">JISAO</a>, U.Washington'
        write(2,'(a)') '# based on HadSST 1900-1980, OI SST v1 '//
     +       '1982-2001, OI SST v2 2002-now.'
        write(2,'(a)') '# PDO [1]'
 100    continue
        read(1,'(a)',end=800) line
        if ( line(1:2).ne.'19' .and. line(1:2).ne.'20' ) goto 100
        do i=1,3
            j = index(line,'*')
            if ( j.ne.0 ) line(j:j) = ' '
        end do
        i = 13
 200    continue
        i = i - 1
        read(line,*,end=200,err=200) yr,(val(j),j=1,i)
        do j=i+1,12
            val(j) = -999.9
        end do
        write(2,'(i4,12f8.2)') yr,val
        goto 100
 800    continue
        close(2)
        close(1)
        end
