        program cet2dat
*
*       convert the Hadley Centre files into Climate Explorer format
*
        implicit none
        integer yr,mo
        real val(13)
        character line*120,file*80

        call getarg(1,file)
        open(1,file=file,status='old')
        if ( file.eq.'cetml1659on.dat' ) then
            print '(a)','# CET [C]'
        elseif ( file.eq.'cetminmly1878on_urbadj4.dat' ) then
            print '(2a)','# CETmin [C] monthly mean minimum ',
     +           'Central England Temperature'
            print '(2a)','# <a href="http://hadobs.metoffice.com/',
     +           'hadcet" target="_new">Hadley Centre</a>'
        elseif ( file.eq.'cetmaxmly1878on_urbadj4.dat' ) then
            print '(2a)','# CETmax [C] monthly mean maximum ',
     +           'Central England Temperature'
            print '(2a)','# <a href="http://hadobs.metoffice.com/',
     +           'hadcet" target="_new">Hadley Centre</a>'
        else
            write(0,*) 'error: unknown file ',trim(file)
            call abort
        endif
 100    continue
        read(1,'(a)',end=800) line
        if ( line.eq.' ' ) goto 100
        if ( index(line,' JAN ').ne.0 ) then
            print '(2a)','# <a href="http://hadobs.metoffice.com/',
     +           'hadcet" target="_new">Hadley Centre</a>'
            goto 100
        endif
        if ( line(1:1).ne.' ' ) then
            print '(2a)','# ',trim(line)
            goto 100
        endif
        read(line,*) yr,val
        do mo=1,13
            if ( val(mo).eq.-99.9 ) val(mo) = -999.9
        enddo
        print '(i4,13f7.1)',yr,val
        goto 100
 800    continue
        close(1)
        end

