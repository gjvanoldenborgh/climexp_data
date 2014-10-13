        PROGRAM dat2grads
!
!       convert NODC's ASCII format to a griudded file, based on analyse.for
!
        implicit none
#include "recfac.h"
        integer nx,ny,nz,yrbeg,yrend
        parameter (nx=360, ny=180, nz=33, yrend=2020)
        integer i,j,k,yr,mo,irec
        real data(nx,ny),lat
        character file*70,hex(0:15),depth*5,var*2,altvar*4
        integer,external :: get_endian
        data hex /'0','1','2','3','4','5','6','7','8','9','A','B','C'
     +       ,'D','E','F'/
 
        call getarg(1,depth)
        call getarg(2,var)
        if ( var.eq.'HC' ) then
            altvar = 'heat'
        else if ( var.eq.'MT' ) then
            altvar = 'temp'
        else
            write(00,*) 'dat2grads: error: unknown var ',trim(var)
            call abort
        end if
        if ( trim(depth).eq.'700' .or. trim(depth).eq.'100' ) then
            yrbeg = 1955
        else if ( trim(depth).eq.'2000' ) then
            yrbeg = 2005
        else
            write(0,*) 'dat2grads: unknown value for depth ',trim(depth)
            call abort
        end if
        open(2,file=altvar//trim(depth)//'.grd',access='direct',
     +       recl=nx*ny*recfa4)
        irec = 0
        do yr=yrbeg,yrend
            do mo=1,12,3
                write(file,'(4a,2(a,i1),i2.2,a,i2.2,a)') var,'_0-',
     +               trim(depth),'_',
     +               hex((yr-1900)/10),mod(yr,10),
     +               hex((yr-1900)/10),mod(yr,10),mo,'-',mo+2,'.dat'
                print *,'opening ',trim(file)
                open(1,file=trim(file),status='old',err=101)
                goto 102
 101            continue
                write(file,'(4a,a,i1,i2.2,a,i2.2,a)') var,'_0-',
     +               trim(depth),'__',
     +               hex((yr-1900)/10),mod(yr,10),mo,'-',mo+2,'.dat'
                print *,'opening ',trim(file)
                open(1,file=trim(file),status='old',err=800)
 102            continue
                do j=1,ny
                    lat = (-90.5+j)*atan(1.)/45 ! in radians
                    read(1,'(10f8.3)',err=900,end=900)(data(i,j),i=1,nx)
                    do i=1,nx
                        if ( data(i,j).lt.-90 ) then
                            data(i,j) = 3e33
                        else if ( var.eq.'HC' ) then
!                           convert from 10^18 J/gridbox to J/m2
                            data(i,j) = 10.**18*data(i,j)*
     +                          (90./10000000.)**2/cos(lat)/10.**9
                        end if
                    end do
                end do
                close(1)
                do k=1,3
                    irec = irec + 1
                    write(2,rec=irec) data
                end do
            end do              ! mo
        end do                  ! yr
 800    continue
        close(2)
        open(2,file=altvar//trim(depth)//'.ctl')
        write(2,'(a)') 'DSET ^'//altvar//trim(depth)//'.grd'
        if ( var.eq.'HC' ) then
            write(2,'(a)') 'TITLE NODC heat content 0-'//trim(depth)//
     +           'm'
        else if ( var.eq.'MT' ) then
            write(2,'(a)') 'TITLE NODC mean temperature 0-'//trim(depth)
     +           //'m'
        end if
        if ( get_endian().eq.-1 ) then
            write(2,'(a)') 'OPTIONS LITTLE_ENDIAN'    
        else if ( get_endian().eq.+1 ) then
            write(2,'(a)') 'OPTIONS BIG_ENDIAN'
        end if
        write(2,'(a)') 'UNDEF 3e33'
        write(2,'(a)') 'XDEF 360 LINEAR 0.5 1'
        write(2,'(a)') 'YDEF 180 LINEAR -89.5 1'
        write(2,'(a)') 'ZDEF 1 LINEAR 350 1'
        write(2,'(a,i5,a,i4,a)') 'TDEF ',irec,' LINEAR 15JAN',yrbeg,
     +       ' 1MO'
        write(2,'(a)') 'VARS 1'
        if ( var.eq.'HC' ) then
            write(2,'(a)') altvar//' 0 99 heat content 0-'//
     +           trim(depth)//'m [GJ/m2]'
        else if ( var.eq.'MT' ) then
            write(2,'(a)') altvar//' 0 99 mean temperature 0-'//
     +           trim(depth)//'m [K]'
        end if
        write(2,'(a)') 'ENDVARS'
        close(2)
        goto 999
 900    write(0,*) 'error reading NODC file ',trim(file)
        write(0,*) 'at j=',j
        if ( j.gt.1 ) then
            write(0,*) 'last data read ',(data(i,j),i=1,nx)
        end if
        call abort
 999    continue
        end
