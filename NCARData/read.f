      PROGRAM RSNO
      DIMENSION IGEO(89,89),ISNO(89,89),IROW(89)
      character rec*72,flnm*64,CMNT*60
C EXAMPLE READ FOR NESDIS SNOWCOVER FIELDS - DS315.0.
C
C-------------------------------------------------------------------------
C-------   Define type of read -------------------------------------------
C     MODRD = 1
C             1 => READ LAND/SEA MASK
C             2 => READ WEEKLY OR MONTHLY SNOW/ICE DATA
C-------------------------------------------------------------------------
      NF=1
      write(*,*) 'NAME OF FILE YOU WANT TO READ'
      read(*,'(a64)') flnm
      WRITE(*,*) 'WHAT TYPE OF DATA ARE YOU READING'
      WRITE(*,*) '  1) LAND/SEA MASK'
      WRITE(*,*) '  2) MONTHLY OR WEEKLY SNOW GRIDS'
      READ (*,*) MODRD


      OPEN(1,FILE=flnm,status='unknown',
     1     form='formatted' )

      IF (MODRD .EQ. 1 ) GO TO 10
      IF (MODRD .EQ. 2 ) GO TO 20
   10 continue
      read(1,'(a72)') rec
C READ LAND/WATER GRID
   11 continue
 1000 FORMAT(I4,I2)

      DO 15 J=1,89
      READ(1,1001,END=80)IROW(J),(IGEO(I,J),I=1,89)
 1001 FORMAT(6X,I2,3X,89I1)
  15  CONTINUE

   18 CONTINUE
      CLOSE(1)
      go to 80

C READ WEEKLY (file 2) AND/OR MONTHLY (file 3) FIELDS.
   20 READ(1,1004,END=80)IYR,IDT,CMNT
 1004 FORMAT(I4,I2,A)
      IF (IYR .gt. 1987 .and. idt .eq. 50 ) WRITE(20,1004) IYR,IDT,CMNT
      DO 25 J=1,89
      READ(1,1003,END=80) IYR,IMO,IROW(J),(ISNO(I,J),I=1,89)
      IF (IYR .gt. 1987 .and. idt .eq. 50 ) THEN
        WRITE(20,1003) IYR,IMO,IROW(J),(ISNO(I,J),I=1,89)
      ENDIF
 25   CONTINUE
      WRITE(*,1002) IYR,IDT
 1002 FORMAT(1X,I4,I3)
 1003 FORMAT(I4,I2,I2,3X,89I1)
      GO TO 20
   80 CONTINUE
      NF=NF+1
      END


