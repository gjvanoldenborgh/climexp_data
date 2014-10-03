	program gen_latlon
	real lats(181),lons(240)
	do i=1,181
	    lats(i) = -91 + i
	end do
	do i=1,240
	    lons(i) = -180 + 1.5*i
	end do
	print '(a)',' latitude = '
	print '(12(f6.0,'',''))',(lats(i),i=1,180)
	print '(f6.0,a)',lats(181),' ;'
	print '(a)',' longitude  = '
	print '(12(f7.1,'',''))',(lons(i),i=1,239)
	print '(f7.1,a)',lons(240),' ;'
	end
