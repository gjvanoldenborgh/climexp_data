        program hulmes2dat
*
*       put Hulmes' precipitation data in a GrADS .dat file
*       for use in the Climate explorer (befiore I switched to NetCDF)
*
        implicit none
#include "recfac.h"
        integer nx,ny,ny1,ny2
        parameter (nx=96,ny=71,ny1=1900,ny2=1998)
        integer i,j,k,n,ilat,ilon,iy1,iy2,iprcp(12),irec
        real*4 field(nx,ny,12,ny1:ny2)
        character name*15,diag*14
*
        open(1,file='gu23wld0098.dat',status='old')
        open(2,file='hulme23.dat',access='direct',form='unformatted'
     +        ,recl=nx*ny*recfa4)
        do k=ny1,ny2
            do n=1,12
                do j=1,ny
                    do i=1,nx
                        field(i,j,n,k) = 3e33
                    enddo
                enddo
            enddo
        enddo
*       
  100   continue
        read(1,'(I7,I5,I6,I5,A15,I4,A14,2I4,I7,I9)',err=900,end=200)
     +        i,ilat,ilon,j,name,n,diag,iy1,iy2
        do k=iy1,iy2
            read(1,'(I4,12I5,I6)',err=900,end=900) j,iprcp
            if ( k.ne.j ) then
                print *,'error: years ',k,j,' conflict'
                stop
            endif
            if ( k.lt.ny1 .or. k.gt.ny2 ) then
                print *,'error: k out of range: ',k,ny1,ny2
                stop
            endif
            i = ilon/375 + 49
            if ( i.lt.1 .or. i.gt.nx ) then
                print *,'error: i out of range: ',i,nx
                stop
            endif
            j = ilat/250 + 36
            if ( j.lt.1 .or. j.gt.ny ) then
                print *,'error: j out of range: ',j,ny
                stop
            endif
            do n=1,12
                if ( iprcp(n).ge.0 ) then
                    field(i,j,n,k) = iprcp(n)/10.0
                endif
            enddo
        enddo
        goto 100
*       
*       finito
  200   continue
        irec = 0
        do k=ny1,ny2
            do n=1,12
                irec = irec + 1
                write(2,rec=irec) ((field(i,j,n,k),i=1,nx),j=1,ny)
            enddo
        enddo
        close(2)
        close(1)
*       
*       errors
        stop
  900   print *,'error reading data'
        end

