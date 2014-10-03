	program grid2dat
*
*	convert the ADVICE (?) pressure data to a GrADS file
*
	implicit none
#include "recfac.h"
	integer yrbeg,yrend,x1,x2,y1,y2
	parameter(yrbeg=1780,yrend=1995,x1=-3,x2=4,y1=7,y2=14)
	integer yr,mn,x,y,n,yr1,yr2,yrin,ivars(12),irec
	real slp(x1:x2,y1:y2,12,yrbeg:yrend),vars(12),
     +		nslp(x1:x2,y1:y2,12,yrbeg:yrend)
	character string*22,ns*1,ew*1,slash*1
	integer get_endian
	external get_endian

	open(1,file='eurqual60.dat',status='old')
	open(2,file='eurqual.dat',form='unformatted',
     +		access='direct',recl=(x2-x1+1)*(y2-y1+1)*recfa4)
	open(3,file='eurqual.ctl')
*
*	initialize
*
	do yr=yrbeg,yrend
	    do mn=1,12
		do y=y1,y2
		    do x=x1,x2
			slp(x,y,mn,yr) = 3e33
			nslp(x,y,mn,yr) = 3e33
		    enddo
		enddo
	    enddo
	enddo
*
*	read in
*
  100	continue
	read(1,1000,err=900,end=800) n,yr1,yr2,string,y,ns,x,ew
 1000	format(i6,2i5,a21,i4,a1,i4,a1)
	if ( yr1.lt.yrbeg .or. yr2.gt.yrend ) then
	    write(0,*) 'error: yr1,yr2 not in yrbeg,yrend: ',
     +		yr1,yr2,yrbeg,yrend
	    call abort
	endif
	y = y/5
	x = x/10
	if ( ns.ne.'N' .or. y.lt.y1 .or. y.gt.y2 ) then
	    write(0,*) 'error: ',5*y,ns,' not in ',5*y1,5*y2
	    call abort
	endif
	if ( ew.eq.'W' ) then
	    x = -x
	endif
	if ( ew.ne.'E' .and. ew.ne.'W' .or. 
     +		x.lt.x1 .or. x.gt.x2 ) then
	    write(0,*) 'error: ',10*x,ew,' not in ',10*x1,10*x2
	    call abort
	endif
	print *,'x,y = ',x,y
	do yr=yr1,yr2
	    read(1,1001) yrin,(vars(mn),slash,ivars(mn),mn=1,12)
 1001	    format(i5,12(f7.1,a1,i1))
	    if ( yr.ne.yrin ) then
		write(0,*) 'error: yr != yrin: ',yr,yrin
		call abort
	    endif
	    do mn=1,12
		slp(x,y,mn,yr) = vars(mn)
		nslp(x,y,mn,yr) = ivars(mn) 
	    enddo
	enddo
	goto 100
  800	continue
*
*	write out
*
	irec = 0
	do yr=yrbeg,yrend
	    do mn=1,12
		irec = irec + 1
		write(2,rec=irec) ((slp(x,y,mn,yr),x=x1,x2),y=y1,y2)
	    enddo
	enddo
	write(3,'(a)') 'DSET ^eurqual.dat'
	write(3,'(a)') 'TITLE ADVICE gridded SLP'
	if ( get_endian().eq.+1 ) then
	    write(3,'(a)') 'OPTIONS BIG_ENDIAN'
	else
	    write(3,'(a)') 'OPTIONS LITTLE_ENDIAN'
	endif
	write(3,'(a)') 'UNDEF 3e33'
	write(3,'(a,i4,a,i4,a)') 
     +		'XDEF ',x2-x1+1,' LINEAR ',10*x1,' 10'
	write(3,'(a,i4,a,i4,a)') 
     +		'YDEF ',y2-y1+1,' LINEAR ',5*y1,' 5'
	write(3,'(a)') 'ZDEF 1 LINEAR 0 1'
	write(3,'(a,i6,a,i4,a)') 'TDEF ',12*(yrend-yrbeg+1),
     +		' LINEAR 15JAN',yrbeg,' 1MO'
	write(3,'(a)') 'VARS 1'
	write(3,'(a)') 'SLP 1 0 sea-level pressure [mb]'
	write(3,'(a)') 'ENDVARS'
	stop
*
*	errors
*
  900	continue
	write(0,*) 'error reading data'
	call abort
	end