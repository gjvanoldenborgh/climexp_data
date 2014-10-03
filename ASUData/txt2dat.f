        program txt2dat
*
*       convert Randy Cerveny's astro-list into climate dat
*
        implicit none
        integer i,j,yr,mo
        real x,val(12)
*
        i = -1
  100   continue
        read(*,*,end=800) yr,mo,x
        if ( yr.ne.i ) then
            if ( i.ne.-1 ) then
                print '(i4,12f10.6)',i,val
            endif
            do j=1,12
                val(j) = -999.9
            enddo
            i = yr
        endif
        if ( mo.lt.1 .or. mo.gt.12 ) then
            write(0,*) 'error: month = ',mo
            call abort
        endif
        val(mo) = x
        goto 100
  800   continue
        end
