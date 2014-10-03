        program dat2dat
!
!       convert SSMI daily SST to grads format
!
        implicit none
#include "recfac.h"
        integer nnx,nny,yrbeg,yrend
        parameter(nnx=1440,nny=720,yrbeg=1998,yrend=2020)
        integer yr,dy,i,j,nday,iret,nrec,nx,ny,ivars(2,1)
        character(len=1) cvals(nnx,nny)
        real vals(nnx,nny),xx(nnx),yy(nny),zz(1)
        logical lwrite
        character file*100,vars(1)*20,lvars(1)*40,units(1)*20
        integer,external :: leap
        lwrite = .false.
!!!        lwrite = .true.

        open(1,file='ssmi_sst.grd',access='direct',form='unformatted'
     +       ,recl=recfa4*360*180)

        nrec = 0
        do yr=yrbeg,yrend
            nday = 364 + leap(yr)
            print *,yr,nday
            do dy=1,nday
                if ( yr.lt.2002 .or. yr.eq.2002.and.dy.lt.154 ) then
                    write(file,'(a,i4,a,i3.3,a)')
     +                   'tmi.fusion.',yr,'.',dy,'.v01.gz'
                else
                    write(file,'(a,i4,a,i3.3,a)')
     +                   'tmi_amsre.fusion.',yr,'.',dy,'.v02.gz'
                endif
                if ( lwrite ) print *,'opening ',trim(file)
                call mysystem('gunzip -c '//trim(file)//
     +               ' > /tmp/ssmi.dat',iret)
                if (iret.ne.0 ) goto 800
                open(2,file='/tmp/ssmi.dat',access='direct',
     +               form='unformatted',recl=nnx*nny,status='old',
     +               err=800)
                read(2,rec=1) cvals
                close(2)
                do i=1,nnx
                    do j=1,nny
                        if ( ichar(cvals(i,j)).le.250 ) then
                            vals(i,j) = 0.15*ichar(cvals(i,j)) - 3
                        else
                            vals(i,j) = 3e33
                        endif
                    end do
                end do
                nx = nnx
                ny = nny
                do i=1,nnx
                    xx(i) = -.125 + 0.25*i
                end do
                do j=1,nny
                    yy(j) = -90.125 + 0.25*j
                end do
                zz(1) = 0
                call spatialaverage(vals,xx,yy,nx,ny,1,1,1,4,4,lwrite)
                if ( nx.ne.360 .or. ny.ne.180 .or. 
     +               xx(1).ne.0.5   .or. xx(nx).ne.359.5 .or.
     +               yy(1).ne.-89.5 .or. yy(ny).ne.89.5 ) then
                    write(0,*) 'error in the spatial averaging'
                    write(0,*) 'nx,xx(1),xx(nx) = ',nx,xx(1),xx(nx)
                    write(0,*) 'ny,yy(1),yy(ny) = ',ny,yy(1),yy(ny)
                    call abort
                end if
                nrec = nrec + 1
                write(1,rec=nrec) ((vals(i,j),i=1,nx),j=1,ny)
            end do              ! dy
        end do                  ! yr
!
!       end of data
!
 800    continue
        call mysystem('rm ssmi_sst.ctl',iret)
        vars(1) = 'SST'
        ivars(1,1) = 0
        ivars(2,1) = 99
        lvars(1) = 'sea surface temperature'
        units(1) = 'Celsius'
        call writectl('ssmi_sst.ctl','ssmi_sst.grd',nx,xx,ny,yy,1,zz,
     +        nrec,366,yrbeg,1,3e33,'Microwave OI SST Data',1,vars,ivars
     +        ,lvars,units)

        end
