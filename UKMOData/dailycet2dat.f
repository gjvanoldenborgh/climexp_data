        program dailycet2dat
*
*       convert the weird daily CET format to standard Climate Explorer format.
*
        implicit none
        integer yr,mo,dy,val(12),i,j
        real data(31,12)
        character file*80,line*120

        call getarg(1,file)
        if ( file.eq.'cetdl1772on.dat' ) then
            print '(a)','# CET [C] Central England Temperature'
        elseif ( file.eq.'cetmindly1878on_urbadj4.dat' ) then
            print '(a)'
     +           ,'# CETmin [C] Central England minimum temperature'
        elseif ( file.eq.'cetmaxdly1878on_urbadj4.dat' ) then
            print '(a)'
     +           ,'# CETmax [C] Central England maximum temperature'
        else
            write(0,*) 'unknown file ',trim(file)
            call abort
        endif
        print '(2a)','# <a href="http://hadobs.metoffice.com/',
     +       'hadcet" target="_new">Hadley Centre</a>'
        open(1,file=file,status='old')
 100    continue
        read(1,*,end=800) yr,dy,val
        do mo=1,12
            if ( val(mo).ne.-999 ) then
                data(dy,mo) = val(mo)/10.
            else
                data(dy,mo) = -999.9
            endif
        enddo
        if ( dy.eq.31 ) then
            do mo=1,12
                do dy=1,31
                    if ( data(dy,mo).ne.-999.9 ) then
                        print '(i4,2i3,f7.1)',yr,mo,dy,data(dy,mo)
                    endif
                enddo
            enddo
        endif
        goto 100
 800    continue
        end

                
