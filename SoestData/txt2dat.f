        program txt2dat
!
!       convert the SOEST daily monsoon index values to a climexp format
!
        implicit none
        integer i,dy,mo,yr
        real val
        character file*20
!
        print '(a)','# Western North Pacific Monsoon Index from'//
     +       '<a href="http://iprc.soest.hawaii.edu/users/ykaji/'//
     +       'monsoon/realtime-monidx.html">SOEST</a>'
        print '(a)','# WNPMI [1]'
        yr=1947
 100    continue
        yr = yr + 1
        write(file,'(a,i4,a)') 'wnpmidx.',yr,'.day.txt'
        open(1,file=trim(file),status='old',err=900)
        read(1,'(a)')
 200    continue
        read(1,*,end=300) i,val
        call getdymo(dy,mo,i,366)
        write(*,'(i4,2i3,f9.3)') yr,mo,dy,val
        goto 200
 300    continue
        close(1)
        goto 100
 900    continue
        end

        subroutine getdymo(dy,mo,firstmo,nperyear)
        implicit none
        integer dy,mo,firstmo,nperyear
        integer m,i,dpm(12),dpm365(12)
        logical lwrite
        data dpm    /31,29,31,30,31,30,31,31,30,31,30,31/
        data dpm365 /31,28,31,30,31,30,31,31,30,31,30,31/

        lwrite = .false.
        if ( nperyear.le.12 ) then
            dy = 1
            mo = firstmo
            return
        endif
        m = 1+mod(firstmo-1,nperyear)
        if ( m.eq.0 ) m = m + nperyear
        if ( nperyear.eq.36 ) then
            dy = 1
            do i=1,(m-1)/3
                dy = dy + dpm(i)
            enddo
            dy = dy + 5 + 10*mod(m-1,3)
        elseif ( nperyear.le.366 ) then
            dy = nint(0.5 + (m-0.5)*nint(366./nperyear))
        else
            dy = nint(0.5 + (m-0.5)*366./nperyear)
        endif
        mo = 1
 400    continue
        if ( nperyear.eq.365 .or. nperyear.eq.73 ) then
            if ( dy.gt.dpm365(mo) ) then
                dy = dy - dpm365(mo)
                mo = mo + 1
                goto 400
            endif
        elseif ( nperyear.eq.360 ) then
            if ( dy.gt.30 ) then
                dy = dy - 30
                mo = mo + 1
                goto 400
            endif
        else
            if ( dy.gt.dpm(mo) ) then
                dy = dy - dpm(mo)
                mo = mo + 1
                goto 400
            endif
        endif
        if ( lwrite ) then
            print *,'getdymo: input: firstmo,nperyear = ',firstmo
     +           ,nperyear
            print *,'         outpuyt: dy,mo          = ',dy,mo
        end if
        if ( mo.le.0 .or. mo.gt.12 ) then
            write(0,*) 'getdymo: error: impossible month ',mo
            mo = 1
        endif
        end

