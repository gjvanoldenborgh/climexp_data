      PROGRAM VERIFY_RSS_OISST

c	this program calls the fortran subroutine to read the 
c	daily microwave sst fusion files.  It is currently set
c	to write out the data in the verification file.
	
c	remove or comment out sections you do not have files for
     
      CHARACTER(len=150)			  :: file_name
      REAL*4,   DIMENSION(1440,720) :: sst_data
      REAL*4,   DIMENSION(1440,720) :: error_data
      INTEGER*1,DIMENSION(1440,720) :: mask_data
	INTEGER*4					  :: iexist

CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
	
	!change this path to match your system
	filename='your drive:\your directory\sst\tmi_amsre.fusion.2004.140.v03'	  !change to match your system
	CALL READ_RSS_OISST(file_name,sst_data,error_data,mask_data,iexist)
	if(iexist.eq.0) stop

	write(*,*) 'sst'
	write(*,'(6f11.2)') sst_data(770:775,474:478)

	stop
	end

	include 'read_rss_oisst.f'
