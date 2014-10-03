        subroutine day2month1(dtemp,mtemp,nz,firstyear,lastyear,iwrite)
*
*       average daily measurements in dtemp into monthly ones in mtemp,
*       just skipping missing values, and average if at least mindays days
*
        implicit none
        integer nz,firstyear,lastyear,iwrite
        real dtemp(nz,31,12,firstyear:lastyear),
     +        mtemp(nz,12,firstyear:lastyear)
*       
        integer mindays,i,k,n,yr,mn,dy,leap,dpm(12,2)
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31
     +        ,31,29,31,30,31,30,31,31,30,31,30,31/
        data mindays /20/
*       
*       loop over all data
*
        do k=1,nz
            do yr=firstyear,lastyear
                if ( mod(yr,4).eq.0 ) then
                    leap = 2
                else
                    leap = 1
                endif
                do mn=1,12
                    n = 0
                    mtemp(k,mn,yr) = 0
                    do dy=1,dpm(mn,leap)
                        if ( dtemp(k,dy,mn,yr).lt.1e33 ) then
*                           valid point
                            n = n + 1
                            mtemp(k,mn,yr) = mtemp(k,mn,yr) + 
     +                            dtemp(k,dy,mn,yr)
                        endif
                    enddo
                    if ( n.ge.mindays ) then
                        mtemp(k,mn,yr) = mtemp(k,mn,yr)/n
                    else
                        mtemp(k,mn,yr) = 3e33
                    endif
                    if ( iwrite.ge.2 ) then
                        print *,'mtemp(',k,mn,yr,') = ',mtemp(k,mn,yr)
                    endif
                enddo           ! months
            enddo               ! years
        enddo                   ! depths
        end
