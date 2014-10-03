	program jones2dat
*
*	convert Jones & Parker dataset to GrADS format
*
	implicit none
#include "recfac.inc"
	integer yrbeg,yr2
	parameter(yrbeg=1851,yr2=2006)
	integer month,year,mo,yr,i,j,k,ifile,yr1,yrend,idata(72),irec
	real t(72,36,12,yrbeg:yr2),n(72,36,12,yrbeg:yr2)
	character*19 file,ctlfile
	integer system
	external system
*
	call getarg(1,file)
	if ( file.eq.' ' ) then
	    print *,'usage: jones2dat file.gz'
	    stop
	endif
	if ( file.eq.'hadcrut.dat.gz' ) then
	    yr1 = 1856
	elseif ( file.eq.'hadcrutv.dat.gz' ) then
	    yr1 = 1870
	elseif ( file.eq.'crutem1.dat.gz' ) then
	    yr1 = 1851
	elseif ( file.eq.'crutem1v.dat.gz' ) then
	    yr1 = 1851
	elseif ( file.eq.'hadcrut2.dat.gz' ) then
	    yr1 = 1856
	elseif ( file.eq.'hadcrut2v.dat.gz' ) then
	    yr1 = 1870
	elseif ( file.eq.'crutem2.dat.gz' ) then
	    yr1 = 1851
	elseif ( file.eq.'crutem2v.dat.gz' ) then
	    yr1 = 1851
	else
	    write(0,*) 'unknown dataset ',file
	    yr1 = yrbeg
	endif
*
*       put t to absent
*
	do year = yr1,yr2
	    do month = 1,12
		do j=1,36
		    do i=1,72
			t(i,j,month,year) = 3e33
			n(i,j,month,year) = 3e33
		    enddo
		enddo
	    enddo
	enddo
*
*	read data
*
	i = system('gunzip -c '//file//' > aap')
	if ( i.ne.0 ) then
	    write(0,*) 'gunzipping failed'
	    call abort
	endif
	open(1,file='aap',status='old')
	do year = yr1,yr2
	    do month = 1,12
		do j=36,1,-1
		    read(1,'(i4,i3,i2,72i6)',end=800) yr,mo,k,idata
		    if ( mo.ne.month .or. yr.ne.year ) then
			write(0,*) 'jones2dat: error: month,year = ',
     +			      month,year,mo,yr,', j,k = ',j,k
			call abort
		    endif
		    do i=1,72
			if ( idata(i).ne.-9999 ) then
			    t(i,j,month,year) = real(idata(i))/100
			else
			    t(i,j,month,year) = 3e33
			endif
		    enddo
		enddo
		if ( file.eq.'crutem1.dat.gz' .or. 
     +		      file.eq.'crutem2.dat.gz') then
		    do j=36,1,-1
			read(1,'(i4,i3,i2,72i6)',end=800) yr,mo,k,idata
			if ( mo.ne.month .or. yr.ne.year ) then
			    write(0,*) 'jones2dat: error: month,year = ',
     +				  month,year,mo,yr,', k = ',k
			    call abort
			endif
			do i=1,72
			    n(i,j,month,year) = real(idata(i))
			enddo
		    enddo
		endif
	    enddo
	enddo
  800	continue
	close(1,status='delete')
*
*	write data
*
	i = index(file,'.gz')
	file(i:) = ' '
	open(1,file=file,form='unformatted',access='direct',
     +		recl=recfa4*36*72*12)
	irec = 0
	do year=yr1,yr2
	    irec = irec + 1
	    write(1,rec=irec) (((t(i,j,month,year),i=1,72),j=1,36),
     +		    month=1,12)
	enddo
	close(1)
	i = index(file,'.dat')
	ctlfile = file
	ctlfile(i:) = '.ctl'
	open(1,file=ctlfile)
	write(1,'(2a)') 'DSET ^',file
	write(1,'(2a)') 'TITLE CRU dataset ',file
	write(1,'(a)') 'UNDEF 3e33'
	write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
	write(1,'(a)') 'XDEF 72 LINEAR -177.5 5'
	write(1,'(a)') 'YDEF 36 LINEAR -87.5 5'
	write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
	write(1,'(a,i4,a,i4,a)')'TDEF ',(yr2-yr1+1)*12,' LINEAR 15JAN',
     +		yr1,' 1MO'
     	write(1,'(a)') 'VARS 1'
     	write(1,'(a)') 'T 0 1 T anomaly [K]'
     	write(1,'(a)') 'ENDVARS'
     	close(1)
	if ( file.eq.'crutem1.dat' .or. file.eq.'crutem2.dat' ) then
	    open(1,file='n'//file,form='unformatted',access='direct',
     +		recl=recfa4*36*72*12)
	    irec = 0
	    do year=yr1,yr2
		irec = irec + 1
		write(1,rec=irec) (((n(i,j,month,year),i=1,72),j=1,36),
     +		      month=1,12)
	    enddo
	    close(1)
	    open(1,file='n'//ctlfile)
	    write(1,'(2a)') 'DSET ^n',file
	    write(1,'(2a)') 'TITLE CRU dataset ',file
	    write(1,'(a)') 'UNDEF 3e33'
	    write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
	    write(1,'(a)') 'XDEF 72 LINEAR -177.5 5'
	    write(1,'(a)') 'YDEF 36 LINEAR -87.5 5'
	    write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
	    write(1,'(a,i4,a,i4,a)')'TDEF ',(yr2-yr1+1)*12,' LINEAR 15JAN',
     +		  yr1,' 1MO'
	    write(1,'(a)') 'VARS 1'
	    write(1,'(a)') 'N 0 1 number of stations'
	    write(1,'(a)') 'ENDVARS'
	    close(1)
	endif
	end
