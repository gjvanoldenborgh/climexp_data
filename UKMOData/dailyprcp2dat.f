        program dailyprcp2dat
*
*       convert the daily prcp format to standard Climate Explorer format.
*
        implicit none
        integer yr,mo,dy,i,j
        real val(31)
        character file*80,line*1000

        call getarg(1,file)
        i = index(file,'Had') + 3
        j = i + index(file(i:),'_')
        if ( i.eq.3 .or. j.eq.i ) then
            write(0,*) 'unknown file ',trim(file)
            call abort
        endif
        print '(3a)','# prcp [mm/dy] ',file(i:j-2),' precipitation'
        print '(2a)','# <a href="http://hadobs.metoffice.com/',
     +       'hadukp" target="_new">Hadley Centre</a>'
        open(1,file=file,status='old')
 100    continue
        read(1,'(a)',end=800) line
        if ( line(1:1).ne.' ' .and. line(1:1).ne.'1' .and.
     +       line(1:1).ne.'2' ) then
            if ( index(line,'Format').eq.0 ) then
                print '(2a)','# ',trim(line)
            endif
            goto 100
        endif
        if ( line.eq.' ' ) goto 100
        val = -999.9
        read(line,*) yr,mo,val
        do dy=1,31
            if ( val(dy).ge.0 ) then
                print '(i4,2i3,f7.1)',yr,mo,dy,val(dy)
            endif
        enddo
        goto 100
 800    continue
        end

                
