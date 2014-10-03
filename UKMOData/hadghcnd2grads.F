        program hadghcnd2grads
*
*       convert the UKMO HadGHCND files to GrADS format
*
        implicit none
#include "recfac.h"
        integer yrbeg,yrend,nx,ny
        parameter (yrbeg=1946,yrend=2000,nx=96,ny=73)
        integer yr,dy,i,j,yr1,dy1,ndy,irec,retval
        real data(nx,ny),dat(nx)
        character type*2,utype*2,lvar*40,line*255,file*255
        integer leap

        call getarg(1,type)
        if ( type.ne.'tx' .and. type.ne.'tn' ) then
            write(0,*) 'usage: hadghcnd tx|tn'
            stop
        endif

        open(10,file='hadghcnd_'//type//'.ctl')
        open(11,file='hadghcnd_'//type//'.dat',access='direct',
     +       form='unformatted',recl=recfa4*nx*ny)
        irec = 0

        if ( type.eq.'tx' ) then
            utype='TX'
            lvar='maximum temperature'
        elseif ( type.eq.'tn' ) then
            utype = 'TN'
            lvar='minimum temperature'
        endif

        do yr1=yrbeg,yrend
            if ( yr1.eq.1946 ) then
                file='HadGHCND_'//utype//'_1946-1950_acts.txt'
            elseif ( mod(yr1,10).eq.1 ) then
                close(1,status='delete')
                write(file,'(3a,i4,a,i4,a)') 'HadGHCND_',utype,'_',yr1
     +               ,'-',yr1+9,'_acts.txt'
            else
                file=' '
            endif
            if ( file.ne.' ' ) then
                print *,trim(file)
                call mysystem('gunzip -c HadGHCND_'//utype//'_acts/'
     +               //trim(file)//'.gz > /tmp/'//file,retval)
                open(1,file='/tmp/'//trim(file),status='old')
                read(1,'(a)') line
            endif
            if ( leap(yr1).eq.1 ) then
                ndy = 365
            else
                ndy=366
            endif
            do dy1=1,ndy
                read(1,'(2i4)',end=900) yr,dy
                if ( dy.ne.dy1 .or. yr.ne.yr1 ) then
                    write(0,*) 'error: date wrong: ',dy,yr,dy1,yr1
                    call abort
                endif
                do j=ny,1,-1
                    read(1,'(10000(f9.3))') dat
                    do i=1,nx
                        if ( dat(i).ne.-999.99 )
     +                       then
                            data(i,j) = dat(i)
                        else
                            data(i,j) = 3e33
                        endif
                    enddo
                enddo
                irec = irec + 1
                write(11,rec=irec) data
            enddo               ! mo1
        enddo                   ! yr1
        close(1,status='delete')

        write(10,'(a)') 'DSET ^hadghcnd_'//type//'.dat'
        write(10,'(a)') 'TITLE '//trim(line)
        write(10,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(10,'(a)') 'UNDEF 3e33'
        write(10,'(a,i3,a,2f7.2)') 'XDEF ',nx,' LINEAR ',0.,360./nx
        write(10,'(a,i3,a,2f7.2)') 'YDEF ',ny,' LINEAR ',-90.,
     +       180./(ny-1)
        write(10,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(10,'(a,i5,a)') 'TDEF ',irec,' LINEAR 01JAN1946 1DY'
        write(10,'(a)') 'VARS 1'
        write(10,'(4a)') utype,' 1 99 ',trim(lvar),' [C]'
        write(10,'(a)') 'ENDVARS'
        goto 999
 900    continue
        write(0,*) 'error: reached end of file on ',trim(file)
        write(0,*) '       yr,dy = ',yr1,dy1
 999    continue
        end
