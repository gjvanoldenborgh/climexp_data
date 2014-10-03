	program precip2dat
!
!	converts the homogenised (and raw) precipitation data into CE-standard files
!
	implicit none
	integer yrbeg,yrend,nstatmax
	parameter(yrbeg=1900,yrend=2030,nstatmax=1000)
	integer i,m,yr,mo,dy,ii(nstatmax),nstat,istat,dpm(12),yr1,yr2
	real*8 datum
	real data(366,yrbeg:yrend,nstatmax),dayvals(nstatmax),
     +		lats(nstatmax),lons(nstatmax),lon,lat
     	character file*255,type*3,string*80,outfile*80,
     +		names(nstatmax)*25
     	integer iargc,leap
	data dpm /31,29,31,30,31,30,31,31,30,31,30,31/
!
!	process arguments
!
	if ( iargc().ne.2 ) then
	    write(0,*) 'usage: precip2dat raw|hom 1910|1951'
	    stop
	end if

	call getarg(1,type)
	call getarg(2,string)
	read(string,*) yr1
	yr2=2009
	if ( yr1.eq.1910 ) then
	    nstat = 102 ! from Theo's e-mail
	else if ( yr1.eq.1951 ) then
	    nstat = 240
	else
	    write(0,*) 'precip2dat: error: yr1 can be 1910 or 1951, not'
     +	    	,yr1
     	    stop
     	end if
!
!	open data files
!
	if ( type.eq.'raw' ) then
	    open(1,file=trim(string)//'_2009_daily_values_raw.txt',
     +	    	status='old')
	else if ( type.eq.'hom' ) then
	    open(1,file=trim(string)//
     +	    	'_2009_daily_values_homogenized.txt',status='old')
	else
	    write(0,*) 'precip2dat: unknown value for type: ',type
	    stop
	end if
!
!	read station metadata
!
	lats = 3e33
	lons = 3e33
	names = 'onbekend'
	open(2,file='metadata_allstations.list',status='old')
100	continue
	read(2,'(i7,2f11.7,x,a40)',end=110) istat,lat,lon,string
	lats(istat) = lat
	lons(istat) = lon
	names(istat) = string
	goto 100
110	continue
	close(2)
!
!	read data
!
!	first a line with station numbers
	read(1,'(a8,1000f8.2)') string,(dayvals(istat),istat=1,nstat)
	do istat=1,nstat
	    ii(istat) = nint(dayvals(istat))
	end do
!	next a line with latitudes
	read(1,'(a8,1000f8.2)') string,(dayvals(istat),istat=1,nstat)
	do istat=1,nstat
	    if ( abs(lats(ii(istat))-dayvals(istat)).gt.0.02 ) then
	    	write(0,*) 'precip2dat: warning: latitudes for station'
     +	    		,ii(istat),' do not match ',
     +			lats(ii(istat)),dayvals(istat)
     	    end if
	end do
!	next a line with longitudes
	read(1,'(a8,1000f8.2)') string,(dayvals(istat),istat=1,nstat)
	do istat=1,nstat	
	    if ( abs(lons(ii(istat))-dayvals(istat)).gt.0.02 ) then
	    	write(0,*) 'precip2dat: warning: longitudes for station'
     +	    		,ii(istat),' do not match ',
     +			lons(ii(istat)),dayvals(istat)
     	    end if
     	end do
!	next the data
	data = 3e33
200     continue
	read(1,*,end=210) datum,(dayvals(istat),istat=1,nstat)
	yr = int(datum/10000+0.4)
	mo = int((datum-10000*yr)/100+0.3)
	dy = int(datum-10000*yr-100*mo+0.5)
	i = dy
	do m=1,mo-1
	    i = i + dpm(m)
	end do
	do istat=1,nstat
	    data(i,yr,istat) = dayvals(istat)
	end do
	goto 200
210	continue
	close(1)
!
!	write out metadata
!
	write(file,'(3a,i4,a,i4,a)') 'list_precip_',type,'_',
     +		yr1,'-',yr2,'.txt'
	open(1,file=trim(file))
	write(1,'(a)') 'located stations in 50.0N:54.0N, 3.0E:8.0E'
	write(1,'(a)') '=============================================='
	do istat=1,nstat
	    write(1,'(2a)') names(ii(istat)),' (Netherlands)'
	    write(1,'(a,f8.2,a,f8.2,a)') 'coordinates: ',
     +	    	lats(ii(istat)),'N, ',lons(ii(istat)),'E'
     	    write(1,'(a,i3.3,2a)') 'station code: ',ii(istat),' ',
     +	    	trim(names(ii(istat)))
	    write(1,'(a,i4,a,i4,a,i4)') 'Found ',yr2-yr1+1,
     +	    	' years with data in ',yr1,'-',yr
	    write(1,'(a)') 
     +	    	'=============================================='
	end do
	close(1)
!
!	write out datafiles
!
	do istat=1,nstat
	    write(file,'(a,i3.3,3a,i4,a,i4,a)')'precip',ii(istat),
     +	    	'_',type,'_',yr1,'-',yr2,'.dat'
	    open(1,file=trim(file))
	    write(1,'(a)') '# THESE DATA CAN BE USED FREELY PROVIDED'//
     +	    	' THAT THE FOLLOWING SOURCE IS ACKNOWLEDGED: ROYAL'//
     +		' NETHERLANDS METEOROLOGICAL INSTITUTE'
     	    if ( type.eq.'raw' ) then
     	    	write(1,'(a)')
     +     	    '# precip [mm/dy] observed precipitation (8-8)'
	    else
     	    	write(1,'(a)')
     +     	    '# precip [mm/dy] homogenised precipitation (8-8)'
	    end if
	    write(1,'(3a,f7.2,a,f7.2,a)') '# ',trim(names(ii(istat))),
     +		' (',lats(ii(istat)),'N, ',lons(ii(istat)),'E)'
	    write(1,'(a)') '# Buishand, T.A., G. De Martino, J.N. '//
     +		'Spreeuw en T. Brandsma, Homogeneity of precipitation '
     +		//'series in the Netherlands and their trends in the '
     +		//'past century <a href="http://www.knmi.nl/'
     +		//'publicaties/showAbstract.php?id=8714">more</a>'
	    write(1,'(a)') '# source: <a href="http://climexp.knmi.nl"'
     +		    //'>KNMI</a>'
	    do yr=yr1,yr2
	    	do i=1,366
	    	    if ( data(i,yr,istat).gt.1e33 ) cycle
	    	    call getdymo(dy,mo,i,366)
	    	    write(1,'(i4,2i2.2,f8.2)')yr,mo,dy,data(i,yr,istat)
	    	end do
	    end do
	end do
!
!	finito
!
	end
	
        subroutine getdymo(dy,mo,firstmo,nperyear)
!
!       given the firstmo-period of the year out of nperyear periods per
!       year, computes the day and month
!
        implicit none
        integer dy,mo,firstmo,nperyear
        integer m,i,dpm(12),dpm365(12)
        logical lwrite
        data dpm    /31,29,31,30,31,30,31,31,30,31,30,31/
        data dpm365 /31,28,31,30,31,30,31,31,30,31,30,31/

        lwrite = .false.
        if ( nperyear.le.12 ) then
            dy = 1
            mo = firstmo
            return
        endif
        m = 1+mod(firstmo-1,nperyear)
        if ( m.eq.0 ) m = m + nperyear
        if ( nperyear.eq.36 ) then
            dy = 1
            do i=1,(m-1)/3
                dy = dy + dpm(i)
            enddo
            dy = dy + 5 + 10*mod(m-1,3)
        elseif ( nperyear.le.366 ) then
            dy = nint(0.5 + (m-0.5)*nint(366./nperyear))
        else
            dy = nint(0.5 + (m-0.5)*366./nperyear)
        endif
        mo = 1
 400    continue
        if ( nperyear.eq.365 .or. nperyear.eq.73 ) then
            if ( dy.gt.dpm365(mo) ) then
                dy = dy - dpm365(mo)
                mo = mo + 1
                goto 400
            endif
        elseif ( nperyear.eq.360 ) then
            if ( dy.gt.30 ) then
                dy = dy - 30
                mo = mo + 1
                goto 400
            endif
        else
            if ( dy.gt.dpm(mo) ) then
                dy = dy - dpm(mo)
                mo = mo + 1
                goto 400
            endif
        endif
        if ( lwrite ) then
            print *,'getdymo: input: firstmo,nperyear = ',firstmo
     +           ,nperyear
            print *,'         outpuyt: dy,mo          = ',dy,mo
        end if
        if ( mo.le.0 .or. mo.gt.12 ) then
            write(0,*) 'getdymo: error: impossible month ',mo
            mo = 1
        endif
        end

        subroutine invgetdymo(dy,mo,firstmo,nperyear)
!
!       given dy and mo, compute in which period out of nperyear ones it
!       falls
!
        implicit none
        integer dy,mo,firstmo,nperyear
        integer m,i,dpm(12),dpm365(12)
        logical lwrite
        data dpm    /31,29,31,30,31,30,31,31,30,31,30,31/
        data dpm365 /31,28,31,30,31,30,31,31,30,31,30,31/
!
        if ( nperyear.lt.12 ) then
            firstmo = mo
        else if ( nperyear.eq.360 ) then
            firstmo = 30*(mo-1) + dy
        else if ( nperyear.eq.365 ) then
            firstmo = 0
            do m=1,mo-1
                firstmo = firstmo + dpm365(mo)
            end do
            firstmo = firstmo + dy
        else if ( nperyear.eq.366 ) then
            firstmo = 0
            do m=1,mo-1
                firstmo = firstmo + dpm(m)
            end do
            firstmo = firstmo + dy
        else
            write(0,*) 'invgetdymo: error: cannot yet hndle nperyear = '
     +           ,nperyear
            call abort
        end if
        end
