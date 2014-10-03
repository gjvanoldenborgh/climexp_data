        program average
*
*       average GrADS files month-by-month
*
        implicit none
#include "recfac.h"
        integer nx,ny
        parameter(nx=144,ny=73)
        integer i,j,m,n(nx*ny,12)
        real*4 rain(nx*ny),s(nx*ny,12)
        character*255 string
        integer iargc
        external iargc,getarg

        if ( iargc().ne.1 ) then
            print *,'usage: average file'
            stop
        endif
        call getarg(1,string)
        i = index(string,'.dat')
        if ( i.ne.0 ) then
            string(i:i+3) = '    '
        endif
        do m=1,12
            do j=1,nx*ny
                s(j,m) = 0
            enddo
        enddo
        do m=1,12
            do j=1,nx*ny
                n(j,m) = 0
            enddo
        enddo
        i = index(string,' ')-1
        open(2,file=string(1:i)//'.dat',status='old',access='direct'
     +        ,recl=nx*ny*recfa4)
        open(1,file=string(1:i)//'_clim.dat',status='new',access
     +        ='direct',recl=nx*ny*recfa4)
        do i=0,20
            do m=1,12
                read(2,rec=12*i+m) rain
                do j=1,nx*ny
                    if ( rain(j).ge.0 ) then
                        s(j,m) = s(j,m) + rain(j)
                        n(j,m) = n(j,m) + 1
                    endif
                enddo
            enddo
        enddo
        do m=1,12
            do j=1,nx*ny
                if ( n(j,m).gt.0 ) then
                    s(j,m) = s(j,m)/n(j,m)
                else
                    s(j,m) = -999
                endif
            enddo
        enddo
        do m=1,12
            write(1,rec=m) (s(j,m),j=1,nx*ny)
        enddo
        end
