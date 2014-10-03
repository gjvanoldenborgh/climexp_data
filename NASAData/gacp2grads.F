        program gacp2grads
!
!       convert the GACP data from GISS to grads format
!
        implicit none
#include "recfac.h"
        integer param,yr,mo,i,j,irec,iret
        real data(360,180)
        character file*25
        integer,external :: get_endian

        do param=1,2

            if ( param.eq.1 ) then
                open(1,file='gacp_tau.grd',form='unformatted',
     +               access='direct',recl=360*180*recfa4)
            else
                open(1,file='gacp_a.grd',form='unformatted',
     +               access='direct',recl=360*180*recfa4)
            endif

            yr = 1981
            mo = 8
            irec = 0
            
 100        continue

            if ( param.eq.1 ) then
                write(file,'(2i2.2,a)') mod(yr,100),mo,'.tau.ascii.gz'
            else
                write(file,'(2i2.2,a)') mod(yr,100),mo,'.a.ascii.gz'
            endif
            print *,trim(file)
            call mysystem('gunzip -c '//trim(file)//' > /tmp/aap.txt'
     +           ,iret)
            if ( iret.ne.0 .and. yr.ge.2006 ) goto 200
            
            if ( iret.eq.0 ) then
                open(2,file='/tmp/aap.txt',status='old')
                read(2,'(i4,i3)') i,j
                if ( i.ne.yr .or. j.ne.mo ) then
                    write(0,*) 'error: expected ',yr,mo,', got ',i,j
                    call abort
                endif
                do j=180,1,-1
                    if ( param.eq.1 ) then
                        read(2,'(360f7.3)') (data(i,j),i=1,360)
                    else
                        read(2,'(360f6.2)') (data(i,j),i=1,360)
                    endif
                enddo
                close(2,status='delete')
                
                do j=1,180
                    do i=1,360
                        if ( data(i,j).eq.-1. ) data(i,j) = 3e33
                    enddo
                enddo
            else
                data = 3e33
            endif
            
            irec = irec + 1
            write(1,rec=irec) data
            
            mo = mo + 1
            if ( mo.gt.12 ) then
                mo = 1
                yr = yr + 1
            endif
            
            goto 100

 200        continue
            close(1)

            if ( param.eq.1 ) then
                open(1,file='gacp_tau.ctl')
                write(1,'(a)') 'DSET ^gacp_tau.grd'
            else
                open(1,file='gacp_a.ctl')
                write(1,'(a)') 'DSET ^gacp_a.grd'
            endif
            write(1,'(a)')
     +           'TITLE Global Aerosol Climatology (GISS/NASA)'
            if ( get_endian().eq.-1 ) then
                write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
            elseif ( get_endian().eq.+1 ) then
                write(1,'(a)') 'OPTIONS BIG_ENDIAN'
            endif
            write(1,'(a)') 'UNDEF 3e33'
            write(1,'(a)') 'XDEF 360 LINEAR -179.5 1'
            write(1,'(a)') 'YDEF 180 LINEAR -89.5 1'
            write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
            write(1,'(a,i5,a)') 'TDEF ',irec,' LINEAR 15AUG1981 1MO'
            write(1,'(a)') 'VARS 1'
            if ( param.eq.1 ) then
                write(1,'(a)')
     +               'tau 0 99 aerosol optical thickness at 550nm [1]'
            else
                write(1,'(a)')
     +               'a 0 99 Angstrom exponent [1]'
            endif
            write(1,'(a)') 'ENDVARS'
            close(1)

        end do                  ! param

        end

