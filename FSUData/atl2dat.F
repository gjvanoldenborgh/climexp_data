	program atl2dat
*
*	convert Jacques Servain atlantic wind stress fields to GrADS
*	http://www.coaps.fsu.edu/WOCE/SAC/atlantic/index.html
*
	implicit none
#include"recfac.h"
	integer i,j,k,yr,mn,ifield(38),imask(38,25)
	real*4 field(38,25,3)
*
	open(1,file='pwsx6497.atl',status='old')
	open(2,file='pwsy6497.atl',status='old')
	open(3,file='sst6497.atl',status='old')
	open(4,file='pws.dat',status='new',form='unformatted',
     +	      access='direct',recl=38*25*3*recfa4)
	do yr=1964,1997
	    do mn=1,12
		do k=1,3
		    do j=1,25
			read(k,'(13i5)') (ifield(i),i= 1,13)
			read(k,'(13i5)') (ifield(i),i=14,26)
			read(k,'(12i5)') (ifield(i),i=27,38)
			do i=1,38
			    if ( ifield(i).eq.99998 ) then
				field(i,j,k) = 3e33
				if ( yr.eq.1964 .and. mn.eq.1 ) then
				    imask(i,j) = 1
				else
				    if ( imask(i,j).ne.1 ) then
					print *,'landsea mask changed ',
     +					      1,i,j,yr,mn
				    endif
				endif
			    else
				if ( abs(ifield(i)).gt.9999 ) then
				    print *,'suspicious data ',i,j,k
     +					  ,ifield(i)
				endif
				if ( yr.eq.1964 .and. mn.eq.1 ) then
				    imask(i,j) = 0
				else
				    if ( imask(i,j).ne.0 ) then
					print *,'landsea mask changed ',
     +					      0,i,j,yr,mn
				    endif
				endif
				field(i,j,k) = ifield(i)/10.
			    endif
			enddo
		    enddo
		enddo
		write(4,rec=12*(yr-1964)+mn) field
	    enddo
	enddo
	close(3)
	close(2)
	close(1)
	end
