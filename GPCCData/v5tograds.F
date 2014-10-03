        program v4tograds
*
*       convert the GPCC v5 files into GrADS files
*
        implicit none
#include "recfac.h"
        integer i,j,n,yr,yr1,mo,irec,ires,nx,ny
        real prec(720,360),aprec(720,360),nprec(720,360),dx
        character file*255,file2*255,file3*255,line*80
        integer iargc
        
        if ( iargc().ne.1) then
            write(0,*) 'usage: v5tograds 05|10|25'
            call abort
        end if
        call getarg(1,line)
        read(line,*) dx
	if ( dx.eq.0 ) then
            write(0,*) 'error: dx = ',dx
            call abort
        endif
        dx = dx/10.
        nx = nint(360/dx)
        ny = nint(180/dx)
        write(file2,'(a,i2.2,a)') 'gpcc_V5_',nint(10*dx),'.grd'
        open(2,file=file2,form='unformatted',access='direct',
     +       recl=nx*ny*recfa4)
        write(file3,'(a,i2.2,a)') 'gpcc_V5_',nint(10*dx),'_n1.grd'
        open(3,file=file3,form='unformatted',access='direct',
     +       recl=nx*ny*recfa4)
        irec = 0
        do yr=1901,2009
!           unzip 10-yr archive
            if ( mod(yr,10).eq.1 ) then
                if ( yr.eq.2001 ) then
                    yr1 = 2009
                else
                    yr1 = yr + 9
                end if
                write(file,'(a,i2.2,a,i4,a,i4,a)')
     +               'gpcc_full_data_archive_v005_',nint(10*dx)
     +               ,'_degree_',yr,'_',yr1,'.zip'
                write(*,*) 'unzipping ',trim(file)
                call mysystem('unzip -u '//trim(file),ires)
                if ( ires.ne.0 ) then
                    write(0,*) 'error unzipping ',trim(file)
                    call abort
                end if
            end if
            do mo=1,12
                write(file,'(a,i2.2,a,i2.2,i4.4)')
     +               'gpcc_full_data_v005_',nint(10*dx),'_degree_',mo,yr
                write(*,*) 'opening ',trim(file)
                open(1,file=file,status='old',err=800)
                read(1,*) n
                do i=2,n
                    read(1,'(a)') line
                end do
                if ( line(1:3).ne.'===' ) then
                    write(0,*) 'error skipping over header'
                    call abort
                end if
                do j=1,ny
                    do i=1,nx
                        read(1,*) prec(i,j),aprec(i,j),nprec(i,j)
                        if ( prec(i,j).eq.-99999.99 ) prec(i,j) = 3e33
                        if ( aprec(i,j).eq.-99999.99 ) aprec(i,j) = 3e33
!                       throw away the anomalies, recycle the data for 
!                       the "at least one obs" field that I find more useful
                        if ( nprec(i,j).gt.0.5 ) then
                            aprec(i,j) = prec(i,j)
                        else
                            aprec(i,j) = 3e33
                        end if
                    end do
                end do
                irec = irec + 1
                write(2,rec=irec) ((prec(i,j),i=1,nx),j=1,ny)
                write(3,rec=irec) ((aprec(i,j),i=1,nx),j=1,ny)
                close(1,status='delete')
            end do              ! mo
        end do                  ! yr
 800    continue
        close(2)
        close(3)
        write(file,'(a,i2.2,a)') 'gpcc_V5_',nint(10*dx),'.ctl'
        open(2,file=file)
        write(2,'(a)') 'DSET ^'//trim(file2)
        write(file,'(a,i2.2,a)') 'gpcc_V5_',nint(10*dx),'_n1.ctl'
        open(3,file=file)
        write(3,'(a)') 'DSET ^'//trim(file3)
        do i=2,3
            write(i,'(a)')
     +           'TITLE GPCC V5 rain gauge precipitation dataset'
            write(i,'(a)') 'OPTIONS LITTLE_ENDIAN YREV'
            write(i,'(a)') 'UNDEF 3e33'
            write(i,'(a,i4,a,2f8.2)') 'XDEF ',nx,' LINEAR ',
     +           -180+dx/2,dx
            write(i,'(a,i4,a,2f8.2)') 'YDEF ',ny,' LINEAR ',
     +           -90+dx/2,dx
            write(i,'(a)') 'ZDEF 1 LINEAR 0 1'
            write(i,'(a,i4,a)') 'TDEF ',irec,' LINEAR 15JAN1901 1MO'
            write(i,'(a)') 'VARS 1'
            write(i,'(a)') 'prcp 1 0 precipitation [mm/month]'
            write(i,'(a)') 'ENDVARS'
            close(i)
        enddo
        end

        subroutine mysystem(string,retval)
        implicit none
        integer retval
        character*(*) string
#ifdef __linux
*       pgf90, but possibly more
        integer system
        retval = system(string)
#else
*       curiously, g95 does not define __linux...
        call system(string,retval)
#endif
        end
