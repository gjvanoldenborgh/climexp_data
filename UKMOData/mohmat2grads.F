        program mohmat2grads
*
*       convert the UKMO MOHMAT files to GrADS format
*
        implicit none
#include "recfac.h"
        integer yrbeg,yrend,nx,ny
        parameter (yrbeg=1856,yrend=2020,nx=360/5,ny=180/5)
        integer yr,mo,dy,i,j,yr1,mo1,idat(nx),irec
        real data(nx,ny),clim(nx,ny)
        logical anom
        character arg*20
        
        call getarg(1,arg)
        if ( arg(1:4).eq.'anom' ) then
            anom = .true.
        else
            anom = .false.
        end if
        
        if ( anom ) then
            open(10,file='mohmat43a.ctl')
            open(11,file='mohmat43a.grd',access='direct',
     +           form='unformatted',recl=recfa4*nx*ny)
            irec = 0
        else
            open(10,file='mohmat43.ctl')
            open(11,file='mohmat43.grd',access='direct',
     +           form='unformatted',recl=recfa4*nx*ny)
            irec = 0
        end if

        if ( anom ) then
            clim = 0
        else
            open(1,file='MOHMAT43_climatology.txt',status='old')
            do mo1=1,12
                read(1,'(3i6)') dy,mo,yr
                if ( mo.ne.mo1 .or. yr.ne.1961 ) then
                    write(0,*) 'error: climatology wrong: ',dy,mo,yr
                    call abort
                endif
                do j=ny,1,-1
                    read(1,'(10000(i6))') idat
                    do i=1,nx
                        if ( idat(i).ne.-32768 ) then
                            clim(i,j) = idat(i)/100.
                        else
                            clim(i,j) = 3e33
                        endif
                    enddo
                enddo
            enddo
            close(1)
        end if

        do yr1=yrbeg,yrend
            if ( yr1.eq.1856 ) then
                print *,'opening MOHMAT43_1856-99.txt'
                open(1,file='MOHMAT43_1856-99.txt',status='old')
            elseif ( yr1.eq.1900 ) then
                close(1)
                print *,'opening MOHMAT43_1900-49.txt'
                open(1,file='MOHMAT43_1900-49.txt',status='old')
            elseif ( yr1.eq.1950 ) then
                close(1)
                print *,'opening MOHMAT43_1950-99.txt'
                open(1,file='MOHMAT43_1950-99.txt',status='old')
            elseif ( yr1.eq.2000 ) then
                close(1)
                print *,'opening MOHMAT43_2000+.txt'
                open(1,file='MOHMAT43_2000+.txt',status='old')
            endif
            do mo1=1,12
                read(1,'(3i6)',end=800) dy,mo,yr
                if ( mo.ne.mo1 .or. yr.ne.yr1 ) then
                    write(0,*) 'error: date wrong: ',dy,mo,yr,mo1,yr1
                    call abort
                endif
                do j=ny,1,-1
                    read(1,'(10000(i6))') idat
                    do i=1,nx
                        if ( idat(i).ne.-32768 .and. clim(i,j).ne.3e33 )
     +                       then
                            data(i,j) = idat(i)/100. + clim(i,j)
                        else
                            data(i,j) = 3e33
                        endif
                    enddo
                enddo
                irec = irec + 1
                write(11,rec=irec) data
            enddo               ! mo1
        enddo                   ! yr1

 800    continue
        mo1 = mo1 - 1
        if ( mo1.eq.0 ) then
            mo1 = 12
            yr1 = yr1 - 1
        endif
        if ( anom ) then
            write(10,'(a)') 'DSET ^mohmat43a.grd'
            write(10,'(a)') 'TITLE UKMO Historical Marine Air '//
     +           'Temperature MOHMAT 4.3 anomalies'
        else
            write(10,'(a)') 'DSET ^mohmat43.grd'
            write(10,'(a)') 'TITLE UKMO Historical Marine Air '//
     +           'Temperature MOHMAT 4.3 anomalies+climatology'
        end if
        write(10,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(10,'(a)') 'UNDEF 3e33'
        write(10,'(a,i3,a,2f7.2)') 'XDEF ',nx,' LINEAR ',-180+360./nx/2
     +       ,360./nx
        write(10,'(a,i3,a,2f7.2)') 'YDEF ',ny,' LINEAR ',-90+180./ny/2
     +       ,180./ny
        write(10,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(10,'(a,i5,a)') 'TDEF ',irec,' LINEAR 15JAN1856 1MO'
        write(10,'(a)') 'VARS 1'
        write(10,'(a)') 'Tair 1 99 Air Temperature [C]'
        write(10,'(a)') 'ENDVARS'
        end
