	program changemissing
*
*	change missing value to 3e33
*
	implicit none
#include "recfac.h"
	integer nx,ny,nt
	parameter (nx=90,ny=45,nt=1668)
	integer i,j,it
	real missing,field(nx,ny)
*
	missing = 163.835
*
	open(1,file='kaplan_slpa.dat',access='direct',
     +		form='unformatted',recl=nx*ny*recfa4)
	open(2,file='kaplan_slpa_new.dat',access='direct',
     +		form='unformatted',recl=nx*ny*recfa4)
        do it=1,nt
            read(1,rec=it) field
            do j=1,ny
                do i=1,nx
                    if ( abs(field(i,j)-missing).lt.0.01 ) then
                        field(i,j) = 3e33
                    elseif ( field(i,j).gt.160 ) then
                        print *,'warning: ',it,i,j,field(i,j),missing
                    endif
                enddo
            enddo
            write(2,rec=it) field
        enddo
	close(1)
	close(2)
*
	end
