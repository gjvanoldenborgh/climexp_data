        program sunspots2double
*
*       convert the SIDC sunspot data two positive/negative numbers
*
        implicit none
        include 'param.inc'
        integer nmo
        parameter (nmo=12*(yrend-yrbeg+1))
        integer mo,imin1,imin2,nperyear
        real data(nmo),xmin
        logical lwrite
        lwrite = .false.

        call makeabsent(data,12,yrbeg,yrend)
        call readdat(data,12,nperyear,yrbeg,yrend,'sunspots.dat')
        mo = 1 + (1754-yrbeg)*12
        if ( data(mo).ne.0 ) then
            write(0,*) 'error: cannot find first zero in 1754',mo
     +           ,data(mo)
            call abort
        endif
        imin1 = mo
 100    continue
        xmin = 3e33
        do mo=min(imin1+11*12-48,nmo),min(imin1+11*12+48,nmo)
            if ( data(mo).lt.xmin ) then
                xmin = data(mo)
                imin2 = mo
            endif
        enddo
        if ( lwrite ) print *,'imin2 = ',imin2
        if ( xmin.eq.3e33 .or. imin2.eq.nmo ) goto 800
        do mo=imin1,imin2-1
            data(mo) = -data(mo)
        enddo
        xmin = 3e33
        do mo=min(imin2+11*12-48,nmo),min(imin2+11*12+48,nmo)
            if ( data(mo).lt.xmin ) then
                xmin = data(mo)
                imin1 = mo
            endif
        enddo
        if ( lwrite ) print *,'imin1 = ',imin1
        if ( xmin.eq.3e33 .or. imin1.eq.nmo ) goto 800
        goto 100
 800    continue
        print '(a)','# sunspot2 [1] monthly mean sunspot number'//
     +       ' with alternating signs '
        print '(a)','# from <a href="http://sidc.oma.be/">SIDC</a>'
        do mo=1,4
            print '(a)','#'
        enddo
        call printdatfile(6,data,12,nperyear,yrbeg,yrend)
        end

        
        
