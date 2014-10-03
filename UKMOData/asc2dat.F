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

        do ifile=1,2
            if ( ifile.eq.1 ) then
                open(1,file='hadSLP1_1871-1998.asc',status='old')
                open(2,file='hadslp1.dat',status='new',form
     +               ='unformatted',access='direct',recl=recfa4*72*37)
                format = '(18i7)'
            else
                open(1,file='hadSLP1.0_1871-1998.asc',status='old')
                open(2,file='hadslp1_0.dat',status='new',form
     +               ='unformatted',access='direct',recl=recfa4*72*37)
                format = '(18i8)'
            endif
            nrec = 0
        
            yr=1871
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
            write(2,rec=nrec) field
            if ( mo.eq.12 ) print *,yr,nrec
            goto 100
 800        continue
            close(1)
            close(2)
        enddo
        end
