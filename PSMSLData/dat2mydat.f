        program dat2mydat
*
*       read the PSMSL data file and print it out in a format more
*       suitable for my programs.
c
c example job to read the file of PSMSL monthly mean values.
c for a description of each variable, see 'psmsldat.hel' and the
c 'Data Holdings of the PSMSL' report.
c
      CHARACTER FILEIN*80
      CHARACTER SNAME*40,SLAT*8,SLON*8,ACODE*2,FCODE*2
      CHARACTER*80 TEXTS(999),TEXTA(999),TEXTC(999)
      CHARACTER*3 CCODE,SCODE,GLOSS
      CHARACTER*26 MISSDAYS,AMISSDAYS(200)
      CHARACTER*1 RLRMET,MR,MRS
      CHARACTER*2 MDAYS(13)
      CHARACTER*1 IDOCFLS,IDOCFLY(3000)
      INTEGER YR,MEANM(13),MEANR(13),RLRFAC,IYRLR
      INTEGER IYEAR(200),AMEANM(13,200),AMEANR(13,200)
C
C OPEN THE FILE - THIS OPEN STATEMENT MAY BE SYSTEM DEPENDENT
C
      WRITE(6,*)
        filein = 'psmsl.dat'
      OPEN(1,FILE=FILEIN,STATUS='OLD',FORM='FORMATTED',IOSTAT=IST)
        open(2,file='psmsl.mydat',status='new',form='formatted')
      IF(IST.NE.0) WRITE(6,*) ' ERROR FILE1: IST =',IST
      IF(IST.NE.0) STOP
      NNYEAR=0
      NNCOMS=0
      NNCOMC=0
      NNCOMA=0
C
    1 CONTINUE
      READ(1,901,END=9) SNAME,CCODE,SCODE,SLAT,SLON,ACODE,FCODE,IYRLR,
     & GLOSS,MRS
  901 FORMAT(A40,2A3,2A8,2A2,I4,A3,A1,6X)
      WRITE(6,*) ' READING STATION ',CCODE,SCODE,' CALLED ',SNAME
c
c SNAME is the station name
c CCODE,SCODE is the country,station code
c SLAT,SLON are latitude,longitude
c ACODE,FCODE are the authority,frequency codes
c IYRLR will be 9999 if the station is not RLR i.e.Metric only
c GLOSS will be '   ' if the station is not in GLOSS
c MRS flags that there should be an entry for this station
c in the documentation which follows.
c
      IDOCFLS=MRS
      DO 1530 I=1,3000
      IDOCFLY(I) = ' '
 1530 CONTINUE
C
c Subroutine LATLON converts SLAT,SLON to REAL*4 parameters
c
      CALL LATLON(SLAT,SLON,ALAT,ALON)
C
      READ(1,1901) NYEAR,NCOMS,NCOMC,NCOMA
 1901 FORMAT(4I3,68X)
      NNYEAR=NNYEAR+NYEAR
      NNCOMS=NNCOMS+NCOMS
      NNCOMC=NNCOMC+NCOMC
      NNCOMA=NNCOMA+NCOMA
c
c NYEAR is the number of years of data
c NCOMS is the number of lines of station comments
c NCOMC is the number of lines of country comments
c NCOMA is the number of lines of authority comments
c
c the IYEAR(IY),AMISSDAYS(IY),AMEANM(I,IY),AMEANR(I,IY) arrays
c store the year, missing days, metric and rlr values for
c month I =(1,13) and year counter IY =(1,NYEAR)
c
      DO 7 IY=1,200
      IYEAR(IY)=0
      DO 17 I=1,13
      AMEANM(I,IY)=99999
      AMEANR(I,IY)=99999
   17 CONTINUE
    7 CONTINUE
C
      IF(NYEAR.GT.200) THEN
          WRITE(6,*) ' ARRAY SIZE EXCEEDED'
          STOP
      ENDIF
C  
      IF(NYEAR.EQ.0) GOTO 5
      DO 6 IY=1,NYEAR
      READ(1,911) YR,MISSDAYS,MR
  911 FORMAT(I4,6X,A26,4X,A1,39X)
      READ(MISSDAYS,913) MDAYS
  913 FORMAT(13A2)
c
      IYEAR(IY)=YR
      AMISSDAYS(IY)=MISSDAYS
c
c YR is the year of this station-year
c MISSDAYS contains 2 bytes of missing days information for each
c month in the format as described in 'Data Holdings'.
c MR flags that there should be an entry for this station-year
c in the documentation which follows.
C
      IDOCFLY(YR)=MR
C
      READ(1,912) MEANM,RLRFAC
  912 FORMAT(13I5,I10,5X)
c
c MEANM(1-12) are the 12 Metric monthly mean values. MEANM(13) is
c the annual mean value. A value of any of these of 99999 flags
c a missing monthly or annual mean. RLRFAC is the RLR factor for
c the station-year. A value of 99999 flags that this year is
c not RLR.
c
c To convert Metric values to RLR values, add the RLR factor. RLR
c values should be approximately 7000. Units are millimetres.
c
      DO 11 I=1,13
      MEANR(I)=99999
      IF(RLRFAC.NE.99999.AND.MEANM(I).NE.99999)
     &    MEANR(I)=MEANM(I) + RLRFAC
C
      AMEANM(I,IY)=MEANM(I)
      AMEANR(I,IY)=MEANR(I)
   11 CONTINUE
C
    6 CONTINUE
c
c now read the station, country and authority comments
c
    5 IF(NCOMS.EQ.0) GOTO 2
      DO 21 I=1,NCOMS
      READ(1,903) TEXTS(I)
  903 FORMAT(A80)
   21 CONTINUE
    2 IF(NCOMC.EQ.0) GOTO 3
      DO 31 I=1,NCOMC
      READ(1,903) TEXTC(I)
   31 CONTINUE
    3 IF(NCOMA.EQ.0) GOTO 4
      DO 41 I=1,NCOMA
      READ(1,903) TEXTA(I)
   41 CONTINUE
    4 CONTINUE
*
*       print out data in the format 
*       stationcode (countrycode//station) 12*monthly value
*
*       change antarctica to a number
        if ( ccode.eq.'A  ' ) ccode = '999'
        do iy=1,nyear
            n = 0
            do i=1,13
                if ( ccode.eq.'140' .or. ccode.eq.'150' ) then
*                   trust dutch and german data
                    ameanr(i,iy) = ameanm(i,iy) + 7000
                endif                
                if ( ameanr(i,iy).eq.99999 ) then
                    ameanr(i,iy) = -9999
                    n = n + 1
                else
                    ameanr(i,iy) = ameanr(i,iy) - 7000
                endif
            enddo
            if ( n.lt.13 ) then
                do i=1,12
                    if ( ameanr(i,iy).eq.99999 ) ameanr(i,iy)=-9999
                end do
                write(2,'(2a3,1x,i4,1x,12i6)') ccode,scode,iyear(iy)
     +                ,(ameanr(i,iy),i=1,12)
            endif
        enddo
C
      GOTO 1
    9 WRITE(6,*) 
     &' END OF FILE: NNYEAR (Total No. of station-years) = ',NNYEAR
      WRITE(6,*) 'NNCOMS (No.station comments) = ',NNCOMS
      WRITE(6,*) 'NNCOMC (No.country comments) = ',NNCOMC
      WRITE(6,*) 'NNCOMA (No.authority comments) = ',NNCOMA
      CLOSE (1)
        close(2)
      STOP
      END
      SUBROUTINE LATLON(CLAT,CLON,ALAT,ALON)
C
      SAVE
C
C CLAT AND CLON ARE 8 BYTE CHARACTERS CONTAINING LAT AND LON
C E.G. ' 51 44 N' OR '123 33 E'
C ALAT AND ALON ARE LAT (RANGE +90 TO -90 NORTH POSITIVE)
C               AND LON (RANGE 0 TO 360 EAST)
C
      CHARACTER*8 CLAT,CLON
      CHARACTER*1 CH(8),CC
C
      READ(CLAT,901) CH
  901 FORMAT(8A1)
      IF(CH(1).NE.' '.OR.CH(4).NE.' '.OR.CH(7).NE.' '.OR.
     &  (CH(8).NE.'N'.AND.CH(8).NE.'S')) THEN
       WRITE(6,*) 
     & ' ILLEGAL FORMAT IN S/R LATLON: CLAT =',CLAT
       STOP
      ENDIF
C
      READ(CLON,901) CH
      IF(CH(4).NE.' '.OR.CH(7).NE.' '.OR.
     &  (CH(8).NE.'W'.AND.CH(8).NE.'E')) THEN
       WRITE(6,*)
     & ' ILLEGAL FORMAT IN S/R LATLON: CLON =',CLON
       STOP
      ENDIF
C
      READ(CLAT,902) II,JJ,CC
  902 FORMAT(2I3,1X,A1)
      ALAT = FLOAT(II) + FLOAT(JJ)/60.
      IF(CC.EQ.'S') ALAT = - ALAT
C
      READ(CLON,902) II,JJ,CC
      ALON = FLOAT(II) + FLOAT(JJ)/60.
      IF(CC.EQ.'W') ALON = 360. - ALON
C
      RETURN
      END
      SUBROUTINE PRTSTN(RLRMET,SNAME,CCODE,SCODE,SLAT,SLON,ACODE,
     &   FCODE,IYRLR,GLOSS,NYEAR,IYEAR,AMISSDAYS,AMEANM,AMEANR,
     &   NCOMS,TEXTS,NCOMC,TEXTC,NCOMA,TEXTA,
     &   IDOCFLS,IDOCFLY)
C
      SAVE
C
      CHARACTER*1 RLRMET,METRLR
      CHARACTER CCODE*3,SCODE*3,SNAME*40,SLAT*8,SLON*8
      CHARACTER ACODE*2,FCODE*2,GLOSS*3
      CHARACTER*80 TEXTS(999),TEXTC(999),TEXTA(999)
      CHARACTER*1 IDOCFLS,IDOCFLY(3000)
      CHARACTER*26 MISSD,AMISSDAYS(200)
      INTEGER YR,IYRLR,IYEAR(200),AMEANM(13,200),AMEANR(13,200)
      CHARACTER*2 CHMD(13),BL,DASH
      CHARACTER*4 CHMDB(13),BL4
      CHARACTER*5 DOT,ACON(13)
      DIMENSION ICON(13)
      DATA DOT/'   ..'/,BL/'  '/
      DATA BL4/'    '/
      DATA DASH/' -'/
C
      METRLR=RLRMET
      IF(METRLR.EQ.'r') METRLR='R'
C
      IF(IYRLR.EQ.9999.AND.METRLR.EQ.'R') GOTO 7002
      WRITE(6,800)
  800 FORMAT(1H1)
      WRITE(6,401) SNAME,SLAT,SLON
  401 FORMAT(38X,A40,A8,1X,A8)
      WRITE(6,412) CCODE,SCODE,ACODE,FCODE
  412 FORMAT(/,26X,'COUNTRY CODE: ',A3,3X,'STATION CODE: ',A3,3X,
     & 'AUTHORITY CODE: ',A2,3X,'FREQUENCY CODE: ',A2)
      IF(GLOSS.NE.'   ') WRITE(6,1412) GLOSS
 1412 FORMAT(/,26X,29X,'GLOSS CODE  : ',A3)
      IF(METRLR.EQ.'R') WRITE(6,1403) IYRLR
 1403 FORMAT(//,45X,'VALUES ARE MEASURED TO DATUM OF RLR ',I5)
      IF(METRLR.NE.'R') THEN
               WRITE(6,404)
  404          FORMAT(//,38X,'SUPPLIED DATA VALUES ONLY -',
     &                   ' NOT MEASURED TO A COMMON DATUM')
               WRITE(6,4404)
 4404          FORMAT(38X,17X,
     &         '(I.E. A "METRIC" RECORD)')
               WRITE(6,4405)
 4405          FORMAT(33X,'THESE VALUES SHOULD NOT BE USED FOR',
     &                    ' MULTI-YEAR TIME SERIES ANALYSIS')
      ENDIF
C
      WRITE(6,405)
  405 FORMAT(/,1H ,37X,'MONTHLY & ANNUAL MEAN HEIGHTS OF SEA LEVEL',
     &' IN MILLIMETRES.')
C
      WRITE(6,406)
  406 FORMAT(/,1H ,9X,'I',8X,'II',7X,'III',6X,'IV',7X,'V',
     &8X,'VI',7X,'VII',5X,'VIII',6X,'IX',7X,'X',8X,'XI',7X,
     &'XII',6X,'Y')
C
      IF(NYEAR.LE.0) GOTO 403
      DO 402 IY=1,NYEAR
      YR=IYEAR(IY)
      MISSD=AMISSDAYS(IY)
C
C SET UP THE METRIC OR RLR VALUES.
      DO 43 I=1,13
      ICON(I)=AMEANM(I,IY)
      IF(METRLR.EQ.'R') ICON(I)=AMEANR(I,IY)
      WRITE(ACON(I),943) ICON(I)
  943 FORMAT(I5)
      IF(ICON(I).EQ.99999) ACON(I)=DOT
   43 CONTINUE
C
C READ THE MISSING DAYS INFORMATION
      DO 246 I=1,13
      CHMD(I)=BL
      CHMDB(I)=BL4
  246 CONTINUE
      READ(MISSD,902) CHMD
  902 FORMAT(13A2)
      DO 146 I=1,13
      IF(I.EQ.13.AND.CHMD(I).EQ.DASH) CHMD(I)=BL
      IF(CHMD(I).EQ.BL) GOTO 146
      WRITE(CHMDB(I),946) CHMD(I)
  946 FORMAT('(',A2,')')
  146 CONTINUE
   46 CONTINUE
C
      WRITE(6,409) YR,(ACON(I),CHMDB(I),I=1,13),YR
  409 FORMAT(2X,I4,2X,13(A5,A4),I4)
C
C IF A YEAR OF DATA IS 'METRIC ONLY' AND THIS IS AN RLR PRINTOUT
C THEN EACH MONTH'S INFORMATION WILL BE A SET OF DOTS.
C
  402 CONTINUE
  403 CONTINUE
C
C PRINT EXPLANATION OF ABOVE PRINTOUT
C
      WRITE(6,4601)
 4601 FORMAT(/,' VALUES IN BRACKETS SHOW NUMBER OF MISSING DAYS',
     &         ' EACH MONTH',
     &         ' WITH NO INTERPOLATION MADE IN COMPUTING THE MEAN;')
      WRITE(6,4602)
 4602 FORMAT(' "XX" SIGNIFIES MISSING OBSERVATIONS WERE INTERPOLATED',
     &       ' BEFORE COMPUTING THE MONTHLY MEAN;')
      WRITE(6,4603)
 4603 FORMAT(' "XX" FOR AN ANNUAL MEAN SIGNIFIES A VALUE LIKELY TO BE',
     & ' MATERIALLY AFFECTED BY MISSING DATA;')
      WRITE(6,4604)
 4604 FORMAT(' YEARS WITH MORE THAN ONE MISSING MONTH HAVE ANNUAL',
     &       ' MEANS DROPPED.')
C
      WRITE(6,6600) ACODE
 6600 FORMAT(/,' DATA COME FROM AUTHORITY "',A2,
     & '" - SEE FILE indexa.dat ON PSMSL DISK FOR FULL ADDRESS')
C
C READ DOCUMENTATION FOR THIS STATION.
      WRITE(6,411)
  411 FORMAT(/,1X,'ANY COMMENTS FOR THIS STATION ARE GIVEN BELOW:',/)
      IF(FCODE.EQ.' C'.OR.FCODE.EQ.'C ') WRITE(6,6611)
 6611 FORMAT(' FREQUENCY',
     &       ' CODE "C " IMPLIES DATA OBTAINED FROM INTEGRATION',
     & ' FROM CONTINUOUS RECORDS')
      IF(FCODE.EQ.'HL') WRITE(6,6612)
 6612 FORMAT(' FREQUENCY',
     &       ' CODE "HL" IMPLIES MEAN TIDE LEVEL (I.E. HIGH AND',
     & ' LOW WATERS)')
      IF(FCODE.NE.'C '.AND.FCODE.NE.' C'.AND.FCODE.NE.'HL')
     & WRITE(6,6613) FCODE,FCODE
 6613 FORMAT(' FREQUENCY',
     &       ' CODE "',A2,'" IMPLIES DATA OBTAINED FROM ',A2,
     & ' READINGS PER DAY')
      WRITE(6,*)
C
C PRINT DOCUMENTATION FLAG WARNINGS
C
      ISKIP=0
      IF(IDOCFLS.NE.' ') THEN
         ISKIP=1
         WRITE(6,9502)
 9502 FORMAT(' WARNING:',
     &' DOCUMENTATION FLAG SET FOR ENTIRE STATION - SEE COMMENTS BELOW')
      ENDIF
      DO 503 I=1,3000
      IF(IDOCFLY(I).NE.' ') THEN
          ISKIP=1
          WRITE(6,9503) I
 9503 FORMAT(' WARNING: DOCUMENTATION FLAG SET FOR YEAR ',I5,'  - SEE',
     &    ' COMMENTS BELOW')
      ENDIF
  503 CONTINUE
      IF(ISKIP.EQ.1) WRITE(6,*)
C
C STATION COMMENTS
      IF(NCOMS.LE.0) GOTO 502
      DO 501 I=1,NCOMS
      WRITE(6,410) TEXTS(I)
  410 FORMAT(1X,A80)
  501 CONTINUE
  502 CONTINUE
C
C COUNTRY COMMENTS
      IF(NCOMC.LE.0) GOTO 1502
      WRITE(6,1411)
 1411 FORMAT(/,1X,'ANY COMMENTS FOR THIS COUNTRY ARE GIVEN BELOW:',/)
      DO 1501 I=1,NCOMC
      WRITE(6,410) TEXTC(I)
 1501 CONTINUE
 1502 CONTINUE
C
C AUTHORITY COMMENTS
      IF(NCOMA.LE.0) GOTO 2502
      WRITE(6,2411)
 2411 FORMAT(/,1X,'ANY COMMENTS FOR THIS AUTHORITY ARE GIVEN BELOW:',/)
      DO 2501 I=1,NCOMA
      WRITE(6,410) TEXTA(I)
 2501 CONTINUE
 2502 CONTINUE
C
  700 CONTINUE
      RETURN
C
 7002 WRITE(6,97002) CCODE,SCODE
97002 FORMAT(' STATION ',A3,'/',A3,' IS NOT AN RLR STATION',
     &       ' NO PRINTOUT PRODUCED')
      GOTO 700
      END
