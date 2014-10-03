

c ======================================================================
c ======================================================================
c 1. The Read routines
c      pluimlees
c      astrolees
c      obsread8
c      gidsread
c ======================================================================
c ======================================================================


      SUBROUTINE PLUIMLEES(ku,kparx,px,ksteps,km,kdate,kstat,plat,plon)
c ----------------------------------------------------------------------
c     Reads opzet datafiles  created by opzet.f
c     Can be used for  all plume files, buth check fileformat
c     Fileformat: 
c       (1x,i4,2F7.2) station,lat,lon
c       (2X,I3,2X,I10) parameter,dtganalyse
c       OPER RUN (20I4) +6,12,18,+24,...,+240
c       CONTR.R. (20I4)   idem
c       50 LEDEN (20I4)   idem
c     Input 
c       ku               unit to read from
c       px(ksteps,km)    plume file
c       ksteps, km       number of timesteps and members
c       kparx            selected parameter ( opzet = 270 )
c       kstat            selected station number
c     Output
c       kdate            date
c       plat, plon       coords 
c
c     Note
c     ksteps and km  are given, this routine is limited for 
c     ntijdmax timesteps per member 
c-----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      parameter ( ntijdmax= 500 )
      dimension px(ksteps,km)
      integer kdate,kstat,kparx

c     local array  to read time steps per member
      integer ifield(ntijdmax)

      integer i,j,jread,ipar
      real scale

      if(ksteps.gt.ntijdmax) stop "make ntijdmax larger in pluimlees"

c 0.  Initialization

c 0.1 Initialize array
      do j=1,km
        do i=1,ksteps
          px(i,j)=0
        enddo
      enddo

c 0.2 Start at begin of file 
      REWIND(ku)

c 1.  Read info ( station and coords ) 
      READ(ku,'(i5,2F7.2)') istat,plat,plon
      WRITE(6,'("pluimlees",2I6,2F7.2)') kstat,istat,plat,plon

c 2.  Read , try 25 times to find the right parameter iparx
      do 190 jread=1,25

c 2.1   Read info  ( parameter and date )
        READ(ku,*,end=1000) ipar,kdate
        write(6,'(2X,I7,2X,i10)') ipar,kdate
c       Jan van Vuure :  ipar = tsf convention (> 1000),
c       otherwise MARS
c       Jan van Vuure :  read is in 40i4
        if(ipar.gt.1000) then

c         Convert to MARS parameter
          itsfpar = ipar
          call  TSF2MARS(itsfpar,ipar)
c         Read 1 block with operational, control en 50 members
c         independent of number of members or timesteps 
          do im=1,km
            READ(ku,'(60I4)') (ifield(it),it=1,ksteps)
            do it=1,ksteps
             px (it,im) = ifield(it)
            enddo
          enddo 

        else

c         Read 1 block with operational, control en 50 members
c         independent of number of members or timesteps 
          do im=1,km
            READ(ku,'(20I4)') (ifield(it),it=1,ksteps)
c            if(im.eq.1) WRITE(6,'(20I4)') (ifield(it),it=1,20)
            do it=1,ksteps
             px (it,im) = ifield(it)
            enddo
          enddo 

        endif


c 2.3   If you have found the selected parameter/station, do rescale 
        if(ipar.eq.kparx.and.istat.eq.kstat) then 
          call  MSCALE(px,ksteps,km,ipar)
c         Finished , jump out of search loop 
          write(6,'("Read:",2I7,2X,i10)') itsfpar,ipar,kdate
          goto  210

        endif

190   continue

210   continue

      return


1000  continue
      write(6,'(1h ,"Ehhhh , niks gevonden , foutje ",2i4)') 
     +         kparx,ipar 
      stop  " Fout in pluimlees "

      return
      end


      subroutine MSCALE(px,ksteps,km,ipar)
c  ---------------------------------------------------------------------
c  Scale the field px
c  ---------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      dimension px(ksteps,km)

      zscale = 1.0
      if(ipar.eq.142) zscale=0.1
      if(ipar.eq.144) zscale=0.1
      if(ipar.eq.164) zscale=1.0
      if(ipar.eq.165) zscale=0.1
      if(ipar.eq.166) zscale=0.1
      if(ipar.eq.265) zscale=0.1
      if(ipar.eq.49) zscale=0.1
c     kilojoule ( is op ecmwf niet teruggeschaald )
      if(ipar.eq.59) zscale=0.001
      if(ipar.eq.167) zscale=0.1
      if(ipar.eq.168) zscale=0.1
c      if(ipar.eq.189) zscale=0.1
      if(ipar.eq.201) zscale=0.1
      if(ipar.eq.202) zscale=0.1
c     latent heat flux and P-E
      if(ipar.eq.147) zscale=0.1/2.5
c     evaporation conversion ( na 3 aug 2006 geen omkering van teken meer!!!!!) 
c     evaporation conversion ( na 6 mei 2008 omkering van teken meer!!!!!) 
      if(ipar.eq.182) zscale=0.1
c     total rainfall
      if(ipar.eq.228) zscale=0.1
      if(ipar.eq.991) zscale=0.1
c     wind surge
      if(ipar.eq.270) zscale=1.0

      do j=1,km
        do i=1,ksteps
          pp = px(i,j)
          if(pp.lt.9999) then
            px(i,j) = px(i,j)*zscale
          else
            px(i,j) = 9999
          endif
        enddo
      enddo


      return
      end 


      subroutine MASTROLEES(kuastro,kdate,paslow,pashigh,ksteps)
c23456789012345678901234567890123456789012345678901234567890123456789012
c ---------------------------------------------------------------------
c  Read tidal file 
c  Tides happen at odd intervals, at a little  more than 6 hours
c  The roundoff to the nearest hour  causes problems. 
c  Sometimes dates are skipped or 
c  high and low are at the same (rounded off) time !!
c  So the time series is quasi regular 
c input     
c   kuastro        : unit to read from
c   kdate          : initial date (yyyymmddhh)
c   kpar           : parameter
c   ksteps         : number of values
c output
c   paslow(0:ksteps)  : values of low tide 
c   pashigh(0:ksteps) : values of high tide 
c
c Note that analysis point is read , but skipped in output file 
c
c                            Robert Mureau      23-2-2001
c ----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      IMPLICIT NONE

      INTEGER kuastro,kdate,ksteps
      REAL paslow(ksteps),pashigh(ksteps)
      INTEGER ntijdmax
      parameter (ntijdmax=500) 
      REAL zg,zastro(0:ntijdmax)
      INTEGER indate(0:ntijdmax)
      INTEGER iymdh, iymdh0, iymdh2,iymd
      INTEGER i,j,jstep,jhour,ihour,iminute,jstep1,itermax
      LOGICAL LPRINT 

      if(ksteps.gt.ntijdmax) stop " Foute dimensie in bastro"

c 0.1 Initialization
      do j=0,ksteps
        zastro(j)  = 9999
      enddo
      do j=1,ksteps
        pashigh(j) = 9999 
        paslow(j)  = 9999 
      enddo

c 0.2 Rewind file unit
      REWIND(kuastro)

c 0.3 Test print ys or no
      Lprint =.FALSE.
      Lprint =.TRUE.

c ----------------------------------------------------------------------
c 1.  Find the starting date ( step=0 )
c ----------------------------------------------------------------------

      iymdh0 = kdate

      itermax=10000
      do 140 j=1,itermax

c 1.1   iymd, ihour, iminute  is de exacte datum en tijd,
c       iymdh is de afgeronde datumtijd ( in 6 uur vakken)
        READ(kuastro,910,END=280) iymd,ihour,iminute,iymdh,zg

c       Als je de exacte datumtijd vindt spring je uit de loop, en 
c       je moet verder lezen vanaf step :  jstep1 
        if(iymdh.ge.iymdh0) then

c 1.2     You have found the date
          write(6,'(1h ,20x,"Tidal file:",/, 
     +    "The date closest to the initial date: ",i10," is: ",i10)') 
     +         iymdh0,iymdh 

c 1.3     For exact datetime, set zero'th element of array
          if(iymdh.eq.iymdh0) then
            zastro(0) = zg
            indate(0) = iymdh
            jstep1    = 1
            if(Lprint) WRITE(6,'(i8,2i3,1x,i10,f7.2)') 
     +               iymd,ihour,iminute,indate(0),zastro(0)
          endif 

c 1.4     als de begindatumtijd niet bestaat (raar getij) heb je een
c         probleem, en is het start element undefined 
          if(iymdh.gt.iymdh0) then
            zastro(0) = 9999

            zastro(1) = zg
            indate(0) = iymdh0
            indate(1) = iymdh
            jstep1    = 2
            if(LPRINT) then
              WRITE(6,'(8x,6x,1x,i10,f7.2)') 
     +                                  indate(0),zastro(0)
              WRITE(6,'(i8,2i3,1x,i10,f7.2)') 
     +               iymd,ihour,iminute,indate(1),zastro(1)
            endif
          endif 

c 1.5     Jump out of loop, continue reading at step = jstep1
          goto 160

        endif

140   continue    

160   continue

c ----------------------------------------------------------------------
c 2.  Read next 10 days (a few extra steps for safety)
c     Note : these are irregular time steps
c ----------------------------------------------------------------------
      do 240 j=jstep1,ksteps+5
        READ(kuastro,910,END=280) iymd,ihour,iminute,indate(j),zastro(j)
        if(Lprint) WRITE(6,'(i8,2i3,1x,i10,f7.2)') 
     +               iymd,ihour,iminute,indate(j),zastro(j)
240   continue   


c ----------------------------------------------------------------------
C 3.  Make timeseries with constant 6 hour interval for low and high tide.
c     Start at step 1 like the plume does !!!
c ----------------------------------------------------------------------
      do 360 j=1,ksteps

c 3.1   Create regular time step date-time (yymmddhh) 
        jhour = 6*j 
        call MDATFOR(iymdh0,jhour,iymdh2)

c 3.2   Check whether there is a match with the tidal dates
c       and then fill high/low tide arrays
        do i=1,ksteps
          if(indate(i).eq.iymdh2) then
            if(zastro(i).lt.9999) then
              if(zastro(i).le.0) paslow(j)  = zastro(i)
              if(zastro(i).ge.0) pashigh(j) = zastro(i)
            endif
          endif
        enddo

360   continue

c     -------------------------------------------------------
c     Check print
c     -------------------------------------------------------
      if(Lprint) then 

        write(6,'(//18x,"Low tide",4x,"High tide")') 
        do j=1,ksteps
          jhour = 6*j 
          call MDATFOR(iymdh0,jhour,iymdh2)
          write(6,'(1h ,i2,2x,i10,4f12.2)') 
     +         j,iymdh2,paslow(j),pashigh(j)
        enddo

      endif

910   FORMAT (i8,i2,1x,i2,1x,i10,f7.2)

      return

c     -------------------------------------------------------
c     jump out of loop 
c     -------------------------------------------------------

280   continue
      write(6,*) " "
      write(6,*) " "
      write(6,*) " "
      write(6,*) "************************************************ "
      write(6,*) " FOUT: Voortijdig einde astro file"
      write(6,*) iymd,ihour,iminute,iymdh,zg
      write(6,*) "step ",j,itermax
      write(6,*) "************************************************ "
      write(6,*) " "
      write(6,*) " "
      write(6,*) " "
      write(6,*) " "

      return
      end


      subroutine BMIX(pastro,pin,pout,nsteps,nmemb)
c Add tide and surge
      dimension pin(nsteps,nmemb), pout(nsteps,nmemb)
      dimension pastro(nsteps)

c     Total water level = astro level + surge 
      do i=1,nsteps
        do j=1,nmemb
          pout(i,j) = pin(i,j) + 100*pastro(i)
        enddo
      enddo


      return
      end


      subroutine BMFILL(px,px2,nsteps)
c ---------------------------------------------------
c Fill in the gaps between low and high tide such that you get
c a continous series of eiter high tide or low tide
c It is not an interpolation!
c
c     px(nsteps)    input array with the high tides or the low tides
c     px2(nsteps)   output array with the gaps filled in
c --------------------------------------------------------------
      dimension px(nsteps), px2(nsteps)

c 1.  Transfer
      do i=1,nsteps
        px2(i) = px(i)
      enddo

c 2.  interpolate the first step, if it is missing ( = 999 )
      i=1 
      if(px2(i).ge.999) then
        if(px2(i+1).lt.999) then
          px2(i) = px2(i+1) 
        else
          px2(i) = px2(i+2) 
        endif
      endif

c 3.  interpolate the other steps, if it is missing ( = 999 )
      do i=2,nsteps-1

        if(px2(i).ge.999) then
          if(px2(i+1).lt.999) then
           if(px(i-1).gt.0)  px2(i) = MAX( px2(i-1) , px2(i+1) ) 
           if(px(i-1).lt.0)  px2(i) = MIN( px2(i-1) , px2(i+1) ) 
          else
            if(px(i-1).gt.0)  px2(i) = MAX( px2(i-1) , px2(i+2) ) 
            if(px(i-1).lt.0)  px2(i) = MIN( px2(i-1) , px2(i+2) ) 
          endif

        endif

      enddo


c 4.  interpolate the last step, if it is missing ( = 999 )
      i=nsteps 
      if(px2(i).ge.999) then
        if(px2(i-1).lt.999) then
          px2(i) = px2(i-1) 
        else
          px2(i) = px2(i-2) 
        endif
      endif



      return
      end


      subroutine OBSREAD(kuobs,kdate,kpar,pobs,ksteps,Lobs)
c ---------------------------------------------------------------------
c  Read observations of file
c input     
c   kuobs        : unit to read from
c   kdate        : initial date
c   kpar         : parameter
c output
c   pobs(0:20)   : oberved values 
c
c Comm
c The range can be set via  day1 and day2, but is only relative in 
c the main program.
c It can be set to , e.g. -5 - +5   and therefore not be noticed by 
c the main plotting program 
c
c ---------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      IMPLICIT NONE
      integer ntijdmax
      parameter (ntijdmax=200)
      INTEGER kuobs,kdate,kpar,ksteps
      REAL pobs(0:ksteps)
      Logical Lobs

      REAL ztobs(0:ntijdmax),ztwobs(0:ntijdmax)
      REAL zysobs(0:ntijdmax),zprecobs(0:ntijdmax),zffobs(0:ntijdmax)
      INTEGER istep1,istep2
      INTEGER mark,mmm,mdd,mhh,mff,mta,mrh,n,mww,mprec,mtw,mzi,mzs0
      INTEGER imdh, imdh0
      INTEGER j

c =========================
c 0.  Initialization
c =========================

c 0.1 steps
      istep1 = 0
      istep2 = ksteps

c 0.2 Initialization
      do j=istep1,istep2
        ztobs(j)    = 999
        zysobs(j)   = 999
        zprecobs(j) = 999
        zffobs(j)   = 999
        ztwobs(j)   = 999
        pobs(j) = 999
      enddo

c 1.  Read ( but only if kuobs is set )
      if(Lobs) then

c       Rewind
        REWIND(kuobs)

c 1.    Find the starting date
        imdh0 = MOD(kdate,1000000)
        do 110 j=1,500 
          READ (kuobs,910,END=321)
     *    mark,mmm,mdd,mhh,mff,mta,mrh,n,mww,mprec,mtw,mzi,mzs0
          imdh = mmm*10000 + mdd*100 + mhh
          if(imdh.eq.imdh0) goto 111 
110     continue
111     continue

c 2.    Convert the analysis data -------------------------------
        ztobs(istep1)    = REAL(mta)/10.0
        ztwobs(istep1)   = REAL(mtw)/10.0
        zysobs(istep1)   = REAL(mzi)/10.0
        zprecobs(istep1) = REAL(mprec)/10.0
        zffobs(istep1)   = REAL(mff)
        write(6,'(1h ,"starting date:",4i3,5f10.2)') mark,mmm,mdd,mhh,
     $         ztobs(istep1),ztwobs(istep1),zysobs(istep1),
     $         zprecobs(istep1),zffobs(istep1)

c 3.    Read next 10 days for verification - every 12 hours------------
c       ( mark=9 means observation ; =4 means forecast )
c        do 320 j=2,istep2,2
        do 320 j=istep1+1,istep2
          READ (kuobs,910,END=321)
     *      mark,mmm,mdd,mhh,mff,mta,mrh,n,mww,mprec,mtw,mzi,mzs0
          if(mark.ne.4) then
            if(mhh.eq.12.or.mhh.eq.24) then
              ztobs(j)  = REAL(mta)/10.0
              ztwobs(j) = REAL(mtw)/10.0
              zysobs(j) = REAL(mzi)/10.0
              zprecobs(j)  = REAL(mprec)/10.0
              zffobs(j) = REAL(mff)

             write(6,'(1h ,8x,"obsdate:",4i3,5f10.2)') mark,mmm,mdd,mhh,
     $         ztobs(j),ztwobs(j),zysobs(j),zprecobs(j),zffobs(j)
            endif
          else
            ztobs(j)  = 999
            ztwobs(j) = 999
            zysobs(j) = 999
            zprecobs(j) = 999
            zffobs(j) = 999
          endif
320     continue  

321     continue

        if(kpar.eq.167) then 
          do j=istep1,istep2
            pobs(j)=ztobs(j)
          enddo
        endif
        if(kpar.eq.142.or.kpar.eq.143) then 
          do j=istep1,istep2
            pobs(j)=zprecobs(j)
          enddo
        endif
        if(kpar.eq.991) then 
          do j=istep1,istep2
            pobs(j)=ztwobs(j)
            if(zysobs(j).gt.0.and.zysobs(j).lt.999) pobs(j)= -zysobs(j)
          enddo
        endif
        if(kpar.eq.992) then 
          do j=istep1,istep2
            pobs(j)=zysobs(j)
          enddo
        endif
        if(kpar.eq.165.or.kpar.eq.265) then 
          do j=istep1,istep2
            pobs(j)=zffobs(j)
          enddo
        endif

      endif

910   FORMAT (i1,4i2,2i4,2i2,4i4,a1)


      return
      end


      subroutine MOBSLEES8(kuobs,kdate,pobs,ksteps)
c23456789012345678901234567890123456789012345678901234567890123456789012
c ---------------------------------------------------------------------
c  Read tidal file 
c  Tides happen at odd intervals, at a little  more than 6 hours
c  The roundoff to the nearest hour  causes problems. 
c  Sometimes dates are skipped or 
c  high and low are at the same (rounded off) time !!
c  So the time series is quasi regular 
c input     
c   kuobs        : unit to read from
c   kdate          : initial date (yyyymmddhh)
c   kpar           : parameter
c   ksteps         : number of values
c output
c   paslow(0:ksteps)  : values of low tide 
c   pashigh(0:ksteps) : values of high tide 
c
c Note that analysis point is read , but skipped in output file 
c
c                            Robert Mureau      23-2-2001
c ----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      IMPLICIT NONE

      INTEGER kuobs,kdate,ksteps
      REAL pobs(0:ksteps)

      REAL zg,zobs(0:50),zdummy
      INTEGER indate(0:50)
      INTEGER iymdh, iymdh0, iymdh2,iymd
      INTEGER i,j,jstep,jhour,ihour,iminute,jstep1
      LOGICAL LPRINT 
      REAL a1


c 0.1 Initialization
      do j=0,ksteps
        zobs(j)  = 9999
        pobs(j)  = 9999
      enddo

c 0.2 Rewind file unit
      REWIND(kuobs)

c 0.3 Test print ys or no
      Lprint =.FALSE.
      Lprint =.true.

c ----------------------------------------------------------------------
c 1.  Find the starting date ( step=0 )
c ----------------------------------------------------------------------

      iymdh0 = kdate

      do 140 j=1,1000

c 1.1   iymd, ihour, iminute  is de exacte datum en tijd,
c       iymdh is de afgeronde datumtijd ( in 6 uur vakken)
c       READ(kuobs,920,END=280) iymd,ihour,iminute,iymdh,zdummy,zdummy,zg
        READ(kuobs,*) a1,zg
        call MCONV(a1,iymdh)

c       Als je de exacte datumtijd vindt spring je uit de loop, en 
c       je moet verder lezen vanaf step :  jstep1 
        if(iymdh.ge.iymdh0) then

c 1.2     You have found the date
          write(6,'(1h ,20x,"Obs file:",/, 
     +    "The date closest to the initial date: ",i10," is: ",i10)') 
     +         iymdh0,iymdh 

c 1.3     For exact datetime, set zero'th element of array
          if(iymdh.eq.iymdh0) then
            zobs(0) = zg
            indate(0) = iymdh
            jstep1    = 1
            if(Lprint) WRITE(6,'(i10,f7.2)') indate(0),zobs(0)
          endif 

c 1.4     als de begindatumtijd niet bestaat (raar getij) heb je een
c         probleem, en is het start element undefined 
          if(iymdh.gt.iymdh0) then
            zobs(0) = 9999
            zobs(1) = zg
            indate(0) = iymdh0
            indate(1) = iymdh
            jstep1    = 2
            if(LPRINT) then
              WRITE(6,'(8x,6x,1x,i10,f7.2)') indate(0),zobs(0)
              WRITE(6,'(i10,f7.2)') indate(1),zobs(1)
            endif
          endif 

c 1.5     Jump out of loop, continue reading at step = jstep1
          goto 160

        endif

140   continue    

160   continue

c ----------------------------------------------------------------------
c 2.  Read next 10 days (a few extra steps for safety)
c     Note : these are irregular time steps
c ----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      write(6,*) "hier", jstep1,ksteps
      do 240 j=jstep1,ksteps+5
c        READ(kuobs,920,END=280) iymd,ihour,iminute,indate(j),
c     +     zg,zg,zobs(j)
        READ(kuobs,*) a1,zobs(j)
        call MCONV(a1,iymdh)
        indate(j) = iymdh
        if(Lprint) WRITE(6,'(i10,f7.2)') indate(j),zobs(j)
240   continue   

280   continue

c ----------------------------------------------------------------------
C 3.  Make timeseries with constant 6 hour interval for low and high tide.
c     Start at step 1 like the plume does !!!
c ----------------------------------------------------------------------
      do 360 j=1,ksteps

c 3.1   Create regular time step date-time (yymmddhh) 
        jhour = 6*j 
        call MDATFOR(iymdh0,jhour,iymdh2)

c 3.2   Check whether there is a match with the tidal dates
        do i=1,ksteps
          if(indate(i).eq.iymdh2) then
            if(zobs(i).lt.9999) then
              pobs(j)  = 100*zobs(i)
            endif
          endif
        enddo

360   continue

c     -------------------------------------------------------
c     Check print
c     -------------------------------------------------------
      if(Lprint) then 

        write(6,'(//18x,"obs surge tide")') 
        do j=1,ksteps
          jhour = 6*j 
          call MDATFOR(iymdh0,jhour,iymdh2)
          write(6,'(1h ,i2,2x,i10,4f12.2)') j,iymdh2,pobs(j)
        enddo

      endif

910   FORMAT (i8,i2,1x,i2,1x,i10,f7.2)

920   FORMAT (i8,i2,1x,i2,1x,i10,3f7.2,5x,3f9.3)

      return
      end


      subroutine MCONV(a1,iymdh)
c     convert date for obs read
      dimension months(12),mm(12)
      data months /31,29,31,30,31,30,31,31,30,31,30,31/

      mm(1) = months(1)
      do im=2,12
        mm(im) = months(im) + mm(im-1)
      enddo

      ahour = AMOD(a1,24.0)

      arest=AMOD(ahour,6.0)
      if(arest.le.3) a1 = a1 -arest
      if(arest.gt.3) a1 = a1 -arest +6 

      ahour = AMOD(a1,24.0)
      idag  = 1 + a1/24.0

      ihour = ahour
      iminute = (ahour - INT(ahour)) * 60

      do im=1,12
        id = idag - mm(im) 
        if(id.le.0) then
c          write(6,*) idag,id,mm(im),im
          imonth=im 
          if(im.eq.1) then
            mm0 = 0
          else
            mm0 = mm(im-1)
          endif
          idag = idag - mm0
          goto 21
        endif
      enddo 
21    continue

      iymdh=2004*1000000+ imonth*10000 + idag*100 +ihour

      return
      end 


      subroutine MGIDSLEES(kunit,ptgids,ksteps,kstepsg,Lgids)
c-----------------------------------------------------------------------
c  Read gids data from file especially created in ascii format
c  Input
c   kunit            read from unit kunit
c   ksteps           number of time steps in ensemble 
c  output
c   ptgids(0:ksteps)   array to contain tmin tmax for gids
c
c  The gids data are Tmin and Tmax and are given every 12 hours.
c    i.e. the gids data series always consists of 20 points
c    so skip while reading 
c  Note: element 0 corresponds to Tmax of analysis day
c        element 1 corresponds to Tmin of T+12
c ---------------------------------------------------------------------
      IMPLICIT NONE

      INTEGER kunit,ksteps,kstepsg
      REAL ptgids(0:ksteps),uur
      INTEGER j,jstep,jskip
      Logical Lgids

c 1.  initialize ( 999 values will not be plotted )
      do j=0,ksteps
        ptgids(j) = 9999
      enddo

c 2.  Read gids data
      if(Lgids) then

c 2.1   skip while reading as Tmx and Tmn are plotted at 12 and 00utc
        if(ksteps.eq.20) jskip=1
        if(ksteps.ge.40) jskip=2

c 2.2   read (and skip time steps) 
        do j=0,kstepsg,jskip
          READ(kunit,*) uur,ptgids(j)
        enddo

      endif 


      return
      end



c ======================================================================
c ======================================================================
c 2.  Main plot part 
c       mpluim
c       mbars
c       mlayout
c ======================================================================
c ======================================================================


c23456789012345678901234567890123456789012345678901234567890123456789012
      SUBROUTINE MPLUIM(pens,ksteps,km,kpar,kdate,kstation,pgids,Lgids,
     +                   pobs,Lobs,kcolor)
c ---------------------------------------------------------------------
c    Makes plume plot
c 
c  pens(ksteps,km)  ensemble 
c  ksteps           aantal forecast steps ( begin bij 0 ) 
c  km               aantal leden in het ensemble
c  kpar             parameter (MARS convention , but 991 is T water )
c  kdate            date (yymmdd)
c  kstation         station number ( including block) 
c  kcolor           parameter to indicate colour or bw plot 
c
c ----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      IMPLICIT NONE
      INTEGER ntijdmax,mlarge,mengels,mplottype
      parameter (ntijdmax=500)

      COMMON /SETTINGS/ mlarge,mengels,mplottype
      integer ksteps,km,kpar,kdate,kstation,kcolor
      REAL pens(ksteps,km),pobs(0:ksteps),pgids(0:ksteps)

      INTEGER ieng,ilarge 
      INTEGER iday1,iday2,iuur1,iuur2
      INTEGER iplottype,jstep

      CHARACTER*20 cpar,cytxt
      LOGICAL Lobs,Lgids,Lprob
 
      REAL xvals(ntijdmax),ymin,ymax,ystep
      REAL subpginfo(4)

c     check
      if(ksteps.gt.ntijdmax) stop "make ntijdmax larger in pluimlees"

c     No probability plot but scenario plot
      Lprob=.false.

c 0.  Preparations 

c 0.1 Text language  ( via common)
      ieng = mengels

c 0.2 Size plot ( number of panels on page ) via common
      ilarge = mlarge 

c     monthly forecast with daily ticks iplottype = 1
c     15 day forecast with 6hrs ticks iplottype = 2
c     10 day forecast with 6hrs ticks iplottype = 0
      iplottype = mplottype

c ----------------------------------------------------------------------
c 1.  Define the subpage frame etc: subpage length are for later
c ----------------------------------------------------------------------
      CALL MLAYOUTP(ilarge,subpginfo)

c ----------------------------------------------------------------------
c 2.  Range of plume from iuur1 to iuur2 (can be different from axis)
C     and range of x-AXIS range ( day1 to day2 ) 
c     and definition of x-coordinates, xvals, expressed in days
c ----------------------------------------------------------------------
      call MXRANGE(iplottype,iuur1,iuur2,iday1,iday2)
      call MXVALS(iuur1,iuur2,xvals,ksteps)

c --------------------------------------------------------------
C 3.  x-AXIS range  and text, ticks, labels etc
c     for monthly forecasts  32 days
c --------------------------------------------------------------
      call MXAXIS(iday1,iday2,kdate,subpginfo,ieng,ilarge,iplottype,
     +            kstation)

c ----------------------------------------------------------------------
c 4.  Define the y-axis  
c ----------------------------------------------------------------------

c 4.1 Set minimum and maximum value, and tick interval
      call MYAXSCALE(kpar,pens,pobs,pgids,ksteps,km,ymin,ymax,ystep)
c      if(kpar.eq.142) then
c       CALL PSETC('AXIS_TICK_POSITIONING','LOGARITHMIC')
c       yMAX = 100.0
c       yMIN = 1.0
c      else
c       CALL PSETC('AXIS_TICK_POSITIONING','REGULAR')
c      endif

c 4.2 text, ticks, labels ....
      call MYAXTXT(kpar,cytxt,Lprob,ieng)
      if(kpar.eq.991) then
        call MYAXIS_ijs(ymin,ymax,ystep,cytxt,ilarge)
      else
        call MYAXIS(ymin,ymax,ystep,cytxt,ilarge)
      endif
c ----------------------------------------------------------------------
c 5.  Set up legend box 
c ----------------------------------------------------------------------
      call MLEGEND(subpginfo,ilarge,Lobs,Lgids,Lprob)

c ----------------------------------------------------------------------
c 6.  Plot ensemble
c ----------------------------------------------------------------------

C 6.1 Data below -999 is ignored
      CALL PSETR('GRAPH_Y_SUPPRESS_BELOW',-998.)
      CALL PSETR('GRAPH_Y_SUPPRESS_ABOVE',998.)

c 6.2 ens plot
      call MENSPL(pens,ksteps,km,xvals,kpar,kcolor,iplottype,ilarge)

c 6.3 Plot Gids 
      if(Lgids) then 
        if(kpar.eq.167.and.kstation.eq.6260) then
          call MGIDSPL(xvals,pgids,ksteps,ilarge)
        endif
      endif

c 6.4 Plot Obs 
      if(Lobs) then 
        call MOBSPL(xvals,pobs,ksteps)
      endif

c 6.5 Plot reference grid lines 
      call MGRIDPL(iday1,iday2,ymin,ymax,kpar)

c 6.6 Plot zero line
      if(ymin.lt.0) then
        call MZEROPL(iday1,iday2,0.0)
      endif

c ----------------------------------------------------------------------
c 7.  Plot tekst 
c ----------------------------------------------------------------------

c 7.1 Set text string for  variable 
      call MPARAM(kdate,kpar,cpar,ieng)

C 7.2 Title and boxes 
      call MTEKST(kpar,subpginfo,kdate,kstation,cpar,ieng,ilarge)

      call MSUBPENQ
      call MPAGENQ

      RETURN
      END


      SUBROUTINE MBARS(phisto,ksteps,kbins,kpar,kdate,kstation,
     +                   cbarleg,cbarcol,kcolor,ktype)
c ---------------------------------------------------------------------
c    Makes bar plot or area plot of probabilities 
c 
c  phisto(ksteps,kbins)  ensemble bins
c  ksteps           aantal forecast steps ( begin bij 0 ) 
c  kbins            aantal bins 
c  kpar             parameter (MARS convention)
c  kdate            date (yymmdd)
c  kstation         station number  
c  kcolor           parameter to indicate colour or bw plot 
c  ktype            area plot or bar plot
c  cbarcol, cbarleg colours and text of legends
c                           may 2005 
c ----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      IMPLICIT NONE

      INTEGER ntijdmax,mlarge,mengels,mplottype
      parameter (ntijdmax=500)
      COMMON /SETTINGS/ mlarge,mengels,mplottype
      integer ksteps,kbins,kpar,kdate,kstation,kcolor,ktype
      REAL phisto(ksteps,kbins)

      INTEGER ieng,ilarge,iplottype
      INTEGER iday1,iday2,iuur1,iuur2
      LOGICAL Lobs,Lgids,Lprob

      CHARACTER*20 cstation, cpar, cytxt
      CHARACTER*12 cbarleg(10) ,cbarcol(10)
 
      REAL xvals(ntijdmax)
      REAL subpginfo(4)
      REAL ymin,ymax,ystep

c     check
      if(ksteps.gt.ntijdmax) stop "make ntijdmax larger in pluimlees"

c     probabilty plot
      Lprob=.true.

c     no observations
      Lobs=.false.

c     nogids 
      Lgids=.false.
c ----------------------------------------------------------------------
c 0.  Preparations 
c ----------------------------------------------------------------------

c 0.1 Text language  (via common)
      ieng = mengels 

c 0.2 size ( via common )
      ilarge = mlarge
c 
c 0.3 type of plot ( via common )
      iplottype = mplottype

c ----------------------------------------------------------------------
c 1.  Size (page subpage etc ) and some general settings 
c ----------------------------------------------------------------------
      CALL MLAYOUTP(ilarge,subpginfo)

c ----------------------------------------------------------------------
c 2.  Range of plume from iuur1 to iuur2 (can be different from axis)
c     and definition of x-coordinates, xvals expressed in days
c ----------------------------------------------------------------------
      call MXRANGE(iplottype,iuur1,iuur2,iday1,iday2)
      call MXVALS(iuur1,iuur2,xvals,ksteps)

c ----------------------------------------------------------------------
C 3.  Horizontal AXIS (from iday1 to iday2), iday1 supposed to be zero!! 
c ----------------------------------------------------------------------
      call MXAXIS(iday1,iday2,kdate,subpginfo,ieng,ilarge,iplottype,
     +            kstation)

c ----------------------------------------------------------------------
c 4.  Prepare y-axis
c ----------------------------------------------------------------------
      YMIN = 0 
      YMAX = 100 
      YSTEP = 20.0 
c      if(ieng.eq.1) then 
c        cytxt="Probability (%)"
c      else
c        cytxt="Kans (%)"
c      endif
      call MYAXTXT(kpar,cytxt,Lprob,ieng)
      call MYAXIS(ymin,ymax,ystep,cytxt,ilarge)

c ----------------------------------------------------------------------
c 5.  Legend box  
c ----------------------------------------------------------------------
      call MLEGEND(subpginfo,ilarge,Lobs,Lgids,Lprob)
      
c ----------------------------------------------------------------------
c 6.  Plot probabilities either bars or contours 
c ----------------------------------------------------------------------
      call MPROBPL(phisto,ksteps,kbins,xvals,
     +                     subpginfo,cbarleg,cbarcol,ktype)

c ----------------------------------------------------------------------
C 7.  Title and boxes 
c ----------------------------------------------------------------------
      call MPARAM(kdate,kpar,cpar,ieng)
      call MTEKST(kpar,subpginfo,kdate,kstation,cpar,ieng,ilarge)

      RETURN
      END



      subroutine MLAYOUTP(klarge,psubpginfo)
C ----------------------------------------------------------------------
C   Set size of plots
c   one landscape plot ( klarge = 1 )
c   a small portrait plot, 3 on a page ( klarge = 3 )
c   landscape, 6 on a page ( klarge = 6 )
c
c   input : 
c     klarge    is number of plots per a4 )   
c     kpar      parameter 
c   output
c     pxsubpl, pysubpl     subpage lengths
c     pxsubp,  pysubp       subpage coord bottom left
c
C ----------------------------------------------------------------------

      dimension psubpginfo(4)

c 1.  Define Super page

c     landscape, one single plot 
      if(klarge.eq.1) then
        XSIZE=28.0
        YSIZE=19.5
        nplots = 1
      endif
c     Portrait, two over each other
      if(klarge.eq.2) then
        XSIZE=19.5
        YSIZE=28.0
        nplots = 2
      endif
c     Portrait, three over each other
      if(klarge.eq.3) then
        XSIZE=19.5
        YSIZE=28.0
        nplots = 3
      endif
c     landscape, 6 on a page
      if(klarge.eq.6) then
        XSIZE=28.0
        YSIZE=19.5
        nplots = 6
      endif

c 2.  Define page lengths depending on number of plots on a page
      zxpagel = xsize
      zypagel = ysize/REAL(nplots) - 0.01
      if(klarge.eq.6) then  
        zxpagel = 13.7
        zypagel = 6.5 
      endif

c 3.  Define subpage lengths, corner points (left and right) etc

c 3.1 Define margins left right top bottom
      if(klarge.eq.1) then  
        pxsubp  = 2.5 
        pxsubpr = 2.3 
        pysubp  = 2 
        pysubpt = 2 
      endif
      if(klarge.eq.2) then  
        pxsubp  = 2.0
        pxsubpr = 2.0
        pysubp  = 1.4
        pysubpt = 1.5 
      endif
      if(klarge.eq.3) then  
        pxsubp  = 1.8 
        pxsubpr = 1.8 
        pysubp  = 1.4
        pysubpt = 1.0 
        pysubpt = 0.9 
      endif
      if(klarge.eq.6) then  
        pxsubp  = 1.1
        pxsubpr = 1.1 
        pysubp  = 1.0
        pysubpt = 0.6 
      endif

c 3.2 Define subpage length
      pxsubpl = zxpagel - (pxsubp + pxsubpr) 
      pysubpl = zypagel - (pysubp + pysubpt) 

      psubpginfo(1) = pxsubpl
      psubpginfo(2) = pysubpl
      psubpginfo(3) = pxsubp
      psubpginfo(4) = pysubp

c 4.  Set the various pages  ( super, page, sub )

c 4.1 superpage
      CALL PSETR ('SUPER_PAGE_X_LENGTH',XSIZE)
      CALL PSETR ('SUPER_PAGE_Y_LENGTH',YSIZE)
      CALL PSETC ('SUPER_PAGE_FRAME','OFF')

      CALL PSETC ('PLOT_START','TOP')
      CALL PSETC ('PLOT_DIRECTION','VERTICAL')

c 4.2 page 
      CALL PSETR('PAGE_X_LENGTH',zxpagel)
      CALL PSETR('PAGE_Y_LENGTH',zypagel)
      CALL PSETR('PAGE_X_POSITION',0.)
      CALL PSETR('PAGE_Y_POSITION',0.)
      CALL PSETC ('PAGE_ID_LINE','OFF')

c 4.3 Set the various sub pages 
      CALL PSETR('SUBPAGE_X_LENGTH',pxsubpl)
      CALL PSETR('SUBPAGE_Y_LENGTH',pysubpl)
      CALL PSETR('SUBPAGE_X_POSITION',pxsubp)
      CALL PSETR('SUBPAGE_Y_POSITION',pysubp)

c 5.  Projection  (stereographic/cylindrical...)
      call PSETC('SUBPAGE_MAP_PROJECTION','NONE')

c 6.  Set no Grid pattern on plot
      CALL PSETC('AXIS_GRID','OFF')

c 7.  New subpage : now you are  ready to plot  
      call PNEW('SUBPAGE')

      RETURN
      END




c ======================================================================
c ======================================================================
c 3.   X-Axis set ups etc 
c      mxaxis
c      mxlabels
c      mxtimes
c ======================================================================
c ======================================================================



      subroutine MXAXIS(kday1,kday2,kdate,psubpginfo,keng,klarge,
     +    kmaand,kstation)
c ----------------------------------------------------------------------
c  Horizontal axis , from kday1 to kday2 
c  Interval is always one day, the minor ticks can be every 6 hours 
c  currently the minor ticks are at 00 UTC, the major ticks at 12 UTC
c   kdate   : initial date
c   psubpginfo(4)  array with subpage info
c -----------------------------------------------------------------------
      dimension psubpginfo(4)

      pxsubpl = psubpginfo(1)
      pysubpl = psubpginfo(2)
      pxsubp  = psubpginfo(3)
      pysubp  = psubpginfo(4)

c     character height of text and labels at x-axis
      if(klarge.eq.1) rheight=0.4
      if(klarge.eq.2) rheight=0.3
      if(klarge.eq.3) rheight=0.3
      if(klarge.eq.6) rheight=0.2

C 1.  Define Horizontal axis
      CALL PSETC('AXIS_ORIENTATION','HORIZONTAL')
      CALL PSETC('AXIS_POSITION','BOTTOM')

c 2.  Scaling
      ZXMIN = kday1
      ZXMAX = kday2 
      CALL PSETR('AXIS_MIN_VALUE',ZXMIN)
      CALL PSETR('AXIS_MAX_VALUE',ZXMAX)

c 3.  Major Ticks, one per day, at the day label
      CALL PSETC('AXIS_TICK','ON')
      if(klarge.ge.6) then
        CALL PSETR('AXIS_TICK_SIZE',0.15)
      else
        CALL PSETR('AXIS_TICK_SIZE',0.17)
      endif
      cALL PSETC('AXIS_TICK_COLOUR','BLACK')
      CALL PSETC('AXIS_TICK_LABEL','ON')
      CALL PSETR('AXIS_TICK_LABEL_HEIGHT',rheight)
      CALL PSETC('AXIS_TICK_LABEL_QUALITY','HIGH')
      CALL PSETC('AXIS_TICK_LABEL_LAST','ON')
      CALL PSETR('AXIS_TICK_INTERVAL',1.0)
      if(kmaand.eq.1) then 
        CALL PSETR('AXIS_TICK_INTERVAL',1.0)
        CALL PSETI('AXIS_TICK_LABEL_FREQUENCY',5)
      else
        call MXLABELS(kdate,kday1,kday2,keng)
      endif

c 3.2 Minor ticks at every 12 hours  or every 6 hours 
c     for monthly forecasts minor ticks every day
      if(kmaand.eq.1) then 
        CALL PSETC('AXIS_MINOR_TICK','OFF')
      else
        CALL PSETI('AXIS_MINOR_TICK_COUNT',3)
        CALL PSETr('AXIS_MINOR_TICK_SIZE',0.05)
        if(ksteps.eq.20) CALL PSETI('AXIS_MINOR_TICK_COUNT',1)
        if(ksteps.ge.40) CALL PSETI('AXIS_MINOR_TICK_COUNT',3)
        if(ksteps.ge.60) CALL PSETI('AXIS_MINOR_TICK_COUNT',3)
      endif


c 4.  Line 
      CALL PSETC('AXIS_LINE','ON')
      CALL PSETI('AXIS_LINE_THICKNESS',4)
      CALL PSETC('AXIS_LINE_COLOUR','BLACK')

c 5.  Text
      CALL PSETC('AXIS_TITLE','ON')
      if(keng.eq.0) CALL PSETC('AXIS_TITLE_TEXT','Dag')
      if(keng.eq.1) CALL PSETC('AXIS_TITLE_TEXT','Day')
      if(kstation.gt.10000) then
        if(keng.eq.0) CALL PSETC('AXIS_TITLE_TEXT','Dag (China tijd)')
        if(keng.eq.1) CALL PSETC('AXIS_TITLE_TEXT','Day (China time)')
      endif
      CALL PSETR('AXIS_TITLE_HEIGHT',rheight)
      CALL PSETC('AXIS_TITLE_QUALITY','HIGH')

c 6.  Draw horixontal axis
      CALL PAXIS

c 7.  Draw 00 labels in between the days 
      if(kmaand.eq.0.or.kmaand.eq.2) then
        call MXTIMES(kday1,kday2,kdate,psubpginfo,klarge,kstation)
      endif

      return
      end



      subroutine MXLABELS(kdate,kday1,kday2,keng)
c -------------------------------------------------------------------
c  Construct text strings for labels   
c  calls to library routines MDATFOR en DTGTXT
c -------------------------------------------------------------------
      dimension rlist(100)
      character*35  cy2adtg
      character*2 clabels(100)

      jdeluur = 6
      nlabels = 24*(kday2-kday1)/jdeluur + 1 

      do 120  j=1,nlabels

c       Forecast range : 0 - 240
        idfc = (j-1)*jdeluur

c       Construct forecast date in yymmddtt
        call MDATFOR(kdate,idfc,idatef)
        ihh =  MOD(idatef,100)
        rlist(j) = REAL(idfc)/24.0 

c       Set the appropriate text of the date : day xx month, year
        call DTGTXT2(idatef,cy2adtg,keng)

c       Transfer only first two characters of day string
        clabels(j) = " " 
        if(ihh.eq.12) then
          clabels(j) = cy2adtg(2:3)
        endif
120   continue

c     plot the ticks 
      CALL PSETC('AXIS_TICK_POSITIONING','POSITION_LIST')
      CALL PSETC('AXIS_TICK_LABEL_UNITS','USER')
      CALL PSET1r('AXIS_TICK_POSITION_LIST',rlist,nlabels)
      CALL PSETC('AXIS_TICK_LABEL_TYPE','LABEL_LIST')
      CALL PSET1C('AXIS_TICK_LABEL_LIST',clabels,nlabels)
      CALL PSETC('AXIS_MINOR_TICK','OFF')


      return
      end



      subroutine MXTIMES(kday1,kday2,kdate,psubpginfo,klarge,kstation)
c ----------------------------------------------------------------------
c  Routine to plot  12 and 00 labels at the axis of the plume  
c  It simply plots a set of text boxes at fixed positions along the axis
c   
c  The positioning of the labels is dependent on 
c      initial position of xaxis ( pxsubp )
c      initial position of yaxis ( pysubp )
c      length of xaxis ( pxsubpl )  
c  The number of labels is dependent on
c      range of days   : kday1 .....  kday2    
c  
c  Input parameters
c    pxsubp     initial position of xaxis ( set in routine layout)
c    pysubp     initial position of yaxis ( set in routine layout)
c    pxsubpl    length of xaxis ( set in routine layout )
c    kday1      first day along axis   ( usually kday1 =0)
c    kday2      last day along xaxis   ( usually kday2 = 10 
c    klarge     parameter to define size of plot ( 0 or 1 )
c 
c  The 12 labels overlap  with the main text axis label.
c  so the middle 12 label ( at day 5 )  is skipped
c
c   Robert Mureau  18-1-2001 
c
c  Adapted for 00 UTC runs with flexible initial times
c
c ----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      dimension psubpginfo(4)

      pxsubpl = psubpginfo(1)
      pysubpl = psubpginfo(2)
      pxsubp  = psubpginfo(3)
      pysubp  = psubpginfo(4)

c 0.1 We are going to plot text boxes with variable positions
      CALL PSETC('TEXT_MODE','POSITIONAL')

c 0.2 Text specs
      CALL PSETC('TEXT_QUALITY','HIGH')
      CALL PSETC('TEXT_COLOUR','BLACK')
      CALL PSETC('TEXT_JUSTIFICATION','CENTRE')
      CALL PSETC('TEXT_BORDER','OFF')

c 0.3 Set size of label text boxes ( each label in a box ) 
      zchgt = 0.2 
      if(klarge.eq.6) zchgt = 0.15 
          if(kstation.gt.10000) then
             zchgt = 0.20
          endif 
      CALL PSETR('TEXT_REFERENCE_CHARACTER_HEIGHT',zchgt)
      xboxpl = zchgt + 0.1 
      yboxpl = zchgt + 0.1 
      CALL PSETR('TEXT_BOX_X_LENGTH',xboxpl)
      CALL PSETR('TEXT_BOX_Y_LENGTH',yboxpl)
      CALL PSETI('TEXT_LINE_COUNT',1)

c 0.5 time interval of ticks ( every 6 hours )
      jdeluur = 6 

c     y position text box 
      scale2cm = pxsubpl / REAL(kday2-kday1)

      nlabels = (kday2-kday1)*24/jdeluur + 1

      do 120  j=1,nlabels

c       Forecast range : 0 - 240
        idfc = (j-1)*jdeluur

c       Construct forecast date in yymmddtt
        call MDATFOR(kdate,idfc,idatef)

        ihh =  MOD(idatef,100)
        xboxp = pxsubp - 0.5*xboxpl + scale2cm*REAL(idfc)/24.0 
        yboxp = pysubp  - yboxpl - 0.15
        if(klarge.eq.6) yboxp = pysubp  - yboxpl 
        CALL PSETR('TEXT_BOX_X_POSITION',xboxp)
        CALL PSETR('TEXT_BOX_Y_POSITION',yboxp)
        CALL PSETi('TEXT_INTEGER_1',ihh)

c       Plot ( special for china
        if(ihh.eq.00) then
          CALL PSETC('TEXT_LINE_1','@(i2.2)TEXT_INTEGER_1@')
          if(kstation.gt.10000) then
            ihh2 = ihh+8
            CALL PSETi('TEXT_INTEGER_1',ihh2)
            CALL PSETC('TEXT_LINE_1','@(i2.2)TEXT_INTEGER_1@')
          endif
          call ptext
        endif
120   continue


      return
      end



c ======================================================================
c ======================================================================
c 4. Y-Axis set ups etc 
c      myaxis
c      myaxscale
c        myaxhilo
c        myaxvals
c        myaxspecs
c        myaxtxt
c ======================================================================
c ======================================================================


      subroutine MYAXIS(pymin,pymax,pystep,cytxt,klarge)
c ----------------------------------------------------------------
c  Vertical axis  
c   kpar         : variable 
c   ymin , ymax  : axis  limits 
c   pystep       : axis vertical intervals of major ticks
c -----------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      character*20 cytxt

c 1.  Set Up  
      CALL PSETC('AXIS_ORIENTATION','VERTICAL')
      CALL PSETC('AXIS_POSITION','LEFT')
      CALL PSETC('AXIS_LINE','ON')

c 2.  Set the axis values  

      cALL PSETR('AXIS_MIN_VALUE',PYMIN)
      CALL PSETR('AXIS_MAX_VALUE',PYMAX)

c 3.  Text at yaxis
      CALL PSETC('AXIS_TITLE','ON')
      if(klarge.eq.1) rheight=0.4
      if(klarge.eq.2) rheight=0.3
      if(klarge.eq.3) rheight=0.3
      if(klarge.eq.6) rheight=0.2
      CALL PSETR('AXIS_TITLE_HEIGHT',rheight)
      CALL PSETC('AXIS_TITLE_QUALITY','HIGH')
      CALL PSETC('AXIS_TITLE_COLOUR','BLACK')

C 4.  Ticks  
      cALL PSETC('AXIS_TICK','ON')
      cALL PSETC('AXIS_TICK_POSITIONING','REGULAR')
      ystp = pystep
      CALL PSETR('AXIS_TICK_INTERVAL',PYSTEP)
      cALL PSETC('AXIS_TICK_COLOUR','BLACK')

c 5.  Labels ( just numbers )
      CALL PSETC('AXIS_TICK_LABEL','ON')
      CALL PSETR('AXIS_TICK_LABEL_HEIGHT',rheight)
      CALL PSETC('AXIS_TICK_LABEL_TYPE','NUMBER')
      CALL PSETC('AXIS_TICK_LABEL_LAST','ON')
      CALL PSETC('AXIS_TICK_LABEL_COLOUR','BLACK')

c 6.  One tick in between the major ticks
      CALL PSETC('AXIS_MINOR_TICK','ON')
      CALL PSETI('AXIS_MINOR_TICK_COUNT',1)
c      if(klarge.eq.6) CALL PSETI('AXIS_MINOR_TICK_COUNT',0)

C 7.  Text at Vertical AXIS 
      CALL PSETC('AXIS_TITLE','ON')
      CALL PSETC('AXIS_TITLE_TEXT',cytxt)

C 8.  Draw axis
      CALL PAXIS

C 9.  Repeat RIGHT VERTICAL AXIS
      CALL PSETC('AXIS_POSITION','RIGHT')
      if(klarge.eq.1) then
       CALL PSETC('AXIS_TITLE','ON')
      else
       CALL PSETC('AXIS_TITLE','OFF')
      endif
      call PAXIS


      return
      end


      subroutine MYAXIS_ijs(pymin,pymax,pystep,cytxt,klarge)
c ----------------------------------------------------------------
c  Vertical axis  
c   kpar         : variable 
c   ymin , ymax  : axis  limits 
c   pystep       : axis vertical intervals of major ticks
c -----------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      character*20 cytxt
      character*2 tlist_left(100)
      character*2 tlist_right(100)


      nticks = 1 + ( pymax - pymin ) / pystep  

      do j=1,nticks 
        label = IFIX (pymin + (j-1)*pystep )
        if(label.gt.0) then
          write(tlist_left(j),'(i2)') label 
        else
          tlist_left(j) = "  "
        endif
      enddo
      do j=1,nticks 
        label = IFIX (pymin + (j-1)*pystep ) 
        if(label.lt.0) then
          write(tlist_right(j),'(i2)') -label 
        else
          tlist_right(j) = "  "
        endif
      enddo

c 1.  Set Up  
      CALL PSETC('AXIS_ORIENTATION','VERTICAL')
      CALL PSETC('AXIS_POSITION','LEFT')
      CALL PSETC('AXIS_LINE','ON')

c 2.  Set the left axis values  
      cALL PSETR('AXIS_MIN_VALUE',pymin)
      CALL PSETR('AXIS_MAX_VALUE',PYMAX)


c 3.  Text at yaxis
      CALL PSETC('AXIS_TITLE','ON')
      if(klarge.eq.1) rheight=0.4
      if(klarge.eq.2) rheight=0.3
      if(klarge.eq.3) rheight=0.3
      if(klarge.eq.6) rheight=0.2
      CALL PSETR('AXIS_TITLE_HEIGHT',rheight)
      CALL PSETC('AXIS_TITLE_QUALITY','HIGH')
      CALL PSETC('AXIS_TITLE_COLOUR','BLACK')

C 4.  Ticks  
      cALL PSETC('AXIS_TICK','ON')
      cALL PSETC('AXIS_TICK_POSITIONING','REGULAR')
      ystp = pystep
      CALL PSETR('AXIS_TICK_INTERVAL',PYSTEP)
      cALL PSETC('AXIS_TICK_COLOUR','BLACK')

c 5.  Labels ( just numbers )
      CALL PSETC('AXIS_TICK_LABEL','ON')
      CALL PSETR('AXIS_TICK_LABEL_HEIGHT',rheight)
      CALL PSETC('AXIS_TICK_LABEL_TYPE','LABEL_LIST')
      CALL PSET1C('AXIS_TICK_LABEL_LIST',TLIST_LEFT,nticks)
      CALL PSETC('AXIS_TICK_LABEL_LAST','ON')
      CALL PSETC('AXIS_TICK_LABEL_COLOUR','BLACK')

c 6.  One tick in between the major ticks
      CALL PSETC('AXIS_MINOR_TICK','ON')
      CALL PSETI('AXIS_MINOR_TICK_COUNT',1)
c      if(klarge.eq.6) CALL PSETI('AXIS_MINOR_TICK_COUNT',0)

C 7.  Text at Vertical AXIS 
      CALL PSETC('AXIS_TITLE','ON')
      CALL PSETC('AXIS_TITLE_TEXT','T (Celsius)')

C 8.  Draw axis
      CALL PAXIS

C 9.  Repeat RIGHT VERTICAL AXIS
      if(pymin.lt.0) then
        cALL PSETR('AXIS_MIN_VALUE',pymin)
        CALL PSETR('AXIS_MAX_VALUE',pymax)
        CALL PSETC('AXIS_POSITION','RIGHT')
        CALL PSET1C('AXIS_TICK_LABEL_LIST',TLIST_RIGHT,nticks)
        CALL PSETC('AXIS_TITLE_TEXT','ijsdikte (cm)')
        CALL PSETC('AXIS_TITLE','ON')
        call PAXIS
      else
        CALL PSETC('AXIS_POSITION','RIGHT')
        call PAXIS
      endif

      return
      end



      subroutine MYAXSCALE(kpar,pens,pobs,pgids,ksteps,km,pmn,pmx,pdel) 
c ---------------------------------------------------------------------- 
c                     Scale Vertical axis  
c  Input 
c   pens(ksteps,km)    : ensemble plume 
c     ksteps  : number of forecast step  
c     km      : number of members 
c   pobs(ksteps)       : obs values 
c   pgids(ksteps)      : gids values 
c   kpar               : variable 
c  Output 
c   pymin , pymax  : axis  limit 
c ---------------------------------------------------------------------- 
c23456789012345678901234567890123456789012345678901234567890123456789012 
      dimension pens(ksteps,km),pobs(0:ksteps),pgids(0:ksteps) 
      ndim = ksteps*km
      rmin = 9999
      rmax = -9999

c     find highest/lowest value of ensemble ( but smaller then 999 )
      call MYAXHILO(pens,ndim,rmin,rmax)
c     check for highest/lowest value and compare pobs with ensemble
      call MYAXHILO(pobs,ksteps,rmin,rmax)
c     check for highest/lowest value and compare pgids with ensemble
      call MYAXHILO(pgids,ksteps,rmin,rmax)

c     Do some clever rounding off to nearest integer value
      call MYAXVALS(rmin,rmax,kymin,kymax,kystp)

c     Correct with my own preferences (like kmin always zero for wind)
      call MYAXSPECS(kpar,kymin,kymax,kystp)

c     Convert  to real
      pmn = kymin
      pmx = kymax
      pdel= kystp

      return
      end



      subroutine MYAXHILO(f,kdim,pmin,pmax)
c ----------------------------------------------------------------------
c   Find minimum maximum value , BUT smaller then 999!!
c   f(kdim)    :  array 
c   pmin , pmax  : min.max : output parameters  
c -----------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      dimension f(kdim)

      do j=1,kdim
        if(f(j).lt.pmin.and.f(j).gt.-998) pmin=f(j)
        if(f(j).gt.pmax.and.f(j).lt.998) pmax=f(j)
      enddo

      return
      end


      subroutine MYAXVALS(rmin,rmax,kymin,kymax,kystp)
c ----------------------------------------------------------------------
c  Clever rounding of to nearest integer for Vertical scale  
c -----------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012

      dimension iyticks(12)
      data iyticks /1,2,5,10,20,25,50,100,200,250,500,1000/

c 1.  Aim for roughly 6-10 tick marks
      nticks=6

c 2.  Calculate the first guess for tick interval 
      dy = (rmax-rmin)/REAL(nticks)

c 3.  Widen the span a bit an do  it again
      rmax = rmax + dy
      rmin = rmin - 0.25 *dy

c 3b. Recalculate the first guess for tick interval 
      dy = (rmax-rmin)/REAL(nticks)
      if(dy.le.1) dy=1

c 4.  Round off to closest preferred tick value
c      we donot expect values larger then 1000
      if(dy.lt.2000) then

        do i=2,12
          if(dy.le.iyticks(i).and.dy.ge.iyticks(i-1)) then
            d1=ABS(dy-iyticks(i))
            d2=ABS(dy-iyticks(i-1))
            if(d1.lt.d2) itickval=iyticks(i)
            if(d1.ge.d2) itickval=iyticks(i-1)
            goto 11
          endif
        enddo
11      continue

      else

        itickval=dy
       
      endif


c 4.  Round min max off to nearest interval 
      zz = itickval
      if(rmin.ge.0) then
        kymin= itickval*IFIX(rmin/zz) 
      else
        kymin= itickval*IFIX(rmin/zz) - itickval 
      endif
      kymax= itickval*IFIX(rmax/zz) + itickval 

c 5.  Set the tick interval in integer values
      kySTP  = itickval 


      return
      end





      subroutine MYAXSPECS(kpar,kymin,kymax,kystp)
c ------------------------------------------------------------------
c     special arrangements 
c
c ------------------------------------------------------------------
c 1.  Precip
      if(kpar.eq.142) then 
        if(kymin.lt.0) kymin=0
        if(kymax.le.20) then 
           kymax=20
           kystp=5
        endif
      endif
      if(kpar.eq.167.or.kpar.eq.168.or.kpar.eq.271.or.kpar.eq.272) 
     +  then 
        kystp=5
      endif

c     Relhum 
      if(kpar.eq.157) then 
        kymin=0
        kymax=100 
        kystp=10
      endif

c     Accum regen
      if(kpar.eq.228) then 
        if(kymin.lt.0) kymin=0
        if(kymax.le.20) then 
           kymax=20
           kystp=5
        endif
      endif

c     Snowfall
      if(kpar.eq.144) then 
        if(kymin.lt.0) kymin=0
        if(kymax.lt.5) then 
           kymax=5
           kystp=1
        endif
      endif


c 2.  wind: never the ymax should be below 20m/s 
      if(kpar.eq.165.or.kpar.eq.265) then
        kymin = 0.
        if(kymax.lt.20) then 
          kymax=20
          kystp=5
        endif
      endif

c     gusts
      if(kpar.eq.49) then
        kymin = 0.
        if(kymax.lt.30) then 
          kymax = 30
          kystp=5
        endif
      endif

c     cape 
      if(kpar.eq.59) then
        kymin = 0.
        if(kymax.lt.4) then 
          kymax = 4 
          kystp = 1
        endif
      endif

c     p-e 
      if(kpar.eq.182) then
        if(kymax.lt.5) then 
          kymax=5
          kystp=1
        endif
c        if(kymin.ge.-5) then 
c          kymin=-5
c        endif
      endif

c     evaporation ( from shlf )
      if(kpar.eq.147) then
        kymin=0
        if(kymax.le.5) then 
          kymax=5
        endif
      endif

c 4.  Watertemperature / Ice 
      if(kpar.eq.991) then
        kystp = 5
        if(kymax.lt.10.and.kymax.gt.0)  kymax = 10
        if(kymax.lt.20.and.kymax.gt.10)  kymax = 20
        if(kymax.lt.0)  kymax = 0 
        if(kymin.gt.-10.and.kymin.lt.0) kymin = -10
        if(kymin.gt.-20.and.kymin.lt.-10) kymin = -20
        if(kymin.gt.0)  kymin = 0 
      endif

c 5.  Solar radiation
      if(kpar.eq.157) then
        kymax = 100.
        kymin = 0.
      endif

c 6.  wind surge, set scale never below 50cm, and set the steps 
      if(kpar.eq.270) then 
        if(kymin.gt.0) kymin=0
        if(kymax.lt.0) kymax=0

        if(kymax.lt.50) then 
          kymax=50
          kystp=10
        endif
        if(kymin.gt.-50) then 
          kymin=-50
          kystp=10
        endif
      endif

c 7.  clouds
      if(kpar.eq.164) then
        kymax = 120.
        kymin = 0.
        kYSTP = 20
      endif

c 8.  wave heights
      if(kpar.eq.229) then
        if(kymax.le.5) then
          kymax = 5.
          kystp=1
        endif
        kymin = 0.
      endif

      return
      end



      subroutine MYAXTXT(kpar,cytxt,Lprob,keng)
C ----------------------------------------------------------------------
c   Set  TEXT for the yaxis, for prob maps a universal text is set
c ---------------------------------------------------------------------
      CHARACTER*20 cytxt

      if(Lprob) then

        if(keng.eq.1) then 
          cytxt="Probability (%)"
        else
          cytxt="Kans (%)"
        endif

      else

        if(kpar.eq.142) CYTXT='mm'
        if(kpar.eq.144) CYTXT='cm'
        if(kpar.eq.228) CYTXT='mm'
c       P-E (or latent heat flux)
        if(kpar.eq.147) CYTXT='mm'
c       evaporation
        if(kpar.eq.182) CYTXT='mm'
        if(kpar.eq.164) CYTXT='%'
        if(kpar.eq.49) CYTXT='m/s'
        if(kpar.eq.59) CYTXT='kJ/kg'
        if(kpar.eq.165) CYTXT='m/s'
        if(kpar.eq.265) CYTXT='m/s'
        if(kpar.eq.166) CYTXT='m/s'
        if(kpar.eq.167) CYTXT='Celsius'
        if(kpar.eq.168) CYTXT='Celsius'
        if(kpar.eq.201) CYTXT='Celsius'
        if(kpar.eq.202) CYTXT='Celsius'
        if(kpar.eq.229) CYTXT='m'
        if(kpar.eq.991) CYTXT='Celsius'
        if(kpar.eq.992) CYTXT='ijs (cm)'
        if(kpar.eq.270) CYTXT='Opzet (cm)'
c       wbgt
        if(kpar.eq.271) CYTXT='Celsius'

        if(keng.eq.1) then 
          if(kpar.eq.992) CYTXT='ice (cm)'
          if(kpar.eq.270) CYTXT='Surge (cm)'
          if(kpar.eq.271) CYTXT='Celsius'
        endif

      endif

      return
      end


 
c ======================================================================
c ======================================================================
c 5.  The plotting routines
c       mxrange
c       mxvals
c       menspl
c       mgidspl
c       mobspl
c       mprobpl
c       mzeropl
c       mgridpl
c ======================================================================
c ======================================================================


      subroutine MXRANGE(kplottype,kuur1,kuur2,kday1,kday2)
c ----------------------------------------------------------------------
c     Range of plume from iuur1 to iuur2 (can be different from axis)
c     and definition of x-coordinates, xvals, expressed in days
C     and range of x-AXIS range ( day1 to day2 ) 
c     Note that combinations might  vary 
c     kplottype    : type of plot ( 10days, 15 days, monthly )
c     kuur1, kuur2 : first and last time step  (in hours)
c     kday1,kdays  : first and last value on axis (in daysO
c ----------------------------------------------------------------------
c     10 days
      if(kplottype.eq.0) then 
        kuur1 = 6 
        kuur2 = 240 
        kday1 = 0
        kday2 = 10
      endif
c     month ( not every  6 hours but one per day )
      if(kplottype.eq.1) then 
        kuur1 = 24 
        kuur2 = 32*24 
        kday1 = 0
        kday2 = 32
      endif
c     15 days
      if(kplottype.eq.2) then 
        kuur1 = 6 
        kuur2 = 360 
        kday1 = 0
        kday2 = 15
      endif

      return
      end


      subroutine MXVALS(kuur1,kuur2,pxvals,ksteps)
c ----------------------------------------------------------------------
c  Set the x coordinates of the plot, expressed in fraction of days, 
c  Input 
c    kuur1 is first time step of plume 
c    kuur2 is last time step of the plume ( in hours )
c    ksteps  number of time steps
c  Output
c    pxvals (ksteps) contains x coords in fraction of days 
c ----------------------------------------------------------------------
      dimension pxvals(ksteps)

c 1.  Interval of each forecast step (in hours and  days) 
      iuurstep = (kuur2-kuur1) / (ksteps-1) 
      zdxval = REAL(iuurstep)/24.0

c 2.  Definition of x-coordinates, expressed in days
      do jstep=1,ksteps
        pxvals(jstep) = REAL(jstep)*zdxval
      enddo

      return
      end


      subroutine MENSPL(pens,ksteps,km,pxvals,kpar,
     +                  kcolor,kplottype,klarge)
c23456789012345678901234567890123456789012345678901234567890123456789012
c ----------------------------------------------------------------------
c Plots ensemble lines 
c   input 
c     pens(ksteps,km) the ensemble for  timesteps / nr of members
c     pxvals(ksteps)  the x values of the plot
c     kpar            parameter
c     kcolor          color or black / white option ( dotted lines )
c   output
c    none
c ----------------------------------------------------------------------
      IMPLICIT NONE

      INTEGER ntijdmax
      parameter (ntijdmax=500)

      INTEGER ksteps,km,kpar,kcolor
      REAL pens(ksteps,km),pxvals(ksteps)
      REAL zensmn(ntijdmax),zy(ntijdmax)
      INTEGER jmstart,jm,jmember1,jstep,nmin,itel
      INTEGER klarge,kplottype

cc      COMMON /SETTINGS/ mlarge,mengels,mplottype

      if(ksteps.gt.ntijdmax) then
        write(6,*) "te veel tijdstappen in PROBPL, verhoog ntijdmax"
        stop
      endif

c ----------------------------------------------------------------------
c 1.  general settings 
c ----------------------------------------------------------------------

c     no sybols
      CALL PSETC('GRAPH_SYMBOL','OFF')

c     line curves connecting the points  
      CALL PSETC('GRAPH_LINE','ON')
      CALL PSETC('GRAPH_CURVE_METHOD','STRAIGHT')
cc        CALL PSETC('GRAPH_CURVE_METHOD','ROUNDED')

c     plot over everything that is already there
      CALL PSETC('GRAPH_BLANKING','OFF')

c ----------------------------------------------------------------------
c 2.  plot the pert ensemble members first ( oper should be on top )
c ----------------------------------------------------------------------

c 2.1 No legend entry
      CALL PSETC('LEGEND_ENTRY','OFF')

c 2.2 dotted for bw curve, solid for colour
      if(kcolor.eq.1) then 
        CALL PSETC('GRAPH_LINE_STYLE','DOT')
        CALL PSETI('GRAPH_LINE_THICKNESS',1)
      endif
      if(kcolor.eq.2) then 
        CALL PSETC('GRAPH_LINE_STYLE','SOLID')
        CALL PSETI('GRAPH_LINE_THICKNESS',1)
        if(klarge.eq.1) CALL PSETI('GRAPH_LINE_THICKNESS',3)
      endif

c 2.3 green 
      CALL PSETC('GRAPH_LINE_COLOUR','AVOCADO')

c 2.4 Set the start id of the first memeber to plot
c     skip control and oper  because they are separate color
c     ( in monthly forecast there is 51 members and no oper run ! ) 
      if(kplottype.eq.1) then
        jmember1=2
      else
        jmember1=3
      endif 

c 2.5 Plot all the members, but skip control and oper 
      do 190 jm=jmember1,km

c       Transfer plot values into plotarray (skip first two members)
        do jstep=1,ksteps
          zy(jstep) = pens(jstep,jm)
        enddo
        CALL PSET1R('GRAPH_CURVE_X_VALUES',pxvals,ksteps)
        CALL PSET1R('GRAPH_CURVE_Y_VALUES',zy,ksteps)
        CALL PGRAPH
 
190   continue

c ----------------------------------------------------------------------
c 3.  Set  the general settings for plot control, oper and ensemble mean
c ----------------------------------------------------------------------

c 3.1 legend on  
      CALL PSETC('LEGEND_ENTRY','ON')

c 3.2 Make both very thick
      CALL PSETI('GRAPH_LINE_THICKNESS',4)
      if(klarge.eq.1) CALL PSETI('GRAPH_LINE_THICKNESS',12)
      if(klarge.eq.3) CALL PSETI('GRAPH_LINE_THICKNESS',8)

c ----------------------------------------------------------------------
c 4.  plot the control and oper ( oper and ensmn should plotted last)
c ----------------------------------------------------------------------

      do jm=jmember1-1,1,-1

c 4.1   Set Style and colours  for control forecast and plot

        if(jm.eq.2) then
          CALL PSETC('GRAPH_LINE_STYLE','DASH')
          CALL PSETC('GRAPH_LINE_COLOUR','BLUE')
          CALL PSETC('LEGEND_USER_TEXT',"Control")
        endif
        if(jm.eq.1) then
          CALL PSETC('GRAPH_LINE_STYLE','SOLID')
          CALL PSETC('GRAPH_LINE_COLOUR','RED')
          CALL PSETC('LEGEND_USER_TEXT',"Oper")
        endif
c       make exception for monthly forecast  model
        if(jm.eq.1.and.jmember1.eq.2) then
          CALL PSETC('GRAPH_LINE_STYLE','DASH')
          CALL PSETC('GRAPH_LINE_COLOUR','BLUE')
          CALL PSETC('LEGEND_USER_TEXT',"Control")
        endif

c 4.2   Transfer plot values into plotarray (skip first two steps)
        do jstep=1,ksteps
          zy(jstep) = pens(jstep,jm)
        enddo

        CALL PSET1R('GRAPH_CURVE_X_VALUES',pxvals,ksteps)
        CALL PSET1R('GRAPH_CURVE_Y_VALUES',zy,ksteps)
        CALL PGRAPH

      enddo

c ----------------------------------------------------------------------
c 5.  Ensemble mean
c ----------------------------------------------------------------------
      CALL PSETC('GRAPH_LINE_STYLE','DOT')
      CALL PSETC('GRAPH_LINE_COLOUR','BROWN')
      CALL PSETC('LEGEND_USER_TEXT',"Ens mn")
      CALL PSETI('GRAPH_LINE_THICKNESS',7)
      if(klarge.eq.1) CALL PSETI('GRAPH_LINE_THICKNESS',12)
      if(klarge.eq.3) CALL PSETI('GRAPH_LINE_THICKNESS',8)
      call MENSMEAN(pens,zensmn,ksteps,km)
      CALL PSET1R('GRAPH_CURVE_X_VALUES',pxvals,ksteps)
      CALL PSET1R('GRAPH_CURVE_Y_VALUES',zensmn,ksteps)
      CALL PGRAPH

      return
      end

      subroutine MENSMEAN(pens,zensmn,ksteps,km)
c ----------------------------------------------------------------------
c     calculate ensemble mean
c ----------------------------------------------------------------------
      REAL pens(ksteps,km), zensmn(ksteps)

      do jstep=1,ksteps
        zensmn(jstep) = 0
        itel = 0
        do jm=1,km
          if(pens(jstep,jm).lt.999) then
           itel = itel+1
           zensmn(jstep) = zensmn(jstep) + pens(jstep,jm) 
          endif
        enddo
        zensmn(jstep) = zensmn(jstep) / REAL(itel) 
      enddo

      return
      end


      subroutine MOBSPL(pxvals,pobs,ksteps)
c ----------------------------------------------------------------------
c  Plot  observations 
c  including the plot of the very first analysis point 
c  Input
c     Array pxvals(1:ksteps)       : x-coordinats of plot
c     Array pobs(0:ksteps)         : y-coordinate of plot  
c ----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      IMPLICIT NONE
      integer ntijdmax
      parameter (ntijdmax=500)

      INTEGER ksteps
      REAL pobs(0:ksteps),pxvals(ksteps)

      REAL zy(ntijdmax)
      INTEGER jstep,nx

      if(ksteps.gt.ntijdmax) then
        write(6,*) "te veel tijdstappen in PROBPL, verhoog ntijdmax"
        stop
      endif

c 2.  Y-values 
      do  jstep=1,ksteps
        zy(jstep) = pobs(jstep)
      enddo 

c 3.  Number of points to be plotted 

c 4.  Plot
      CALL PSET1R('GRAPH_CURVE_X_VALUES',pxvals,ksteps)
      CALL PSET1R('GRAPH_CURVE_Y_VALUES',zy,ksteps)
c      CALL PSETC('GRAPH_LINE','OFF')
      CALL PSETC('GRAPH_LINE','ON')
      CALL PSETC('GRAPH_LINE_STYLE','SOLID')
      CALL PSETC('GRAPH_LINE_COLOUR','BLACK')
      CALL PSETI('GRAPH_LINE_THICKNESS',8)
      CALL PSETC('GRAPH_SYMBOL','ON')
      CALL PSETr('GRAPH_SYMBOL_HEIGHT',0.2)
      CALL PSETi('GRAPH_SYMBOL_MARKER_INDEX',18)
      CALL PSETc('GRAPH_SYMBOL_COLOUR','BLACK')
      CALL PSETC('LEGEND_ENTRY','ON')
      CALL PSETC('LEGEND_USER_TEXT',"Obs")
      CALL PGRAPH

      return
      end



      subroutine MGIDSPL(pxvals,pgids,ksteps,klarge)
c ------------------------------------------------------------
c  Plot guidance (for temperature)
c  Allows for plotting guidance when model is presented in
c    either 6hour resolution or 12 hour resolution
c  Input
c     Array pxvals(ksteps)       : xcoordinats of plot
c     Array pgids(kgids1:kgids2) : guidance values
c                                      17-2-2000 
c ------------------------------------------------------------
      parameter (ntijdmax=200)
      dimension pgids(0:ksteps),pxvals(ksteps)
      dimension zx(50),zy(ntijdmax)
      dimension zzx(3),zzy(3)

c     -------------------------------
c 1.  Transfer data to working arrays
c     -------------------------------
      do jstep=0,ksteps
        zy(jstep) = pgids(jstep)
      enddo

c     ---------------------------------------------
c 2.  Number of points to be plotted 
c     ---------------------------------------------
      nmax = ksteps+1

c     ---------------------------------------------
c 3.  Plot 
c     ---------------------------------------------
      CALL PSETC('LEGEND_ENTRY','ON')
      CALL PSETC('LEGEND_USER_TEXT',"MOS TnTx")

      CALL PSETC('GRAPH_LINE','OFF')
      CALL PSETC('GRAPH_SYMBOL','ON')
      CALL PSETR('GRAPH_SYMBOL_HEIGHT',0.2)
      if(klarge.eq.6) then
        if(ksteps.eq.40) then 
          CALL PSETR('GRAPH_SYMBOL_HEIGHT',0.18)
        endif
        if(ksteps.eq.60) then 
          CALL PSETR('GRAPH_SYMBOL_HEIGHT',0.15)
        endif
      endif
      if(klarge.eq.1) CALL PSETR('GRAPH_SYMBOL_HEIGHT',0.3)
      CALL PSETI('GRAPH_SYMBOL_MARKER_INDEX','ON')
      CALL PSETC('GRAPH_SYMBOL_COLOUR','BROWN')

      CALL PSETC('GRAPH_CURVE_METHOD','STRAIGHT')
      MIND=15
      CALL PSETI('GRAPH_SYMBOL_MARKER_INDEX',MIND)
 
      CALL PSET1R('GRAPH_CURVE_X_VALUES',pxvals(1),ksteps)
      CALL PSET1R('GRAPH_CURVE_Y_VALUES',zy(1),ksteps)

      CALL PGRAPH

c     ---------------------------------------------
c 4.  Plot horizontal segments through symbols, only for 6 hour resolution
c     ---------------------------------------------
      CALL PSETC('LEGEND_ENTRY','OFF')
      CALL PSETC('GRAPH_SYMBOL','OFF')
      CALL PSETC('GRAPH_LINE','ON')
      CALL PSETC('GRAPH_LINE_STYLE','SOLID')
      CALL PSETI('GRAPH_LINE_THICKNESS',5)
      CALL PSETC('GRAPH_LINE_COLOUR','BROWN')

c     Generate and plot the segments
      do 410 jpoint=0,nmax

c 4.1   Number of points in segment 
        nx = 3   

c 4.2   Segment is: 6 hours to the left,to 6 hours to the right 
c          ( i.e. plot line of 3 points each time )
        dx = pxvals(2) - pxvals(1)
        if(ksteps.eq.20) dx = 0.5* (pxvals(2) - pxvals(1))
        zzx(2) = pxvals(jpoint)
        zzx(1) = zzx(2) -dx 
        zzx(3) = zzx(2) +dx 

c 4.3   Set y values 
        do j=1,nx
          zzy(j) = zy(jpoint)
        enddo

c       Draw segments of 3 steps 
        CALL PSET1R('GRAPH_CURVE_X_VALUES',zzx,nx)
        CALL PSET1R('GRAPH_CURVE_Y_VALUES',zzy,nx)

        CALL PGRAPH

410   continue 



      return
      end


      subroutine MPROBPL(phisto,ksteps,kbins,
     +                   pxvals,psubpginfo,cbarleg,cbarcol,ktype)
c     ------------------------------------------------------------------
c Plots ensemble bars 
c  input
c    phisto(ksteps,kbins)  histogram with the probs
c    kbins                 number of bins , set in MOCRIT
c    pxvals                time steps array 
c    psxubpl               length of horiz axis 
c                           ( needed for width of bars )
c    cbarleg,cbarcol       character strings with legends /colors
c    ktype                 area plot ktype =1, bar plot ktype = -1 
c  output
c    none
c ----------------------------------------------------------------------
c23456789012345678901234567890123456789012345678901234567890123456789012
      IMPLICIT NONE
      integer nloc
      parameter (nloc=500)

      INTEGER ksteps,kbins,ktype
      REAL phisto(ksteps,kbins),pxvals(ksteps),xsubpl,ysubpl
      CHARACTER*12 cbarcol(10), cbarleg(10), cbar, cleg 
      INTEGER jbin,jstep
      REAL yl(nloc),yu(nloc)
      REAL zwidth,zcheck

      REAL psubpginfo(4)
      xsubpl = psubpginfo(1)
      ysubpl = psubpginfo(2)
      
      if(ksteps.gt.nloc) then
        write(6,*) "te veel tijdstappen in PROBPL, verhoog nloc"
        stop
      endif

c ----------------------------------------------------------------------
c 1.  Set type plot ( area or bars )
c ----------------------------------------------------------------------
      if(ktype.le.0) then 
        CALL PSETC('GRAPH_TYPE','AREA')
        CALL PSETC('GRAPH_CURVE_METHOD','ROUNDED')
      endif
      if(ktype.gt.0) then 
        CALL PSETC('GRAPH_TYPE','BAR')
c       width depends on physical length of axis (annoying)
        zwidth = xsubpl/REAL(ksteps) 
        CALL PSETR('GRAPH_BAR_WiDTH',zwidth)
      endif 

      write(6,*) "width",xsubpl,ysubpl,zwidth
c ----------------------------------------------------------------------
c 2.  General settings
c ----------------------------------------------------------------------
      CALL PSETC('GRAPH_SYMBOL','OFF')
      CALL PSETC('GRAPH_LINE_COLOUR','BLACK')
      CALL PSETC('GRAPH_LINE_STYLE','SOLID')
      CALL PSETi('GRAPH_LINE_THICKNESS',2)
      CALL PSETC('GRAPH_MISSING_DATA_MODE','IGNORE')
      CALL PSETC('LEGEND_ENTRY','ON')

c ----------------------------------------------------------------------
c 3.  Shade the bars
c ----------------------------------------------------------------------
      CALL PSETC('GRAPH_SHADE','ON')
      CALL PSETC('GRAPH_SHADE_STYLE','AREA_FILL')

c ----------------------------------------------------------------------
c 4.  Plot the bars or the ares plot
c ----------------------------------------------------------------------
      do 190 jbin=1,kbins

c 4.1   Transfer lower and upper  values into plotarray 

c       lowest treshold is always 0 
        if(jbin.eq.1) then 
          do jstep=1,ksteps
            yl(jstep) = 0 
            yu(jstep) = phisto(jstep,jbin) 
          enddo
        else
          do jstep=1,ksteps
            yl(jstep) = phisto(jstep,jbin-1) 
            yu(jstep) = phisto(jstep,jbin) 
          enddo
        endif
        zcheck=0
        do jstep=1,ksteps
          zcheck = zcheck + yu(jstep) - yl(jstep)
        enddo
        zcheck=1

c       only plot nonzero bars ( to limit the lsit of legends )
        if(zcheck.gt.0) then

        cbar = cbarcol(jbin)
        cleg = cbarleg(jbin)
        write(6,*) "steps",jbin,ksteps
        write(6,'(20f4.0)') (pxvals(jstep),jstep=1,ksteps)
        write(6,*) "upper bin",jbin
        write(6,'(20i4)') (IFIX(yu(jstep)),jstep=1,ksteps)
        write(6,*) "lower bin",jbin,ksteps
        write(6,'(20i4)') (IFIX(yl(jstep)),jstep=1,ksteps)

c 4.2   set the legend text and colours
        CALL PSETC('LEGEND_USER_TEXT',cleg)
        CALL PSETC('GRAPH_SHADE_COLOUR',cbar)

c      call MSUBPENQ
c      call MPAGENQ


c 4.3   Set the plotarrays 
        if(ktype.le.0) then
c         area plot
          CALL PSET1R('GRAPH_CURVE_X_VALUES',pxvals,ksteps)
          CALL PSET1R('GRAPH_CURVE_Y_VALUES',YL,ksteps)
          CALL PSET1R('GRAPH_CURVE2_X_VALUES',pxvals,ksteps)
          CALL PSET1R('GRAPH_CURVE2_Y_VALUES',YU,ksteps)
        else
c         bar plot 
          CALL PSETC('GRAPH_BAR_COLOUR',cbar)
          CALL PSETC('GRAPH_BLANKING','OFF')
          CALL PSET1R('GRAPH_BAR_X_VALUES',pxvals,ksteps)
          CALL PSET1R('GRAPH_BAR_Y_UPPER_VALUES',YU,ksteps)
          CALL PSET1R('GRAPH_BAR_Y_LOWER_VALUES',YL,ksteps)
        endif

c 4.4   Plot
        CALL PGRAPH

        endif

190   continue



      return
      end




      subroutine MZEROPL(kday1,kday2,pval)
c ----------------------------------------------------------------------
c  Draw horizontal (zero) line, from day1 to day2
c ----------------------------------------------------------------------
      dimension zx(2),zy(2)

c 1.  fill array values
      zx(1) = kday1 
      zx(2) = kday2 
      zy(1) = pval 
      zy(2) = pval 

c 2.  Draw horizontal line
      CALL PSETC('LEGEND_ENTRY','OFF')
      CALL PSETC('GRAPH_LINE','ON')
      CALL PSET1R('GRAPH_CURVE_X_VALUES',zx,2)
      CALL PSET1R('GRAPH_CURVE_Y_VALUES',zy,2)
      CALL PSETC('GRAPH_LINE_STYLE','SOLID')
      CALL PSETI('GRAPH_LINE_THICKNESS',10)
      CALL PSETC('GRAPH_LINE_COLOUR','BLACK')
      CALL PSETC('GRAPH_SYMBOL','OFF')
      CALL PGRAPH

      return
      end


      subroutine MGRIDPL(kday1,kday2,pymin,pymax,kpar)
c ----------------------------------------------------------------------
c  Draw horizontal reference line, for certain critical values  
c  From day1 to day2, if values are between pymin and pymax
c ----------------------------------------------------------------------
      dimension zx(2),zy(2),vals(20)
      character*20 ccol,cstyle 
      Logical Lgrid

      ivalspecial=999
      Lgrid=.false.

c 1.  Set values of horizontal gridlines 
  
c     wind surge ( -200, -150, -100,.....50, 100, 150, 200 ) ) 
      if(kpar.eq.270) then
        nilvals = 9
        do ival=1,nilvals
          vals(ival) = -200 + 50*REAL(ival-1)
        enddo
        ivalspecial=8
        Lgrid=.true.
      endif

c     Wind speed  ( Bft)
      if(kpar.eq.265.or.kpar.eq.165) then
        vals(1) = 10.8
        vals(2) = 13.9 
        vals(3) = 17.2
        vals(4) = 20.8
        vals(5) = 24.5
        vals(6) = 28.5
        vals(7) = 32.6 
        nilvals = 7
c       purple at 9 Bft
        ivalspecial=4
        Lgrid=.true.
      endif

c     Precip
      if(kpar.eq.142) then
        vals(1) = 15.0 
        vals(2) = 20.0 
        ivalspecial=2
        nilvals = 2
        Lgrid=.true.
      endif

c     Precip
      if(kpar.eq.144) then
        vals(1) = 5.0 
        ivalspecial=1
        nilvals = 1
        Lgrid=.true.
      endif

c     Gusts 
      if(kpar.eq.49) then
        vals(1) = 20.0 
        vals(2) = 25.0 
        vals(3) = 28.5
c       purple at 56 knots
        ivalspecial=3
        nilvals = 3
        Lgrid=.true.
      endif

c     Cape 
      if(kpar.eq.59) then
        vals(1) = 1.0 
        vals(2) = 2.0 
        ivalspecial=2
        nilvals = 2
        Lgrid=.true.
      endif

c     Wet Bulb globe potential temp 
      if(kpar.eq.271) then
        vals(1) = 27.0 
        vals(2) = 31.0 
        ivalspecial=2
        nilvals = 2
        Lgrid=.true.
      endif
      if(kpar.eq.272) then
        vals(1) = 26.6 
        vals(2) = 32.0
        ivalspecial=2
        nilvals = 2
        Lgrid=.true.
      endif
      if(kpar.eq.167) then
        vals(1) = 25.0 
        vals(2) = 30.0 
        ivalspecial=2
        nilvals = 2
        Lgrid=.true.
      endif


c     Watertemperature
      if(kpar.eq.991) then
        cALL PSETC('GRAPH_LINE','ON')
        vals(1) = 23.0 
        vals(2) = 25.0 
        vals(3) = 30.0 
        ivalspecial=3
        nilvals = 3
      endif


      if(Lgrid) then

c 2.    fill x-array values for plot 
        zx(1) = kday1 
        zx(2) = kday2 

        CALL PSETC('GRAPH_LINE','ON')
        CALL PSETC('LEGEND_ENTRY','OFF')
        CALL PSETC('GRAPH_SYMBOL','OFF')

c 3.    Plot the lines , first determine style etc.....
        do 190 ival=1,nilvals
        
          CALL PSETC('GRAPH_LINE_STYLE','DOT')
          CALL PSETI('GRAPH_LINE_THICKNESS',3)
          ccol="BLACK"
          if(ival.eq.ivalspecial) then
            ccol="MAGENTA"
            cstyle="DASH"
          else
            ccol="BLACK"
            cstyle="DOT"
          endif
          CALL PSETC('GRAPH_LINE_COLOUR',ccol)
          CALL PSETC('GRAPH_LINE_STYLE',cstyle)
c         Draw the positive line    
          if(vals(ival).gt.pymin.and.vals(ival).lt.pymax) then 
            zy(1) = vals(ival) 
            zy(2) = vals(ival) 
            CALL PSET1R('GRAPH_CURVE_X_VALUES',zx,2)
            CALL PSET1R('GRAPH_CURVE_Y_VALUES',zy,2)
            CALL PGRAPH
          endif

190     continue

      endif


      return
      end




c ----------------------------------------------------------------------
c ----------------------------------------------------------------------
c 6.   Text routines
c    mlegend
c    mtekst
c      mtitle
c        mdatefiddle
c      mrechts 
c        mstation
c        mparam
c      mlogo
c ----------------------------------------------------------------------
c ----------------------------------------------------------------------




      subroutine MLEGEND(psubpginfo,klarge,Lobs,Lgids,Lprob)
c ----------------------------------------------------------------------
C   LEGEND box, height, width and position etc. 
c   Depends on lengths and position of subpages and on size 
c  Input 
c   psubpginfo(4)    array with specs of subpagelengths etc
c   klarge           number of plots on an A4
c   Lprob            if true, probability plots have larger legend
c   Lobs             if true, larger legend for extra line
c  Output
c   none
c ----------------------------------------------------------------------
      dimension psubpginfo(4)
      Logical Lobs,Lgids,Lprob

      xsubpl = psubpginfo(1)
      ysubpl = psubpginfo(2)
      xsubp  = psubpginfo(3)
      ysubp  = psubpginfo(4)

c 1.  Positional means that you define the position 
      CALL PSETC('LEGEND','ON')

      CALL PSETC('LEGEND_BOX_MODE','POSITIONAL')

c 2.  Set width and height of legend box
      if(klarge.eq.1) then
        xlegl = 3.5
        ylegl = 1.7 
        if(Lobs.or.Lgids) ylegl = 2.4 
        if(Lprob) then
          ylegl = 1.0
          xlegl = 0.8* xsubpl
          xlegl = xsubpl
        endif 
      endif
      if(klarge.eq.2) then
        xlegl = 3.5
        ylegl = 1.5 
        if(Lobs.or.Lgids) ylegl = 2.0 
        if(Lprob) then
          ylegl = 0.8 
          xlegl = 0.8* xsubpl
        endif 
      endif 
      if(klarge.eq.3) then
        xlegl = 3.5
        ylegl = 1.5 
        if(Lobs.or.Lgids) ylegl = 2.0 
        if(Lprob) then
          ylegl = 0.6 
          xlegl = 0.8* xsubpl
        endif 
      endif
      if(klarge.eq.6) then
        xlegl = 2.4
        ylegl = 1.0  
        if(Lobs.or.Lgids) ylegl = 1.1 
        if(Lprob) then
          ylegl = 0.6 
          xlegl = 0.8* xsubpl
        endif 
      endif

c 3.  Set corner point of legend (top left)
      xlegp = xsubp + 0.1 
      ylegp = (ysubp+ysubpl) - ylegl
      if(klarge.eq.1) then 
        xlegp = xsubp + 0.2
      endif
      if(klarge.eq.3) then 
        xlegp = xsubp + 0.1
      endif
c 4.  Feed into Magics
      CALL PSETR('LEGEND_BOX_X_POSITION',xlegp)
      CALL PSETR('LEGEND_BOX_Y_POSITION',ylegp)
      CALL PSETR('LEGEND_BOX_X_LENGTH',xlegl)
      CALL PSETR('LEGEND_BOX_Y_LENGTH',ylegl)
      CALL PSETc('LEGEND_BOX_BLANKING','OFF')
 
      CALL PSETC('LEGEND_BORDER','OFF')
cc      CALL PSETC('LEGEND_BORDER','ON')
 
      CALL PSETC('LEGEND_TEXT_COMPOSITION','BOTH')
      if(Lprob) then 
        CALL PSETC('LEGEND_ENTRY_PLOT_DIRECTION','ROW')
        CALL PSETi('LEGEND_COLUMN_COUNT',6)
        if(klarge.eq.1) CALL PSETi('LEGEND_COLUMN_COUNT',8)
c        if(klarge.eq.1) CALL PSETR('LEGEND_ENTRY_MAXIMUM_WIDTH',2.5)
c        if(klarge.eq.6) CALL PSETR('LEGEND_ENTRY_MAXIMUM_WIDTH',2.0)
      else
        CALL PSETC('LEGEND_ENTRY_PLOT_DIRECTION','COLUMN')
        CALL PSETi('LEGEND_COLUMN_COUNT',1)
      endif

c     gap between legend texts 
      CALL PSETR('LEGEND_ENTRY_Y_GAP',0.1)
      if(klarge.eq.6) CALL PSETR('LEGEND_ENTRY_Y_GAP',0.03)
c     character heights 
      if(klarge.eq.1) rheight=0.4 
        if(klarge.eq.1) rheight=0.3 
      if(klarge.eq.2) rheight=0.3 
      if(klarge.eq.3) rheight=0.3 
      if(klarge.eq.6) rheight=0.2
      CALL PSETR('LEGEND_ENTRY_MAXIMUM_HEIGHT',rheight)
      CALL PSETR('LEGEND_TEXT_MAXIMUM_HEIGHT',rheight)

      CALL PSETC('LEGEND_TEXT_COLOUR','BLACK')
      CALL PSETC('LEGEND_TEXT_QUALITY','HIGH')

      RETURN
      END


      subroutine MTEKST(kpar,psubpginfo,kdate,kstation,cpar,keng,klarge)

c ----------------------------------------------------------------------
c         Text in plot ( title and box left and right ) 
c   kpar      : variable ( grib/mars convention, 991=water; 992 = ice )
c   psubpginfo : sarray with subpage length , position etc
c   kdate 
c   kstation
c   cpar             : text string containing name of parameter 
c ----------------------------------------------------------------------
      dimension psubpginfo(4)

c 1.  Title over plot
      call MTITLE(psubpginfo,kdate,keng,klarge,kstation)

c 2.  Text box at right corner ( top or bottom )
      call MRECHTS(psubpginfo,kstation,cpar,klarge)

c 3.  Text box at bottom right corner ( KNMI logo )
      call MKNMILOGO(psubpginfo,klarge)


      return
      end


      subroutine MTITLE(psubpginfo,kdate,keng,klarge,kstation)
c ----------------------------------------------------------------------
c Title over plot 
c   Input 
c     psubpginfo   array with info on subpage size
c     kstation     station code
c     cpar         text to be printed
c     klarge       size of plot 
c ----------------------------------------------------------------------
      dimension psubpginfo(4)
      CHARACTER*20 Cpar
      character*28 cdatet
      CHARACTER*4  cini

      xsubpl = psubpginfo(1)
      ysubpl = psubpginfo(2)
      xsubp  = psubpginfo(3)
      ysubp  = psubpginfo(4)

c 1.  Fiddle a bit to get the text of the date ( truncated ) 
      call MDATEFIDDLE(kdate,keng,cdatet,cini,ihh)

c 2.  Specification of date string 
      CALL PSETC('TEXT_CHARACTER_1',cdatet)
      CALL PSETC('TEXT_CHARACTER_2',cini)
      CALL PSETI('TEXT_INTEGER_1',ihh)
c 3.
      CALL PSETC('TEXT_MODE','POSITIONAL')

c 4.  Size of Text Box  
      xboxp = xsubp 
      yboxp = ysubp + ysubpl +0.2 
      if(klarge.eq.6) yboxp = ysubp + ysubpl +0.1 
      if(klarge.eq.3) yboxp = ysubp + ysubpl +0.1 
      if(klarge.eq.1) yboxp = ysubp + ysubpl +0.9 

      xboxpl = xsubpl  
cc      if(klarge.eq.1) yboxpl = 1.5
        if(klarge.eq.1) yboxpl = 1.1
      if(klarge.eq.2) yboxpl = 1.0
      if(klarge.eq.3) yboxpl = 0.75 
      if(klarge.eq.6) yboxpl = 0.5 
 
      CALL PSETR('TEXT_BOX_X_POSITION',xboxp)
      CALL PSETR('TEXT_BOX_Y_POSITION',yboxp)
      CALL PSETR('TEXT_BOX_X_LENGTH',xboxpl)
      CALL PSETR('TEXT_BOX_Y_LENGTH',yboxpl)

c 5.  Size of text characters
      if(klarge.eq.1) rheight=0.6
      if(klarge.eq.2) rheight=0.4
      if(klarge.eq.3) rheight=0.4
      if(klarge.eq.6) rheight=0.3
      CALL PSETR('TEXT_REFERENCE_CHARACTER_HEIGHT',rheight)

c 6.  Soem general specs
      CALL PSETC('TEXT_JUSTIFICATION','CENTRE')
      CALL PSETC('TEXT_COLOUR','BLACK')
      CALL PSETC('TEXT_QUALITY','HIGH')
      CALL PSETC('TEXT_BORDER','OFF')

c 7.  The lines
      CALL PSETI('TEXT_LINE_COUNT',1)
      if(keng.eq.0) then 
        CALL PSETC('TEXT_LINE_1','@TEXT_CHARACTER_1@'//
     +   '  (starttijd @TEXT_CHARACTER_2@ @(i2.2)text_INTEGER_1@ UTC)')
c        if(kstation.gt.10000) then
c          ihh2 = ihh + 8 
c          CALL PSETI('TEXT_INTEGER_1',ihh2)
c          CALL PSETC('TEXT_LINE_1','@TEXT_CHARACTER_1@'//
c     +   '  (starttijd @TEXT_CHARACTER_2@'//
c     +   '  @(i2.2)text_INTEGER_1@ lt China)')
c        endif
      else
        CALL PSETC('TEXT_LINE_1','@TEXT_CHARACTER_1@'//
     +  '  (start time @TEXT_CHARACTER_2@ @(i2.2)text_INTEGER_1@ UTC)')
      endif

c 8.  Do it
      call PTEXT

      return
      end

      subroutine MDATEFIDDLE(kdate,keng,cdatet,cini,ihh)
c ----------------------------------------------------------------------
c  Fiddle a bit to get the date of availability and the truncated
c  starting date.
c ----------------------------------------------------------------------
      character*35 cdate
      character*28 cdatet

      CHARACTER*28  cinidag
      CHARACTER*4  cini
      CHARACTER*3  cini2

c 1.  Create the date of availability ( in text format )
c     Note: now we assume  the 12 utc run is available the next day
      idfc = 12 
      call MDATFOR(kdate,idfc,idatef)
      call DTGTXT2(idatef,cdate,keng)

c 2.  truncate to cut off the time to get the day rather than the date
      cdatet=cdate

c 3.  Initial date
      call DTGTXT2(kdate,cinidag,keng)

c 4.  Truncate initial date to two (dutch) or three (english) letters
c     Note : there is a trailing blank
      if(keng.eq.1) cini  = cinidag
      if(keng.eq.0) then 
        cini2 = cinidag
        cini = cini2
      endif
c 5.  the time of the initial date
      ihh =  MOD(kdate,100)

      return
      end



      subroutine MRECHTS(psubpginfo,kstation,cpar,klarge)
c ----------------------------------------------------------------------
c     Tekst rechtsboven
c   Input 
c     psubpginfo   array with info on subpage size
c     kstation     station code
c     cpar         text to be printed
c     klarge       size of plot 
c ----------------------------------------------------------------------

      dimension psubpginfo(4)

      character*20 cpar,cstation

      xsubpl = psubpginfo(1)
      ysubpl = psubpginfo(2)
      xsubp  = psubpginfo(3)
      ysubp  = psubpginfo(4)

c 1.  Text mode position is explicitly specified
      CALL PSETC('TEXT_MODE','POSITIONAL')

c 2.  Make text string station name
      call MSTATION(kstation,cstation) 

c 3.  Size of text box 
      xboxpl = 4.0 
      yboxpl = 1.2 
      if(klarge.eq.1) then
        xboxpl = 6.0 
        yboxpl = 1.5 
      endif
      if(klarge.eq.2) then
        xboxpl = 4.0 
        yboxpl = 1.2
      endif 
      if(klarge.eq.3) then
        xboxpl = 3.5 
        yboxpl = 1.0
      endif 
      if(klarge.eq.6) then
        xboxpl = 2.7 
        yboxpl = 0.8 
      endif 
      xboxp = xsubp + xsubpl - xboxpl 
      yboxp = ysubp + ysubpl - yboxpl

      CALL PSETR('TEXT_BOX_X_POSITION',xboxp)
      CALL PSETR('TEXT_BOX_Y_POSITION',yboxp)
      CALL PSETR('TEXT_BOX_X_LENGTH',xboxpl)
      CALL PSETR('TEXT_BOX_Y_LENGTH',yboxpl)

c 4.  General Specs  
      CALL PSETC('TEXT_BOX_BLANKING','OFF')
      CALL PSETC('TEXT_COLOUR','BLACK')
      CALL PSETC('TEXT_JUSTIFICATION','CENTRE')
      CALL PSETC('TEXT_BORDER','OFF')

c 5.  Size of text
      if(klarge.eq.1) rheight=0.4
      if(klarge.eq.2) rheight=0.3
      if(klarge.eq.3) rheight=0.3
      if(klarge.eq.6) rheight=0.2
       if(klarge.eq.6) rheight=0.3
      CALL PSETR('TEXT_REFERENCE_CHARACTER_HEIGHT',rheight)

c 6.  The lines
      CALL PSETI('TEXT_LINE_COUNT',2)
      CALL PSETC('TEXT_LINE_1',cstation)
      CALL PSETC('TEXT_LINE_2',cpar)

c 7.  Do it
      call PTEXT

      return
      end



      subroutine MKNMILOGO(psubpginfo,klarge)
c ----------------------------------------------------------------------
c KNMI logo in bottom right corner   
c
c  Input 
c    psubpginfo    array with info on subpages 
c    klarge        size info: number of pages on a page
c ----------------------------------------------------------------------
      dimension psubpginfo(4)

      xsubpl = psubpginfo(1)
      ysubpl = psubpginfo(2)
      xsubp  = psubpginfo(3)
      ysubp  = psubpginfo(4)

c 1.  Text mode position is explicitly specified
      CALL PSETC('TEXT_MODE','POSITIONAL')

c 2.  Size of text box
      xboxpl = 3.0 
      yboxpl = 0.5

c 3.  Position is bottom right 
      xboxp = xsubp + xsubpl -1.3 
      if(klarge.eq.6) xboxp = xsubp + xsubpl -2.0 
      yboxp = 0.2 
      CALL PSETR('TEXT_BOX_X_POSITION',xboxp)
      CALL PSETR('TEXT_BOX_Y_POSITION',yboxp)
      CALL PSETR('TEXT_BOX_X_LENGTH',xboxpl)
      CALL PSETR('TEXT_BOX_Y_LENGTH',yboxpl)

c 4.  Size of characters
      CALL PSETR('TEXT_REFERENCE_CHARACTER_HEIGHT',0.20)

c 5.  Center of text box
      CALL PSETC('TEXT_JUSTIFICATION','CENTRE')

c 6.  General specs
      CALL PSETC('TEXT_COLOUR','BLUE')
      CALL PSETC('TEXT_BORDER','OFF')

c 7.  Text of logo
      CALL PSETI('TEXT_LINE_COUNT',1)
      CALL PSETC('TEXT_LINE_1','Bron: ECMWF/KNMI')
c      CALL PSETC('TEXT_LINE_1','Bron: PPI')

c 8.  Do it
      call PTEXT

      return
      end




      Subroutine MSTATION(kstation,cstation) 
      CHARACTER*20 cstation

      if(kstation.eq.6225) cstation='IJmuiden'
      if(kstation.eq.6235) cstation='De Kooy'
      if(kstation.eq.6240) cstation='Schiphol'
      if(kstation.eq.6252) cstation='K13, Noordzee'
      if(kstation.eq.6254) cstation='Meetpaal Noordwijk'
      if(kstation.eq.6260) cstation='De Bilt'
      if(kstation.eq.6268) cstation='Lelystad'
      if(kstation.eq.6270) cstation='Leeuwarden'
      if(kstation.eq.6280) cstation='Eelde'
      if(kstation.eq.6280) cstation='Leeuwarden'
      if(kstation.eq.6290) cstation='Twente'
      if(kstation.eq.6310) cstation='Vlissingen'
      if(kstation.eq.6330) cstation='Hoek van Holland'
      if(kstation.eq.6375) cstation='Volkel'
      if(kstation.eq.6380) cstation='Maastricht'

c     Olympisch
      if(kstation.eq.47101) cstation='Chuncheon'
      if(kstation.eq.54511) cstation='Beijing'
      if(kstation.eq.54005) cstation='Honk Kong'
      if(kstation.eq.54857) cstation='Qingdao'
      if(kstation.eq.54527) cstation='Tianjin'
      if(kstation.eq.58362) cstation='Shanghai'
      if(kstation.eq.54342) cstation='Shenyang'
      if(kstation.eq.54436) cstation='Qinghuangdao'


c     Eigen uitvindingen
      if(kstation.eq.6291) cstation='Zoommeer'
      if(kstation.eq.6293) cstation='Basel'
      if(kstation.eq.6294) cstation='Koblenz'
      if(kstation.eq.6295) cstation='Mannheim'
      if(kstation.eq.6296) cstation='Verdun'
      if(kstation.eq.6298) cstation='S-Suriname'
      if(kstation.eq.6299) cstation='N-Suriname'

      if(kstation.eq.6401) cstation='Vak 1'
      if(kstation.eq.6402) cstation='Vak 2'
      if(kstation.eq.6403) cstation='Vak 3'
      if(kstation.eq.6404) cstation='Vak 4'
      if(kstation.eq.6405) cstation='Vak 5'
      if(kstation.eq.6406) cstation='Vak 6'
      if(kstation.eq.6407) cstation='Vak 7'

      if(kstation.eq.6501) cstation='36.00/76.50 (CK2)'
      if(kstation.eq.6502) cstation='36.25/76.50 (NK2)'
      if(kstation.eq.6503) cstation='35.75/76.50 (ZK2)'
      if(kstation.eq.6504) cstation='36.00/76.00 (WK2)'
      if(kstation.eq.6505) cstation='36.00/77.00 (EK2)'

c opzet 
      if(kstation.eq.6520) cstation='Vlissingen'
      if(kstation.eq.6514) cstation='Hoek van Holland'
      if(kstation.eq.6314) cstation='OS-11'
      if(kstation.eq.6513) cstation='Harlingen'
      if(kstation.eq.6511) cstation='Delfzijl'
      if(kstation.eq.6512) cstation='Den Helder'
      if(kstation.eq.6522) cstation='IJmuiden'


      return
      end
     
 
      subroutine MPARAM(kdate,kpar,cpar,keng)
      CHARACTER*20 Cpar
     
      mm = MOD(kdate/10000,100)
 
      if(keng.eq.0) then 
        if(kpar.eq.49) cpar='Windstoten'
        if(kpar.eq.59) cpar='Cape/Onweer'
        if(kpar.eq.142) cpar='Neerslag/6 uur'
        if(kpar.eq.228) cpar='Accum Neerslag'
        if(kpar.eq.144) cpar='Sneeuwval/6 uur'
        if(kpar.eq.147) cpar='Verdamping'
        if(kpar.eq.157) cpar='Rel Vochtigheid'
        if(kpar.eq.182) cpar='E-P'
        if(kpar.eq.164) cpar='Bewolking'
        if(kpar.eq.165) cpar='10m wind'
        if(kpar.eq.265) cpar='10m wind'
        if(kpar.eq.167) cpar='T2m'
        if(kpar.eq.168) cpar='Td'
        if(kpar.eq.189) cpar='Z-schijnduur'
        if(kpar.eq.201) cpar='Tmax'
        if(kpar.eq.202) cpar='Tmin'
        if(kpar.eq.229) cpar='Sign Wave Hgt'
        if(kpar.eq.991) then 
         if(mm.ge.4.and.mm.le.10) then
           cpar='Water Temperatuur'
         else
           cpar='Water Temp/ijsdikte'
         endif
        endif
        if(kpar.eq.992) cpar='ijsdikte'
        if(kpar.eq.270) cpar='Windopzet'
        if(kpar.eq.271) cpar='WBGT'
        if(kpar.eq.272) cpar='Apparent Temp'
      endif
      if(keng.eq.1) then 
        if(kpar.eq.49) cpar='Gusts'
        if(kpar.eq.59) cpar='Cape'
        if(kpar.eq.142) cpar='Precipitation'
        if(kpar.eq.228) cpar='Accum Prec'
        if(kpar.eq.144) cpar='Snowfall/6 hrs'
        if(kpar.eq.182) cpar='Evaporation'
        if(kpar.eq.147) cpar='E-P'
        if(kpar.eq.157) cpar='Rel Humidity'
        if(kpar.eq.164) cpar='Cloud Cover'
        if(kpar.eq.165) cpar='10m wind'
        if(kpar.eq.265) cpar='10m wind'
        if(kpar.eq.166) cpar='10m v wind'
        if(kpar.eq.167) cpar='T2m' 
        if(kpar.eq.168) cpar='Td'
        if(kpar.eq.189) cpar='Sunshine duration'
        if(kpar.eq.201) cpar='Tmax'
        if(kpar.eq.202) cpar='Tmin'
        if(kpar.eq.229) cpar='Sign Wave Hgt'
        if(kpar.eq.991) cpar='T water'
        if(kpar.eq.992) cpar='ice thickness'
        if(kpar.eq.270) cpar='Wind surge'
        if(kpar.eq.271) cpar='WBGT'
        if(kpar.eq.272) cpar='App T'
      endif

      return
      end 


c23456789012345678901234567890123456789012345678901234567890123456789012

c ======================================================================
c ======================================================================
c the statistical part
c ======================================================================
c ======================================================================


c23456789012345678901234567890123456789012345678901234567890123456789012
      subroutine MSAMPLE(pluim,ks,km,phisto,kbins,pcrit,ktide) 
c ----------------------------------------------------------------------
c  Samples (in a specified interval) probabilities of wind surge 
c    kaccu        : selected interval ( hours )
c    kini         : initial forecast step for accumulation ( hours )
c    pluim(ks,km) : plume data array
c    ks           : number of time steps 
c    km           : number of members
c    ktype        : 1 or 2  , either simple sampling of extreme sampling 
c                 : + or -  either bars or contours 
c  Output
c    phisto(ks,kbins) : sampling histogram
c    kbins            : number of categories 
c    cbarleg(kbins)   : treshold values in text ( for plotting )
c
c Note that the number of categories (bins) is an output parameter, 
c set on the basis of the selected time interval
c 
c Sampling is within the interval for steps 0,1,2,3,..... kaccu - 1 
c   except for rainfall which starts at 1,2,3,....  kaccu 
c ----------------------------------------------------------------------
      IMPLICIT NONE

      INTEGER nloc
c     maximum number of intervals
      PARAMETER ( nloc = 10 )

c     Subroutine parameters
      REAL pluim(ks,km), phisto(ks,kbins)
      CHARACTER*12 cbarleg(nloc) 
      INTEGER kpar,ks,km,kbins,ktide

c     Local variables 
      INTEGER i,j,jx,jbin 
      INTEGER jstep,jm
      REAL zcr,zx,zhisto(40)
      LOGICAL laccum,lreorg
 
      REAL pcrit(10)

c 0.  Initialize histogram
      do jstep=1,ks
        do jbin=1,kbins
          phisto(jstep,jbin) = 999 
        enddo
      enddo


c 3.  Start the sampling and  fill histogram for every time step 

      do jstep=1,ks

        do jbin=1,kbins

c         Initialize local sampling array
          zhisto(jbin) = 0 

c         Set local threshold value
          zcr = pcrit(jbin) 

c         Sample by count in time interval, once is enough 
          if(ktide.ge.1) then
            do jm=1,km
              zx = pluim(jstep,jm)
              if(zx.ge.zcr.and.zx.lt.999) then 
                zhisto(jbin) = zhisto(jbin) + 1 
              endif
            enddo
          else 
            do jm=1,km
              zx = pluim(jstep,jm)
              if(zx.le.zcr.and.zx.lt.999) then 
                zhisto(jbin) = zhisto(jbin) + 1 
              endif
            enddo
          endif 

        enddo

c       Normalize and transfer
        do jbin=1,kbins 
          phisto(jstep,jbin) =  100*zhisto(jbin)/REAL(km) 
        enddo

      enddo



      return
      end

c23456789012345678901234567890123456789012345678901234567890123456789012


      subroutine MCRITS(kpar,kaccum,pxcrit,cbarleg,cbarcol,kbins,
     +           kstation,ktide) 
c ----------------------------------------------------------------------
c  Sets criterium for the tide levels 
c  For each station  a different set for high and low tide 
c
c  Input           
c    kstation      : station 
c    ktide         : high or low tide
c                     
c                        
c  Output
c    kbins               : number of categories (bins)
c    xcrit(kbins)        : sampling histogram
c    cbarleg(kbins)      : treshold values in text ( for plotting )
c
c Note that the number of categories (bins) is an output parameter, 

c This is a very ad hoc routine : every adjustment has to be checked

c ----------------------------------------------------------------------
      parameter (nstats=7)
      CHARACTER*12 cbarleg(10) ,cbarcol(10)
      INTEGER kbins,kstation,ktide
      REAL pxcrit(20)

      write(6,*) "begin crits:",kpar,kstation,ktide

      if(kpar.eq.270) then
        call MTRESHOPZET(pxcrit,cbarleg,cbarcol,kbins,
     +           kstation,ktide) 
      endif
      if(kpar.eq.142.or.kpar.eq.228) then
        call MTRESHPREC(kaccum,pxcrit,cbarleg,cbarcol,kbins)
      endif
      if(kpar.eq.265) then
        call MTRESHWIND(pxcrit,cbarleg,cbarcol,kbins)
      endif
      if(kpar.eq.49) then
        call MTRESHGUSTS(pxcrit,cbarleg,cbarcol,kbins)
      endif
      if(kpar.eq.59) then
        call MTRESHCAPE(pxcrit,cbarleg,cbarcol,kbins)
      endif


      return
      end

c23456789012345678901234567890123456789012345678901234567890123456789012
      subroutine MTRESHOPZET(pxcrit,cbarleg,cbarcol,kbins,
     +           kstation,ktide) 
c ----------------------------------------------------------------------
c  Sets criterium for the tide levels 
c  For each station  a different set for high and low tide 
c
c  Input           
c    kstation      : station 
c    ktide         : high or low tide
c                     
c                        
c  Output
c    kbins               : number of categories (bins)
c    xcrit(kbins)        : sampling histogram
c    cbarleg(kbins)      : treshold values in text ( for plotting )
c
c Note that the number of categories (bins) is an output parameter, 

c This is a very ad hoc routine : every adjustment has to be checked

c ----------------------------------------------------------------------
      parameter (nstats=7)
      CHARACTER*12 cbarleg(10) ,cbarcol(10)
      INTEGER kbins,kstation,ktide
      INTEGER ivlis(6),ihvh(6),idh(6)
      INTEGER ihrl(6),idfz(6),iijm(6),ios(6)
      REAL pxcrit(6)
      INTEGER icrit(6,nstats),istations(nstats)

c23456789012345678901234567890123456789012345678901234567890123456789012

c order is crucial !!!!
      data istations /6520,6314,6514,6522,6512,6513,6511/ 

c 1.  Get the tresholds and get  number of bins (kbins)
      call MOPZVALS(ivlis,ihvh,idh,ihrl,idfz,iijm,ios,kbins,ktide)

c 2.  set the criteria     order is crucial !!!!
      do j=1,kbins
        icrit(j,1) = ivlis(j)
        icrit(j,2) = ios(j)
        icrit(j,3) = ihvh(j)
        icrit(j,4) = iijm(j)
        icrit(j,5) = idh(j)
        icrit(j,6) = ihrl(j)
        icrit(j,7) = idfz(j)
      enddo

c 3.  Determine station number 
      do js=1,nstats
        if(istations(js).eq.kstation) then
          jstat = js
          goto 40
        endif
      enddo
40    continue

c     the criteria in reals (output)
      do j=1,kbins
        pxcrit(j) = icrit(j,jstat)
      enddo

c 5.  Create the text legends for plotting in BARPL (output)
      do i=1,kbins
        cbarleg(i) = "             " 
      enddo

      if(ktide.eq.1) then
        write(cbarleg(1),'("+",i3)') IFIX(pxcrit(1))
      else
        write(cbarleg(1),'(i4)') ibar
      endif

      do j=2,kbins
        ibar1 = pxcrit(j)
        ibar2 = pxcrit(j-1)
        if(ktide.eq.1) then
          write(cbarleg(j),'(i3,"-",i3)') ibar1,ibar2
        else
          write(cbarleg(j),'(i4,"a",i4)') ibar1,ibar2
        endif
      enddo

c 7.  Set Style and colours  for control and oper forecast
      cbarcol(1)='BLACK'
      cbarcol(2)='RED'
      cbarcol(3)='BLUE'
      cbarcol(4)='LAVENDER'
      cbarcol(5)='AVOCADO'
      cbarcol(6)='GREY'


      return
      end 

      subroutine MOPZVALS(ivlis,ihvh,idh,ihrl,idfz,iijm,ios,kbins,ktide)
c  define treshold values for wind surge
      INTEGER ivlis(6),ihvh(6),idh(6)
      INTEGER ihrl(6),idfz(6),iijm(6),ios(6)

      INTEGER ivlish(6),ihvhh(6),idhh(6)
      INTEGER ihrlh(6),idfzh(6),iijmh(6),iosh(6)

      INTEGER ivlisl(6),ihvhl(6),idhl(6)
      INTEGER ihrll(6),idfzl(6),iijml(6),iosl(6)

c      Vlissingen, os12, hoek v holl ijmuiden, den helder, harl, delfz
      data ivlisl/-300,-280,-260,-240,-220,-200/
      data iosl/-200,-180,-160,-140,-120,-100/
      data ihvhl/-200,-180,-160,-140,-120,-100/
      data iijml/-200,-180,-160,-140,-120,-100/
      data idhl/-200,-180,-160,-140,-120,-100/
      data ihrll/-250,-230,-210,-190,-170,-150/
      data idfzl/-300,-280,-260,-240,-220,-200/

c      Vlissingen, os12, hoek v holl ijmuiden, den helder, harl, delfz
      data ivlish/370,350,330,310,290,270/
      data iosh/350,330,310,290,275,210/
      data ihvhh/280,260,220,200,180,160/
      data iijmh/270,250,220,200,180,150/
      data idhh/260,225,190,170,150,100/
      data ihrlh/330,305,270,250,230,140/
      data idfzh/380,350,300,260,240,180/

      kbins=6

      if(ktide.eq.1) then

      do j=1,kbins
        ivlis(j) = ivlish(j)
        ios(j)   = iosh(j)
        ihvh (j) = ihvhh(j)
        iijm(j)  = iijmh(j)
        idh(j)   = idhh(j)
        ihrl(j)  = ihrlh(j)
        idfz(j)  = idfzh(j)
      enddo

      else

      do j=1,kbins
        ivlis(j) = ivlisl(j)
        ios(j)   = iosl(j)
        ihvh (j) = ihvhl(j)
        iijm(j)  = iijml(j)
        idh(j)   = idhl(j)
        ihrl(j)  = ihrll(j)
        idfz(j)  = idfzl(j)
      enddo

      endif

      return
      end










c23456789012345678901234567890123456789012345678901234567890123456789012


      subroutine TSF2MARS(ktsfpar,kpar)
c ----------------------------------------------------------------
c   converts from tsf parameter to mars parameter
c   TSF parameters generated by J.Hozee ( KNMI)
c ----------------------------------------------------------------
c     wind components u,v and speed and direction and gust
      if(ktsfpar.eq.11003) kpar=165
      if(ktsfpar.eq.11004) kpar=166
      if(ktsfpar.eq.11011) kpar=266
      if(ktsfpar.eq.11012) kpar=265
      if(ktsfpar.eq.11041) kpar=49
c     T2m, dewpoint, Tmax and Tmin
      if(ktsfpar.eq.12004) kpar=167
      if(ktsfpar.eq.12006) kpar=168
      if(ktsfpar.eq.12199) kpar=201
      if(ktsfpar.eq.12200) kpar=202
c     Snowfall, rainfall
      if(ktsfpar.eq.13233) kpar=144
      if(ktsfpar.eq.13011) kpar=228
      if(ktsfpar.eq.13021) kpar=142


      if(ktsfpar.eq.13230) then 
        kpar=142
        write(6,*) "hallo"
      endif

c     Cape
      if(ktsfpar.eq.13241) kpar=59
c     Cloudcover 
      if(ktsfpar.eq.20010) kpar=186
c     pressure
      if(ktsfpar.eq.10051) kpar=151

      return
      end


      Subroutine MACCUM(px,paccum,ksteps,km)
c --------------------------------------------------------
c running accumulation over inerval of acchours
c for zoommeer? 
c --------------------------------------------------------
      dimension px(ksteps,km),paccum(ksteps,km)

      iacchours=24
      idelstep=6
c     accum time expressed in time steps
      jaccsteps=iacchours/idelstep
c     time step the accumulated fiels is assigned to
      jsx=jaccsteps/2 -1

c     initialize
      do jm=1,km
       do js=1,ksteps
         paccum(js,jm) = 0
       enddo
      enddo

c     accumulate
      do jm=1,km
       do js=1,ksteps-jaccsteps+1
         do jaccum=0,jaccsteps-1
           paccum(js+jsx,jm) = paccum(js+jsx,jm) + px(js+jaccum,jm)
         enddo
       enddo
      enddo

      do js=1,jsx
      do jm=1,km
         paccum(js,jm) = 999
      enddo
      enddo

      do js=ksteps-jsx,ksteps
      do jm=1,km
         paccum(js,jm) = 999
      enddo
      enddo

      return
      end

 
      Subroutine MACCUMX(px,paccum,ksteps,km)
c -------------------------------------------------------
c accumulate rainfall
c--------------------------------------------------------

      dimension px(ksteps,km),paccum(ksteps,km)

      do jm=1,km
       do js=1,ksteps
         paccum(js,jm) = 0
       enddo
      enddo

c     initialize first time step
      do jm=1,km
       paccum(1,jm) =  px(1,jm)
      enddo

c     accumulate
      do jm=1,km
       do js=2,ksteps
           paccum(js,jm) = paccum(js-1,jm) + px(js,jm)
       enddo
      enddo


      return
      end


      Subroutine MACCUMY(px,ksteps,km)
c -------------------------------------------------------
c accumulate rainfall and override old array px 
c--------------------------------------------------------
      dimension px(ksteps,km)

c     accumulate
      do jm=1,km
       do js=2,ksteps
           px(js,jm) = px(js-1,jm) + px(js,jm)
       enddo
      enddo

      return
      end

 
c     old stuff


      subroutine MLINEPL(kday1,kday2,pymax,kpar)
c -----------------------------------------------------
c  Draw horizontal reference line, for certain values  
c      itype = 1  solid 
c      itype = 2  dot
c      itype = 3  dash
c  ----------------------------------------------------
      dimension zx(2),zy(2)
      dimension vals(10),itype(10),ithick(10)
      character*20 ccol 

      cALL PSETC('GRAPH_LINE','OFF')
c     Set values of horizontal gridlines 
      if(kpar.eq.991) then
        cALL PSETC('GRAPH_LINE','ON')
        vals(1) = 23.0 
        vals(2) = 25.0 
        vals(3) = 30.0 
        nilvals = 3
        if(vals(3).gt.pymax) nilvals=2
        if(vals(2).gt.pymax) nilvals=1
        if(vals(1).gt.pymax) nilvals=0
        itype(1) = 2
        itype(2) = 2
        itype(3) = 3
        ithick(1) = 3
        ithick(2) = 3
        ithick(3) = 5
        if(nilvals.eq.3) ccol="MAGENTA"
      endif
      if(kpar.eq.49) then
        cALL PSETC('GRAPH_LINE','ON')
        vals(1) = 13.9 
        vals(2) = 20.8 
        vals(3) = 28.5
        nilvals = 3
        if(vals(2).gt.pymax) nilvals=1
        itype(1) = 2
        itype(2) = 2
        itype(3) = 3
        ithick(1) = 3
        ithick(2) = 3
        ithick(3) = 5
        if(nilvals.eq.3) ccol="MAGENTA"
      endif
      if(kpar.eq.265.or.kpar.eq.165) then
        cALL PSETC('GRAPH_LINE','ON')
        vals(1) = 10.8
        vals(2) = 13.9 
        vals(3) = 17.2
        vals(4) = 20.8
        vals(5) = 24.5
        vals(6) = 28.5
        vals(7) = 32.6 
        nilvals = 7
        if(vals(7).gt.pymax) nilvals=6
        if(vals(6).gt.pymax) nilvals=5
        if(vals(5).gt.pymax) nilvals=4
        if(vals(4).gt.pymax) nilvals=3
        do j=1,5
          itype(j) = 2
          ithick(j) = 3
        enddo
        itype(6) = 3
        ithick(6) = 5
        if(nilvals.eq.7) then 
          ccol = "MAGENTA"
        else
          ccol = "BLACK"
        endif
      endif
      if(kpar.eq.144) then
        cALL PSETC('GRAPH_LINE','ON')
        vals(1) = 5.0 
        nilvals = 1
        if(vals(1).gt.pymax) nilvals=0
        itype(1) = 2
        ithick(1) = 5
        if(nilvals.eq.1) ccol="MAGENTA"
      endif

c     fill x array values for plot 
      zx(1) = kday1 
      zx(2) = kday2 

c     plot the lines , first determine style etc.....
      do 190 il=1,nilvals
        
        zy(1) = vals(il) 
        zy(2) = vals(il) 
        ityp = itype(il)
        ithi = ithick(il)

c       set the magics  parameters
        cALL PSETC('LEGEND_ENTRY','OFF')
        if(ityp.eq.2) CALL PSETC('GRAPH_LINE_STYLE','DOT')
        if(ityp.eq.3) CALL PSETC('GRAPH_LINE_STYLE','DASH')
        cALL PSETI('GRAPH_LINE_THICKNESS',ithick)

        cALL PSETC('GRAPH_LINE_COLOUR','BLACK')
        if(il.eq.nilvals) then 
           cALL PSETC('GRAPH_LINE_COLOUR',ccol)
        endif
        cALL PSETC('GRAPH_SYMBOL','OFF')

c       draw horizontal line
        cALL PSET1R('GRAPH_CURVE_X_VALUES',zx,2)
        cALL PSET1R('GRAPH_CURVE_Y_VALUES',zy,2)

        cALL PGRAPH

190   continue


      return
      end







c23456789012345678901234567890123456789012345678901234567890123456789012
      subroutine MTRESHPREC(kaccum,pcrit,cbarleg,cbarcol,kbins) 
c ----------------------------------------------------------------------
c  defines rainfall criterium 
c  Input 
c    kaccum             : accumulation interval ( hours )
c  Output
c    kcat               : number of categories 
c    xcrit(kcat)        : sampling histogram
c    cbarleg(kcat)      : treshold values in text ( for plotting )
c
c Note that the number of categories (bins) is an output parameter, 
c set on the basis of the accumulation interval 
c ----------------------------------------------------------------------
      CHARACTER*12 cbarleg(10),cbarcol(10) 
      INTEGER kaccum,kbins
      REAL pcrit(10)

      do i=1,10
        cbarleg(i) = "             " 
      enddo

c 1.  Treshold values  
      if(kaccum.lt.24) then 
        pcrit(1) = 30
        pcrit(2) = 10
        pcrit(3) = 3
        pcrit(4) = 1
        pcrit(5) = 0.3 
        pcrit(6) = 0.01 
        kbins= 6
      endif 
      if(kaccum.ge.24) then 
        pcrit(1) = 60
        pcrit(2) = 30
        pcrit(3) = 10
        pcrit(4) = 5
        pcrit(5) = 0.3 
        kbins = 5
      endif 
      if(kaccum.ge.48) then 
        pcrit(1) = 80 
        pcrit(2) = 60 
        pcrit(3) = 40 
        pcrit(4) = 20 
        kbins = 4
      endif 
      if(kaccum.ge.120) then 
        pcrit(1) = 200 
        pcrit(2) = 150 
        pcrit(3) = 100 
        pcrit(4) = 50 
        pcrit(5) = 20 
        pcrit(6) = 1 
        kbins = 6
      endif 


c 3.  Create the text legends for plotting in BARPL
      j=1
      write(cbarleg(j),'("+",i2,"mm")') IFIX(pcrit(j)) 
      do j=2,kbins-2
        write(cbarleg(j),'(i2,"-",i2)') IFIX(pcrit(j)),IFIX(pcrit(j-1))
      enddo
      j=kbins-1
      write(cbarleg(j),'(f4.1,"-",i2)') pcrit(j),IFIX(pcrit(j-1))
      j=kbins
      write(cbarleg(j),'(f5.2,"-",f4.1)') pcrit(j),pcrit(j-1)

c 2.  Create the text legends for plotting in BARPL
      if(kaccum.gt.24) then
        j    = 1
        ibar = pcrit(j)
        if(ibar.lt.100) write(cbarleg(j),'("+",i2)') ibar
        if(ibar.ge.100) write(cbarleg(j),'("+",i3)') ibar
        do j=2,kbins-1
          ibar1 = pcrit(j)
          if(ibar1.lt.100) write(cbarleg(j),'(i2)') ibar1
          if(ibar1.ge.100) write(cbarleg(j),'(i3)') ibar1
        enddo
        j    = kbins
        bar1 = pcrit(j)
        ibar2 = pcrit(j-1)
        write(cbarleg(j),'(f3.1)') bar1
        if(kaccum.le.24) then
          j    = kbins-1
          bar1 = pcrit(j)
          ibar2 = pcrit(j-1)
          write(cbarleg(j),'(f3.1)') bar1
          j    = kbins
          bar1 = pcrit(j)
          bar2 = pcrit(j-1)
          write(cbarleg(j),'(f3.1)') bar1
        endif

      endif

      kpar = 142 
      call MBARCOLS(kpar,kaccum,cbarcol,kbins)


      return
      end 


      subroutine MTRESHCAPE(pcrit,cbarleg,cbarcol,kbins) 
c ----------------------------------------------------------------------
c  defines  gusts criterium 
c  Output
c    kcat               : number of categories 
c    xcrit(kcat)        : sampling histogram
c    cbarleg(kcat)      : treshold values in text ( for plotting )
c
c Note that the number of categories (bins) is an output parameter, 
c set on the basis of the accumulation interval 
c ----------------------------------------------------------------------
      CHARACTER*12 cbarleg(10),cbarcol(10) 
      INTEGER kbins
      REAL pcrit(10)

      do i=1,10
        cbarleg(i) = "             " 
      enddo

c 1.  Treshold values  
      kbins = 4
      pcrit(1) = 20 
      pcrit(2) = 10 
      pcrit(3) = 5 
      pcrit(4) = 2 

c 2.  Create the text legends for plotting in BARPL
      j=1
      write(cbarleg(j),'("+",i4)') IFIX(pcrit(j))*100 
      do j=2,kbins
        i1 = IFIX ( pcrit(j)*100) 
        i2 = IFIX ( pcrit(j-1)*100) 
        write(cbarleg(j),'(i4,"-",i4)') i1,i2 
      enddo

      kpar = 59 
      kaccum = 6
      call MBARCOLS(kpar,kaccum,cbarcol,kbins)


      return
      end 



      subroutine MTRESHWATER(xcrit,cbarleg,cbarcol,kcat) 
c ----------------------------------------------------------------------
c  defines  water criterium 
c  Output
c    kcat               : number of categories 
c    xcrit(kcat)        : sampling histogram
c    cbarleg(kcat)      : treshold values in text ( for plotting )
c
c Note that the number of categories (bins) is an output parameter, 
c set on the basis of the accumulation interval 
c ----------------------------------------------------------------------
      CHARACTER*12 cbarleg(10) ,cbarcol(10)
      INTEGER kcat
      REAL xcrit(10)

      do i=1,10
        cbarleg(i) = "             " 
      enddo

c 1.  Treshold values  
      kcat = 8
      do j=1,kcat
      xcrit(j) = 31.0 - j 
      enddo

c 2.  Create the text legends for plotting in BARPL
      do j=1,kcat
        write(cbarleg(j),'(I2)') IFIX(xcrit(j)) 
      enddo

      kpar = 991 
      kaccum = 6
      call MBARCOLS(kpar,kaccum,cbarcol,kbins)

      return
      end 


      subroutine MTRESHWIND(pcrit,cbarleg,cbarcol,kbins) 
c ----------------------------------------------------------------------
c  defines rainfall criterium 
c  Input 
c  Output
c    kbins              : number of categories 
c    xcrit(kbins)        : sampling histogram
c    cbarleg(kbins)      : treshold values in text ( for plotting )
c
c Note that the number of categories (bins) is an output parameter, 
c set on the basis of the accumulation interval 
c ----------------------------------------------------------------------
      CHARACTER*12 cbarcol(10),cbarleg(10) 
      INTEGER kbins
      REAL pcrit(10)
      CHARACTER*2 cleg(10) 

      INTEGER iwcrit(10)
      REAL wbft(10)

c     Set lower bound for wind, Force 11  is rare so not included
      DATA wbft /0.3,1.6,3.4,5.5,8.0,10.8,13.9,17.2,20.8,24.5/


c 1.  Treshold values  
      iwcrit(1) = 10 
      iwcrit(2) = 9 
      iwcrit(3) = 8 
      iwcrit(4) = 7 
      iwcrit(5) = 6 
      iwcrit(6) = 5 
      iwcrit(7) = 4 
      kbins = 7

c 2.  Find the treshold for each Bft 
      do j=1,kbins
        jj = iwcrit(j)
        pcrit(j) = wbft(jj) 
      enddo

c 2.  Create the text legends for plotting in BARPL
      j=1
      cbarleg(j) = " " 
      write(cbarleg(j),'(i2," Bft")') iwcrit(j)
      do j=2,kbins
        cbarleg(j) = " " 
        write(cbarleg(j),'(i2)') iwcrit(j)
      enddo

c 3.  Colours
      kpar = 265
      kaccum = 6
      call MBARCOLS(kpar,kaccum,cbarcol,kbins)

      return
      end 


      subroutine MTRESHGUSTS(pcrit,cbarleg,cbarcol,kbins) 
c ----------------------------------------------------------------------
c  defines  gusts criterium 
c  Output
c    kbins               : number of categories 
c    xcrit(kbins)        : sampling histogram
c    cbarleg(kbins)      : treshold values in text ( for plotting )
c
c Note that the number of categories (bins) is an output parameter, 
c set on the basis of the accumulation interval 
c ----------------------------------------------------------------------
      CHARACTER*12 cbarleg(10),cbarcol(10) 
      INTEGER kbins
      REAL pcrit(10)

      do i=1,10
        cbarleg(i) = "             " 
      enddo

c 1.  Set number Treshold values  
      kbins = 5

c 2.  Set Treshold values  
      pcrit(1) = 28.5 
      pcrit(2) = 25.0 
      pcrit(3) = 20.0 
      pcrit(4) = 15.0 
      pcrit(5) = 10.0 

c 3.  Create the text legends for plotting in BARPL
      write(cbarleg(1),'("+",f4.1,"m/s")') pcrit(1) 
      write(cbarleg(2),'(i2,"-",f4.1)') IFIX(pcrit(2)),pcrit(1)
      do j=3,kbins
        write(cbarleg(j),'(i2,"-",i2)') IFIX(pcrit(j)),IFIX(pcrit(j-1))
      enddo

c 4.  Set colours
      kpar = 49
      kaccum = 6
      call MBARCOLS(kpar,kaccum,cbarcol,kbins)


      return
      end

      subroutine MBARCOLS(kpar,kaccum,cbarcol,kbins)
c ----------------------------------------------------------------------
c     Set colours for barplots 
c     Note: number of colours should match with number of crits
c ----------------------------------------------------------------------
      CHARACTER*12 cbarcol(kbins) 
      INTEGER kpar,kbins

c     gusts
      if(kpar.eq.49) then
        cbarcol(1)='BLACK'
        cbarcol(2)='RED'
        cbarcol(3)='BLUE'
        cbarcol(4)='AVOCADO'
        cbarcol(5)='GREY'
      endif

c     Cape
      if(kpar.eq.59) then
        cbarcol(1)='BLACK'
        cbarcol(2)='RED'
        cbarcol(3)='AVOCADO'
        cbarcol(4)='GREY'
      endif

c     T2m
      if(kpar.eq.167) then
        cbarcol(1)='BLUE'
        cbarcol(2)='SKY'
        cbarcol(3)='GREY'
        cbarcol(4)='PEACH'
        cbarcol(5)='MAGENTA'
      endif

c     Precip ( distrib )
      if(kpar.eq.142.or.kpar.eq.143.or.kpar.eq.228) then
        cbarcol(1)='BLACK'
        cbarcol(2)='RED'
        cbarcol(3)='PEACH'
        cbarcol(4)='OLIVE'
        cbarcol(5)='AVOCADO'
        cbarcol(6)='GREY'
      endif

c     wind
      if(kpar.eq.265) then
        cbarcol(1)='BLACK'
        cbarcol(2)='RED'
        cbarcol(3)='BLUE'
        cbarcol(4)='LAVENDER'
        cbarcol(5)='CYAN'
        cbarcol(6)='AVOCADO'
        cbarcol(7)='GREY'
      endif

c     water temperature
      if(kpar.eq.991.or.kpar.eq.992) then
        cbarcol(1)='BLACK'
        cbarcol(2)='RED'
        cbarcol(3)='PEACH'
        cbarcol(4)='BLUE'
        cbarcol(5)='LAVENDER'
        cbarcol(6)='CYAN'
        cbarcol(7)='YELLOW'
        cbarcol(8)='ORANGE'
        cbarcol(9)='WHITE'
      endif

      return
      end

 
      subroutine MSUBPENQ
c     retrieve info on subpages, positions and sizes
      call penqr('SUBPAGE_X_LENGTH',xsubpl)
      call penqr('SUBPAGE_Y_LENGTH',ysubpl)
      call penqr('SUBPAGE_X_POSITION',xsubp)
      call penqr('SUBPAGE_Y_POSITION',ysubp)
c      write(6,*) "subpages", xsubp,ysubp,xsubpl,ysubpl

      return
      end

      subroutine MPAGENQ
c     retrieve info on subpages, positions and sizes
      call penqr('PAGE_X_LENGTH',xpagel)
      call penqr('PAGE_Y_LENGTH',ypagel)
      call penqr('PAGE_X_POSITION',xpagep)
      call penqr('PAGE_Y_POSITION',ypagep)
c      write(6,*) "pages", xpagep,ypagep,xpagel,ypagel


      return
      end
