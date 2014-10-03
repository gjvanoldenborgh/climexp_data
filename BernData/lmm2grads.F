        program lmm2grads
*
*       proglet to make a GrADS data file out of Juerg's lmm.dat
*
        implicit none
#include "recfac.h"
        integer i,j,yr,mo,irec,yr1,mo1,firstyr,firstmo,icycle
        real data(12,8)
        character line*128
*
        open(1,file='lmm.dat',status='old')
        do icycle=1,2
           if ( icycle.eq.1 ) then
              do i=1,1000
                 read(1,'(a)') line
                 if ( line(1:1).eq.'1' ) goto 100
              enddo
 100          continue
              read(line,*) i
              open(2,file='slp_mm.dat',form='unformatted',access
     $             ='direct',recl=12*8*recfa4)
           else
              open(2,file='slp_mm_1.dat',form='unformatted',access
     $             ='direct',recl=12*8*recfa4)
           endif
           irec = 0
*     
           if ( i.lt.100000 ) then
              yr1 = i/10
              mo1 = mod(i,10)
           else
              yr1 = i/100
              mo1 = mod(i,100)
           endif
           firstyr = yr1
           firstmo = mo1
 200       continue
           read(1,*) data
           irec = irec + 1
           write(2,rec=irec) data
           print *,yr,mo,irec
           mo1 = mo1 + 1
           if ( mo1.gt.12 ) then
              mo1 = mo1 - 12
              yr1 = yr1 + 1
           endif
           read(1,*,end=800) i
           if ( i.lt.100000 ) then
              yr = i/10
              mo = mod(i,10)
           else
              yr = i/100
              mo = mod(i,100)
           endif
           if ( yr.ne.yr1 .or. mo.ne.mo1 ) then
              if ( icycle.ne.1 ) then
                 write(0,*) 'error: dates do not agree',i,yr1,mo1
                 call abort
              else
                 goto 800
              endif
           endif
           goto 200
*       
 800       continue
           close(2)
           if ( icycle.eq.1 ) then
              open(3,file='slp_mm.ctl')
              write(3,'(a)') 'DSET ^slp_mm.dat'
              write(3,'(a)')
     +             'TITLE Luterbacher Maunder Minimum SLP '//
     +             'reconstruction'
           else
              open(3,file='slp_mm_1.ctl')
              write(3,'(a)') 'DSET ^slp_mm_1.dat'
              write(3,'(a)')
     +             'TITLE Luterbacher Recent Years SLP reconstruction'
           endif
           write(3,'(a)') 'UNDEF 3e33'
#if defined(sun) || defined(__sun__) || defined (__NeXT__) || defined (__sgi)
           write(3,'(a)') 'OPTIONS YREV BIG_ENDIAN'
#elif defined(__alpha) || defined(linux)
           write(3,'(a)') 'OPTIONS YREV LITTLE_ENDIAN'
#else
           write(3,'(a)') 'OPTIONS YREV'
#endif
           write(3,'(a)') 'XDEF 12 LINEAR -25 5'
           write(3,'(a)') 'YDEF  8 LINEAR  35 5'
           write(3,'(a)') 'ZDEF  1 LINEAR   0 1'
           if ( firstmo.ne.1 ) then
              write(0,*)
     +             'error: can only handle fields starting in January'
              call abort
           endif
           write(3,'(a,i4,a,i4.4,a)') 'TDEF ',irec,' LINEAR 15JAN'
     $          ,firstyr,' 1MO'
           write(3,'(a)') 'VARS 1'
           write(3,'(a)') 'slp 0 99 sea level pressure'
           write(3,'(a)') 'ENDVARS'
           close(3)
        enddo
        close(1)
        end
