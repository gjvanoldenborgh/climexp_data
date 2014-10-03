        program full2dat
*
*       convert the full GPCC files into GrADS files
*
        implicit none
#include "recfac.h"
        integer i,j,yr,mo,irec,ires,nx,ny
        real prec(720,360,12),nprec(720,360,12),dx
        character file*255,file2*255,file3*255
        
        call getarg(1,file)
        read(file,*) dx
	if ( dx.eq.0 ) then
            write(0,*) 'error: dx = ',dx
            call abort
        endif
        dx = dx/10.
        nx = nint(360/dx)
        ny = nint(180/dx)
        write(file2,'(a,i2.2,a)') 'gpcc_V31_',nint(10*dx),'.dat'
        open(2,file=file2,form='unformatted',access='direct',
     +       recl=12*nx*ny*recfa4)
        write(file3,'(a,i2.2,a)') 'ngpcc_V31_',nint(10*dx),'.dat'
        open(3,file=file3,form='unformatted',access='direct',
     +       recl=12*nx*ny*recfa4)
        irec = 0
        do yr=1951,2004
            write(file,'(a,i2.2,a,i4.4,a)') 'gpcc_full_V3_',nint(10*dx),
     +           '_',yr,'_precip_gauges'
            write(*,*) 'opening ',trim(file)
            open(1,file=file,status='old',err=800)
            do j=1,ny
                do i=1,nx
                    read(1,*) (prec(i,j,mo),nprec(i,j,mo),mo=1,12)
                    do mo=1,12
                        if ( prec(i,j,mo).eq.-99999.99 )
     +                       prec(i,j,mo) = 3e33
                    enddo                        
                enddo
            enddo
            irec = irec + 1
            write(2,rec=irec) (((prec(i,j,mo),i=1,nx),j=1,ny),mo=1,12)
            write(3,rec=irec) (((nprec(i,j,mo),i=1,nx),j=1,ny),mo=1,12)
            close(1)
        enddo
 800    continue
        close(2)
        close(3)
        write(file,'(a,i2.2,a)') 'gpcc_V31_',nint(10*dx),'.ctl'
        open(2,file=file)
        write(2,'(a)') 'DSET ^'//trim(file2)
        write(file,'(a,i2.2,a)') 'ngpcc_V31_',nint(10*dx),'.ctl'
        open(3,file=file)
        write(3,'(a)') 'DSET ^'//trim(file3)
        do i=2,3
            write(i,'(a)')
     +           'TITLE GPCC rain gauge precipitation dataset'
            write(i,'(a)') 'OPTIONS LITTLE_ENDIAN YREV'
            write(i,'(a)') 'UNDEF 3e33'
            write(i,'(a,i4,a,2f8.2)') 'XDEF ',nx,' LINEAR ',
     +           -180+dx/2,dx
            write(i,'(a,i4,a,2f8.2)') 'YDEF ',ny,' LINEAR ',
     +           -90+dx/2,dx
            write(i,'(a)') 'ZDEF 1 LINEAR 0 1'
            write(i,'(a,i4,a)') 'TDEF ',12*irec
     +           ,' LINEAR 15JAN1951 1MO'
            write(i,'(a)') 'VARS 1'
            if ( i.eq.2 ) then
                write(i,'(a)') 'prcp 1 0 precipitation [mm/month]'
            else
                write(i,'(a)')
     +               'nprcp 1 0 number of gauges per grid point'
            endif
            write(i,'(a)') 'ENDVARS'
            close(i)
        enddo
        end
