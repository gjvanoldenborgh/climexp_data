	program yrev
*
*	reverses the Y-direction of a 72x36 field
*
	implicit none
#include "recfac.h"
	integer i,j,n,nrec
	real data(72,36),ndata(72,36)
	character*255 string
	integer iargc
	external iargc,getarg
*
	if ( iargc().ne.3 ) then	
	    print *,'usage: yrev nrec infile outfile'
	    print *,'NOTE: only for 72x36 files (5x5o)!'
	    stop
	endif
*
	call getarg(1,string)
	read(string,*,err=900) nrec
	call getarg(2,string)
	open(1,file=string,status='old',form='unformatted',
     +		access='direct',recl=recfa4*72*36)
	call getarg(3,string)
	open(2,file=string,status='new',form='unformatted',
     +		access='direct',recl=recfa4*72*36)
*
	do n=1,nrec
	    read(1,rec=n) data
	    do j=1,36
		do i=1,72
		    ndata(i,j) = data(i,37-j)
		enddo
	    enddo
	    write(2,rec=n) ndata
	enddo
	stop
  900	print *,'error reading nrec from ',string
	end
