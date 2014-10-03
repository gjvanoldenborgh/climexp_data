        program hadsst2grads
*
*       convert the UKMO HadSST files to GrADS format
*
        implicit none
#include "recfac.h"
        integer yrbeg,yrend,nx,ny
        parameter (yrbeg=1850,yrend=2020,nx=360/5,ny=180/5)
        integer yr,mo,dy,i,j,yr1,mo1,irec
        real data(nx,ny)
        
        open(10,file='hadsst2.ctl')
        open(11,file='hadsst2.dat',access='direct',form='unformatted',
     +       recl=recfa4*nx*ny)
        irec = 0

        open(1,file='HadSST2_SST_1850on.txt',status='old')
        do yr1=yrbeg,yrend
            do mo1=1,12
                read(1,'(2i12)',end=800) mo,yr
                if ( mo.ne.mo1 .or. yr.ne.yr1 ) then
                    write(0,*) 'error: date wrong: ',dy,mo,yr,mo1,yr1
                    call abort
                endif
                do j=ny,1,-1
                    read(1,'(10000(f8.3))') (data(i,j),i=1,nx)
                    do i=1,nx
                        if ( data(i,j).eq.-99.99 ) then
                            data(i,j) = 2e20
                        endif
                    enddo
                enddo
                irec = irec + 1
                write(11,rec=irec) data
            enddo               ! mo1
        enddo                   ! yr1

 800    continue
        mo1 = mo1 - 1
        if ( mo1.eq.0 ) then
            mo1 = 12
            yr1 = yr1 - 1
        endif
        write(10,'(a)') 'DSET ^hadsst2.dat'
        write(10,'(a)') 'TITLE Hadley Centre SST data set HadSST2'
        write(10,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(10,'(a)') 'UNDEF 2e20'
        write(10,'(a,i3,a,2f7.2)') 'XDEF ',nx,' LINEAR ',-180+360./nx/2
     +       ,360./nx
        write(10,'(a,i3,a,2f7.2)') 'YDEF ',ny,' LINEAR ',-90+180./ny/2
     +       ,180./ny
        write(10,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(10,'(a,i5,a)') 'TDEF ',irec,' LINEAR 12Z16JAN1850 1MO'
        write(10,'(a)') 'VARS 1'
        write(10,'(a)')
     +       'SSTa 1 99 sea surface temperature anomalies [C]'
        write(10,'(a)') 'ENDVARS'
        end
