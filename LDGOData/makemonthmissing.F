	program makemonthmissing
*
*	geenrate a month with missing values
*
	implicit none
#include "recfac.h"
	integer nx,ny
	parameter (nx=90,ny=45)
	integer i,j
	real missing,field(nx,ny)
*
	missing = 163.835
	do i=1,nx
	    do j=1,ny
		field(i,j) = missing
	    enddo
	enddo
*
	open(1,file='missing.dat',access='direct',
     +		form='unformatted',recl=nx*ny*recfa4)
	write(1,rec=1) field
	close(1)
*
	end
