	PROGRAM CONVERT_89TO2
C*************************************************************************
C
C   ABSTRACT: THIS PROGRAM CONVERTS AN 89X89 SNOW GRID LOCATED ON
C   THE EARTH NATURAL COORDINATE SYSTEM OF LATITUDE/LONGITUDE TO A
C   2X2 DEGREE GRID COORDINATE SYSTEM OVERLAID ON A POLAR STEREOGRAPHIC
C   MAP PROJECTION TRUE AT 60 DEGREES N LATITUDE.
C 
C   THE 2X2 SNOW DATA STARTS AT THE EQUATOR AND GREENWICH AND WRAPS
C   AROUND THE EARTH FROM WEST TO EAST AND WORKS ITS WAY UP TO THE 
C   NORTH POLE.
C
C   VARIABLES:
C
C     isday   - starting day
C     ismth   - startin month
C     isyr    - starting year
C     ieday   - ending day
C     iemth   - ending month
C     ieyr    - ending year
C     idim    - dimension of the x-axis of the output file
C     jdim    - dimension of the y-axis of the output file
C 
C   NOTE: The character variables year,indir,infile,and outfile are
C         used to change the year of the input filename in order to
C         read-in the entire history of (89,89) snow data. (The ending
C         year can be changed to be the same as the starting year so
C         that only one year of snow data is processed at a time.)
C          
C   ARRAYS:
C
C     isndat  - array of size (89) to store rows of snow data read in
C     fld     - array of size (89,89) which stores one week of snow data
C     snow    - array of size (181,46) which stores the 2x2 weekly
C               snow data
C     regsnw  - array of size (180,45) which stores the 2x2 weekly
C               snow data for graphics package compatibility.
C     kweeks  - array of size (22) which stores the number of weeks
C               for each year
C
C   OUTPUT:
C
C     grdxxxx - array of size (180,45) which stores each week of snow data
C               by year. (ie. grd1973, grd1974 ....) This is controlled
C		by parameter istyle = 2.
C     snwfile - array of size (180,45) which stores all the 2x2 weekly
C               snow data. this is controlled by parameter istyle = 1.

C
C***************************************************************************       
C  IMPORTANT:
C
C   CHANGE THE INPUT PARMETERS isday,ismth,istyr,ieday,iemth, and ieyr TO THE
C   YEAR YOU WOULD LIKE TO PROCESS.  I WOULD PROCESS ONE YEAR AT A TIME TO 
C   MAKE SURE EVERYTHING IS WORKING PROPERLY.
C
C*****************************************************************************
        parameter(isday=1,ismth=1,isyr=95)
        parameter(ieday=31,iemth=12,ieyr=95)
        parameter(idim=181,jdim=46)
        parameter(ireg=180,jreg=45)
C..
        DIMENSION kYEAR(53),IMN(53),ISWK(53),IEND(53),
     *  IWKNUM(53)
	integer iland(180,91)
	integer isndat(89)
	real*4 fld(89,89)
	real*4 snow(idim,jdim),regsnw(ireg,jreg)
	real*4 kweeks(32)
        character*4 year
C**************************************************************************
C IMPORTANT:
C
C   You need specify the character names (location) and lengths for these 
C   input and output character filenames.
C
C**************************************************************************
        character*? indir,date*?,infil2*?
        character*? infile 
       character*? outfile,outfil1*?
C..
        data kweeks/52,52,52,53,52,52,52,52,53,52,52,
     *              52,52,52,53,52,52,52,52,53,52,52,
     *              52,52,53,52,52,52,52,52,53,52/
C..
C**************************************************************************
C IMPORTANT:
C
C..  Note: Program will automatically stick a date at the end of the next
C..        three parameters.  Example:
C..
C..			????? - YOU MUST SPECIFY PATH NAME
C..
C.. 			date = '/?????/yr' --> date = '/?????/yr1996'
C..			indir='/?????/wk'  --> indir='/?????/wk1996'
C..			outfil1= '/?????/grd' -> outfil1= '/?????/grd1996'
C..
C***************************************************************************
        date = '/?????/yr'  (* Year file from anonymous ftp *)
        indir='/?????/wk'   (* Weekly 89X89 file from anonymous ftp *)
        outfil1= '/?????/grd'  (* 2x2 output file ie: /home/grd1996 *)
C..
C..
        OPEN(9,file='/?????/mask2d',  (* mask2d file from anonymous ftp *) 
     *     access='sequential',form='formatted') 
        call w3fs17(isyr,ismth,isday,ncns)
        print *,' start date ',isyr,ismth,isday,ncns
        call w3fs17(ieyr,iemth,ieday,ncne)
        print *,' end date ',ieyr,iemth,ieday,ncne
        kys=isyr+1900
        kye=ieyr+1900
C..
        nweek=0
        nyear=0
C..
      DO 14 I=1,180                                                             
      READ (9,16) (ILAND(I,J),J=1,71)                                           
   16 FORMAT (71I1)                                                             
      READ (9,16) (ILAND(I,J),J=72,91)                                          
   14 CONTINUE
C..
C.. Loop through snow data from start year to end year
C..
        do iyear=kys,kye
        write(year,'(I4)') iyear
C..
C.. The variable infile is the filename of the (89,89) snow file to be
C.. read-in.
C..
        infile=indir // year
        infil2=date // year
        print *,'year ',year,' infile ',infile
        open(1,file=infil2,form='formatted',access='sequential')
        open(11,file=infile,form='formatted',access='sequential')
C..      nyear=nyear+1
        nyear=iyear-1972
        kweek=kweeks(nyear)
C..
C.. Loops through the number of weeks for that particular year.
C..
        do iweek=1,kweek
        nweek=nweek+1
        ncn=ncns+(nweek-1)*7
	i = iweek
C..
	if(istyle.eq.2) then
	  read(1,6) kyear(i),imn(i),iswk(i),hyp,iend(i),iwknum(i)
 6        FORMAT(1X,I4,I3,I4,A1,I2,I4)
          if(imn(i).gt.iemth. and .kyear(i).eq.kye) go to 999
          print *,'iyear',kyear(i),'imn',imn(i),'eyr',kye,
     *           'iemth',iemth
	end if 
C..
        call w3fs19(ncn,iyr,imth,iday)
        print *,'total week ',nweek,' year week ',iweek,
     *  ' date ',iyr,imth,iday
C..
C.. Read in the snow data to array fld(89,89)
C..
	do i=1,89
	read(11,'(i4,2i2,a1,45i1)')
     &  iyears,iwks,irow,ichar,(isndat(j),j=1,45)
C..      print *,iyears,iwks,irow,ichar,isndat(j)
        read(11,'(i4,2i2,a1,44i1)')
     &  iyears,iwks,irow,ichar,(isndat(j),j=46,89)
C..      print *,iyears,iwks,irow,isndat(j)
        do j=1,89
        fld(j,i)=float(isndat(j))
	enddo
	enddo
C..
        read(11,'(i4)') iyears
        if (iyears .ne. 9999) then
        print *,'error in week ',nweek,' and years ',iyears
        call abort
        endif
C..
C.. This loop converts (89,89) snow data to (181,46)
C..

        do j=1,jdim
        jj= jdim+1 - j
        do i=1,idim
	alat = (j-1) * 2
        wlon = 360. - (i-1) * 2
C..
        call w3fb04(alat,wlon,190.5,80.,xi,xj)
        xi = xi + 44.5
        xj = xj + 44.5
	call w3ft01 (xi,xj,fld,snocov,89,89,0,1)
C..
C.. The variable snocov was interpolated to the (181,46), which is a 
C.. fractional value.  The if statment below tests if the grid box was
C.. 50% or more fractionally (snow) covered.  If it was then the grid
C.. box is given a value of (1) signifying the entire grid box was snow
C.. covered. Otherwise a value of (0) is put in the grid box signifying
C.. no snow cover.
C..

	if (snocov .ge. 0.5) then
        snow(i,jj) = 1.
	else
        snow(i,jj) = 0.
	endif
C..
	enddo
	enddo
C..
C.. The array snow is now rewritten as (180,45) array called regsnw.  
C.. The grid is rewritten so it conforms with graphing packages.  The 
C.. file is written out as an unformatted (180,45) grid array, which
C.. consists of zeros and ones.
C..
        call conv(snow,regsnw)
C..
C..  The subroutine mask2d changes all points located over water to 999.0
C..
	CALL MASK2D(iland,regsnw)
C..
        outfile = outfil1 // year
        print *,'year ',year,' outfile ',outfile
C..
        open(51,file=outfile,form='unformatted')
        write (51) regsnw 
	enddo
	enddo
C..
 999    stop
        end
       SUBROUTINE W3FB04(ALAT,ALONG,XMESHL,ORIENT,XI,XJ)
C$$$   SUBPROGRAM  DOCUMENTATION  BLOCK
C
C SUBPROGRAM: W3FB04         LATITUDE, LONGITUDE TO GRID COORDINATES
C   AUTHOR: MCDONELL,J.      ORG: W345       DATE: 86-07-17
C
C ABSTRACT: CONVERTS THE COORDINATES OF A LOCATION ON EARTH FROM THE
C   NATURAL COORDINATE SYSTEM OF LATITUDE/LONGITUDE TO THE GRID (I,J)
C   COORDINATE SYSTEM OVERLAID ON A POLAR STEREOGRAPHIC MAP PRO-
C   JECTION TRUE AT 60 DEGREES N OR S LATITUDE. W3FB04 IS THE REVERSE
C   OF W3FB05.
C
C PROGRAM HISTORY LOG:
C   86-07-17  MCDONELL,J.
C   88-06-07  R.E.JONES   CLEAN UP CODE, TAKE OUT GOTO, USE THEN, ELSE
C   89-11-02  R.E.JONES   CHANGE TO CRAY CFT77 FORTRAN
C
C USAGE:  CALL W3FB04 (ALAT, ALONG, XMESHL, ORIENT, XI, XJ)
C
C   INPUT VARIABLES:
C     NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C     ------ --------- -----------------------------------------------
C     ALAT   ARG LIST  LATITUDE IN DEGREES (<0 IF SH)
C     ALONG  ARG LIST  WEST LONGITUDE IN DEGREES
C     XMESHL ARG LIST  MESH LENGTH OF GRID IN KM AT 60 DEG LAT(<0 IF SH)
C                   (190.5 LFM GRID, 381.0 NH PE GRID,-381.0 SH PE GRID)
C     ORIENT ARG LIST  ORIENTATION WEST LONGITUDE OF THE GRID
C                   (105.0 LFM GRID, 80.0 NH PE GRID, 260.0 SH PE GRID)
C
C   OUTPUT VARIABLES:
C     NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C     ------ --------- -----------------------------------------------
C     XI     ARG LIST  I OF THE POINT RELATIVE TO NORTH OR SOUTH POLE
C     XJ     ARG LIST  J OF THE POINT RELATIVE TO NORTH OR SOUTH POLE
C
C   SUBPROGRAMS CALLED:
C     NAMES                                                   LIBRARY
C     ------------------------------------------------------- --------
C     COS SIN                                                 SYSLIB
C
C   REMARKS: ALL PARAMETERS IN THE CALLING STATEMENT MUST BE
C     REAL. THE RANGE OF ALLOWABLE LATITUDES IS FROM A POLE TO
C     30 DEGREES INTO THE OPPOSITE HEMISPHERE.
C     THE GRID USED IN THIS SUBROUTINE HAS ITS ORIGIN (I=0,J=0)
C     AT THE POLE IN EITHER HEMISPHERE, SO IF THE USER'S GRID HAS ITS
C     ORIGIN AT A POINT OTHER THAN THE POLE, A TRANSLATION IS NEEDED
C     TO GET I AND J. THE GRIDLINES OF I=CONSTANT ARE PARALLEL TO A
C     LONGITUDE DESIGNATED BY THE USER. THE EARTH'S RADIUS IS TAKEN
C     TO BE 6371.2 KM.
C
C WARNING:  THIS CODE IS NOT VECTORIZED. TO VECTORIZE TAKE IT AND
C           SUBROUTINE IT CALLS AND PU THEM IN LINE.
C
C ATTRIBUTES:
C   LANGUAGE: CRAY CFT77 FORTRAN
C   MACHINE:  CRAY Y-MP8/832
C
C$$$
C
      DATA  RADPD /.01745329/
      DATA  EARTHR/6371.2/
C
      RE    = (EARTHR * 1.86603) / XMESHL
      XLAT  = ALAT * RADPD
C
      IF (XMESHL.GE.0.) THEN
        WLONG = (ALONG + 180.0 - ORIENT) * RADPD
        R     = (RE * COS(XLAT)) / (1.0 + SIN(XLAT))
        XI    =   R * SIN(WLONG)
        XJ    =   R * COS(WLONG)
      ELSE
        RE    = -RE
        XLAT  = -XLAT
        WLONG = (ALONG - ORIENT) * RADPD
        R     = (RE * COS(XLAT)) / (1.0 + SIN(XLAT))
        XI    =   R * SIN(WLONG)
        XJ    =  -R * COS(WLONG)
      ENDIF
C
      RETURN
      END
       SUBROUTINE W3FT01(STI,STJ,FLD,HI,II,JJ,NCYCLK,LIN)
C$$$   SUBPROGRAM  DOCUMENTATION  BLOCK
C
C SUBPROGRAM: W3FT01         INTERPOLATE VALUES IN A DATA FIELD
C   AUTHOR: MCDONELL, J.     ORG: W345       DATE: 84-06-27
C   UPDATE: JONES,R.E.       ORG: W342       DATE: 87-03-19
C
C ABSTRACT: FOR A GIVEN GRID COORDINATE IN A DATA ARRAY, ESTIMATES
C   A DATA VALUE FOR THAT POINT USING EITHER A LINEAR OR QUADRATIC
C   INTERPOLATION METHOD.
C
C PROGRAM HISTORY LOG:
C   84-06-27  J.MCDONELL
C   89-11-01  R.E.JONES   CHANGE TO CRAY CFT77 FORTRAN
C
C USAGE:  CALL W3FT01 (STI, STJ, FLD, HI, II, JJ, NCYCLK, LIN)
C
C   INPUT VARIABLES:
C     NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C     ------ --------- -----------------------------------------------
C     STI    ARG LIST  REAL*4 I GRID COORDINATE OF THE POINT FOR WHICH
C                      AN INTERPOLATED VALUE IS DESIRED
C     STJ    ARG LIST  REAL*4 J GRID COORDINATE OF THE POINT FOR WHICH
C                      AN INTERPOLATED VALUE IS DESIRED
C     FLD    ARG LIST  REAL*4 SIZE(II,JJ) DATA FIELD
C     II     ARG LIST  INTEGER*4 NUMBER OF COLUMNS IN 'FLD'
C     JJ     ARG LIST  INTEGER*4 NUMBER OF ROWS IN 'FLD'
C     NCYCLK ARG LIST  INTEGER*4 CODE TO SPECIFY IF GRID IS CYCLIC OR
C                      NOT:
C                       = 0 NON-CYCLIC IN II, NON-CYCLIC IN JJ
C                       = 1 CYCLIC IN II, NON-CYCLIC IN JJ
C                       = 2 CYCLIC IN JJ, NON-CYCLIC IN II
C                       = 3 CYCLIC IN II, CYCLIC IN JJ
C     LIN    ARG LIST  INTEGER*4 CODE SPECIFYING INTERPOLATION METHOD:
C                       = 1 LINEAR INTERPOLATION
C                      .NE.1  QUADRATIC INTERPOLATION
C
C   OUTPUT VARIABLES:
C     NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C     ------ --------- -----------------------------------------------
C     HI     ARG LIST  REAL*4 DATA FIELD VALUE AT (STI,STJ) OBTAINED
C                      BY INTERPOLATION.
C
C ATTRIBUTES:
C   LANGUAGE: CRAY CFT77 FORTRAN
C   MACHINE:  CRAY Y-MP8/832
C
C$$$
C
      REAL    ERAS(4)
      REAL    FLD(II,JJ)
      REAL    JY(4)
C
      I     = STI
      J     = STJ
      FI    = I
      FJ    = J
      XDELI = STI - FI
      XDELJ = STJ - FJ
      IP2   = I + 2
      IM1   = I - 1
      IP1   = I + 1
      JY(4) = J + 2
      JY(1) = J - 1
      JY(3) = J + 1
      JY(2) = J
      XI2TM = 0.0
      XJ2TM = 0.0
      IF (LIN.NE.1) THEN
        XI2TM = XDELI * (XDELI - 1.0) * 0.25
        XJ2TM = XDELJ * (XDELJ - 1.0) * 0.25
      ENDIF
      IF ((I.LT.2).OR.(J.LT.2))       GO TO 10
      IF ((I.GT.II-3).OR.(J.GT.JJ-3)) GO TO 10
C
C     QUADRATIC (LINEAR TOO) OK W/O FURTHER ADO SO GO TO 170
C
      GO TO 170
C
   10 CONTINUE
        ICYCLK = 0
        JCYCLK = 0
        IF (NCYCLK) 20,120,20
C
   20 CONTINUE
        IF (NCYCLK / 2 .NE. 0) JCYCLK = 1
        IF (NCYCLK .NE. 2)     ICYCLK = 1
        IF (ICYCLK) 30,70,30
C
   30 CONTINUE
        IF (I.EQ.1)      GO TO 40
        IF (I.EQ.(II-1)) GO TO 50
        IP2 = I + 2
        IM1 = I - 1
        GO TO 60
C
   40 CONTINUE
        IP2 = 3
        IM1 = II - 1
        GO TO 60
C
   50 CONTINUE
        IP2 = 2
        IM1 = II - 2
C
   60 CONTINUE
        IP1 = I + 1
C
   70 CONTINUE
        IF (JCYCLK) 80,120,80
C
   80 CONTINUE
        IF (J.EQ.1)      GO TO 90
        IF (J.EQ.(JJ-1)) GO TO 100
        JY(4) = J + 2
        JY(1) = J - 1
        GO TO 110
C
   90 CONTINUE
        JY(4) = 3
        JY(1) = JJ - 1
        GO TO 110
C
  100 CONTINUE
        JY(4) = 2
        JY(1) = JJ - 2
C
  110 CONTINUE
        JY(3) = J + 1
        JY(2) = J
C
  120 CONTINUE
        IF (LIN.EQ.1) GO TO 160
        IF (ICYCLK) 140,130,140
C
  130 CONTINUE
        IF ((I.LT.2).OR.(I.GE.(II-1)))  XI2TM = 0.0
C
  140 CONTINUE
        IF (JCYCLK) 160,150,160
C
  150 CONTINUE
        IF ((J.LT.2).OR.(J.GE.(JJ-1)))  XJ2TM = 0.0
C
  160 CONTINUE
C
C.....DO NOT ALLOW POINT OFF GRID,CYCLIC OR NOT
C
        IF (I.LT.1)   I   = 1
        IF (IP1.LT.1) IP1 = 1
        IF (IP2.LT.1) IP2 = 1
        IF (IM1.LT.1) IM1 = 1
C
C.....DO NOT ALLOW POINT OFF GRID,CYCLIC OR NOT
C
        IF (I.GT.II)   I   = II
        IF (IP1.GT.II) IP1 = II
        IF (IP2.GT.II) IP2 = II
        IF (IM1.GT.II) IM1 = II
C
  170 CONTINUE
      DO 180 K = 1,4
        J1 = JY(K)
C
C.....DO NOT ALLOW POINT OFF GRID,CYCLIC OR NOT
C
        IF (J1.LT.1)  J1 = 1
        IF (J1.GT.JJ) J1 = JJ
       ERAS(K) = (FLD(IP1,J1) - FLD(I,J1)) * XDELI + FLD(I,J1) +
     &  (FLD(IM1,J1) - FLD(I,J1) - FLD(IP1,J1) + FLD(IP2,J1)) * XI2TM
  180 CONTINUE
C
      HI = ERAS(2) + (ERAS(3) - ERAS(2)) * XDELJ + (ERAS(1) -
     &     ERAS(2) -  ERAS(3) + ERAS(4)) * XJ2TM
C
      RETURN
      END
      SUBROUTINE W3FS17(NYY,NMM,NDD,NCEN)
C$$$  SUBPROGRAM DOCUMENTATION BLOCK                                  
C                .      .    .                                       
C SUBPROGRAM:    W3FS17      DAY TO SERIAL DAY OF CENTURY            
C   PRGMMR: R.E.JONES        ORG: W421       DATE: 89-10-25            
C
C ABSTRACT: CONVERTS A GIVEN DATE (YEAR, MONTH, DAY) TO THE SERIAL
C   DAY OF THE TWENTIETH CENTURY. W3FS17 IS THE REVERSE OF W3FS19.
C
C PROGRAM HISTORY LOG:
C   84-06-21  J.HOWCROFT
C   89-10-25  R.E.JONES    CONVERT TO CRAY CFT77 FORTRAN
C                                                                     
C USAGE:    CALL W3FS17(NYY, NMM, NDD, NCN)
C
C   INPUT ARGUMENT LIST:                                               
C      NYY     - INTEGER YEAR OF CENTURY, 00-99
C      NMM     - INTEGER MONTH OF YEAR,    1-12
C      NDD     - INTEGER DAY OF MONTH,     1-31
C                                                                    
C   OUTPUT ARGUMENT LIST:                                            
C      NCN     - INTEGER DAY OF THE CENTURY
C                                                                       
C   RESTRICTIONS: THIS PROCEDURE IS VALID FROM JAN. 1, 1900 THRU
C     FEB. 2000.  IT WOULD BE BETTER TO USE A JULIAN DAY NUMBER,
C     FUNCTION IW3JDN,  USE OF THIS FUNCTION WILL TAKE CARE OF THE
C     YEAR 2000 PROBLEM. W3FS26 CONVERTS THE JULIAN DAY NUMBER INTO
C     YEAR, MONTH, DAY, DAY OF WEEK, DAY OF YEAR.
C
C   NOTES: THE INPUT DATA IS NOT VALIDATED.
C
C ATTRIBUTES:
C   LANGUAGE: CRAY CFT77 FORTRAN
C   MACHINE:  CRAY Y-MP8/832
C
C$$$
C
      INTEGER NTAB(12)
C
      DATA  NTAB/0,31,59,90,120,151,181,212,243,273,304,334/
C
      LP = 0
      IF (MOD(NYY,4).EQ.0 .AND. NYY.NE.0)  LP = 1
      NLP  = NYY / 4
      IF (LP.EQ.1 .AND. NLP.GT.0)  NLP = NLP - 1
      IF (LP.EQ.1 .AND. NMM.LT.3)  LP  = 0
      JDAY = NTAB(NMM) + NDD  + LP
      NCEN = NYY * 365 + JDAY + NLP
      RETURN
      END
       SUBROUTINE W3FS19 (NCEN,NYR,MON,NDAY)
C$$$   SUBPROGRAM  DOCUMENTATION  BLOCK
C
C SUBPROGRAM: W3FI19         YEAR, MONTH, AND DAY FROM DAY OF CENTURY
C   AUTHOR: HOWCROFT,J.      ORG: W342       DATE: 84-06-21
C
C ABSTRACT: CALCULATES YEAR, MONTH, AND DAY WHEN GIVEN THE SERIAL
C   DAY OF CENTURY. W3FS19 IS THE REVERSE OF W3FS17.
C
C PROGRAM HISTORY LOG:
C   84-06-21  JIM HOWCROFT
C   89-10-25  R.E.JONES      CONVERT TO CFT77 FORTRAN
C
C USAGE: CALL W3FS19 (NCEN,NYR,MON,NDAY)
C
C   INPUT VARIABLES:
C     NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C     ------ --------- -----------------------------------------------
C     NCEN   ARG LIST  INTEGER   DAY OF CENTURY FROM JAN. 1, 1900
C
C   OUTPUT VARIABLES:
C     NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C     ------ --------- -----------------------------------------------
C     NYR    ARG LIST  INTEGER   YEAR
C     MON    ARG LIST  INTEGER   MONTH
C     NDAY   ARG LIST  INTEGER   DAY
C
C ATTRIBUTES:
C   LANGUAGE: CRAY CFT77 FORTRAN
C   MASHINE:  CRAY Y-MP8/832
C
C$$$
C
       INTEGER   NTAB(24)
C
       DATA  NTAB  /0,31,59,90,120,151,181,212,243,273,304,334,
     &              0,31,60,91,121,152,182,213,244,274,305,335/
C
       LP = 0
       IF (NCEN.GT.365) GO TO 10
          NYR  = 0
          NDAY = NCEN
          GO TO 25
C
   10  CONTINUE
         NSY = (NCEN - 365) / 1461
         NDR = MOD((NCEN-365),1461)
         IF (NDR.NE.0) GO TO 15
           NDAY = 366
           LP   = 12
           NYR  = (NCEN - 366) / 365
           GO TO 25
C
   15  CONTINUE
         NYER = NSY *4 + 1
         N    = NDR / 365
         NDAY = NDR - N * 365
         IF (NDAY.NE.0) GO TO 20
           NDAY = 365
           N    = N - 1
C
   20  CONTINUE
         NYR = NYER + N
         IF ((MOD(NYR,4).EQ.0) .AND. NYR.NE.0) LP = 12
C
   25  CONTINUE
       DO 30 N = 2,12
          MON = N - 1
          IF (NDAY.LE.NTAB(N+LP)) GO TO 35
   30  CONTINUE
         MON = 12
C
   35  CONTINUE
         NDAY = NDAY - NTAB(MON+LP)
         RETURN
       END
C
       SUBROUTINE CONV (SNOW,REGSNW)
C$$$   SUBPROGRAM  DOCUMENTATION  BLOCK
C..
C.. SUBPROGRAM: CONV         YEAR, MONTH, AND DAY FROM DAY OF CENTURY
C..   AUTHOR: GARRETT,D.       ORG: W/NMC52       DATE: 94-02-26
C..
C.. ABSTRACT: THIS SUBROUTINE TRANSFORMS A (180,46) GRID INTO A
C.. 	      (180,45) GRID FOR DISPLAY PURPOSES.
C..	    
C..
C.. PROGRAM HISTORY LOG:
C..  94-02-26  GARRETT,D.
C..  95-06-19  GARRETT,D.   ADDT'L DOCUMENTION
C..
C.. USAGE:  CALL CONV(SNOW,REGSNW)
C..
C.. INPUT VARIABLES:
C..   NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C..   ------ --------- -----------------------------------------------
C..   SNOW  ARG LIST  REAL*4 (180,46) ARRAY OF THE SNOW DATA
C..                   VALUES --> (0'S AND 1'S)
C..
C.. OUTPUT VARIABLES:
C..   NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C..   ------ --------- -----------------------------------------------
C..   REGSNW ARG LIST  REAL*4 (180,45) ARRAY OF THE SNOW DATA
C..                    VALUES --> (0'S AND 1'S)
C..
C..     
        parameter(idim=181,jdim=46)
        parameter(nlon=180,nlat=45)
	real*4 snow(idim,jdim),regsnw(nlon,nlat)
C..
	do j=1,nlat
 	  jj=j+1
          jk=nlat+1-j
	  do i=1,nlon
	    regsnw(i,jk)=snow(i,jj)
	  enddo
        enddo
	return 
	end
C..
      SUBROUTINE MASK2D(ILAND,LAND)                                                           
C$$$   SUBPROGRAM  DOCUMENTATION  BLOCK
C
C..SUBPROGRAM: MASK2D         MASK OUT ALL WATER POINTS
C.. AUTHOR: GARRETT,D.       ORG: W/NMC52       DATE: 94-04-10
C..
C.. ABSTRACT: THIS SUBROUTINE IDENTIFIES WATER POINTS AND REPLACES THEM
C.. 	      WITH 999.9
C..	    
C..
C.. PROGRAM HISTORY LOG:
C..  94-04-10  GARRETT,D.
C..  95-06-19  GARRETT,D.  ADDT'L DOCUMENTATION
C..
C..USAGE:  CALL MASK2D(ILAND,LAND)
C..
C.. INPUT VARIABLES:
C..   NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C..   ------ --------- -----------------------------------------------
C..   ILAND  ARG LIST  INTEGER*4 (180,91) ARRAY OF THE LAND SEA POINTS
C..                    VALUES --> (0'S AND 1'S)
C..
C.. OUTPUT VARIABLES:
C..   NAMES  INTERFACE DESCRIPTION OF VARIABLES AND TYPES
C..   ------ --------- -----------------------------------------------
C..   LAND   ARG LIST  REAL*4 (180,45) ARRAY OF LAND/SEA MASK SNOW DATA  
C..                    VALUES --> (0'S, 1'S, AND 999.9)
C..                                                                               
                                      
C.. OBS ARRAY IS SET TO 1 OVER MASKED AREAS                                      
C.. OTHERWISE, OBS ARRAY IS SET TO 0 FOR NO DATA AND 1 FOR DATA                  
      INTEGER ILAND(180,91) 
      REAL LAND(180,45)                                                                                                               	                    C..                                
      DO 17 I1 = 1,180  
	DO 18 J1 = 46,90 
C..
C..  If the value of iland is zero then the grid point is considered water and
C..  given a value of 999.9.  The value was chosen for input into GraDS
C..
	  IF(ILAND(I1,J1).EQ.0) THEN
	    J2 = J1 - 45
	    LAND(I1,J2) = 999.9
	  END IF
  18	CONTINUE
C..	WRITE(6,200) (LAND(I1,J2),J2=1,45)
C.. 200 FORMAT(45F6.1) 
  17  CONTINUE
      RETURN
      END 
