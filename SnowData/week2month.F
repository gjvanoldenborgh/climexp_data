        program week2month
*
*       convert the weekly 2x2 grads files into monthly 2x2 grads files 
*       for use in the Climate Explorer
*
        implicit none
#include "recfac.h"
        integer ie,je,isyr,ieyr
        parameter(ie=180,je=45)
        parameter(isyr=1972,ieyr=2020)
        integer yr,mo,dy,dpm(12,2),kweeks(ieyr-isyr+1)
        integer i,j,irec,jrec,leap,nday,iday
        logical opened
        character file*7
        real wkfield(ie,je),mofield(ie,je)
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31,
     +            31,29,31,30,31,30,31,31,30,31,30,31/
C..                 72 73 74 75 76 77 78 79 80 81 82 83
C..                 84 85 86 87 88 89 90 91 92 93 94
C..                 95 96 97 98 99 00 01 02 03 04 05
C..                 06 07 08 09 10 11 12 13 14 15 16
C..                 17 18 29 20
        data kweeks/52,52,52,52,53,52,52,52,52,53,52,52,
     *              52,52,52,53,52,52,52,52,53,52,52,
     *              52,52,52,53,52,52,52,52,52,53,52,
     +              52,52,52,53,52,52,52,52,52,53,52,
     +              52,52,52,53/
*
        open(2,file='nhsnow.grd',form='unformatted',
     +        access='direct',recl=ie*je*recfa4)
        jrec = 0
        dy = 3
        mo = 1
        yr = 1972
        leap = 2
        opened = .FALSE.
        nday = 0
        do j=1,je
            do i=1,ie
                mofield(i,j) = 0
            enddo
        enddo
  100   continue
*       
*       open input file
*
        if ( .not.opened ) then
            if ( mo.eq.1 ) then
                write(file,'(a,i4.4)') 'grd',yr
            elseif ( mo.eq.12 ) then
                write(file,'(a,i4.4)') 'grd',yr+1
            else
                print *,'error: opening new file on month ',mo
                stop
            endif
            print *,'opening file ',file
            open(1,file=file,form='unformatted',status='old',
     +            access='direct',recl=ie*je*recfa4,err=800)
            irec = 0
            opened = .TRUE.
        endif
*
*       read data
*
        irec = irec + 1
        if ( irec.le.kweeks(yr-1971) ) then
            print *,'reading week ',irec
            read(1,rec=irec,err=800) wkfield
        else
            print *,'read ',irec-1,' weeks for ',yr,' at ',yr,mo,dy
            close(1)
            opened = .FALSE.
            if ( irec.gt.50 ) then
                goto 100
            else
                goto 800
            endif
        endif
*
*       update date
*
        dy = dy + 7
        if ( dy.gt.dpm(mo,leap) ) then
            dy = dy - dpm(mo,leap)
	    mo = mo + 1
	    iday = 7 - dy + 1
            if ( mo.gt.12 ) then
                mo = mo - 12
                yr = yr + 1
                if ( mod(yr,4).eq.0 ) then
                    leap = 2
                else
                    leap = 1
                endif
            endif
        else
	    iday = 7
        endif
        nday = nday + iday
        do j=1,je
            do i=1,ie
                mofield(i,j) = mofield(i,j) + iday*wkfield(i,j)
            enddo
        enddo
*
*       save month file, start new one
*
        if ( dy.le.7 ) then
            do j=1,je
                do i=1,ie
                    mofield(i,j) = mofield(i,j)/nday
                enddo
            enddo
            print *,'wrote ',nday,'-day month before ',yr,mo,dy
            jrec = jrec + 1
            write(2,rec=jrec) mofield
            iday = 7 - iday
            nday = iday
            do j=1,je
                do i=1,ie
                    mofield(i,j) = iday*wkfield(i,j)
                enddo
            enddo
        endif
*
*       next week
*
        goto 100
*
*       finish loose ends
*
  800   continue
        if ( nday.gt.20 ) then
            print *,'wrote ',nday,'-day last month'
            do j=1,je
                do i=1,ie
                    mofield(i,j) = mofield(i,j)/nday
                enddo
            enddo
            jrec = jrec + 1
            write(2,rec=jrec) mofield
        endif
        close(2)
*
*       write metadata
*
        open(2,file='nhsnow.ctl')
        write(2,'(a)') 'DSET ^nhsnow.grd'
        write(2,'(a)') 'TITLE CPC snow cover'
        write(2,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(2,'(a)') 'UNDEF 3e33'
        write(2,'(a)') 'XDEF 180 LINEAR 0 2'
        write(2,'(a)') 'YDEF  45 LINEAR 0 2'
        write(2,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(2,'(a,i5,a)') 'TDEF ',jrec,' LINEAR 15JAN1972 1MO'
        write(2,'(a)') 'VARS 1'
        write(2,'(a)') 'snow 1 99 snowcover [1]'
        write(2,'(a)') 'ENDVARS'
        close(2)
        end
