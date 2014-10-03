        program gauge2dat
*
*       convert the GPCC files into GrADS files
*
        implicit none
#include "recfac.h"
        integer i,j,yr,mo,irec,nx,ny
        real prec(360,180),nprec(360,180),step,lon1,lon2,lat1,lat2,dx
        character file*100,res*2

        call getarg(1,res)
        if ( res.eq.'10' ) then
            nx = 360
            ny = 180
            dx = 1
        elseif ( res.eq.'25' ) then
            nx = 144
            ny = 72
            dx = 2.5
        else
            write(0,*) 'please specify resolution, either 10 or 25'
            call abort
        endif
        write(*,*) 'gpcc_'//res//'_mon.dat'
        open(2,file='gpcc_'//res//'_mon.dat',form='unformatted',access
     +       ='direct',recl=nx*ny*recfa4)
        write(*,*) 'ngpcc_'//res//'_mon.dat'
        open(3,file='ngpcc_'//res//'_mon.dat',form='unformatted',access
     +       ='direct',recl=nx*ny*recfa4)
        irec = 0
        do yr=1986,2020
            do mo=1,12
                if ( yr.lt.2000 ) then
                    write(file,'(3a,2i2.2,a)') 'gpcc_',res,'_',mo,
     +                   mod(yr,100),'_monitor_gauge'
                else
                    write(file,'(3a,i2.2,i4,a)') 'gpcc_',res,'_',mo,yr,
     +                    '_monitor_gauge'
                endif
                write(*,*) 'opening ',trim(file)
                open(1,file=file,status='old',err=110)
                goto 120
 110            continue
                i = 7
 111            continue
                i = i - 1
                if ( i.le.0 ) goto 115
                write(file,'(3a,i2.2,i4,a,i1)') 'gpcc_',res,'_',mo,yr,
     +                    '_monitoring_product_v',i
                write(*,*) 'opening ',trim(file)
                open(1,file=file,status='old',err=111)
                goto 120
 115            continue
                write(file,'(a,i2.2,a,i4)') 'gpcc_first_guess_',mo,'_'
     +               ,yr
                write(*,*) 'opening ',trim(file)
                open(1,file=file,status='old',err=800)
 120            continue
                read(1,*) i
                if ( i.eq.32 ) i = 33 ! smullen
***                if ( i.ne.8 ) then
***                    write(0,*) 'error: format changed ',i
***                    call abort
***                endif
***                read(1,'(6x,f9.6)') step
***                if ( step.ne.1 ) then
***                    write(0,*) 'error: I thought we had 1x1 grids, not '
***     +                    ,step
***                    call abort
***                endif
***                read(1,'(6x,2f12.6,2f11.6)') lon1,lon2,lat1,lat2
***                if (  lon1.ne.-180 .or. lon2.ne.180 .or. 
***     +                lat1.ne.-90  .or. lat2.ne.90 ) then
***                    write(0,*) 'error: I thought we had the earth, not '
***     +                    ,lon1,lon2,lat1,lat2
***                    call abort
***                endif
***                read(1,'(6x,i3,i5)') j,i
***                if ( i.ne.yr .or. j.ne.mo ) then
***                    write(0,*) 'error: expected ',yr,mo,', but found ',
***     +                    i,j
***                    call abort
***                endif
                do i=1,i-1
                    read(1,'(a)') file
                enddo
                do j=1,ny
                    do i=1,nx
                        read(1,*) prec(i,j),nprec(i,j)
                        if ( prec(i,j).eq.-99999.99 ) prec(i,j) = 3e33
                    enddo
                enddo
                irec = irec + 1
                write(2,rec=irec) ((prec(i,j),i=1,nx),j=1,ny)
                write(3,rec=irec) ((nprec(i,j),i=1,nx),j=1,ny)
                close(1)
            enddo
        enddo
  800   continue
        close(2)
        close(3)
        write(*,*) 'gpcc_'//res//'_mon.ctl'
        open(2,file='gpcc_'//res//'_mon.ctl')
        write(2,'(a)') 'DSET ^gpcc_'//res//'_mon.dat'
        write(*,*) 'ngpcc_'//res//'_mon.ctl'
        open(3,file='ngpcc_'//res//'_mon.ctl')
        write(3,'(a)') 'DSET ^ngpcc_'//res//'_mon.dat'
        do i=2,3
            write(i,'(a)')
     +            'TITLE GPCC rain gauge precipitation dataset'
            write(i,'(a)') 'OPTIONS LITTLE_ENDIAN YREV'
            write(i,'(a)') 'UNDEF 3e33'
            write(i,'(a,i3,a,2f7.2)') 'XDEF ',nx,' LINEAR ',-180+dx/2,dx
            write(i,'(a,i3,a,2f7.2)') 'YDEF ',ny,' LINEAR ',-90+dx/2,dx
            write(i,'(a)') 'ZDEF 1 LINEAR 0 1'
            write(i,'(a,i4,a)') 'TDEF ',irec,' LINEAR 15JAN1986 1MO'
            write(i,'(a)') 'VARS 1'
            if ( i.eq.2 ) then
                write(i,'(a)') 'prcp 1 0 precipitation [mm/month]'
            else
                write(i,'(a)')
     +                'nprcp 1 0 number of gauges per grid point'
            endif
            write(i,'(a)') 'ENDVARS'
            close(i)
        enddo
        end
