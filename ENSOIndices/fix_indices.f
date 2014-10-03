	program fix_indices
!
!	get rid of the nonsensical values
!
	implicit none
	integer npermax,yrbeg,yrend
	parameter(npermax=12,yrbeg=1960,yrend=2020)
	integer yr,mo,iargc,iarg,nperyear,retval
	real data(12,yrbeg:yrend)
	character file*256,var*20,units*40
	logical lstandardunits,lwrite,ldirty
	lstandardunits = .false.
	lwrite = .false.

	do iarg=1,iargc()
	    ldirty = .false.
	    call getarg(iarg,file)
	    write(0,*) 'opening ',trim(file)
	    call readseries(file,data,npermax,yrbeg,yrend,nperyear,
     +		var,units,lstandardunits,lwrite)
	    do yr=yrbeg,yrend
	    	do mo=1,nperyear
	    	    if ( data(mo,yr).lt.1e33 .and. 
     +	    	         abs(data(mo,yr)).gt.100 ) then
	    	    	write(0,*) 'fix_indices: found data(',mo,yr,
     +	    	    	    ') = ',data(mo,yr), ', setting to undef'
     			data(mo,yr) = 3e33
     			ldirty = .true.
     		    end if
     		end do
     	    end do
     	    if ( ldirty ) then
     	    	call mysystem('mv '//trim(file)//' '//trim(file)//
     +	    	    '.bak',retval)
     		open(1,file=trim(file),status='new')
     		call copyheader(trim(file)//'.bak',1)
     		call printdatfile(1,data,npermax,nperyear,yrbeg,yrend)
     	    end if
	end do ! iareg
	end
