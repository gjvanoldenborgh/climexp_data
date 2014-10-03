        PROGRAM dat2grads
!
!       sum the NODS files
!
        implicit none
#include "recfac.h"
        integer nx,ny,nz,yrbeg,yrend
        parameter (nx=360, ny=180, nz=33, yrbeg=1955, yrend=2020)
        integer i,j,k,yr,mo,irec
        real data(nx,ny),lat,s
        character file*70,hex(0:15)
        integer,external :: get_endian
        data hex /'0','1','2','3','4','5','6','7','8','9','A','B','C'
     +       ,'D','E','F'/
 
        irec = 0
        do yr=yrbeg,yrend
            do mo=1,12,3
                s = 0
                write(file,'(a,2(a,i1),i2.2,a,i2.2,a)') 'HC_0-700_',
     +               hex((yr-1900)/10),mod(yr,10),
     +               hex((yr-1900)/10),mod(yr,10),mo,'-',mo+2,'.dat'
                print *,'opening ',trim(file)
                open(1,file=trim(file),status='old',err=101)
                goto 102
 101            continue
                write(file,'(a,a,i1,i2.2,a,i2.2,a)') 'HC_0-700__',
     +               hex((yr-1900)/10),mod(yr,10),mo,'-',mo+2,'.dat'
                print *,'opening ',trim(file)
                open(1,file=trim(file),status='old',err=800)
 102            continue
                do j=1,ny
                    read(1,'(10f8.3)',err=900,end=900)(data(i,j),i=1,nx)
                    do i=1,nx
                        if ( data(i,j).lt.-90 ) then
                            data(i,j) = 3e33
                        else
                            s = s + data(i,j)
                        end if
                    end do
                end do
                close(1)
                print *,yr,mo,s
            end do              ! mo
        end do                  ! yr
 800    continue
        goto 999
 900    write(0,*) 'error reading NODC file ',trim(file)
        write(0,*) 'at j=',j
        if ( j.gt.1 ) then
            write(0,*) 'last data read ',(data(i,j),i=1,nx)
        end if
        call abort
 999    continue
        end
