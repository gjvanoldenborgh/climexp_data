        program file2dat
*
*       convert the GPCP data into GrADS
*
        implicit none
#include "recfac.h"
        integer yr,mo,i,j,irec,jrec
        CHARACTER*80    keywd (50), value (50)
        INTEGER         neq   (50), kstrt (50), nvend (50)
        INTEGER         iret, l_header, ipt, in, numkey, mowithdata
        real data(144,72,12)
        character file*18,header*576

        open(2,file='gpcp_22.grd',form='unformatted',access='direct',
     +        recl=144*72*recfa4*12)
        irec = 0
        do yr=1979,2020
            write(file,'(a,i4)') 'gpcp_v2.2_psg.',yr
            write(*,*) 'opening ',file
            open(1,file=file,form='unformatted',access='direct',
     +            recl=144*recfa4,status='old',err=800)
            jrec=1
            read(1,rec=jrec) header
            if ( irec.eq.0 ) then
*       
*       copied from V2.doc
*
                DO  10 i = 1, 576
                    IF  ( header (577-i:577-i) .NE. ' ' )  GO TO 20
   10           CONTINUE
                WRITE (*, *) 'Error: found no non-blanks in the header'
                STOP
   20           l_header = 577 - i
C
C       Parse for "=".
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
   30           CONTINUE
                WRITE (*, *)
     +                'Error: ran through header without ending parsing'
                STOP
   40           CONTINUE
                numkey = i - 1
C
C       Now find corresponding beginning of each keyword by parsing 
C       backwards for " ".  The first automatically starts at 1.  We 
C       assume that there are at least 2 keywords!
C
                kstrt (1) = 1
                DO  60 i = 2, numkey
                    DO  50 j = 1, neq (i) - 1
                        IF  ( header (neq(i)-j:neq(i)-j) .EQ. ' ' )  GO
     +                        TO 55
   50               CONTINUE
   55               kstrt (i) = neq (i) - j + 1
   60           CONTINUE
C       
C       The end of the value string is the 2nd character before the start
C       of the next keyword, except the last is at l_header.
C
                DO  70 i = 1, numkey - 1
                    nvend (i) = kstrt (i+1) - 2
   70           CONTINUE
                nvend (numkey) = l_header
C       
C       Now use these indices to load the arrays.  We assume that null
C       strings will not be encountered.
C
                DO  80 i = 1, numkey
                    keywd (i) = header (kstrt(i):neq(i)-1)
                    value (i) = header (neq(i)+1:nvend(i))
   80           CONTINUE
C       
C       Now there are "numkey" keywords with corresponding values ready 
C       to be manipulated, printed, etc.  For example, print them:
C
                DO  85 i = 1, numkey
                    WRITE (*, *) '"', keywd (i) (1:neq(i)-kstrt(i)),
     +                    '" = "',value (i) (1:nvend(i)-neq(i)), '"'
   85           CONTINUE
                
            endif
            mowithdata = 0
            do mo=1,12
                do j=1,72
                    jrec = jrec + 1
                    read(1,rec=jrec) (data(i,j,mo),i=1,144)
                    call swapbyte4(data(1,j,mo),144)
                    do i=1,144
                        !!!print *,i,j,mo,yr,data(i,j,mo)
                        if ( data(i,j,mo).lt.0 ) then
                            if ( abs(data(i,j,mo)+99999).gt.0.1 ) then
                                write(0,*)
     +                                'error: found negative value '
     +                                ,data(i,j,mo),i,j,mo,yr
                            endif
                            data(i,j,mo) = 3e33
                        else
                            mowithdata = mo
                        endif
                    enddo
                enddo
            enddo
            irec = irec + 1
            write(2,rec=irec) (((data(i,j,mo),i=1,144),j=72,1,-1),
     +           mo=1,12)
            close(1)
        enddo
  800   continue
        close(2)
        open(2,file='gpcp_22.ctl')
        write(2,'(a)') 'DSET ^gpcp_22.grd'
        do i=1,numkey
            if ( keywd(i).eq.'title' ) then
                write(2,'(2a)') 'TITLE ',value(i)
            endif
        enddo
        write(2,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(2,'(a)') 'UNDEF 3e33'
        write(2,'(a)') 'XDEF 144 LINEAR 1.25 2.5'
        write(2,'(a)') 'YDEF  72 LINEAR -88.75 2.5'
        write(2,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(2,'(a,i4,a)') 'TDEF ',12*(irec-1) + mowithdata,
     +       ' LINEAR 15JAN1979 1MO'
        write(2,'(a)') 'VARS 1'
        write(2,'(a)') 'prcp 1 0 precipitation [mm/day]'
        write(2,'(a)') 'ENDVARS'
        close(2)
        end
