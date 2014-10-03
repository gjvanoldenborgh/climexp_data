	program knmi2dat
*
*	convert KNMI/KD database output to my .dat format
*
	implicit none
	integer i,j,istation,idate,itemp,iprec,yr,mo,yrold,istationold
	logical ltemp,lprec
	real temp(12),prec(12)
	character line*80
*
	open(1,file='KNMI.LST',status='old')
	do mo=1,12
	    temp(mo) = -999.9
	    prec(mo) = -999.9
	enddo
	ltemp = .FALSE.
	lprec = .FALSE.
	yrold = 0
	istationold = 0
  100	continue
	read(1,'(a)',err=900,end=800) line
	if ( line(29:29).eq.' ' ) then
	    if ( line(39:39).eq.' ' ) then
*		no data
		goto 100
	    else
		read(line,*) yr,idate,iprec
		itemp = -9999
	    endif
	elseif ( line(39:39).eq.' ' ) then
	    read(line,*) istation,idate,itemp
	    iprec = -9999
	else
	    read(line,*) istation,idate,itemp,iprec
	endif
	if ( istation.ne.istationold ) then
	    if ( istationold.ne.0 ) then
*		write last record
		if ( ltemp ) write(2,'(i5,12f7.1)') yrold,temp
		if ( lprec ) write(3,'(i5,12f7.1)') yrold,prec
	    	do mo=1,12
		    temp(mo) = -999.9
		    prec(mo) = -999.9
	    	enddo
	    	ltemp = .FALSE.
	    	lprec = .FALSE.
	    	yrold = 0
	    	close(2)
	    	close(3)
	    endif
	    istationold = istation
	    write(line,'(a,i3.3,a)') 't',istation,'.dat'
	    open(2,file=line,status='new')
	    write(line,'(a,i3.3,a)') 'p',istation,'.dat'
	    open(3,file=line,status='new')
	    do i=2,3
		write(i,'(a)') 'Generated from KNMI.LST bij knmi2dat.f'
		do j=1,4
		    write(i,'(a)') 'this line intentionally left blank'
		enddo
	    enddo
	endif
	yr = idate/10000
	if ( yrold.eq.0 ) then
	    yrold = yr
	elseif ( yr.ne.yrold ) then
	    if ( ltemp ) write(2,'(i5,12f7.1)') yrold,temp
	    if ( lprec ) write(3,'(i5,12f7.1)') yrold,prec
	    yrold = yr
	    do mo=1,12
		temp(mo) = -999.9
		prec(mo) = -999.9
	    enddo
	    ltemp = .FALSE.
	    lprec = .FALSE.
	endif
	mo = mod(idate/100,100)
	if ( itemp.ne.-9999 ) then
	    ltemp = .TRUE.
	    temp(mo) = itemp/10.
	endif
	if ( iprec.ne.-9999 ) then
	    lprec = .TRUE.
	    prec(mo) = iprec/10.
	endif
	goto 100
  800	continue
*	write last record
	if ( ltemp ) write(2,'(i5,12f7.1)') yrold,temp
	if ( lprec ) write(3,'(i5,12f7.1)') yrold,prec
	close(2)
	close(3)
        stop
*
*	error messages
*
  900	print *,'error reading KNMI.LST'
	print *,line
	end
