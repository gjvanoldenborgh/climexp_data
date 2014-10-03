	subroutine read_rss_oisst(file_name,sst_data,error_data,mask_data,file_exists)

!	This routine reads version-2 or version-3 RSS MW only, OISST daily files made from tmi and/or amsre data
!	You must UNZIP FILES before reading them
!
!	INPUT
! 	file_name  with path in form satnames.yyyy.doy.v03
!	where satname  = name of satellite ('tmi_amsre', 'amsre', or 'tmi')
!	      yyyy = year
!		  doy  = day of year
!
!	OUTPUT  
!	sst_data  (a 1440 x 720 real*4 array of Sea Surface Temperature)
!	error_data  (a 1440 x 720 real*4 array of the interpolation error estimate)
!	mask_data  (a 1440 x 720 integer*1 array of data masking information)
!			mask_data 
!				bit 0 = 1 for land			
!				bit 1 = 1 for ice
!				bit 2 = 1 for IR data used
!				bit 3 = 1 for MW data used	
!				bit 4 = 1 for bad data	
!     file_exits  = 1 if file read and data returned,  = 0 if no file
!
!	xcell=grid cell values between 1 and 1440
!     ycell=grid cell values between 1 and  720
!     dx=360./1440.
!     dy=180./720.
!	Center of grid cell Longitude  = dx*xcell-dx/2.    (degrees east)
!	Center of grid cell Latitude   = dy*ycell-(90+dy/2.)  (-90 to 90)
!
!	Please read the data description on www.remss.com
!	To contact RSS support:
!	http://www.remss.com/support
!
!	updated 8/2010 d.smith


	integer*4,parameter				:: xdim = 1440
	integer*4,parameter				:: ydim = 720
	character(len=150)				:: file_name
	real*4,dimension(xdim,ydim)		:: sst_data,error_data
	integer*1,dimension(xdim,ydim)	:: mask_data
	integer(4)					    :: file_exists    

	character(len=1),dimension(1440,720) :: buffer
	logical lexist

	real(4),parameter				:: scale  =  0.15
	real(4),parameter				:: offset = -3.0
	real*4,parameter				:: scale_error  = 0.005
	real*4,parameter				:: offset_error = 0.0

	 
!	check to see if file exists -- if not return a -1 in file_exists
	file_exists=0
	inquire(file=file_name,exist=lexist)
	if(.not. lexist) return
	file_exists=1

!	open the file and read in character data
	write(*,*) 'reading sst file: ', file_name
	open(3,file=file_name,status='OLD',RECL=1036800,access='DIRECT',form='UNFORMATTED')
	read(3,rec=1) buffer
	sst_data = real(ichar(buffer))
	read(3,rec=2) buffer
	error_data = real(ichar(buffer))
	read(3,rec=3) buffer
	mask_data = ichar(buffer)
	close(3)

	close(3)

!	section to set land/ice/bad data to flag values in SST and error data arrays using the mask information
	do i=1,xdim
	do j=1,ydim
!		convert character data to real SSTs using byte scaling and offset parameters
		if(sst_data(i,j)<=250) sst_data(i,j)=sst_data(i,j)*scale_sst + offset_sst
!
!		convert character data to real errors using byte scaling and offset parameters
		if(error_data(i,j)<=250) error_data(i,j)=error_data(i,j)*scale_error + offset_error
!
!		add mask to data
		if(btest(mask_data(i,j),0)) then
			sst_data(i,j)=255
			error_data(i,j)=255
		endif
		if(btest(mask_data(i,j),1)) then
			sst_data(i,j)=252
			error_data(i,j)=252
		endif
		if(btest(mask_data(i,j),4)) then
			sst_data(i,j)=254
			error_data(i,j)=254
		endif
	enddo
	enddo


	return
	end


