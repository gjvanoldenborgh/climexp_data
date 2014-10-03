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
	PROGRAM PublicReadGrid_Fortran
	IMPLICIT NONE

	include "fcc_CDFP_PublicCommon.h"
	include "fcc_CDFP_PublicReadGrid.h"

	INTEGER*4	MaxNumberOfLatitudes
	PARAMETER	(MaxNumberOfLatitudes = 181)
	INTEGER*4	MaxNumberOfLongitudes
	PARAMETER	(MaxNumberOfLongitudes = 720)
	INTEGER*4	MaxNumberOfLayers
	PARAMETER	(MaxNumberOfLayers = 10)

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

	INTEGER*4	Status

	write(*, 1000) 'Name of netcdf grid file to read:'
1000	format(A,$)
	read(*, 1005) FileName
1005	format(A)
	write(*, 1000) 'Grid name (positive number)     :'
	read(*, 1006) GridNumber
1006	format(I5)
	write(*, 1010)
1010	format(1X)

	write (*, 1020) GridNumber, FileName
1020	format('Grid ',I4, ' of file ',A,/,
	1    'has been accessed by program PublicReadGrid_Fortran',/,
	2    79('='),2(/))


C
C
C Read the grid
C
C
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
	if (Status .ne. 0) goto 9998


C
C
C Write grid characteristics
C
C
	if (GridType .eq. E_CDFP_GridDots) then
	  write (*, 1030) 'DOTS'
	else if (GridType .eq. E_CDFP_GridBoxes) then
	  write (*, 1030) 'BOXES'
	else if (GridType .eq. E_CDFP_GridDotsMercator) then
	  write (*, 1030) 'MERCATOR DOTS'
	else if (GridType .eq. E_CDFP_GridBoxesMercator) then
	  write (*, 1030) 'MERCATOR BOXES'
	else
	  write (*, 1030) 'UNKNOWN', GridType
	end if

	write (*, 1040) GridUnit, NbLongitudes, NbLatitudes, GridDepth
1030	format ('Grid type                  : ', A, :, ' (',I5,')')
1040    format ('Grid unit                  : ',A,/
     &		'Number of longitude samples: ',I8,/,
     &		'Number of latitude samples : ',I8,/,
     &		'Number of layers (depth)   : ',I8)

C
C
C Write longitudes/latitudes
C
C
	write (*, 1050) 'Longitudes',
	1  (IndexLon, Longitudes(IndexLon), IndexLon=1,NbLongitudes)
	write (*, 1050) 'Latitudes',
	1  (IndexLat, Latitudes(IndexLat), IndexLat=1,NbLatitudes)
1050	format (/,A,':',9999(/,'       ',I4,': ',F12.6))

C
C
C Write grid data
C
C
	write (*,1010)
	write (*,1010)
	do IndexLon=1, NbLongitudes
	  do IndexLat=1, NbLatitudes
	    write (*, 1060) IndexLat, IndexLon
1060        format ('          Data[*,',I4,',',I4,'] =',$)
	    do IndexDepth=1, GridDepth
C
C
C	    All values at the same position are printed on the same line
C
C
	      if (GridData(IndexDepth, IndexLat, IndexLon) .eq. 
	1	     dc_CDFP_DefReal8) then
		write (*, 1070)
	      else
		write (*, 1080) GridData(IndexDepth, IndexLat, IndexLon)
	      endif
1070	      format ('    -default-   ',$)
1080	      format (' ',G13.6,$)
	    end do

	    write (*, 1010)
	  end do
	end do

	goto 10000

9998	CONTINUE
	write (*, 2000) FileName
2000    format ('Error accessing file ',A)

9999	CONTINUE
	STOP 1

10000	CONTINUE
	END

