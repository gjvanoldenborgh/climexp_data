	program temp2nino
*
*	program to read a binary file from GrDAS, one value per week
*	and convert to standard ASCII format.
*	We also make anomalies using the climatology deduced from
*	wksst.for
*
	implicit none
#include "recfac.h"
	integer dy,yr,mo,jul0,inino,i,j,nn(31,12,2:5)
	real data(1500,2:5),anom(2:5),clim(31,12,2:5),xx(2,2:5)
	character month*3,months*36,file*256
	integer julday
	external julday

	data months /'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC'/
	do inino=2,5
	    do mo=1,12
		do dy=1,31
		    clim(dy,mo,inino) = 3e33
		    nn(dy,mo,inino) = 0
		enddo
	    enddo
	enddo

	open(1,file='wksst.for',status='old')
	do i=1,5
	    read(1,'(a)')
	enddo
  100	continue
	read(1,'(i3,a3,i4,4(f9.1,f4.1))',end=200) dy,month,yr,
     +	    xx(1,2),xx(2,2),xx(1,3),xx(2,3),
     +	    xx(1,5),xx(2,5),xx(1,4),xx(2,4)
	mo = (index(months,month)+2)/3
	if ( mo.eq.0 ) then
	    write(0,*) 'error reading month from ',month
	    call abort
	endif
	do inino=2,5
	    if ( clim(dy,mo,inino).gt.1e33 ) then
		clim(dy,mo,inino) = xx(1,inino) - xx(2,inino)
		nn(dy,mo,inino) = nn(dy,mo,inino) + 1
	    else
		if ( abs(clim(dy,mo,inino) - xx(1,inino) + 
     +			xx(2,inino)).gt.0.15 ) then
		    write(0,*) 'warning climatology NINO,',inino,
     +			'inconsistent on ',dy,month,
     +			clim(dy,mo,inino),xx(1,inino) - xx(2,inino)
		endif
		clim(dy,mo,inino) = (nn(dy,mo,inino)*clim(dy,mo,inino) 
     +			+ xx(1,inino) - xx(2,inino))/
     +			(nn(dy,mo,inino)+1)
		nn(dy,mo,inino) = nn(dy,mo,inino) + 1
	    endif
	enddo
	goto 100
  200	continue

	do inino=2,5 
	    do i=1,1500
		data(i,inino) = -999.9
	    enddo
	    write(file,'(a,i1,a)') 'tnino',inino,'week1.dat'
	    open(1,file=file,access='direct',
     +		recl=recfa4,status='old')
	    do i=1,427
		read(1,rec=i,end=800,err=800) data(i,inino)
	    enddo
	    close(1)
	    write(file,'(a,i1,a)') 'tnino',inino,'week2.dat'
	    open(1,file=file,access='direct',
     +		recl=recfa4,status='old')
	    do i=1,721
		read(1,rec=i,end=800,err=800) data(i+427,inino)
	    enddo
	    close(1)
	enddo

	open(1,file='mywksst.for',status='unknown')
	write(1,'(2a)') 'Weekly NINO indices self-generated from',
     +		' Reynolds OIv2 weekly gridded SST'
	write(1,'(a)')
	write(1,'(a)')
	write(1,'(a)')
	jul0 = julday(11,1,1981) - 7
	do i=1,427
	    call caldat(jul0+7*i,mo,dy,yr)
	    write(1,'(i3,a3,i4,4(f9.2,f4.1)') 
     +		dy,months(3*mo-2:3*mo),yr,
     +		data(i,2),data(i,2) - clim(dy,mo,2),
     +		data(i,3),data(i,3) - clim(dy,mo,3),
     +		data(i,5),data(i,5) - clim(dy,mo,5),
     +		data(i,4),data(i,4) - clim(dy,mo,4)
	enddo
	jul0 = julday(1,3,1990) - 7
	do i=427+1,417+721
	    call caldat(jul0+7*(i-427),mo,dy,yr)
	    write(1,'(i3,a3,i4,4(f9.2,f4.1)')
     +		dy,months(3*mo-2:3*mo),yr,
     +		data(i,2),data(i,2) - clim(dy,mo,2),
     +		data(i,3),data(i,3) - clim(dy,mo,3),
     +		data(i,5),data(i,5) - clim(dy,mo,5),
     +		data(i,4),data(i,4) - clim(dy,mo,4)
	enddo

  800	continue
	end