        PROGRAM CAREA
        DEGRAD=180./3.14159265
        S60=SIN(60./DEGRAD)
C SET FACT TO THIS GRIDS RELATIONSHIP TO THE NMC 65X65 GRID
        FACT=2.
C
        ER=FACT*31.204359052
        ER4=ER*ER
        GRIDS=381./FACT
        PRINT 1002,ER
 1002   FORMAT(' ER= ',F12.8)
C SET POLE POINTS
        IP=45
        JP=45
        DO 20 I=1,89
        DO 20 J=44,46
C
        X=I-IP
        Y=J-JP
        RR=X*X+Y*Y
        XLAT=ASIN((ER4-RR)/(ER4+RR))*DEGRAD
        XLON=0.
        IF(IP.EQ.I .AND. JP.EQ.J) GO TO 12
        XLON=ATAN2(Y,X)*DEGRAD + 10.
        IF(XLON.GT.180.) XLON=XLON-360.
   12   CONTINUE
        XA=ABS(X+.5)
        YA=ABS(Y+.5)
        RRA=XA*XA+YA*YA
        SLAT=(ER4-RRA)/(ER4+RRA)
        XK=(1.+S60)/(1.+SLAT)
        AREA=(GRIDS/XK)**2
        PRINT 1001,I,J,XLAT,XLON,AREA
 1001   FORMAT(1X,2I5,3F12.3)
   20   CONTINUE
        END
