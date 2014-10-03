        program hoytschatten2dat
*
*       interpolate the yearly Hoyt & Schatten data to monthly .dat file
*
        implicit none
        integer i,yr,mo
        real y,s,y1,s1,val(24)
*
        open(1,file='hoytschatten',status='old')
        do i=1,30
            read(1,'(a)')
        enddo
        print '(a)','Hoyt D.V., Schatten K.H.,'
        print '(2a)','A discussion of plausible solar irradiance ',
     +        'variations 1700-1992'
        print '(a)','1993, J. Geophys. Res. 98, 18895'
        print '(a)'
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
        do mo=7,18
            val(mo) = ((mo-7)*s + (19-mo)*s1)/12
        enddo
        print '(i4,12f8.2)',nint(y1),(val(mo),mo=1,12)
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
