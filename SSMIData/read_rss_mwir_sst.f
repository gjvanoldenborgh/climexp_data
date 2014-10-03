	subroutine read_rss_mwir_sst(filename,sst_data,file_exists)

!	This routine reads version-1 RSS MW IR OI SST daily files
!	You must UNZIP FILES before reading them
!
!	INPUT
! 	filename  with full path in form: mwir.fusion.yyyy.doy.v01
!	    yyyy= year
!		doy	= day of year
!
!	OUTPUT  
!	sst_data  (a 4096 x 2048 real*4 array of data)
!	file_exists  =0 if file read and data returned,  = -1 if no file
!
!	xcell = grid cell values between 1 and 4096
!	ycell = grid cell values between 1 and 2048
!	dx=360./4096.  ! ~9km lat/lon grid 
!	dy=180./2048.
!	Center of grid cell Longitude  is dx*xcell-dx/2.       degrees east
!	Center of grid cell Latitude   is dy*ycell-(90+dy/2.)  -90 to 90
!
!	Please read the data description on www.remss.com
!	To contact RSS support:
!	http://www.remss.com/support


	character(len=150)				:: filename
	real(4),dimension(4096,2048)	:: sst_data
	integer(4)						:: file_exists    

	character(len=1),dimension(4096,2048) :: buffer
	logical lexist

	real(4),parameter				:: scale  = 0.15
	real(4),parameter				:: offset = -3.0

	 
!	check to see if file exists -- if not return a -1 in file_exists
	file_exists=0
	inquire(file=filename,exist=lexist)
	if(.not. lexist) then
		file_exists = -1
		return
	endif

!	open the file and read in character data
	write(*,*) 'reading sst file: ', filename
	open(3,file=filename,status='OLD',RECL=8388608,access='DIRECT',form='UNFORMATTED')
	read(3,rec=1) buffer


!	convert character data to real SSTs using byte scaling and offset parameters
	sst_data = real(ichar(buffer))
	where(sst_data<=250)
		sst_data = (sst_data * scale) + offset
	endwhere


!	close the file and return
	close(3)
	return
	end


