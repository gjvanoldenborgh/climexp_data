        program new2grads
*
*       convert Mark News grim files to GrADS
*
        implicit none
        integer i,j,mo,yr,ival(12,1901:2000),ivalclim(12),nn(12)
        real field(720,360,12,1901:2000)
        logical clim,climold,lwrite
        character file*255,line*80,type*3
        integer iargc,llen
        external iargc,llen
*
        lwrite = .false.
        call getarg(1,file)
        if ( file.eq.' ' ) then
            write(0,*) 'give input file name as argument 1'
            call abort
        endif
        open(1,file=file,status='old')
        type = file(llen(file)-2:)
*
*       init
        do yr=1901,2000
            do mo=1,12
                do j=1,360
                    do i=1,720
                        field(i,j,mo,yr) = 3e33
                    enddo
                enddo
            enddo
        enddo
*
*       skip header
        do i=1,5
            read(1,'(a)') line
        enddo
 100    continue
        read(1,'(a)',end=800) line
        if ( line(1:9).ne.'Grid-ref=' ) then
            write(0,*) 'error: expecting ''Grid-ref='', found ',line
            call abort
        endif
        read(line(10:),*) i,j
        do mo=1,12
            ivalclim(mo) = -999
            nn(mo) = 0
        enddo
        do yr=1901,2000
            read(1,'(12i5)') (ival(mo,yr),mo=1,12)
        enddo
        do yr=1902,2000
            clim = .true.
            do mo=1,12
                if ( ival(mo,yr).ne.ival(mo,yr-1) ) clim = .false.
            enddo
            if ( clim ) then
                if ( lwrite) print *,'found climatology ',yr
                do mo=1,12
*                   if the climatology is zero for precip and clouds, 
*                   then leave it in to avoid undefs in the desert
                    if ( (type.eq.'pre' .or. type.eq.'cld') 
     +                   .and. ival(mo,yr).eq.0 ) then
                        ivalclim(mo) = -999
                    else
                        ivalclim(mo) = ival(mo,yr)
                    endif
                enddo
                goto 200
            endif
        enddo
 200    continue
        do yr=1901,2000
            do mo=1,12
                if ( ival(mo,yr).ne.ivalclim(mo) .and. 
     +               ival(mo,yr).ne.-999 ) then
                    if ( lwrite) print *,'reading year,mo ',yr,mo
                    nn(mo) = nn(mo) + 1
                    field(i,j,mo,yr) = 0.1*ival(mo,yr)
                endif
            enddo
        enddo
        print '(14i4)',i,j,nn
        goto 100
 800    continue
        close(1)
*
*       write data
        print *,'writing eastern hemisphere'
        call writedata(1,field,type)
        print *,'writing western hemisphere'
        call writedata(2,field,type)
        end

        subroutine writedata(ii,field,type)
        implicit none
#include "recfac.h"
        integer ii
        real field(720,360,12,1901:2000)
        character type*3
        integer i,j,mo,yr,irec
        character file*255
        integer llen
        external llen
*
        if ( ii.eq.1 ) then
            file = 'cru2_'//type//'_eh.dat'
            open(1,file=file,access='direct',recl=recfa4*440*360)
        else
            file = 'cru2_'//type//'_wh.dat'
            open(1,file=file,access='direct',recl=recfa4*280*360)
        endif
        irec = 0
        do yr=1901,2000
            do mo=1,12
                irec = irec + 1
                if ( ii.eq.1 ) then
                    write(1,rec=irec) ((field(i,j,mo,yr),i=301,720),
     +                   (field(i,j,mo,yr),i=1,20),j=1,360)
                else
                    write(1,rec=irec) ((field(i,j,mo,yr),i=21,300),
     +                   j=1,360)
                endif
            enddo
        enddo
        close(1)
        if ( ii.eq.1 ) then
            open(1,file='cru2_'//type//'_eh.ctl')
        else
            open(1,file='cru2_'//type//'_wh.ctl')
        endif
        write(1,'(3a)') 'DSET ^',file(1:llen(file))
        write(1,'(3a)') 'TITLE New ',type,' dataset'
        write(1,'(a)') 'UNDEF 3e33'
        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
        if ( ii.eq.1 ) then
            write(1,'(a)') 'XDEF 440 LINEAR -29.75 0.5'
        else
            write(1,'(a)') 'XDEF 280 LINEAR -169.75 0.5'
        endif
        write(1,'(a)') 'YDEF 360 LINEAR -89.75 0.5'
        write(1,'(a)') 'ZDEF   1 LINEAR 0 1'
        write(1,'(a)') 'TDEF 1200 LINEAR 15JAN1901 1MO'
        write(1,'(a)') 'VARS 1'
        if ( type.eq.'pre' ) then
            write(1,'(a)') 'pre 0 1 precipitation [mm/month]'
        elseif ( type.eq.'tmp' ) then
            write(1,'(a)') 'tmp 0 1 near-surface temperature [C]'
        elseif ( type.eq.'cld' ) then
            write(1,'(a)') 'cld 0 1 cloud fraction'
        else
            write(0,*) 'unknown type ',type
            call abort
        endif
        write(1,'(a)') 'ENDVARS'
        end
