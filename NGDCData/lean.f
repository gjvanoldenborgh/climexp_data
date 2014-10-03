        program lean2dat
*
*       interpolate the yearly Lean data to monthly .dat file
*
        implicit none
        integer i,yr,mo
        real y,s,y1,s1,val(24)
*
        open(1,file='lean1995data.txt',status='old')
        do i=1,6
            read(1,'(a)')
        enddo
        print '(a)','Lean, J., J. Beer, and R. Bradley, 1995,'
        print '(2a)','Reconstruction of Solar Irradiance ',
     +        'Since 1610: Implications for Climate Change'
        print '(a)','Geophysical Research Letters, '
        print '(a)''v.22, No. 23, pp 3195-3198, December 1, 1995'
        print '(a)','Interpolated to monthly values by GJvO, KNMI'
*
        do mo=1,24
            val(mo) = -999.9
        enddo
        read(1,*,err=900,end=800) y1,s1
  100   continue
        read(1,*,err=900,end=800) y,s
        if ( abs(y-y1-1).gt.0.001 ) then
            write(0,*) 'error: non-consecutive years: ',y1,y
            stop
        endif
        if ( s.gt.0 .and. s1.gt.0 ) then
            do mo=7,18
                val(mo) = ((mo-7)*s + (19-mo)*s1)/12
            enddo
        else
            do mo=7,18
                val(mo) = -999.9
            enddo
        endif
        do i=1,12
            if ( val(i).gt.0 ) then
                print '(i4,12f8.2)',nint(y1),(val(mo),mo=1,12)
                goto 200
            endif
        enddo
  200   continue
        do mo=1,12
            val(mo) = val(mo+12)
        enddo
        y1 = y
        s1 = s
        goto 100
  800   continue
        print '(i4,12f8.2)',nint(y),(val(mo),mo=13,24)
        stop
  900   print *,'error reading input',y,s,y1,s1
        end
