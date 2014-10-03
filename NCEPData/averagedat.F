        program average
*
*       average GrADS files month-by-month
*
        implicit none
#include "recfac.h"
        integer i,j,m,n(144*72,12)
        real*4 rain(144*72),s(144*72,12)

        do m=1,12
            do j=1,144*72
                s(j,m) = 0
            enddo
        enddo
        do m=1,12
            do j=1,144*72
                n(j,m) = 0
            enddo
        enddo
        open(2,file='cmap.dat',status='old',access='direct',recl=144*72
     +        *recfa4)
        open(1,file='cmapclim.dat',status='new',access='direct',recl=144
     +        *72*recfa4)
        do i=0,20
            do m=1,12
                read(2,rec=12*i+m) rain
                do j=1,144*72
                    if ( rain(j).ge.0 ) then
                        s(j,m) = s(j,m) + rain(j)
                        n(j,m) = n(j,m) + 1
                    endif
                enddo
            enddo
        enddo
        do m=1,12
            do j=1,144*72
                if ( n(j,m).gt.0 ) then
                    s(j,m) = s(j,m)/n(j,m)
                else
                    s(j,m) = -999
                endif
            enddo
        enddo
        do m=1,12
            write(1,rec=m) (s(j,m),j=1,144*72)
        enddo
        end

