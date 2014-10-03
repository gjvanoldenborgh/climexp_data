        subroutine day2month(dtemp,mtemp,nz,firstyear,lastyear,iwrite)
*
*       average daily measurements in dtemp into monthly ones in mtemp
*       missing values are interpolated linearly if the gap is shorter
*       than maxdays days (default 10).  These interpolated values are 
*       returned in dtemp.
*
        implicit none
        integer nz,firstyear,lastyear,iwrite
        real dtemp(nz,31,12,firstyear:lastyear),
     +        mtemp(nz,12,firstyear:lastyear)
*       
        integer maxdays,i,j,k,yr,mn,dy,leap,dpm(12,2),yrp,mnp,dyp,state
     +        ,last(3),next(3)
        integer julday
        external julday
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31
     +        ,31,29,31,30,31,30,31,31,30,31,30,31/
        data maxdays /10/
*       
*       loop over all data
*
        do k=1,nz
            state = 0           ! missing data, no interpolation
            do yr=firstyear,lastyear
                if ( mod(yr,4).eq.0 ) then
                    leap = 2
                else
                    leap = 1
                endif
                do mn=1,12
*
*                    first interpolate missing days, if the interval is
*                    not too long
*       
                    do dy=1,dpm(mn,leap)
                        if ( dtemp(k,dy,mn,yr).lt.1e33 ) then
*                           valid point - no interpolation
                            state = 1
                            last(1) = dy
                            last(2) = mn
                            last(3) = yr
                        elseif ( state.eq.0 ) then
*                           no data points before this - no interpolation
                            state = 0
                        elseif ( state.eq.1 ) then
*                           invalid point, will have to figure out
*                           whether to interpolate
                            do i=1,maxdays
                                j = julday(mn,dy,yr) + i
                                call caldat(j,mnp,dyp,yrp)
                                if ( dtemp(k,dyp,mnp,yrp).lt.1e33 ) then
                                    next(1) = dyp
                                    next(2) = mnp
                                    next(3) = yrp
                                    state = 2
                                    goto 110
                                endif
                            enddo
                            state = 0
  110                       continue
                        endif
                        if ( state.eq.2 ) then
*                           invalid point, endpoints of interval known
*                           note the mesjogge order of arguments of julday
                            dtemp(k,dy,mn,yr) = (
     +                            (julday(mn,dy,yr)
     +                            - julday(last(2),last(1),last(3)))
     +                            *dtemp(k,next(1),next(2),next(3)) + 
     +                            (julday(next(2),next(1),next(3))
     +                            - julday(mn,dy,yr))
     +                            *dtemp(k,last(1),last(2),last(3))
     +                            )/(julday(next(2),next(1),next(3))
     +                            - julday(last(2),last(1),last(3)))
                            if ( iwrite.ge.3 ) then
                                print *,'day2month: interpolating '
                                print '(a,i2.2,'':'',i2.2,'':'',i4,
     +                                f8.2)','last ',last,
     +                                dtemp(k,last(1),last(2),last(3)),
     +                                ' new ',dy,mn,yr,
     +                                dtemp(k,dy,mn,yr),
     +                                'next ',next,
     +                                dtemp(k,next(1),next(2),next(3))
                            endif
                        endif
                    enddo
*       
*                   next sum the complete months
*
                    mtemp(k,mn,yr) = 0
                    do dy=1,dpm(mn,leap)
                        if ( dtemp(k,dy,mn,yr).lt.1e33 ) then
                            mtemp(k,mn,yr) = mtemp(k,mn,yr) + 
     +                            dtemp(k,dy,mn,yr)
                        else
                            mtemp(k,mn,yr) = 3e33
                        endif
                    enddo
                    if ( mtemp(k,mn,yr).lt.1e33 ) then
                        mtemp(k,mn,yr) = mtemp(k,mn,yr)/dpm(mn,leap)
                    endif
                    if ( iwrite.ge.2 ) then
                        print *,'mtemp(',k,mn,yr,') = ',mtemp(k,mn,yr)
                    endif
                enddo           ! months
            enddo               ! years
        enddo                   ! depths
        end
