        subroutine day2five(dtemp,temp,nt,maxnt,nz,firstyear,lastyear
     +        ,iwrite)
*
*       average daily measurements in dtemp into 5-daily ones in temp
*
        implicit none
        integer nt,maxnt,nz,firstyear,lastyear,iwrite
        real dtemp(nz,31,12,firstyear:lastyear),temp(nt,nz)
*
        integer i,j,k,n,yr,mn,dy,leap,dpm(12,2)
        integer julday
        external julday
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31
     +        ,31,29,31,30,31,30,31,31,30,31,30,31/
*       
*       loop over all data
*       
        maxnt = 0
        do k=1,nz
            i = 1
            n = 0
            temp(i,k) = 0
            do yr=firstyear,lastyear
***skipping 29-feb in order to get an integer number of 5-day periods
***                if ( mod(yr,4).eq.0 ) then
***                    leap = 2
***                else
***                    leap = 1
***                endif
                do mn=1,12
                    do dy=1,dpm(mn,1)
                        n = n + 1
                        if ( dtemp(k,dy,mn,yr).lt.1e33 ) then
                            if ( abs(dtemp(k,dy,mn,yr)).gt.100000 ) then
                                print *,'day2five: inexplicable value '
     +                                ,dtemp(k,dy,mn,yr),k,dy,mn,yr
                                temp(i,k) = 3e33
                            else
                                temp(i,k) = temp(i,k) + dtemp(k,dy,mn,yr
     +                                )
                            endif
                        else
                            temp(i,k) = 3e33
                        endif
                        if ( n.eq.5 ) then
                            if ( temp(i,k).lt.1e33 ) then
                                temp(i,k) = temp(i,k)/n
                                if ( abs(temp(i,k)).gt.100000 ) then
                                    print *
     +                                    ,'day2five: inexplicable val '
     +                                    ,temp(i,k),i,k
                                    temp(i,k) = 3e33
                                endif
                            endif
                            if ( i.gt.nt ) then
                                write(0,*)'day2five: error: increase nt'
     +                                ,nt
                                call abort
                            endif
                            if ( iwrite.ge.2 .and. temp(i,k).lt.1e33 )
     +                            then
                                print '(a,i5,i3,a,f6.2,i5,2i2.2)'
     +                                ,'temp(',i,k,') = ',temp(i,k),yr
     +                                ,mn,dy
                            endif
                            i = i + 1
                            if ( i.lt.nt ) temp(i,k) = 0
                            n = 0
                        endif
                    enddo       ! days
                enddo           ! months
            enddo               ! years
            maxnt = max(maxnt,i)
        enddo                   ! depths
        end
