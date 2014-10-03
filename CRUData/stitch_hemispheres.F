        program stitch_hemipsheres
!
!       stitch the two half-world files together now that I have a 64
!       -bit climexp server
!
        implicit none
#include "recfac.h"
        integer nx,ny
        parameter(nx=720,ny=360)
        integer i,j,irec,nrec,ivar,ih,n
        real data(nx,ny)
        character vars(6)*3,var*3,file*100,line*100
        
        data vars /'tmp','tmn','tmx','dtr','pre','vap'/
        nrec=1272

        do ivar=1,6
            var = vars(ivar)
            print *,var
            open(1,file='cru3_'//var//'.grd',form='unformatted',
     +           access='direct',recl=recfa4*nx*ny)
            open(2,file='cru3_'//var//'_eh.grd',form='unformatted',
     +           access='direct',recl=recfa4*440*ny,status='old')
            open(3,file='cru3_'//var//'_wh.grd',form='unformatted',
     +           access='direct',recl=recfa4*280*ny,status='old')
            do irec=1,nrec
                read(3,rec=irec) ((data(i,j),i=1,280),j=1,ny)
                read(2,rec=irec) ((data(i+280,j),i=1,440),j=1,ny)
                write(1,rec=irec)  ((data(i,j),i=1,nx),j=1,ny)
            end do
            close(1)
            close(2)
            close(3)
            open(1,file='cru3_'//var//'.ctl')
            open(3,file='cru3_'//var//'_wh.ctl',status='old')
            do i=1,100
                read(3,'(a)',end=800) line
                if ( line(1:4).eq.'DSET' ) then
                    line(6:) = '^cru3_'//var//'.grd'
                end if
                if ( line(1:4).eq.'XDEF' ) then
                    line(6:8) = '720'
                end if
                write(1,'(a)') trim(line)
            end do
 800        continue
            close(1)
            close(3)
        end do
        end
