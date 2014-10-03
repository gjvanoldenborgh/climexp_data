	program prcp2mm
*
*	convert a precipitation rate [kg/m2/s] file into one with [mm/month]
*	quick hack
*
	implicit none
#include "recfac.h"
	integer nxmax,nymax
	parameter(nxmax=240,nymax=121)
	integer irec,i,j,nx,ny,nz,nt,nperyear,dpm(12,2),leap,yrbegin,
     +		mobegin,endian,nvars,ivars(2,1),mo,yr
	real data(nxmax*nymax),xx(nxmax),yy(nymax),zz(1),undef,rho
	character*255 file,datfile,string,title
	character vars(1)*10,lvars(1)*40,units*40
	integer iargc,llen
	external iargc,getarg,llen
	data dpm
     +	    /31,28,31,30,31,30,31,31,30,31,30,31,
     +	     31,29,31,30,31,30,31,31,30,31,30,31/
        data rho /1000./

	if ( iargc().ne.1 ) then
	    print *,'usage: prcp2mm file.ctl'
	    stop
	endif

	call getarg(1,file)
        call parsectl(file,datfile,nxmax,nx,xx,nymax,ny,yy,1
     +        ,nz,zz,nt,nperyear,yrbegin,mobegin,undef,endian,title
     +        ,1,nvars,vars,ivars,lvars,units)
	if ( units.ne.'kg/m2/s' ) then
	    write(0,*) 'prcp2mm: expecting kg/m2/s, not ',trim(units)
	    call abort
	endif
	open(1,file=datfile,status='old',form='unformatted',
     +		access='direct',recl=nx*ny*recfa4)
*	ignore endian
	datfile=datfile(1:llen(datfile)-4)//'.new.dat'
	open(2,file=datfile,status='new',form='unformatted',
     +		access='direct',recl=nx*ny*recfa4)
	mo = mobegin
	yr = yrbegin
	if ( mod(yr,4).eq.0 .and. yr.ne.1900 ) then
	    leap = 2
	else
	    leap = 1
	endif
	do irec=1,nt
	    read(1,rec=irec) (data(i),i=1,nx*ny)
	    do i=1,nx*ny
	    	if ( data(i).ne.undef ) then
		    data(i) = data(i)*3600*24*dpm(mo,leap)*1000/rho
		endif
	    enddo
	    write(2,rec=irec) (data(i),i=1,nx*ny)
	    mo = mo + 1
	    if ( mo.gt.12 ) then
	    	mo = mo - 12
	    	yr = yr + 1
		if ( mod(yr,4).eq.0 .and. yr.ne.1900 ) then
		    leap = 2
		else
		    leap = 1
		endif
	    endif
	enddo
	vars(1) = 'prcp'
	lvars(1) = 'precipitation'
	units = 'mm/month'
	file(llen(file)-3:) = '.new'
        call writectl(file,datfile,nx,xx,ny,yy,nz,zz,
     +		nt,nperyear,yrbegin,mobegin,undef,title,
     +		nvars,vars,ivars,lvars,units)
	end

