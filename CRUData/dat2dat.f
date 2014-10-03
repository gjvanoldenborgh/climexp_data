        program dat2dat
*       convert Jones' temperature data files to my format
        implicit none
        integer m,yr
        real t(13)
        character area*20,version*2,dataset*7
        call getarg(1,area)
        call getarg(2,version)
        call getarg(3,dataset)
        if ( area.eq.'sh' ) then
            area = 'southern hemsiphere'
        elseif ( area.eq.'nh' ) then
            area = 'northern hemsiphere'
        elseif ( area.eq.'gl' ) then
            area = 'global average'
        else
            write(0,*) 'ERROR',area
            call abort
        endif
        if ( dataset.eq.' ' ) dataset='HadCRUT'
                
        print '(a)','# '//trim(dataset)//trim(version)//
     +          ' '//trim(area)//
     +          ' averaged temperature anomaly wrt 1961-1990'
        print '(a)','# <a href="http://www.cru.uea.ac.uk/'//
     +          'cru/data/temperature/" target="_new">CRU</a>'
        print '(a)','# Ta [Celsius]'
100     continue
        read(*,'(i5,12f7.3,f7.3)',end=800,err=900) yr,t
        do m=1,13
           if ( yr.gt.2004 .and. t(m).eq.0 ) then
              write(0,*) 'replaced ',yr,m,' with undef'
              t(m) = -999.9
           endif
        enddo
        write(*,'(i5,13f9.3)') yr,t
        read(*,'(i5)') yr
        goto 100
800     continue
        stop
900     print *,'error reading data'
        end
