	program gpcc2grads
*
*	program to convert the GPCC data files
*	(http://www.dwd.de/research/gpcc/formatdesc.html)
*	to a GrADS binary file
*
	implicit none
#include "recfac.h"
	integer i,j,ii,jj,iii,jjj,k,n,yr,mo,nbin,ioff,joff
	real data(144,72),mean(144,72,12),ndata(144,72),d
	character file*26
	integer iargc
	external iargc,getarg
*
*	arguments
*
	if ( iargc().ge.1 ) then
	    call getarg(1,file)
	    read(file,*) ioff
	    print *,'using offset ',ioff
	else
	    ioff = 0
	endif
	if ( iargc().ge.2 ) then
	    call getarg(2,file)
	    read(file,*) joff
	    print *,'using offset ',joff
	else
	    joff = 0
	endif
	if ( iargc().ge.3 ) then
	    call getarg(3,file)
	    read(file,*) nbin
	    print *,'averaging ',nbin,'x',nbin,' bins into one'
	else
	    nbin = 1
	endif
*
*	read climatology
*
	print *,'opening mean_25_61-90'
	open(1,file='mean_25_61-90',status='old')
	read(1,*) i
	do j=1,i-1
	    read(1,*)
	enddo
	do j=72,1,-1
	    do i=1,144
		read(1,*) (mean(i,j,mo),mo=1,12)
	    enddo
	enddo
	close(1)
*
*	read data
*
	print *,'opening gpcc_ano.dat, recl = ',(144/nbin)*
     +		((72-joff+1)/nbin)*recfa4
	open(2,file='gpcc_ano.dat',status='unknown',form='unformatted',
     +		access='direct',recl=(144/nbin)*((72-joff+1)/nbin)*
     +		recfa4)
	k = 0
	file = 'gpcc_25_mmyy_monitor_gauge'
	do yr=1986,2000
	    do mo=1,12
		write(file(9:12),'(2i2.2)') mo,mod(yr,100)
		print *,'opening file ',file
		open(1,file=file,status='old')
		read(1,*) i
		do j=1,i-1
		    read(1,*)
		enddo
		do j=72,1,-1
		    do i=1,144
			read(1,*) data(i,j)
			if ( data(i,j).ge.0 ) then
			    data(i,j) = data(i,j) - mean(i,j,mo)
			else
			    data(i,j) = 3e33
			endif
		    enddo
		enddo
		k = k + 1
		if ( nbin.eq.1 .and. ioff.eq.0 ) then
		    write(2,rec=k) data
		else
		    do j=1,(72-joff+1)/nbin
			do i=1,144/nbin
			    ndata(i,j) = 0
			    n = 0
			    do jj=1,nbin
				jjj = nbin*(j-1) + jj + joff
				if ( jjj.gt.72 ) jjj = 144 - jjj
				if ( jjj.lt.1  ) jjj = 1 - jjj
				do ii=1,nbin
				    iii = nbin*(i-1) + ii + ioff
				    if ( iii.gt.144 ) iii = iii - 144
				    d = data(iii,jjj)
				    if ( d.lt.1e33 ) then
					ndata(i,j) = ndata(i,j) + d
					n = n + 1
				    endif
				enddo
			    enddo
			    if ( n.gt.0 ) then
				ndata(i,j) = ndata(i,j)/n
			    else
				ndata(i,j) = 3e33
			    endif
			enddo
		    enddo
		    write(2,rec=k) ((ndata(i,j),i=1,144/nbin),
     +			j=1,(72-joff+1)/nbin) 
		endif
	    enddo
	enddo

	end
