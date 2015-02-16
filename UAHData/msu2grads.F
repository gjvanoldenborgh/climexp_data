        program msu2grads
*
*       Convert the Roy Spencer and John Christy data for use 
*       in the Climate Explorer
*
        implicit none
#include "recfac.h"
        integer yrbeg,yrend,nx,ny
        parameter(yrbeg=1979,yrend=2020,nx=144,ny=72)
        integer yr,mo,ix,iy,isat,iyr,imo,ndata(nx,ny),nrec
        real data(nx,ny,12,yrbeg:yrend)
        character acha*12,file*100,version*3

        call getarg(1,version)
        nrec = 0
        do yr=yrbeg,yrend
            write(file,'(a,i4,2a)') 'tltmonamg.',yr,'_',version
            open(1,file=file,status='old',err=10)
            goto 20
 10         continue
            write(file,'(a,i4,3a)') 'tltmonamg.',yr,'_',version,'a'
            open(1,file=file,status='old',err=800)
 20         continue
            do mo=1,12
                read(1,100,end=800) isat,iyr,imo,acha
                if ( iyr.ne.yr .or. imo.ne.mo ) then
                    write(0,*) 'error: wrong date: ',yr,mo,iyr,imo
                    call abort
                endif
                read(1,101) ((ndata(ix,iy),ix=1,nx),iy=1,ny)
 100            format (3i12,a12)
 101            format (16i5)
                do iy=1,ny
                    do ix=1,nx
                        data(ix,iy,mo,yr) = ndata(ix,iy)/100.
                    end do
                end do
                nrec = nrec + 1
            end do
            close(1)
        end do
 800    continue
        close(1)
*
        open(1,file='tlt.grd',form='unformatted',access='direct',
     +       recl=nx*ny*recfa4)
        do mo=1,nrec
            write(1,rec=mo) ((data(ix,iy,1+mod(mo-1,12),1979+(mo-1)/12),
     +           ix=1,nx),iy=1,ny)
        end do
        close(1)
        open(1,file='tlt.ctl')
        write(1,'(a)') 'DSET ^tlt.grd'
        write(1,'(a)') 'TITLE Spencer and Christy '//
     +       '(U. of Alabama Huntsville) MSU lower troposphere '//
     +       'temperature v'//version
        write(1,'(a)') 'UNDEF 3e33'
        write(1,'(a)') 'XDEF 144 LINEAR -178.75 2.5'
        write(1,'(a)') 'YDEF  72 LINEAR  -88.75 2.5'
        write(1,'(a)') 'ZDEF 1 LINEAR 650 1'
        write(1,'(a,i5,a)') 'TDEF ',nrec,' LINEAR 15JAN1979 1MO'
        write(1,'(a)') 'VARS 1'
        write(1,'(a)')
     +       'Tlt 0 99 Temperature anomaly of the lower troposphere [K]'
        write(1,'(a)') 'ENDVARS'
        close(1)
        end
