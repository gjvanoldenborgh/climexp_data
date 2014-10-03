      PROGRAM GETSLP                                                            
C                                                                               
C*** DRIVER FOR ACCESS ROUTINE TO 5-DEGREE LAT/LON SEA LEVEL PRESSURE GRIDS     
C***                                                                            
      COMMON/A/NTAPE,NSTATE,IFM(1),IYR,IMO,IDA,IHR,ILV,ITYPE,ISRC,IGRID,
     *POLE,NUM,SLP(72,15)
      CHARACTER NFLNM*64
C***                                                                            
C*** COMMON BLOCK A IS USED TO LINK WITH CALLING PROGRAM                        
C***     NTAPE - LUN SUPPLIED IN CALLING ROUTINE                                
C***     NSTATE - STATUS OF READ OPERATION                                      
C***     IFM - FORMAT NUMBER                                                    
C***     IYR - YEAR OF GRID, E.G. 1901                                          
C***     IMO - MONTH OF GRID                                                    
C***     IDA - DAY OF GRID                                                      
C***     IHR - HOUR                                                             
C***     ILV - LEVEL                                                            
C***     ITYPE - TYPE                                                           
C***     ISRC - SOURCE                                                          
C***     IGRID - GRID                                                           
C***     POLE - NORTH POLE VALUE                                                
C***     NUM - FOR MONTHLY GRIDS, NUMBER OF DAYS IN MEAN                        
C***     SLP - ARRAY OF SEA LEVEL PRESSURES (0=MISSING)                         
C***                                                                            
C                                                                               
C***    DEFAULT LAT/LON LIMITS ARE FOR FULL GRID AVAILABLE,
	LATLO= 15
	LATHI= 85
	LONLO= 00
	LONHI=355
C***    CHANGE THESE IF SMALLER LAT/LON BOX IS DESIRED,
C***    E.G. FOR MOST OF SCANDINAVIA,
C       LATLO= 50
C       LATHI= 70
C       LONLO= 00
c       LONHI= 30
C***                                                                            
C*** SET NTAPE .EQ. LOGICAL UNIT NUMBER
      NTAPE=11
      NUMR=0
      WRITE(*,*)' ENTER INPUT FILE NAME '
      READ(*,'(A)')NFLNM
      LEN=2048
C THE FOLLOWING STATEMENT IS ONLY NEEDED ON MACHINES EXPECTING WORDS FOR RECL
C     LEN=LEN/4
      OPEN(NTAPE,FILE=NFLNM,ACCESS='DIRECT',
     2 FORM='UNFORMATTED',STATUS='OLD',RECL=LEN )
C                                                                               
   10 CONTINUE                                                                  
C*** READ RECORD AND UNPACK ID PARAMETERS                                       
      NUMR=NUMR+1
      CALL RDSLP(NUMR)
      IF(NSTATE.EQ.1.OR.NSTATE.EQ.3) GO TO 1000                                 
C*** SELECT GRIDS HERE                                                          
C     if(imo.ne.1 .or. mod(iyr,10).ne.0) go to 10
C                                                                               
   20 CONTINUE                                                                  
C*** UNPACK SEA LEVEL PRESSURE GRID                                             
      CALL UPSLP                                                                
C                                                                               
C*** PROCESS GRID                                                               
C                                                                               
      print 100,ifm,iyr,imo,ida,ihr,ilv,itype,isrc,igrid, pole,num
  100 format(//5x,'format',6x,'year',5x,'month',7x,'day',6x,'hour',5x,
     *'level',6x,'type',4x,'source',6x,'grid',6x,'pole',5x,
     *'#grids_in_mean',/,
     *1x,9i10,f10.1,i10,/)
C     IF(NUMR.GT.1)  GO TO 10
      PRINT 101,(I,I=LATLO,LATHI,5)
  101 FORMAT(1H0,5X,15(I7,'N'))
	LTLO=(LATLO/5)-2
	LTHI=(LATHI/5)-2
	LNLO=(LONLO/5)+1
	LNHI=(LONHI/5)+1
      DO 500 I=LNLO,LNHI
      LON=(I-1)*5
      PRINT 150,LON,(SLP(I,J),J=LTLO,LTHI)
  150 FORMAT(2X,I3,'E',15F8.1)
  500 CONTINUE
      GO TO 10                                                                  
 1000 CONTINUE                                                                  
C*** NSTATE=1 FOR EOF , NSTATE=3 FOR EOT
C                                                                               
      NUMR=NUMR-1
      PRINT 1001,NUMR
 1001 FORMAT(' GRIDS READ = ',I4)
      END                                                                       
      SUBROUTINE RDSLP(NRP)
      SAVE
C***                                                                            
C*** ENTRY RDSLP READS A RECORD FROM DAILY OR MONTHLY SEA LEVEL PRESSURE TAPE   
C*** AND RETURNS READ STATUS AND ID INFORMATION                                 
C***                                                                            
C*** ENTRY UPSLP UNPACKS AND FLOATS ARRAY OF SLP                                
C***                                                                            
      COMMON/A/NTAPE,NSTATE,IFM(1),IYR,IMO,IDA,IHR,ILV,ITYPE,ISRC,IGRID,
     *POLE,NUM,SLP(72,15)
C***                                                                            
C*** COMMON BLOCK A IS USED TO LINK WITH CALLING PROGRAM                        
C***     NTAPE - LUN SUPPLIED IN CALLING ROUTINE                                
C***     NSTATE - STATUS OF READ OPERATION                                      
C***     IFM - FORMAT NUMBER                                                    
C***     IYR - YEAR OF GRID, E.G. 1901                                          
C***     IMO - MONTH OF GRID                                                    
C***     IDA - DAY OF GRID                                                      
C***     IHR - HOUR                                                             
C***     ILV - LEVEL                                                            
C***     ITYPE - TYPE                                                           
C***     ISRC - SOURCE                                                          
C***     IGRID - GRID                                                           
C***     POLE - NORTH POLE VALUE                                                
C***     NUM - FOR MONTHLY GRIDS, NUMBER OF DAYS IN MEAN                        
C***     SLP - ARRAY OF SEA LEVEL PRESSURES (0=MISSING)                         
C***                                                                            
      DIMENSION IBUF(512),LCON(12),IDATA(72,15)
      EQUIVALENCE(SLP,IDATA)                                                    
      DATA LCON/06,11,04,05,05,10,09,06,04,15,06,00/
   10 CONTINUE
      NSTATE=0
      READ(NTAPE,REC=NRP,END=90)(IBUF(I),I=1,512)
C THE FOLLOWING STATEMENT IS ONLY NEEDED ON BYTE REVERSED MACHINES (DEC,PC)
C     CALL SWAP4(IBUF,IBUF,2048)
      NREC=NREC+1                                                               
C     IF(NSTATE.NE.0) GO TO 20
      NOFF=0
      DO 100 I=1,11
      CALL GBYTE(IBUF,IFM(I),NOFF,LCON(I))
      NOFF=NOFF+LCON(I)
  100 CONTINUE
      CALL GBYTE(POLE,IPOLE,18,14)
      POLE=IPOLE*.1                                                             
      RETURN
   90 CONTINUE
      NSTATE=1
      RETURN
C                                                                               
      ENTRY UPSLP                                                               
      CALL GBYTES(IBUF,IDATA,121,14,1,1080)
      DO 200 I=1,1080                                                           
      SLP(I,1)=IDATA(I,1)*.1                                                    
  200 CONTINUE                                                                  
      RETURN                                                                    
      END                                                                       

      SUBROUTINE GBYTE (IN,IOUT,ISKIP,NBYTE)
      CALL GBYTES (IN,IOUT,ISKIP,NBYTE,0,1)
      RETURN
      END

      SUBROUTINE SBYTE (IOUT,IN,ISKIP,NBYTE)
      CALL SBYTES (IOUT,IN,ISKIP,NBYTE,0,1)
      RETURN
      END

      SUBROUTINE GBYTES (IN,IOUT,ISKIP,NBYTE,NSKIP,N)
C          Get bytes - unpack bits:  Extract arbitrary size values from a
C          packed bit string, right justifying each value in the unpacked
C          array.
      DIMENSION IN(*), IOUT(*)
C            IN    = packed array input
C            IO    = unpacked array output
C            ISKIP = initial number of bits to skip
C            NBYTE = number of bits to take
C            NSKIP = additional number of bits to skip on each iteration
C            N     = number of iterations
C************************************** MACHINE SPECIFIC CHANGES START HERE
C          Machine dependent information required:
C            LMWD   = Number of bits in a word on this machine
C            MASKS  = Set of word masks where the first element has only the
C                     right most bit set to 1, the second has the two, ...
C            LEFTSH = Shift left bits in word M to the by N bits
C            RGHTSH = Shift right
C            OR     = Logical OR (add) on this machine.
C            AND    = Logical AND (multiply) on this machine
C          This is for Sun UNIX Fortran, DEC Alpha, and RS6000
      PARAMETER (LMWD=32)
      DIMENSION MASKS(LMWD)
      SAVE      MASKS
      DATA      MASKS /'1'X,'3'X,'7'X,'F'X, '1F'X,'3F'X,'7F'X,'FF'X,
     +'1FF'X,'3FF'X,'7FF'X,'FFF'X, '1FFF'X,'3FFF'X,'7FFF'X,'FFFF'X,
     +'1FFFF'X,       '3FFFF'X,       '7FFFF'X,       'FFFFF'X,
     +'1FFFFF'X,      '3FFFFF'X,      '7FFFFF'X,      'FFFFFF'X,
     +'1FFFFFF'X,     '3FFFFFF'X,     '7FFFFFF'X,     'FFFFFFF'X,
     +'1FFFFFFF'X,    '3FFFFFFF'X,    '7FFFFFFF'X,    'FFFFFFFF'X/
C    +'1FFFFFFFF'X,   '3FFFFFFFF'X,   '7FFFFFFFF'X,   'FFFFFFFFF'X,
C    +'1FFFFFFFFF'X,  '3FFFFFFFFF'X,  '7FFFFFFFFF'X,  'FFFFFFFFFF'X,
C    +'1FFFFFFFFFF'X, '3FFFFFFFFFF'X, '7FFFFFFFFFF'X, 'FFFFFFFFFFF'X,
C    +'1FFFFFFFFFFF'X,'3FFFFFFFFFFF'X,'7FFFFFFFFFFF'X,'FFFFFFFFFFFF'X,
C    +'1FFFFFFFFFFFF'X,   '3FFFFFFFFFFFF'X,   '7FFFFFFFFFFFF'X,
C    +                                        'FFFFFFFFFFFFF'X,
C    +'1FFFFFFFFFFFFF'X,  '3FFFFFFFFFFFFF'X,  '7FFFFFFFFFFFFF'X,
C                                             'FFFFFFFFFFFFFF'X,
C    +'1FFFFFFFFFFFFFF'X, '3FFFFFFFFFFFFFF'X, '7FFFFFFFFFFFFFF'X,
C                                             'FFFFFFFFFFFFFFF'X,
C    +'1FFFFFFFFFFFFFFF'X,'3FFFFFFFFFFFFFFF'X,'7FFFFFFFFFFFFFFF'X,
C                                             'FFFFFFFFFFFFFFFF'X/
C          IBM PC using Microsoft Fortran uses different syntax:
C     DATA MASKS/16#1,16#3,16#7,16#F,16#1F,16#3F,16#7F,16#FF,
C    + 16#1FF,16#3FF,16#7FF,16#FFF,16#1FFF,16#3FFF,16#7FFF,16#FFFF,
C    + 16#1FFFF,16#3FFFF,16#7FFFF,16#FFFFF,16#1FFFFF,16#3FFFFF,
C    + 16#7FFFFF,16#FFFFFF,16#1FFFFFF,16#3FFFFFF,16#7FFFFFF,16#FFFFFFF,
C    + 16#1FFFFFFF,16#3FFFFFFF,16#7FFFFFFF,16#FFFFFFFF/
      INTEGER RGHTSH, OR, AND
      LEFTSH(M,N) = ISHFT(M,N)
      RGHTSH(M,N) = ISHFT(M,-N)
C     OR(M,N)  = M.OR.N
C     AND(M,N) = M.AND.N
C     OR(M,N)  = IOR(M,N)
C     AND(M,N) = IAND(M,N)
C************************************** MACHINE SPECIFIC CHANGES END HERE
C          History:  written by Robert C. Gammill, jul 1972.


C          NBYTE must be less than or equal to LMWD
      ICON = LMWD-NBYTE
      IF (ICON.LT.0) RETURN
      MASK = MASKS (NBYTE)
C          INDEX  = number of words into IN before the next "byte" appears
C          II     = number of bits the "byte" is from the left side of the word
C          ISTEP  = number of bits from the start of one "byte" to the next
C          IWORDS = number of words to skip from one "byte" to the next
C          IBITS  = number of bits to skip after skipping IWORDS
C          MOVER  = number of bits to the right, a byte must be moved to be
C                   right adjusted
      INDEX = ISKIP/LMWD
      II    = MOD (ISKIP,LMWD)
      ISTEP = NBYTE+NSKIP
      IWORDS= ISTEP/LMWD
      IBITS = MOD (ISTEP,LMWD)

      DO 6 I=1,N                                                                
      MOVER = ICON-II
      IF (MOVER) 2,3,4

C          The "byte" is split across a word break.
    2 MOVEL = -MOVER
      MOVER = LMWD-MOVEL
      NP1 = LEFTSH (IN(INDEX+1),MOVEL)
      NP2 = RGHTSH (IN(INDEX+2),MOVER)
      IOUT(I) = AND (OR (NP1,NP2) , MASK)
      GO TO 5                                                                   

C          The "byte" is already right adjusted.
    3 IOUT(I) = AND (IN (INDEX+1) , MASK)
      GO TO 5                                                                   

C          Right adjust the "byte".
    4 IOUT(I) = AND (RGHTSH (IN (INDEX+1),MOVER) , MASK)

    5 II = II+IBITS
      INDEX = INDEX+IWORDS
      IF (II .LT. LMWD) GO TO 6
      II = II-LMWD
      INDEX = INDEX+1
    6 CONTINUE                                                                  

      RETURN                                                                    
      END                                                                       

      SUBROUTINE SBYTES (IOUT,IN,ISKIP,NBYTE,NSKIP,N)
C          Store bytes - pack bits:  Put arbitrary size values into a
C          packed bit string, taking the low order bits from each value
C          in the unpacked array.
      DIMENSION IN(*), IOUT(*)
C            IOUT  = packed array output
C            IN    = unpacked array input
C            ISKIP = initial number of bits to skip
C            NBYTE = number of bits to pack
C            NSKIP = additional number of bits to skip on each iteration
C            N     = number of iterations
C************************************** MACHINE SPECIFIC CHANGES START HERE
C          Machine dependent information required:
C            LMWD   = Number of bits in a word on this machine
C            MASKS  = Set of word masks where the first element has only the
C                     right most bit set to 1, the second has the two, ...
C            LEFTSH = Shift left bits in word M to the by N bits
C            RGHTSH = Shift right
C            OR     = Logical OR (add) on this machine
C            AND    = Logical AND (multiply) on this machine
C            NOT    = Logical NOT (negation) on this machine
C          This is for Sun UNIX Fortran
      PARAMETER (LMWD=32)
      DIMENSION MASKS(LMWD)
      SAVE      MASKS
      DATA      MASKS /'1'X,'3'X,'7'X,'F'X, '1F'X,'3F'X,'7F'X,'FF'X,
     +'1FF'X,'3FF'X,'7FF'X,'FFF'X, '1FFF'X,'3FFF'X,'7FFF'X,'FFFF'X,
     +'1FFFF'X,       '3FFFF'X,       '7FFFF'X,       'FFFFF'X,
     +'1FFFFF'X,      '3FFFFF'X,      '7FFFFF'X,      'FFFFFF'X,
     +'1FFFFFF'X,     '3FFFFFF'X,     '7FFFFFF'X,     'FFFFFFF'X,
     +'1FFFFFFF'X,    '3FFFFFFF'X,    '7FFFFFFF'X,    'FFFFFFFF'X/
      INTEGER RGHTSH, OR, AND
      LEFTSH(M,N) = ISHFT(M,N)
      RGHTSH(M,N) = ISHFT(M,-N)
C     OR(M,N)  = M.OR.N
C     AND(M,N) = M.AND.N
C     OR(M,N)  = IOR(M,N)
C     AND(M,N) = IAND(M,N)
C     NOT(M)   = .NOT.M
C***********************************************************************        

C          NBYTE must be less than or equal to LMWD
      ICON = LMWD-NBYTE
      IF (ICON .LT. 0) RETURN
      MASK = MASKS(NBYTE)
C          INDEX  = number of words into IOUT the next "byte" is to be stored
C          II     = number of bits in from the left side of the word to store it
C          ISTEP  = number of bits from the start of one "byte" to the next
C          IWORDS = number of words to skip from one "byte" to the next
C          IBITS  = number of bits to skip after skipping IWORDS
C          MOVER  = number of bits to the right, a byte must be moved to be
C                   right adjusted
      INDEX = ISKIP/LMWD
      II    = MOD(ISKIP,LMWD)
      ISTEP = NBYTE+NSKIP
      IWORDS = ISTEP/LMWD
      IBITS = MOD(ISTEP,LMWD)

      DO 6 I=1,N                                                                
      J = AND (MASK,IN(I))
      MOVEL = ICON-II
      IF (MOVEL) 2,3,4

C          The "byte" is to be split across a word break
    2 MSK = MASKS (NBYTE+MOVEL)
      IOUT(INDEX+1) = OR (AND(NOT(MSK),IOUT(INDEX+1)),RGHTSH(J,-MOVEL))
      ITEMP = AND (MASKS(LMWD+MOVEL),IOUT(INDEX+2))
      IOUT(INDEX+2) = OR(ITEMP,LEFTSH(J,LMWD+MOVEL))
      GO TO 5                                                                   

C          The "byte" is to be stored right-adjusted
    3 IOUT(INDEX+1) = OR ( AND (NOT(MASK),IOUT(INDEX+1)) , J)
      GO TO 5                                                                   

C          The "byte" is to be stored in middle of word, so shift left.
    4 MSK = LEFTSH(MASK,MOVEL)
      IOUT(INDEX+1) = OR(AND(NOT(MSK),IOUT(INDEX+1)),LEFTSH(J,MOVEL))

    5 II = II+IBITS
      INDEX = INDEX+IWORDS
      IF (II .LT. LMWD) GO TO 6
      II = II-LMWD
      INDEX = INDEX+1
    6 CONTINUE

      RETURN                                                                    
      END                                                                       

      SUBROUTINE SWAP4(IN,IO,NN)
c
c Use CHARACTER*1 for DEC Alpha
      LOGICAL*1 IN(1),IO(1),IH
c
      DO 10 I=1,NN,4
      IH=IN(I)
      IO(I)=IN(I+3)
      IO(I+3)=IH
      IH=IN(I+1)
      IO(I+1)=IN(I+2)
      IO(I+2)=IH
  10  CONTINUE
      RETURN
      END
