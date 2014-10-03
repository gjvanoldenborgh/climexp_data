        program mslpnh2grads
*
*       convert file mslpnh.dat into a grads file
*       see http://www.cru.uea.ac.uk/cru/data/pressure.htm.
*
        implicit none
        integer nx,ny
        parameter (nx=36,ny=15)
        integer i,j,n,yr,mo,undef,idum1,idum2,idum3,month,year,idata(15)
        real field(nx,ny),absent
        parameter(absent=3e33)
#include "recfac.h"
*
        undef = -32768
        open(1,file='mslpnh.dat',status='old')
        open(2,file='mslpnhbin.dat',status='new',form='unformatted'
     +        ,access='direct',recl=recfa4*nx*ny)
*       
        n = 0
        do yr=1873,1995
            do mo=1,12
                read(1,'(5i6)') idum1,idum2,month,year,idum3
                if ( month.ne.mo .or. year.ne.yr ) then
                    print *,'help! out of sync! ',year,month,yr,mo
                endif
                do i=1,36
                    read(1,'(16i6)') idum1,idata
                    do j=1,15
                        if ( idata(j).eq.undef ) then
                            field(i,j) = absent
                        else
                            field(i,j) = idata(j)/100. + 1000.
                        endif
                    enddo
                enddo
                n = n+1
                write(2,rec=n) field
            enddo
        enddo
*
        end
