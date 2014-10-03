        program asc2dat
*
*       convert objective analysis FSU ascii files to GrADS
*
        implicit none
        integer nx,ny
        parameter (nx=85,ny=30)
        integer iyfirst,iylast,iyear,m,iyyyy,month,i,nrec
        real taux(nx,ny),tauy(nx,ny)
        real rmask(nx,ny)
        real w(ny)
        character file*60, months(12)*3, var*2
        integer get_endian
        external get_endian
        data months /'jan','feb','mar','apr','may','jun',
     +        'jul','aug','sep','oct','nov','dec'/
        data nrec /0/

        iyfirst = 1978
        iylast  = 2020

        do iyear = iyfirst, iylast
            write(file,'(a,i4.4,a)') 'FSU_obj_psv_pac',iyear,'v11.asc'
            write(6,*) 'opening: ',file
            Open(1,file=file,status='old',err=100)
            do m=1,12
                read (1,10) month,iyyyy,taux,tauy 
                if ( iyyyy.lt.1900 ) iyyyy = iyyyy + 1900
                if ( iyear.ne.iyyyy ) print *
     +                ,'error: years do not agree ',iyear,iyyyy
                if ( m.ne.month ) print *,'error: months do not agree '
     +                ,m,month
   10           format (2i5,14f5.1,/(16f5.1)) 
                call writeit(taux,tauy,nrec)
            enddo
            close(1)
            goto 200
  100       continue
            do m=1,12
                write(file,'(a,i4.4,i2.2,a)') 'FSU_obj_psv_qpac',iyear,m
     +               ,'v11.asc'
                write(6,*) 'opening: ',file
                open(1,file=file,status='old',err=800)
                read (1,10,err=800) month,iyyyy,taux,tauy 
                close(1)
                if ( iyyyy.lt.1900 ) iyyyy = iyyyy + 1900
                if ( iyear.ne.iyyyy ) print *
     +                ,'error: years do not agree ',iyear,iyyyy
                if ( m.ne.month ) print *,'error: months do not agree '
     +                ,m,month
                call writeit(taux,tauy,nrec)
            enddo
  200       continue
        enddo
*
  800   continue
        do i=1,2
            if ( i.eq.1 ) then
                var='wu'
            else
                var='wv'
            endif
            open(1,file=var//'.ctl')
            write(1,'(3a)') 'DSET ^',var,'.dat'
            write(1,'(a)')
     +           'TITLE FSU objective analysis (research + quicklook)'
            write(1,'(a)') 'UNDEF 3e33'
            if ( get_endian().eq.1 ) then
                write(1,'(a)') 'OPTIONS BIG_ENDIAN'
            else
                write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
            endif
            write(1,'(a)') 'XDEF 85 LINEAR 122 2'
            write(1,'(a)') 'YDEF 30 LINEAR -29 2'
            write(1,'(a)') 'ZDEF  1 LINEAR 0 1'
            write(1,'(a,i4,a)') 'TDEF ',nrec,' LINEAR 15JAN1978 1MO'
            write(1,'(a)') 'VARS 1'
            if ( i.eq.1 ) then
                write(1,'(a)') 'taux 0 99 zonal wind pseudo stress'
            else
                write(1,'(a)') 'tauy 0 99 meridional wind pseudo stress'
            endif
            write(1,'(a)') 'ENDVARS'
            close(1)
        enddo
        end
        
        subroutine writeit(taux,tauy,nrec)
        implicit none
#include "recfac.h"
        integer nx,ny
        parameter (nx=85,ny=30)
        real taux(nx,ny),tauy(nx,ny)
        integer nrec,ix,iy
        if ( nrec.eq.0 ) then
            open(2,file='wu.dat',form='unformatted',access
     +            ='direct',recl=nx*ny*recfa4)
            open(3,file='wv.dat',form='unformatted',access
     +            ='direct',recl=nx*ny*recfa4)
        endif
        do iy=1,ny
            do ix=1,nx
                if ( taux(ix,iy).gt.900 ) then
                    taux(ix,iy) = 3e33
                endif
            enddo
        enddo
        do iy=1,ny
            do ix=1,nx
                if ( tauy(ix,iy).gt.900 ) then
                    tauy(ix,iy) = 3e33
                endif
            enddo
        enddo
        nrec = nrec + 1
        print *,'writing record ',nrec
        write(2,rec=nrec) taux
        write(3,rec=nrec) tauy
        end
