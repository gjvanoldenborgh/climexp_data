C**** SBBX_to_1x1.f ; to compile:  f77 SBBX_to_1x1.f
C****
C**** This program uses 2 input files:
C****    the first contains        SURFACE AIR TEMPERATURE anomalies,
C****    the second          OCEAN MIXED LAYER TEMPERATURE anomalies.
C**** It reads monthly anomalies for 8000 equal area subboxes, finds the
C**** anomaly with respect to 1951-1980 for a user-specified month/year.
C**** Whether ocean or land data are used depends on the flag IOCN.
C**** The results are replicated on a regular 1x1 degree grid:
C**** Box (1,1) covers 90S-89S, 180W-179W, (2,1) 179W-178W etc)
C****
C**** Both input files have the same structure:
C**** Record 1 starts with 8 integers I1-I8 and an 80-byte TITLE.
C**** All further records start with 7 integers N1-N7,
C****             a real number R, followed by a data array (real*4).
C**** I1 or N1 is the length of the data array in the NEXT record.
C**** Unless its length is 0, each data-array contains a time series
C**** of monthly T-anomalies (C) starting with January of year I6 for
C**** one grid box. N2,N3,N4,N5 indicate the edges in .01 degrees of
C**** that grid box in the order: latitude of southern edge, latitude of
C**** northern edge, longitude of western edge, longit. of eastern edge.
C**** The world is covered with 8000 equal area grid boxes, so each
C**** file has 8001 records. I7 is the flag for missing data (9999).
C****
      PARAMETER (MONMX=12*(2200-1700), IM=360,JM=180)
      PARAMETER (iy1b=1951, iy2b=1980, navgb=iy2b+1-iy1b)  ! base period

      INTEGER INFO(8),INFOO(8)
      REAL  TIN(MONMX),  TAV(MONMX),   TOUT(IM*JM)
      REAL TINO(MONMX), TAVO(MONMX)
      CHARACTER*80 TITLE,TITLEO
      CHARACTER*80 TITOUT/
     *'               L-OTI(deg C) Anomaly vs 1951-80'/
      CHARACTER*9
     *  MONTH(12)/'  January',' February','    March','    April',
     *            '      May','     June','     July','   August',
     *            'September','  October',' November',' December'/
      COMMON TITLE
      logical debug
C****
C**** Read in the parameters; set station reach 'rland'
C****
      write(*,*) 'rename (link) Ts_anom_file to TS_DATA if ocnflag=0or2'
      write(*,*) 'rename (link) SST_anom_file to SST_DATA if ocnflag>0'
      write(*,*) '       ocn-flag: 0 no ocn, 1 ocn only, 2 ocn+land'
      write(*,*) 'enter: month(1-12) year (1880-?) ocn-flag(0-2)'
      read(*,*) mon,iyr,iocn
                    rland=100. ! land&ocen is used, station reach 100 km
      if(iocn.eq.0) rland=9999.  ! only land data are used
      if(iocn.eq.1) rland=-9999. ! only ocean data are used
      debug=.false.
      if (mon.lt.0) then
        debug=.true.
        mon=-mon
      end if
C****
C**** Read, display, and use the relevant parts of the header record
C****
      WRITE(6,*) 'data type and source:'
      if(rland.ge.0.) then
         open(8,file='TS_DATA',form='unformatted',access='sequential')
         READ(8) INFO,TITLE
         WRITE(6,*) TITLE
         do i=1,8
         if (debug) write(*,*) info(i)
         infoo(i)=info(i)   !  needed for land-only case
         end do
      end if
      if(rland.lt.9999.) then
         open(9,file='SST_DATA',form='unformatted',access='sequential')
         READ(9) INFOO,TITLEO
         WRITE(6,*) TITLEO
         if(rland.lt.0.) then
           do i=1,8
           info(i)=infoo(i)
           end do
         end if
      end if
      Mnow=INFO(1)       ! length of first data record (months)
      MnowO=INFOO(1)
      MONM=INFO(4)       ! max length of time series (months)
      MONMO=INFOO(4)
      IYRBEG=INFO(6)     ! beginning of time series (calendar year)
      IYRBGO=INFOO(6)
      BAD=INFO(7)
      write(*,*) 'missing_data flag:',INFO(7)
C****
C**** Align land and ocean time series
C****
      IYRBGC=MIN(IYRBGO,IYRBEG)       ! use earlier of the 2 start years
      IF(IYR.LT.IYRBGC) STOP 'YEAR TOO LOW'
      I1TIN=1+12*(IYRBEG-IYRBGC)      ! land  offset in combined period
      I1TINO=1+12*(IYRBGO-IYRBGC)     ! ocean offset in combined period
      MONMC=MAX(MONM+I1TIN-1,MONMO+I1TINO-1)  ! use later of the 2 ends
      IYREND=IYRBGC-1+MONMC/12        ! last calendar year of timeseries
C**** M1,M1b: Location in combined series of 1st month needed
      M1=12*(IYR-IYRBGC)+mon
      M1b=12*(iy1b-IYRBGC)+mon
      if(m1.le.0 .or. m1.gt.monmc) then
         write(*,*) 'requested time is out of range'
         stop
      end if
C****
C**** Loop over subboxes - find output data
C****
C**** Initialize the output array
      DO 10 I=1,IM*JM
   10 TOUT(I)=BAD
      kdebug=0
      DO 100 N=1,8000
C**** Read in time series TIN/TINO of monthly means: land/Ocean data
      DO 50 M=1,MONMC
      TIN(M)=BAD           ! set all months to missing initially
   50 TINO(M)=BAD
      DL=9999.             ! in case only ocn data are read in
      if(rland.ge.0.) then
        CALL SREAD (8,TIN(I1TIN),Mnow,LATS,LATN,LONW,LONE,DL,next)
        if(debug.and.kdebug.lt.1.and.TIN(I1TIN).lt.9000.) then
          write(*,*) 'lat:',LATS,LATN
          write(*,*) 'lon:',LONW,LONE
          write(*,*) 'dist:',DL
          write(*,*) 'index:',next
          write(*,*) 'data:',TIN(I1TIN)
          kdebug=kdebug+1
        end if
        Mnow=next  ! Mnow/next: length of current/next time series
      end if
      if(rland.lt.9999.) then   !  read in ocean data
        CALL SREAD (9,TINO(I1TINO),MnowO,LATS,LATN,LONW,LONE,DLO,nextO)
        MnowO=nextO
        wocn=0.                 ! weight for ocean data
        if(DL.gt.rland) wocn=1. ! DL:subbox_center->nearest station (km)
      end if
C***********************************************************************
C**** At this point the 2 time series TIN,TINO are all set and     *****
C**** can be used to compute means, trends , etc. As an example,   *****
C**** we find the requested anomaly:                               *****
C***********************************************************************
C**** Find the mean over the base period
      tavb=0.
      tavbO=0.
      TAV(1)=BAD
      TAVO(1)=BAD
      if(rland.ge.0.) then
C*      collect selected month for each base period year
        CALL AVG(TIN(M1b), 12,NAVGb,    1,BAD,1,TAV)
C*      find mean over the base period for the selected month
        CALL AVG(TAV,   NAVGb,    1,NAVGb,BAD,1,TAV)
      end if
      if(rland.lt.9999.) then  ! do same for ocean data
        CALL AVG(TINO(M1b),12,NAVGb,    1,BAD,1,TAVO)
        CALL AVG(TAVO,  NAVGb,    1,NAVGb,BAD,1,TAVO)
      end if
      tavb=TAV(1)                            ! tavb default: land value
      tavbO=TAVO(1)
C**** Put the requested anomaly into TAV(1), then Tout(i,j)
      TAV(1)=BAD
      TAVO(1)=BAD
      if(tavb.ne.BAD) tav(1)=TIN(M1)         ! tav(1): land value
      if(rland.lt.9999..and.tavbO.ne.BAD) TAVO(1)=TINO(M1)
      if(TAV(1).eq.BAD.or.rland.lt.0.) then  ! disregard land data
         tavb=tavbO                          ! tavb: ocean value
         TAV(1)=TAVO(1)                      ! tav(1): ocean value
      end if
      if(TAVO(1).ne.BAD) then                ! switch tavb/tav(1) to
         tavb=tavb*(1.-wocn)+tavbO*wocn      ! ocn value if appropriate
         TAV(1)=TAV(1)*(1.-wocn)+TAVO(1)*wocn
      end if
      if(TAV(1).NE.BAD) THEN
         TAV(1)=TAV(1)-tavb
C**** Replicate TAV(1) at the appropriate places in the output array
         CALL EMBED(TAV,TOUT,IM,JM, LATS,LATN,LONW,LONE)
      end if
  100 CONTINUE
C**** End of loop over subboxes
C****
C**** Create title, save title and data
C****
      TITLE=TITOUT
      IF(rland.lt.0.) TITLE(16:20)=' Tocn'
      IF(rland.ge.9998.) TITLE(16:20)='Tsurf'
      TITLE(1:9)=MONTH(mon)
      WRITE(TITLE(11:14),'(I4)') IYR
C**** Interpolate TOUT to an appropriate grid or save it as is
      open(10,file='dT1x1MAP',form='unformatted',access='sequential')
      WRITE(10) TITLE,TOUT
      STOP
      END

      SUBROUTINE SREAD (NDISK,ARRAY,LEN, N1,N2,N3,N4, DSTN,LNEXT)
      REAL ARRAY(LEN)
      READ(NDISK) LNEXT, N1,N2,N3,N4, NR1,NR2, DSTN, ARRAY
      RETURN
      END

      SUBROUTINE AVG(ARRAY,KM,NAVG,LAV,BAD,LMIN, DAV)
      REAL ARRAY(KM,NAVG),DAV(NAVG)
      DO 100 N=1,NAVG
      SUM=0.
      KOUNT=0
      DO 50 L=1,LAV
      IF(ARRAY(L,N).EQ.BAD) GO TO 50
      SUM=SUM+ARRAY(L,N)
      KOUNT=KOUNT+1
   50 CONTINUE
      DAV(N)=BAD
      IF(KOUNT.GE.LMIN) DAV(N)=SUM/KOUNT
  100 CONTINUE
      RETURN
      END

      SUBROUTINE EMBED(T,TOUT,IM,JM,LATS,LATN,LONW,LONE)
C**** This program replicates the data onto a regular (finer) grid:
C**** The value in the given box of the input grid is copied to all
C**** output grid boxes whose centers lie in that box.
      REAL TOUT(IM,JM)
C**** Latitudes LATS,LATN and longitudes LONW,LONE are in .01 degrees
C**** In TOUT J=1->JM corresponds to 90S->90N,
C****         I=1->IM corresponds to 180W->180E
      JS=(27000+(LATS+9000)*JM)/18000
      JN=( 9000+(LATN+9000)*JM)/18000
      IW=(54000+(LONW+18000)*IM)/36000
      IE=(18000+(LONE+18000)*IM)/36000
      DO 30 J=JS,JN
      DO 30 I=IW,IE
   30 TOUT(I,J)=T
      RETURN
      END
