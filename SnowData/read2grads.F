UNFINISHED
      PROGRAM RSNO
*       GJvO KNMI:
*       added recfac.h to get correct size of direct access recl on all my systems
*       take care that the values stay between 0 and 1.
*       went to 2.5x2 grads grid instead of 1x1 degree
*       include empty records for jan-oct 1966
*       change undef to 3e33 from -999999
*       block out sea points (change in definition at 1981 gives spurious correlations)
*       now use the weekly data from http://www.nnic.noaa.gov/data/snow,
*       so I have to interpolate in time.
#undef NOSEA
#include "recfac.h"
      parameter (xpd=2*31.204359052,xp=44.5,yp=44.5,xax=10.)
      parameter (ix=89,jx=89,zimin=0.,ziinc=2.5,ie=144,zjmin=20.)
      parameter (zjinc=2.,je=36)
      parameter (ndim=(ie*je+1)/2)
      DIMENSION X(ix,jx),irow(je),ilw(ix,jx)
      dimension e(ie,je),em(ie,je),emonth(ie,je),nbuf(ndim)
      character nb*72,file*6
C INITIALIZE FOR INTERPOLATION
      CALL NUINIT(XPD,XP,YP,XAX,IX,JX,1,EM,
     2 ZIMIN,ZIINC,IE,ZJMIN,ZJINC,JE,2,IST)
C EXAMPLE READ FOR NESDIS SNOWCOVER FIELDS - DS315.0.
C
C-------------------------------------------------------------------------
      NF=1
      irec=0
      open(2,file='nhsnow.dat',status='new',access='direct',
     2 form='unformatted',recl=ie*je*recfa4)
*
#ifdef NOSEA
C READ LAND/WATER GRID
        open(1,file='data_landwater',status='old')
        read(1,'(a)') nb
        do j=1,jx
 1002       format(6x,i2,3x,89i1)
            read(1,1002) jj,(ilw(i,j),i=1,89)
            if ( jj.ne.j ) then
                print *,'error: j.ne.jj: ',j,jj
                stop
            endif
            print 1002,j,(ilw(i,j),i=1,89)
        enddo
        close(1)
#endif
* read data
        do iyr=1973,2100
            write(file,'(a,i4.4)') 'wk',iyr
            open(1,file=file,status='old',err=800)
   10       continue
            irec=irec+1
            READ(5,1001,END=80)(IROW(J),(X(I,J),I=1,89),J=1,89)
 1001       FORMAT(6X,I2,3X,89f1.0)
#ifdef  NOSEA
*       put sea points to zero
        do j=1,jx
            do i=1,ix
                if ( ilw(i,j).eq.0 ) x(i,j) = 0
            enddo
        enddo
#endif
      CALL NUGRID(X,IX,JX,E,EM,IE,JE)
        do j=1,je
            do i=1,ie
                if ( e(i,j).lt.-999000 .or. e(i,j).gt.1e10 ) then
                    e(i,j) = 3e33
                elseif ( e(i,j).ge.0 .and. e(i,j).le.1 ) then
*                   do nothing
                elseif ( e(i,j).lt.0 .and. e(i,j).gt.-0.3 ) then
                    e(i,j) = 0
                elseif ( e(i,j).gt.1 .and. e(i,J).lt.1.3 ) then
                    e(i,j) = 1
                else
                    print *,'error: e(i,j) = ',e(i,j)
                    e(i,j) = 3e33
                endif
            enddo
        enddo
      write(2,rec=irec)e
      GO TO 10
   80 CONTINUE
        enddo                   ! loop over years
  800   continue
      NF=NF+1
      write(*,*) 'NUMBER OF RECORDS= ',IREC
      END
      SUBROUTINE NUGRID(A,IDIM,JDIM,E,EM,LOND,LATD)
C
C DO INTERPOLATION FROM POLAR STEREO GRID A TO LAT-LON GRID E.
C EM  IS AN ARRAY SET BY NUINIT WITH POINTS, WHICH CANNOT BE INTERPOLATED,
C    FLAGGED BY THE VALUE "XOUT".
C
      DIMENSION E(LOND,LATD), A(IDIM,JDIM),EM(LOND,LATD)
      PARAMETER (PI=3.14159265,PI4=PI/4.,DEGRAD=PI/180.)
      PARAMETER (XOUT=3e33)
C
C DEFINE DEFAULT GRID PARAMETERS (REDEFINED BY CALL TO NUINIT).
C         DEFAULTS ARE NMC 47X51 GRID.
C
C
C     DATA YER,YPI,YPJ,YAX,YMNLON,YDLON,NLON,YMNLAT,YDLAT,NLAT,NINT
C    2   /31.204359052,24,26,10.,0.,5.,73,20.,5.,15,2/
      DATA YER,YPI,YPJ,YAX,YMNLON,YDLON,NLON,YMNLAT,YDLAT,NLAT,NINT
     2   /31.204359052,33,33,10.,0.,5.,73,20.,5.,15,2/
C
C  INTERP A LAT-LON ARRAY E FROM A POLAR STEREO ARRAY  A
C
      ZLAT=YMNLAT
      DO 205  J = 1,NLAT
      R=YER*(TAN(PI4-ABS(DEGRAD*ZLAT/2)))
      ZLON=YMNLON
      DO 200  I = 1,NLON
      IF(EM(I,J).EQ.XOUT) THEN
        E(I,J)=XOUT
        GO TO 199
      ENDIF
      ANG=(ZLON-YAX) * DEGRAD
      XX=R*COS(ANG) + YPI
      YY=R*SIN(ANG) + YPJ
C  XX AND YY ARE THE EXACT INDEX VALUES OF THE LAT-LON POINT IN IJ GRID
      M = XX
      N = YY
      DX = XX - M
      DY = YY - N
      IF(NINT.NE.2) GO TO 190
C  DO THE 16 PT BESSEL INTERP SCHEME
      DXX = .25 *(DX - 1.)
      DYY = .25 *(DY - 1.)
      AA = A(M,N-1) + DX *(A(M+1,N-1) - A(M,N-1) + DXX *(A(M+2,N-1) -
     2 A(M+1,N-1) + A(M-1,N-1) - A(M,N-1)))
      AB = A(M,N) + DX*(A(M+1,N) - A(M,N) + DXX *(A(M+2,N) - A(M+1,N) +
     X  A(M-1,N) - A(M,N)))
      AC = A(M,N+1) + DX *(A(M+1,N+1) - A(M,N+1) + DXX *(A(M+2,N+1) - A(
     2 M+1,N+1) + A(M-1,N+1) - A(M,N+1)))
      AD = A(M,N+2) + DX *(A(M+1,N+2) -A(M,N+2) + DXX *(A(M+2,N+2) - A(M
     2 +1,N+2) + A(M-1,N+2) - A(M,N+2)))
      E(I,J) = AB + DY *(AC - AB + DYY *(AD - AC + AA - AB))
      GO TO 199
  190 CONTINUE
C
C  LINEAR 2-DIMENSIONAL INTERPOLATION
      E(I,J) =(1.-DY) * ((1.-DX)*A(M,N)+ DX*A(M+1,N))
     2  + DY * ((1.-DX)*A(M,N+1) + DX*A(M+1,N+1))
  199 ZLON=ZLON+YDLON
  200 CONTINUE
      ZLAT=ZLAT+YDLAT
  205 CONTINUE
      RETURN
C NUINIT ENTRY
C
C DEFINE INPUT GRID PARAMETERS AND OUTPUT GRID CHARATERISTICS.
C
C FOR THE INPUT POLAR STEREO GRID
C    XER - ON THE PROJECTION, NUMBER OF GRID UNITS, POLE TO EQUATOR
C    XPI - I INDEX OF GRID POINT AT THE POLE
C    XPJ - J INDEX OF GRID POINT AT THE POLE
C    XAX - LONGITUDE OF THE + X AXIS OF THE GRID (POLE POINT TO THE RIGHT)
C    IMX - MAXIMUM POINTS IN I DIRECTION
C    JMX - MAXIMUM POINTS IN J DIRECTION
C    IHEM - HEMISPHERE WHERE 1=NH AND -1=SH.
C NOTE --
C  IF PROJECTION IS LOOKING DOWN ON NORTH POLE, IHEM SHOULD BE 1.
C  IF PROJECTION IS LOOKING DOWN ON SOUTH POLE, IHEM SHOULD BE -1.
C
C
C FOR THE OUTPUT LAT-LON GRID
C    XMNLAT - MINIMUM LATITUDE (TO STORE IN J=1 OF OUTPUT ARRAY) N POSITIVE
C    XDLAT -  INCREMENT OF LATITUDE FOR SUCCESSINVE J'S  NORTHWARD POSITIVE
C    INLAT -  NUMBER OF LATITUDES DESIRED
C    XMNLON - MINIMUM LONGITUDE, E POSITIVE
C    XDLON  - INCREMENT OF LONGITUDE, EASTWARD POSITIVE
C    INLON  - NUMBER OF LONGITUDES
C
C IINT   - TYPE OF INTERP 1=4POINT,2=16POINT
C          NOTE THAT 4 POINT ALLOWS INTERPOLATION CLOSER TO GRID EDGES
C          BUT 16 POINT IS MORE ACCURATE.
C NSTAT  - RETURNED STATUS, NON ZERO INDICATES THAT "NSTAT"
C          POINTS CANNOT BE INTERPOLATED FROM THE INPUT GRID.
C EM     - ARRAY TO CONTAIN FLAGS FOR POINTS WHICH ARE OUTSIDE THE
C          RANGE OF THE INTERPOLATION.
C
C INITIALIZATION PARAMETERS FOR COMMON POLAR STEREO GRIDS
C
C       GRID                 XER              XPI,XPJ  XAX    IMX,JMX   IHEM
C       NMC 47X51            31.204359052      24,26    10     47,51      1
C       NMC 65X65  (NH)      31.204359052      33,33    10     65,65      1
C       NMC 65X65  (SH)      31.204359052      33,33    10     65,65     -1
C       NMC LFM (41X38 SET)  2*31.204359052    19,42   -15     41,38      1
C       NAVY 63X63           31.204359052      32,32    10     63,63      1
C       AUSTRALIAN 47X47     23.403269292      24,24     0     47,47     -1
C
C
C
      ENTRY NUINIT(XER,XPI,XPJ,XAX,IMX,JMX,IHEM,EM,
     2 XMNLON,XDLON,LOND,XMNLAT,XDLAT,LATD,IINT,NSTAT)
      XHEM=1.
      IF(IHEM.EQ.-1) XHEM=-1.
      YER=XER
      YPI=XPI
      YPJ=XPJ
      YAX=XAX * XHEM
      YMNLAT=XMNLAT
      YDLAT=XDLAT
      NLAT=LATD
      YMNLON=XMNLON  * XHEM
      YDLON=XDLON  * XHEM
      NLON=LOND
      NINT=IINT
C
C CHECK FOR ALL POINTS IN ARRAY BOUNDS
C
      NERR=0
      ZLAT=YMNLAT
      DO 250 J=1,NLAT
      R=YER*(TAN(PI4-ABS(DEGRAD*ZLAT/2)))
      ZLON=YMNLON
      DO 240 I=1,NLON
      ANG=(ZLON-YAX) * DEGRAD
      XX=R*COS(ANG) + YPI
      YY=R*SIN(ANG) + YPJ
      M=XX
      N=YY
      EM(I,J)=0.
      IF(M.LT.NINT .OR. N.LT.NINT) GO TO 230
      IF(M.GT.(IMX-NINT) .OR. N.GT.(JMX-NINT)) GO TO 230
      GO TO 235
  230 EM(I,J)=XOUT
      NERR=NERR+1
  235 CONTINUE
      ZLON=ZLON+YDLON
  240 CONTINUE
      ZLAT=ZLAT+YDLAT
  250 CONTINUE
      NSTAT=0
      IF(NERR.GT.0) THEN
        PRINT 1001,NERR
 1001   FORMAT(' NUINIT - WARNING POINTS OUTSIDE RANGE = ',I8)
        NSTAT=NERR
      ENDIF
      RETURN
      END
