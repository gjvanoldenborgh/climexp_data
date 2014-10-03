	program jones2dat
*
*	convert Jones & Parker dataset to GrADS format
*
	implicit none
#include "recfac.inc"
	integer yr1,yr2,yr3
	parameter(yr1=1856,yr2=1993,yr3=2000)
	integer month,year,i,j,k,ifile,yrbeg,yrend,idata(12),irec
	real t(72,36,12,yr1:yr3)
	character*19 file
*
*       put t to absent
*
	do year = yr1,yr3
	    do month = 1,12
		do j=1,36
		    do i=1,72
			t(i,j,month,year) = 3e33
		    enddo
		enddo
	    enddo
	enddo
*
*	read data
*
	do ifile=1,2
	    if ( ifile.eq.1 ) then
		yrbeg = yr1
		yrend = yr2
	    else
		yrbeg = yr2+1
		yrend = yr3
	    endif
	    write(file,'(a,2i4,a)') 'tgrid',yrbeg,yrend,'.dat'
	    open(1,file=file,status='old')
	    do year = yrbeg,yrend
		do month = 1,12
		    read(1,'(2i6)',end=800) i,j
		    if ( i.ne.month .or. j.ne.year ) then
			write(0,*) 'jones2dat: error: month,year = ',
     +				month,year,i,j
			call abort
		    endif
		    do j=36,1,-1
			do k=1,6
			    read(1,'(12i6)') idata
			    do i=1,12
				if ( idata(i).ne.-32768 ) then
				    t(i+(k-1)*12,j,month,year) =
     +					real(idata(i))/100
				else
				    t(i+(k-1)*12,j,month,year) = 3e33
				endif
			    enddo
			enddo
		    enddo
		enddo
	    enddo
  800	    continue
	    close(1)
	enddo
*
*	write data
*
	open(1,file='jones.dat',form='unformatted',access='direct',
     +		recl=recfa4*36*72*12,status='new')
	irec = 0
	do year=yr1,yr3
	    irec = irec + 1
	    write(1,rec=irec) (((t(i,j,month,year),i=1,72),j=1,36),
     +		    month=1,12)
	enddo
	close(1)
	open(1,file='jones.ctl',status='new')
	write(1,'(a)') 'DSET ^jones.dat'
	write(1,'(a)') 'TITLE Jones & Parker T2m/SST anomalies'
	write(1,'(a)') 'UNDEF 3e33'
	write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
	write(1,'(a)') 'XDEF 72 LINEAR -177.5 5'
	write(1,'(a)') 'YDEF 36 LINEAR -87.5 5'
	write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
	write(1,'(a,i4,a,i4,a)')'TDEF ',(yr3-yr1+1)*12,' LINEAR 15JAN',
     +		yr1,' 1MO'
     	write(1,'(a)') 'VARS 1'
     	write(1,'(a)') 'T 0 1 T2m & SST anomaly [K]'
     	write(1,'(a)') 'ENDVARS'
     	close(1)
	end
