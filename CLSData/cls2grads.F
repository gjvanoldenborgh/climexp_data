C========== SCCS configuration management ==========================
C
C	SCCS	File name	: PublicReadGrid.f
C	SCCS	Version		: 1.2
C	SCCS	Storage date	: 04/04/05
C
C==================================================================
C
C=========== RCS configuration management =========================
C
C	RCS	File name	: $RCSfile$
C	RCS	Version		: $Revision$
C	RCS	Storage date	: $Date$
C
C==================================================================
C
C*****************************************************************************
C* PROGRAM : PublicReadATD_Fortran
C*
C* ROLE :
C*    Example to show how to use CDFP_PublicReadGrid module
C*    from Fortran language
C*
C*
C*****************************************************************************
C
C Modifications:
C===============
C
C 2004/01/27: Ph. Poilbarbe
C		Created
C 2004/04/05: Ph. Poilbarbe
C		Adapted for MS-Windows
C
	program cls2garsd
	IMPLICIT NONE

	include "fcc_CDFP_PublicCommon.h"
	include "fcc_CDFP_PublicReadGrid.h"
	integer recfa4
	parameter(recfa4=4)

	INTEGER*4	MaxNumberOfLatitudes
	PARAMETER	(MaxNumberOfLatitudes = 181)
	INTEGER*4	MaxNumberOfLongitudes
	PARAMETER	(MaxNumberOfLongitudes = 360)
	INTEGER*4	MaxNumberOfLayers
	PARAMETER	(MaxNumberOfLayers = 1)

	CHARACTER*80	FileName
	INTEGER*4	GridNumber

	REAL*8		GridData(MaxNumberOfLayers,
     &				 MaxNumberOfLatitudes,
     &				 MaxNumberOfLongitudes)
	REAL*8		Latitudes(MaxNumberOfLatitudes)
	REAL*8		Longitudes(MaxNumberOfLongitudes)
	INTEGER*4	NbLatitudes
	INTEGER*4	NbLongitudes
	INTEGER*4	GridDepth
	INTEGER*4	GridType
	CHARACTER*40	GridUnit

	INTEGER*4	IndexLon
	INTEGER*4	IndexLat
	INTEGER*4	IndexDepth

	integer yr,yr1,mo,mo1,dy1,nstep,ivars(2,1)
	real*4 xx(MaxNumberOfLongitudes),yy(MaxNumberOfLatitudes),zz(1)
	real*4 data(MaxNumberOfLayers,MaxNumberOfLatitudes,
	1  MaxNumberOfLongitudes),weight
	character*5 vars(1)
	character*20 lvars(1),units(1)

	integer*4	Status, jul, julday, dpm(12)
	logical         lexist
	data dpm /31,28,31,30,31,30,31,31,30,31,30,31/
!
!       monthly data
!
	yr    = 1993
	mo    = 0
	nstep = 0
 100	continue
	nstep = nstep + 1
	mo = mo + 1
	if ( mo.gt.12 ) then
	    mo = mo - 12
	    yr = yr + 1
	endif
	write(FileName,'(a,i4.4,a,i2.2,a)') 'hh_msla_oer_merged_h_f_y'
	1    ,yr,'_m',mo,'_l10_1deg.nc'
	GridNumber = 1

	write(*,'(2a)') 'opening ',trim(FileName)
	call fcc_CDFP_ReadGrid(FileName,
     &			       GridNumber,
     &			       GridType,
     &			       GridUnit,
     &			       MaxNumberOfLongitudes,
     &			       MaxNumberOfLatitudes,
     &			       MaxNumberOfLayers,
     &			       GridData,
     &			       Longitudes,
     &			       Latitudes,
     &			       NbLongitudes,
     &			       NbLatitudes,
     &			       GridDepth,
     &			       Status)
	if (Status .ne. 0) goto 200

	where ( GridData == dc_CDFP_DefReal8 ) GridData = 3e33

	if ( nstep.eq.1 ) then
	    open(1,file='msla_merged_1deg.dat')
	    close(1,status='delete')
	    open(1,file='msla_merged_1deg.dat',form='unformatted',
	1	 access='direct',recl=recfa4*NbLatitudes*NbLongitudes)
	endif
	write(1,rec=nstep) ((real(GridData(1,IndexLat,IndexLon)),
	1    IndexLon=1,NbLongitudes),IndexLat=1,NbLatitudes)

	goto 100
 200	continue
!
!       weekly data
!
	jul = julday(mo,1,yr) - julday(1,1,1950)
	do
	    write(FileName,'(a,i5.5,a)') 'msla_oer_merged_h_',jul,'_lr.nc'
	    inquire(file=FileName,exist=lexist)
	    if ( lexist ) exit
	    jul = jul + 1
	end do
	data = 0
	weight = 0
 300	continue
	write(FileName,'(a,i5.5,a)') 'msla_oer_merged_h_',jul,'_lr.nc'

	write(*,'(2a)') 'opening ',trim(FileName)
	call fcc_CDFP_ReadGrid(FileName,
     &			       GridNumber,
     &			       GridType,
     &			       GridUnit,
     &			       MaxNumberOfLongitudes,
     &			       MaxNumberOfLatitudes,
     &			       MaxNumberOfLayers,
     &			       GridData,
     &			       Longitudes,
     &			       Latitudes,
     &			       NbLongitudes,
     &			       NbLatitudes,
     &			       GridDepth,
     &			       Status)
	if (Status .ne. 0) goto 400

	where ( GridData == dc_CDFP_DefReal8 ) GridData = 3e33

	call caldat(jul,mo1,dy1,yr1)
	if ( mo1.ne.mo ) then
	    write(*,'(a,i4.4,i2.2)') 'writing ',yr,mo
	    where ( data /= 3e33 ) data = data/weight
	    write(1,rec=nstep) ((real(data(1,IndexLat,IndexLon)),
	1	 IndexLon=1,NbLongitudes),IndexLat=1,NbLatitudes)
	    mo = mo + 1
	    if ( mo.gt.12 ) then
		mo = mo - 12
		yr = yr + 1
	    endif
	    nstep = nstep + 1
	    data = 0
	    weight = 0
	endif

!	for the time being no interpolation
	where ( data /= 3e33 .and. GridData /= 3e33 ) 
	    data = data + real(GridData)
	elsewhere
	    data = 3e33
	end where
	weight = weight + 1

	jul = jul + 7
	goto 300
!
!       wrap up
!
 400	continue
	if ( weight > 1.5 ) then
	    where ( data /= 3e33 ) data = data/weight
	    write(*,'(a,i4.4,i2.2)') 'writing ',yr,mo
	    write(1,rec=nstep) ((real(data(1,IndexLat,IndexLon)),
	1	 IndexLon=1,NbLongitudes),IndexLat=1,NbLatitudes)
	    nstep = nstep + 1
	endif
	close(1)
	print *,'writing metadata'
	nstep = nstep - 1
	xx = Longitudes
	yy = Latitudes
	zz(1) = 0
	ivars(1,1) = 0
	ivars(2,1) = 99
	vars(1) = 'msla'
	lvars(1) = 'mean sealevel anomaly'
	units(1) = 'm'
	open(1,file='msla_merged_1deg.ctl')
	close(1,status='delete')
	call writectl('msla_merged_1deg.ctl','msla_merged_1deg.dat',
     +    NbLongitudes,xx,NbLatitudes,yy,1,zz,nstep,12,1993,1,
     +    3e33,'CLS msla merged',1,vars,ivars,lvars,units)

	end

