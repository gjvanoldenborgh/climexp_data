        program oi2grads
*
*       convert the NCEP v2 OI data to GrADS files
*       based on the example in the file README
*                        Geert Jan van Oldenborgh, KNMI, nov-2000
*
        implicit none
#include "recfac.h"
        integer i,j,yr,mo,iyrst,imst,idst,iyrend,imend,idend,ndays,index
     +        ,irec,iyr1,imn1,dy,jul,decade
        real sst(360,180),ls(360,180),ice(360,180)
        character cyyyymm*6,months(12)*3,file*14,cice(360,180)*1
        logical lexist,lgzip,lafter
	integer julday
	external julday
        data months /
     +        'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG'
     +        ,'SEP','OCT','NOV','DEC'/
*
        open(4,file='lstags.onedeg.dat',form='unformatted',
     +        access='direct',recl=360*180*recfa4,status='old')
        read (4,rec=1) ls
        close(4)

	do decade=1,2
	if ( decade.eq.1 ) then
        open(2,file='sstoi_v2_week1.dat',form='unformatted',
     +		access='direct',recl=360*180*recfa4)
***        open(3,file='iceoi_v2_week1.dat',form='unformatted',
***     +		access='direct',recl=360*180*recfa4)
        jul = julday(11,1,1981)
	else
        open(2,file='sstoi_v2_week2.dat',form='unformatted',
     +		access='direct',recl=360*180*recfa4)
***        open(3,file='iceoi_v2_week2.dat',form='unformatted',
***     +		access='direct',recl=360*180*recfa4)
        jul = julday(1,3,1990)
	endif
        irec = 0
*       
        lafter = .false.
  100	continue
	call caldat(jul,mo,dy,yr)
	write(file,'(a,i4,2i2.2)') 'oisst.',yr,mo,dy
        inquire(file=file,exist=lexist)
        if ( .not.lexist ) then
            inquire(file=file//'.gz',exist=lexist)
            if ( .not.lexist ) then
                print *,'cannot find ',file
                if ( lafter ) goto 800
                do j=1,180
                    do i=1,360
                        sst(i,j) = 3e33
                    enddo
                enddo
                irec = irec + 1
                write(2,rec=irec) sst
***                write(3,rec=irec) sst
                goto 700
            else
                lgzip = .true.
***                print *,'gunzip -c '//file//'.gz > '//file
                call system('gunzip -c '//file//'.gz > '//file)
            endif
        else
            lgzip = .false.
        endif
        lafter = .true.
        open (1,file=file,form='unformatted',status='old')
        read(1) iyrst,imst,idst,iyrend,imend,idend,ndays,index
***        if ( iyrst.ne.yr .or. imst.ne.mo ) then
***             write(0,*) 'error in dates ',yr,mo,dy,iyrst,imst
***             call abort
***        endif
        read(1) ((sst(i,j),i=1,360),j=1,180)
        read(1) ((cice(i,j),i=1,360),j=1,180)
c       Print date info and SST at one location for each month      
        print 7,iyrst,imst,idst,iyrend,imend,idend,sst(70,80)
    7   format ('DATES =',i4,2I2.2,' - ',I4,2i2.2
     +                ,3X,'SST (110.5W,10.5S) =',F6.2)
        do j=1,180
            do i=1,360
                if ( ls(i,j).eq.0 ) then
                    sst(i,j) = 3e33
                endif
            enddo
        enddo
        do j=1,180
            do i=1,360
                if ( ichar(cice(i,j)).eq.122 ) then
                    ice(i,j) = 3e33
                else
                    ice(i,j) = ichar(cice(i,j))
                endif
            enddo
        enddo
        irec = irec + 1
        write(2,rec=irec) ((sst(i,j),i=1,360),j=1,180)
***        write(3,rec=irec) ((ice(i,j),i=1,360),j=1,180)
        if ( lgzip ) then
            close(1,status='delete')
        else
            close(1)
        endif
  700   continue
	jul = jul + 7
        goto 100
  800   continue
        close(2)
***        close(3)

	if ( decade.eq.1 ) then
        open(1,file='sstoi_v2_week1.ctl')
        write(1,'(a)') 'DSET ^sstoi_v2_week1.dat'
	else
        open(1,file='sstoi_v2_week2.ctl')
        write(1,'(a)') 'DSET ^sstoi_v2_week2.dat'
	endif
        write(1,'(a)') 'TITLE Reynolds OI SST'
        write(1,'(a)') 'UNDEF 3e33'
***#if defined(sun) || defined(__sun__) || defined (__NeXT__) || defined (__sgi)
        write(1,'(a)') 'OPTIONS BIG_ENDIAN'
***#elif defined(__alpha) || defined(linux)
***        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
***#endif
        write(1,'(a)') 'XDEF 360 LINEAR 0.5 1'
        write(1,'(a)') 'YDEF 180 LINEAR -89.5 1'
        write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
	if ( decade.eq.1 ) then
        write(1,'(a,i,a)') 'TDEF ',irec,' LINEAR 1NOV1981 7DY'
	else
        write(1,'(a,i,a)') 'TDEF ',irec,' LINEAR 3JAN1990 7DY'
	endif
        write(1,'(a)') 'VARS 1'
        write(1,'(a)') 'sst 0 99 Reynolds OI SST'
        write(1,'(a)') 'ENDVARS'
        close(1)
***        open(1,file='iceoi_v2_week.ctl')
***        write(1,'(a)') 'DSET ^iceoi_v2_week.dat'
***        write(1,'(a)') 'TITLE Reynolds OI SST'
***        write(1,'(a)') 'UNDEF 3e33'
******#if defined(sun) || defined(__sun__) || defined (__NeXT__) || defined (__sgi)
***        write(1,'(a)') 'OPTIONS BIG_ENDIAN'
******#elif defined(__alpha) || defined(linux)
******        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
******#endif
***        write(1,'(a)') 'XDEF 360 LINEAR 0.5 1'
***        write(1,'(a)') 'YDEF 180 LINEAR -89.5 1'
***        write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
***        write(1,'(a,i4,2a,i4,a)') 'TDEF ',irec,' LINEAR 15',months(1)
***     +        ,iyr1,' 1MO'
***        write(1,'(a)') 'VARS 1'
***        write(1,'(a)') 'ice 0 99 Reynolds OI ice cover'
***        write(1,'(a)') 'ENDVARS'
***        close(1)
	enddo
        end
