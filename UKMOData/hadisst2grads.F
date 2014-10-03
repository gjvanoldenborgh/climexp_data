        program hadisst2grads
*
*       convert the UKMO HadISST files to GrADS format
*
        implicit none
#include "recfac.h"
        integer yrbeg,yrend,nx,ny
        parameter (yrbeg=1870,yrend=2020,nx=360,ny=180)
        integer yr,mo,dy,i,j,yr1,mo1,irec,nny,idata(nx)
        real data(nx,ny)
        character year*4
        
        open(10,file='hadisst1.ctl')
        open(11,file='hadisst1.grd',access='direct',form='unformatted',
     +       recl=recfa4*nx*ny)
        irec = 0

        do yr1=yrbeg,yrend
            if ( yr1.eq.1870 ) then
                open(1,file='HadISST1_SST_1870-1900.txt',status='old')
            elseif ( yr1.eq.1901 ) then
                close(1)
                open(1,file='HadISST1_SST_1901-1930.txt',status='old')
            elseif ( yr1.eq.1931 ) then
                close(1)
                open(1,file='HadISST1_SST_1931-1960.txt',status='old')
            elseif ( yr1.eq.1961 ) then
                close(1)
                open(1,file='HadISST1_SST_1961-1990.txt',status='old')
            elseif ( yr1.eq.1991 ) then
                close(1)
                open(1,file='HadISST1_SST_1991-2003.txt',status='old')
            elseif ( yr1.gt.2003 ) then
                close(1)
                write(year,'(i4.4)') yr1
                open(1,file='HadISST1_SST_'//year//'.txt',status='old')
            endif
            do mo1=1,12
                read(1,*,end=800) dy,mo,yr,nny
                if ( mo.ne.mo1 .or. yr.ne.yr1 ) then
                    write(0,*) 'error: date wrong: ',dy,mo,yr,mo1,yr1
                    call abort
                endif
                if ( nny.ne.ny ) then
                    write(0,*) 'error: ny wrong: ',ny,nny
                    call abort
                endif
                do j=ny,1,-1
                    read(1,'(10000(i6))') idata
                    do i=1,nx
                        if ( idata(i).eq.-1000 .or.
     +                       idata(i).eq.-32768 ) then
                            data(i,j) = 3e33
                        else
                            data(i,j) = idata(i)/100.
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
        write(10,'(a)') 'DSET ^hadisst1.grd'
        write(10,'(a)') 'TITLE Hadley Centre SST data set HadISST1'
        write(10,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(10,'(a)') 'UNDEF 3e33'
        write(10,'(a,i3,a,2f7.2)') 'XDEF ',nx,' LINEAR ',-180+360./nx/2
     +       ,360./nx
        write(10,'(a,i3,a,2f7.2)') 'YDEF ',ny,' LINEAR ',-90+180./ny/2
     +       ,180./ny
        write(10,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(10,'(a,i5,a)') 'TDEF ',irec,' LINEAR 15JAN1870 1MO'
        write(10,'(a)') 'VARS 1'
        write(10,'(a)')
     +       'SST 1 99 sea surface temperature [C]'
        write(10,'(a)') 'ENDVARS'
        end
