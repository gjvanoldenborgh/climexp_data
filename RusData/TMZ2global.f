        program TMZ2global
*
*       compute global anomaies from the NH, 30-60S, 60-90S time series
*
        implicit none
        integer yrbeg,yrend
        parameter(yrbeg=1881,yrend=1998)
        integer yr,mo,nperyear
        real nh(12,yrbeg:yrend),sh(12,yrbeg:yrend),sp(12,yrbeg:yrend)
     +        ,global(12,yrbeg:yrend)
*
        call makeabsent(nh,12,yrbeg,yrend)
        call makeabsent(sh,12,yrbeg,yrend)
        call makeabsent(sp,12,yrbeg,yrend)
        call readdat(nh,12,nperyear,yrbeg,yrend,'TMZ_0_90N.dat')
        call readdat(sh,12,nperyear,yrbeg,yrend,'TMZ_0_60S.dat')
        call readdat(sp,12,nperyear,yrbeg,yrend,'TMZ_60_90S.dat')
        do yr=yrbeg,yrend
            do mo=1,12
                global(mo,yr) = nh(mo,yr)/2 + sh(mo,yr)*sqrt(3.)/4
                if ( sp(mo,yr).lt.1e33 ) then
                    global(mo,yr) = global(mo,yr) + 
     +                    sp(mo,yr)*(1-sqrt(3.)/2)/2
                endif
            enddo
        enddo
        print '(a)','Vinnikov et al estimate of the '
        print '(a)','world surface air temperature anomaly [K]'
        print '(a)','computed as TMZ_0_90N/2 + TMZ_0_60S*sqrt(3)/4 '/
     +        /'1881-1956,'
        print '(a)','TMZ_0_90N/2 + TMZ_0_60S*sqrt(3)/4 + TMZ_60_90S'/
     +        /'*(1-sqrt(3)/2)/2 1957-1998'
        print '(a)'
        call printdatfile(6,global,12,nperyear,yrbeg,yrend)
        end
