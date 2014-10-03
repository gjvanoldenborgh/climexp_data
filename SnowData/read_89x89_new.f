      PROGRAM AREA
C*********************************************************************
C
C	THIS PROGRAM SIMPLY READS IN THE SNOW DATA AND
C	WRITES IT OUT FOR A GIVEN YEAR.
C
C	VARIABLES:
C
C	   ISNDAT - 89 X 89 SNOW DATA	   
C
C	FILES:
C
C	   A YEAR OF WEEKLY SNOW DATA IS STORED IN A FILE WITH
C	   THE NAMING CONVENTION:
C
C		wk19xx   xx - is the year (ex. wk1973)
C
C*********************************************************************

      DIMENSION ISNDAT(89,89)
      CHARACTER*1 ICHAR1,ICHAR2
      OPEN(11,FILE='INFILE',
     *   FORM='FORMATTED',ACCESS='SEQUENTIAL')
      OPEN(12,FILE='OUTFILE',
     *   FORM='FORMATTED',ACCESS='SEQUENTIAL')
       DO 199 LP = 1,52
C*********************************************************************
C
C	READS IN THE WEEKLY SNOW DATA.
C
C*********************************************************************
        DO 200 I = 1,89
        READ(11,100,END=10) IYEARS,IWKS,IROW,ICHAR1,(ISNDAT(I,J),J=1,45)
  100    FORMAT (I4,2I2,A1,45I1)
        READ(11,101,END=10)IYEARS,IWKS,IROW,ICHAR2,(ISNDAT(I,J),J=46,89)
  101    FORMAT (I4,2I2,A1,44I1)
C*********************************************************************
C
C	WRITE OUT THE WEEKLY SNOW DATA.
C
C*********************************************************************
         WRITE(12,100) IYEARS,IWKS,IROW,ICHAR1,(ISNDAT(I,J),J=1,45)
         WRITE(12,101) IYEARS,IWKS,IROW,ICHAR2,(ISNDAT(I,J),J=46,89)
  200   CONTINUE
	 READ(11,102) ICONST
  102    FORMAT(I4)
	 WRITE(12,102) ICONST
C
  199   CONTINUE
   10   CONTINUE
 999     STOP
         END
