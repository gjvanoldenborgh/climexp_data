        program oi2grads
*
*       convert the NCEP OI data to GrADS files
*       based on the example in the file oimonth.info
*                        Geert Jan van Oldenborgh, KNMI, nov-2000
*
        implicit none
#include "recfac.h"
        integer i,j,yr,iyrst,imst,idst,iyrend,imend,idend,ndays,index
     +        ,imon,irec,iyr1,imn1
        real sst(360,180)
        integer*2 ISST(360,180)
        integer ls(360,180)
        character cyr*4,months(12)*3
        data months /
     +        'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG'
     +        ,'SEP','OCT','NOV','DEC'/
*
        open(4,file='ls.dat',status='old')
        read (4,53) ls
   53   format (80i1)
        close(4)

        open(2,file='sstoi.dat',form='unformatted',access='direct',recl
     +        =360*180*recfa4)
        irec = 0
*       
        iyr1 = 1981
        do j=1,180
            do i=1,360
                sst(i,j) = 3e33
            enddo
        enddo
        do imon=1,10
            irec = irec + 1
            write(2,rec=irec) sst
        enddo
        do yr=iyr1,2020
            write(cyr,'(i4)') yr
            open (1,file='oi.month.comp.bias.'//cyr,form='unformatted'
     +            ,status='old',err=800)
  200       continue
            read(1,end=100) 
     1            iyrst,imst,idst,iyrend,imend,idend,ndays,index
            if ( iyrst.ne.mod(yr,100) .or. imst.ne.imon ) then
                write(0,*) 'error in dates ',yr,imon,iyrst,imst
                call abort
            endif
            read(1) ((isst(i,j),i=1,360),j=1,180)
            do i=1,360
                do j=1,180
                    sst(i,j) = 0.01*float(ls(i,j)*isst(i,j)) + 
     +                    3e33*(1-ls(i,j))
                enddo
            enddo
c Print date info and SST at one location for each month      
            print 7,imon,
     1            iyrst,imst,idst,iyrend,imend,idend,sst(70,80)
    7       format ('IMON =',I3,3X,'DATES =',3I3,' - ',3I3,3X,
     1            'SST (110.5W,10.5S) =',F6.2)
            imon = imon + 1
            irec = irec + 1
            write(2,rec=irec) sst
            goto 200
  100       continue
            imon = 1
            close(1)
        enddo
  800   continue
        close(2)

        open(1,file='sstoi.ctl')
        write(1,'(a)') 'DSET ^sstoi.dat'
        write(1,'(a)') 'TITLE Reynolds OI SST'
        write(1,'(a)') 'UNDEF 3e33'
#if defined(sun) || defined(__sun__) || defined (__NeXT__) || defined (__sgi)
        write(1,'(a)') 'OPTIONS BIG_ENDIAN'
#elif defined(__alpha) || defined(linux)
        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
#endif
        write(1,'(a)') 'XDEF 360 LINEAR -179.5 1'
        write(1,'(a)') 'YDEF 180 LINEAR -89.5 1'
        write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(1,'(a,i4,2a,i4,a)') 'TDEF ',irec,' LINEAR 15',months(1)
     +        ,iyr1,' 1MO'
        write(1,'(a)') 'VARS 1'
        write(1,'(a)') 'sst 0 99 Reynolds OI SST'
        write(1,'(a)') 'ENDVARS'
        close(1)
        end
