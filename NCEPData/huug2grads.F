        program huug2grads
!
!       simple but necessary...
!
        implicit none
#include "recfac.h"
        integer nx,ny
        parameter (nx=720,ny=360)
        integer nt,i,j
        real data(nx,ny),undef
        undef=-999.0
        open(1,file='t.1948_cur',form='unformatted')
        open(2,file='cpc_t2m.grd',access='direct',recl=recfa4*nx*ny)
        nt = 0
 100    continue
        read(1,end=800) data
        nt = nt + 1
        do j=1,ny
            do i=1,nx
                if ( abs(data(i,j)-undef).lt.0.01 ) data(i,j) = 3e33
            enddo
        enddo
        write(2,rec=nt) data
        goto 100
 800    continue
        close(1)
        close(2)
        open(1,file='cpc_t2m.ctl')
        if ( nx.ne.720 ) call abort
        if ( ny.ne.360 ) call abort
        write(1,'(a)') 'DSET ^cpc_t2m.grd'
        write(1,'(a)') 'TITLE Fan and van den Dool t2m analysis'
        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(1,'(a)') 'UNDEF 3e33'
        write(1,'(a)') 'XDEF 720 LINEAR   0.25 0.5'
        write(1,'(a)') 'YDEF 360 LINEAR -89.75 0.5'
        write(1,'(a)') 'ZDEF   1 LINEAR 0 1'
        write(1,'(a,i5,a)') 'TDEF ',nt,' LINEAR 15JAN1948 1MO'
        write(1,'(a)') 'VARS 1'
        write(1,'(a)') 't2m 0 99 2m temperature [C]'
        write(1,'(a)') 'ENDVARS'                                   
        close(1)
        end
