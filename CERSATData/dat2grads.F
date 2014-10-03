      program grad2dats
*
*     convert the CERSAT data format to GrADS
*     format: bytestream with (x,y,u,v) quadruplets, big_endian
*
      implicit none
#include "recfac.inc"
      integer i,j,yr,mo,irec,x,y
      integer*2 x2,y2,u2,v2
      real uu(360,160,12,1991:2000),vv(360,160,12,1991:2000)
      character file*17
      character type*4
      integer iargc
      external iargc, getarg
*
      if ( iargc().ne.1 ) then
         print *,'usage: dat2grads [wind|strs]'
         stop
      endif
      call getarg(1,type)
*
      do yr=1991,2000
         do mo=1,12
*
*           put to undefined
*
            do j=1,160
               do i=1,360
                  uu(i,j,mo,yr) = 3e33
                  vv(i,j,mo,yr) = 3e33
               enddo
            enddo
*
*           open file
*
            if ( yr.le.1991 .and. mo.lt. 9 ) goto 801
            if ( yr.lt.1996 .or. yr.eq.1996 .and. mo.le.5 ) then
*              ERS-1
               write(file,'(2a,3i2.2,a)') type,'/M1',mod(yr,100),mo,1
     $              ,'.DAT'
            else
*              ERS-2
               write(file,'(2a,3i2.2,a)') type,'/M2',mod(yr,100),mo,1
     $              ,'.DAT'
            endif
            open(1,file=file,form='unformatted',access='direct',
     $           recl=2*recfa4,status='old',err=800)
            print *,'Opened ',file
            irec = 0
            do j=1,160
               do i=1,360
                  irec = irec + 1
*                 note that the order has been swapped by my 4-byte-swapping
                  read(1,rec=irec) x2,y2,v2,u2
                  x = x2
                  if ( x.lt.0 ) x = x + 2**16
                  y = y2
                  if ( abs(x/100.+0.5-i).gt.0.01 ) then
                     print *,'x wrong: ',x2,x,i
                     call abort
                  endif
                  if ( abs(y/100.+80.50-j).gt.0.01 ) then
                     print *,'y wrong: ',y2,y,j
                     call abort
                  endif
                  if ( type.eq.'wind' ) then
                     if ( u2.lt.30000 ) uu(i,j,mo,yr) = real(u2)/100
                     if ( v2.lt.30000 ) vv(i,j,mo,yr) = real(v2)/100
                  elseif ( type.eq.'strs' ) then
                     if ( u2.lt.30000 ) uu(i,j,mo,yr) = real(u2)/1000
                     if ( v2.lt.30000 ) vv(i,j,mo,yr) = real(v2)/1000
                  else
                     write(0,*) 'unknow type ',type
                     call abort
                  endif
               enddo
            enddo
            goto 801
 800        continue
            print *,'could not open ',file
 801        continue
            close(1)
         enddo
      enddo
      open(2,file='ers'//type//'u.dat',form='unformatted',access
     $     ='direct',recl=360*160*recfa4)
      open(3,file='ers'//type//'v.dat',form='unformatted',access
     $     ='direct',recl=360*160*recfa4)
      irec = 0
      do yr=1991,2000
         do mo=1,12
            irec = irec + 1
            write(2,rec=irec) ((uu(i,j,mo,yr),i=1,360),j=1,160)
            write(3,rec=irec) ((vv(i,j,mo,yr),i=1,360),j=1,160)
         enddo
      enddo
      close(2)
      close(3)
      end
