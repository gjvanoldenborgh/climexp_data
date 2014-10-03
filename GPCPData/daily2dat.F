        program file2dat
*
*       convert the GPCP data into GrADS
*
        implicit none
#include "recfac.h"
        integer nx,ny
        parameter (nx=360,ny=180)
        integer yr,mo,dy,i,j,irec,jrec,dpm(12,2)
        CHARACTER*80    keywd (50), value (50)
        INTEGER         neq   (50), kstrt (50), nvend (50)
        INTEGER         iret, l_header, ipt, in, numkey
        real data(nx,ny)
        character file*24,header*1440,version*3
        integer leap
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31,
     +            31,29,31,30,31,30,31,31,30,31,30,31/
        call getarg(1,version)
        if ( version(2:2).ne.'.' ) then
            write(0,*) 'usage: daily2dat M.N'
            call abort
        end if
        
        open(2,file='gpcp_1dd_'//version(1:1)//version(3:3)//'.grd',
     +       form='unformatted',access='direct',recl=nx*ny*recfa4)
        irec = 0
        do yr=1997,2020
            do mo=1,12
                write(file,'(a,i4,i2.2)') 'gpcp_1dd_v'//version//
     +                '_p1d.',yr,mo
                write(*,*) 'opening ',file
                open(1,file=file,form='unformatted',access='direct',
     +               recl=nx*recfa4,status='old',err=800)
                jrec=1
                read(1,rec=jrec) header
                if ( yr.eq.1997 .and. mo.eq.1 ) then
*
*                   copied from V2.doc
*
                    DO  10 i = 1, 1440
                        IF  ( header (1440-i:1440-i) .NE. ' ' )  GO TO
     +                       20
 10                 CONTINUE
                    WRITE (*, *)
     +                   'Error: found no non-blanks in the header'
                    STOP
 20                 l_header = 1440 - i
C
C                   Parse for "=".
C
                    ipt = 1
                    DO  30 i = 1, l_header
                        in = INDEX ( header (ipt:l_header), '=' )
                        IF  ( in .EQ. 0 )  THEN
                            GO TO 40
                        ELSE
                            neq (i) = ipt + in - 1
                            ipt     = ipt + in
                        END IF
 30                 CONTINUE
                    WRITE (*, *)
     +                   'Error: ran through header without ending '//
     +                   'parsing'
                    STOP
 40                 CONTINUE
                    numkey = i - 1
C                   
C                   Now find corresponding beginning of each keyword by
C                   parsing backwards for " ".  The first automatically
C                   starts aT 1.  We assume that there are at least 2 !
C                   keywords
C
                    kstrt (1) = 1
                    DO  60 i = 2, numkey
                        DO  50 j = 1, neq (i) - 1
                            IF  ( header (neq(i)-j:neq(i)-j) .EQ. ' ' )
     +                           GOTO 55
 50                     CONTINUE
 55                     kstrt (i) = neq (i) - j + 1
 60                 CONTINUE
C               
C                   The end of the value string is the 2nd character
C                   before the start of the next keyword, except the
C                   last is at l_header.
C                   
                    DO  70 i = 1, numkey - 1
                        nvend (i) = kstrt (i+1) - 2
 70                 CONTINUE
                    nvend (numkey) = l_header
C               
C                   Now use these indices to load the arrays.  We assume
C                   that null strings will not be encountered.
C
                    DO  80 i = 1, numkey
                        keywd (i) = header (kstrt(i):neq(i)-1)
                        value (i) = header (neq(i)+1:nvend(i))
 80                 CONTINUE
C               
C                   Now there are "numkey" keywords with corresponding
C                   values ready to be manipulated, printed, etc.  For
C                   example, print them:
C                   
                    DO  85 i = 1, numkey
                        WRITE (*, *) '"', keywd (i) (1:neq(i)-kstrt(i)),
     +                       '" = "',value (i) (1:nvend(i)-neq(i)), '"'
 85                 CONTINUE
                endif
                do dy=1,dpm(mo,leap(yr))
                    do j=1,ny
                        jrec = jrec + 1
                        read(1,rec=jrec) (data(i,j),i=1,nx)
                        do i=1,nx
                            if ( data(i,j).lt.0 ) then
                                if ( abs(data(i,j)+99999).gt.0.1 )
     +                               then
                                    write(0,*)
     +                                   'error: found negative value '
     +                                   ,data(i,j),i,j,mo,yr
                                endif
                                data(i,j) = 3e33
                            endif
                        enddo
                    enddo       ! j
                    irec = irec + 1
                    write(2,rec=irec) data
                enddo ! dy
                close(1)
            enddo               ! mo
        enddo                   ! yr
  800   continue
        close(2)
        open(2,file='gpcp_1dd_'//version(1:1)//version(3:3)//'.ctl')
        write(2,'(a)') 'DSET ^gpcp_1dd_'//version(1:1)//version(3:3)//
     +     '.grd'
        do i=1,numkey
            if ( keywd(i).eq.'title' ) then
                write(2,'(2a)') 'TITLE ',trim(value(i))
            endif
        enddo
        write(2,'(a)') 'OPTIONS BIG_ENDIAN YREV'
        write(2,'(a)') 'UNDEF 3e33'
        write(2,'(a,i3,a)') 'XDEF ',nx,' LINEAR 0.5 1'
        write(2,'(a,i3,a)') 'YDEF ',ny,' LINEAR -89.5 1'
        write(2,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(2,'(a,i6,a)') 'TDEF ',irec,' LINEAR 01JAN1997 1DY'
        write(2,'(a)') 'VARS 1'
        write(2,'(a)') 'prcp 1 0 precipitation [mm/day]'
        write(2,'(a)') 'ENDVARS'
        close(2)
        end

	integer function leap(yr)
	implicit none
	integer yr
	if ( mod(yr,4).ne.0 ) then
	    leap = 1
	elseif ( mod(yr,100).ne.0 ) then
	    leap = 2
	elseif ( mod(yr,400).ne.0 ) then
	    leap = 1
	else	
	    leap = 2
	endif
	end
