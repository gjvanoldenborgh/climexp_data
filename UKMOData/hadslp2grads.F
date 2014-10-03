        program asc2dat
*
*       trivial program to convert the ASCII file into a GrADS dat file
*
        implicit none
#include "recfac.h"
        integer i,j,k,mo,yr,nrec,ifile
        integer ifield(72,37)
        real field(72,37)
        character format*6
        integer get_endian

        do ifile=1,2
            if ( ifile.eq.1 ) then
                open(1,file='hadslp2r.asc',status='old')
                open(2,file='hadslp2r.grd',form
     +               ='unformatted',access='direct',recl=recfa4*72*37)
                open(3,file='hadslp2r.ctl')
                format = '(72i8)'
            else
                open(1,file='hadslp2.0_acts.asc',status='old')
                open(2,file='hadslp2_0.grd',form
     +               ='unformatted',access='direct',recl=recfa4*72*37)
                open(3,file='hadslp2_0.ctl')
                format = '(72i8)'
            endif
            nrec = 0
        
            yr=1850
            mo=0
 100        continue
            mo = mo + 1
            if ( mo.gt.12 ) then
                mo = mo - 12
                yr = yr + 1
            endif
            read(1,*,end=800) i,j
            if ( i.ne.yr .or. mo.ne.mo ) then
                print *,'error: expected ',yr,mo,', found ',i,j
                mo = j
                yr = i
            endif
            read(1,format) ifield
            do j=1,37
                do i=1,72
                    if ( ifield(i,j).ne.-99990 ) then
                        field(i,j) = ifield(i,j)/100.
                    else
                        field(i,j) = 3e33
                    endif
                enddo
            enddo
            nrec = nrec + 1
            write(2,rec=nrec) ((field(i,j),i=1,72),j=37,1,-1)
            goto 100
 800        continue
            print *,yr,nrec
            close(1)
            close(2)
            if ( ifile.eq.1 ) then
                write(3,'(a)') 'DSET ^hadslp2r.grd'
                write(3,'(a)') 'TITLE HadSLP2 real-time '//
     +                 'interpolated observations'
            else
                write(3,'(a)') 'DSET ^hadslp2_0.grd'
                write(3,'(a)') 'TITLE HadSLP2.0 '//
     +                 'non-interpolated observations'
            endif
            if ( get_endian().eq.-1 ) then
                write(3,'(a)') 'OPTIONS LITTLE_ENDIAN'
            elseif ( get_endian().eq.+1 ) then
                write(3,'(a)') 'OPTIONS BIG_ENDIAN'
            endif
            write(3,'(a)') 'UNDEF 3e33'
            write(3,'(a)') 'XDEF 72 LINEAR -180 5'
            write(3,'(a)') 'YDEF 37 LINEAR -90 5'
            write(3,'(a)') 'ZDEF 1 LINEAR 0 1'
            write(3,'(a,i5,a)') 'TDEF ',nrec,' LINEAR 1JAN1850 1MO'
            write(3,'(a)') 'VARS 1'
            write(3,'(a)') 'slp 0 99 mean sea-level pressure [hPa]'
            write(3,'(a)') 'ENDVARS'
            close(3)
        enddo
        end
