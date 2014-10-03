        program pdsi2dat
*
*       convert the UCAR PDSI grids to GrADS
*
        implicit none
#include "recfac.h"
        integer yrbeg,yrend,nx,ny
        parameter (yrbeg=1860,yrend=1995,nx=144,ny=55)
        integer yr,mo,i,j,irec
        real pdsi(nx,ny)

        open(1,file='pdsi.monthly.maps.1860-1995.bin',status='old',
     +        form='unformatted')
        open(2,file='pdsi.dat',access='direct',form='unformatted',
     +        recl=nx*ny*recfa4)
        irec = 0
        do yr=yrbeg,yrend
            do mo=1,12
                read(1) pdsi
                do j=1,ny
                    do i=1,nx
                        if ( pdsi(i,j).eq.-99999.0 ) pdsi(i,j) = 3e33
                    enddo
                enddo
                irec = irec + 1
                write(2,rec=irec) pdsi
            enddo
        enddo
        close(1)
        close(2)
        open(1,file='pdsi.ctl')
        write(1,'(a)') 'DSET ^pdsi.dat'
        write(1,'(a)') 'TITLE NCAR Palmer Drought Severity Index'
        write(1,'(a)') 'OPTIONS BIG_ENDIAN'
        write(1,'(a)') 'UNDEF 3e33'
        write(1,'(a)') 'XDEF 144 LINEAR -180 2.5'
        write(1,'(a)') 'YDEF  55 LINEAR  -60 2.5'
        write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(1,'(a,i6,a)') 'TDEF ',12*(yrend-yrbeg+1),
     +        ' LINEAR 15JAN1860 1MO'
        write(1,'(a)') 'VARS 1'
        write(1,'(a)') 'pdsi 1 0 Palmer Drought Severity Index'
        write(1,'(a)') 'ENDVARS'
        close(1)
        end
