        program add_pluim
!
!       add the mean EPS values top the standard series from the
!       climatological service
!
        implicit none
        integer yrbeg,yrend,npermax,ksteps,km
        parameter(yrbeg=1900,yrend=2030,npermax=366,ksteps=60,km=52)
        integer hr,dy,mo,yr,i,j,nperyear,ibeg,kpar,kstat,kdate,n,im
     +       ,dpm(12),jul0,jul1,yr1,mo1,dy1,icut
        real data(npermax,yrbeg:yrend),px(ksteps,km),eps(km,ksteps/4),
     +       stat(ksteps/4,-3:4)
        real plat,plon,s,s1,s2,pi,pcut(-3:4)
        character datfile*255,epsfile*255,var*80,units*80,var1*2,
     +       outfile*255,line*80
        logical lwrite,lstandardunits
        integer iargc
        integer,external :: julday
        data dpm/ 31,29,31,30,31,30,31,31,30,31,30,31/
        data pcut /5.,10.,25.,50.,75.,90.,95.,50./

        pi = 4*atan(1.)
        lwrite = .false.
        lstandardunits = .false.
        if ( iargc().lt.2 ) then
            write(0,*) 'usage: add_pluim series.dat epsfile [perc]'
            call abort
        end if
!
!       read climatological data
!
        call getarg(1,datfile)
        ibeg = index(datfile,'/',.true.)
        var1 = datfile(ibeg+1:ibeg+2)
        call readseries(datfile,data,npermax,yrbeg,yrend,nperyear,
     +       var,units,lstandardunits,lwrite)
!
!       translate variable to EPS kpar
!
        if ( var1.ne.var ) then
            write(0,*) 'error: file name inconsistent with variable'
            write(0,*) trim(datfile),ibeg+1,ibeg+2
            write(0,*) var1
            write(0,*) var
            call abort
        end if
        call var2tsf(var1,kpar)
        if ( kpar.eq.-999 ) then
            write(0,*) 'error: cannot translate ',trim(var1),' to msf'
            call abort
        end if
!
!       get station number
!
        read(datfile(ibeg+3:ibeg+5),'(i3.3)') kstat
        kstat = kstat + 6000
!
!       read ensemble prediction system data
!
        call getarg(2,epsfile)
        open(1,file=epsfile,status='old')
        call pluimlees(1,kpar,px,ksteps,km,kdate,kstat,plat,plon,lwrite)
        close(1)
!
!	read optional percentile
!
	call getarg(3,line)
	if ( line.ne.' ' ) then
	    read(line,*,err=901) pcut(4)
	    if ( pcut(4).ge.0 .and. pcut(4).le.100 ) goto 902
901	    write(0,*) 'addpluim: error: expected percentage, found ',
     +		pcut(4),' in ',trim(line)
     	    call abort
902         continue
	end if
!
!       compute daily variables
!
        do im=1,km
            do i=1,ksteps/4
                if ( var1.eq.'rhacc' ) then
!                   accumulated flux :-(
                    if ( i.eq.1 ) then
                        eps(im,i) = px(4*i,im)
                    else
                        eps(im,i) = px(4*i,im) - px(4*(i-1),im)
                    end if
                else if ( var1.eq.'tg' .or. var1.eq.'fg' .or.
     +                   var1.eq.'rh' ) then
                    s = 0
                    n = 0
                    do j=1,4
                        if ( px(j+4*(i-1),im).lt.1e33 ) then
                            n = n + 1
                            s = s + px(j+4*(i-1),im)
                        end if
                    end do
                    if ( n.ne.4 ) then
                        eps(im,i) = 3e33
                    else
                        if ( var1.eq.'rh' ) then
                            eps(im,1) = s
                        else
                            eps(im,i) = s/n
                        end if
                    end if
                else if ( var1.eq.'fx' .or. var1.eq.'tx' ) then
                    s = -3e33
                    n = 0
                    do j=1,4
                        if ( px(j+4*(i-1),im).lt.1e33 ) then
                            n = n + 1
                            s = max(s,px(j+4*(i-1),im))
                        end if
                    end do
                    if ( n.ne.4 ) then
                        eps(im,i) = 3e33
                    else
                        eps(im,i) = s
                    end if
                else if ( var1.eq.'tn' ) then
                    s = +3e33
                    n = 0
                    do j=1,4
                        if ( px(j+4*(i-1),im).lt.1e33 ) then
                            n = n + 1
                            s = min(s,px(j+4*(i-1),im))
                        end if
                    end do
                    if ( n.ne.4 ) then
                        eps(im,i) = 3e33
                    else
                        eps(im,i) = s
                    end if
                else if ( var1.eq.'dd' ) then
                    s1 = 0
                    s2 = 0
                    n = 0
                    do j=1,4
                        if ( px(j+4*(i-1),im).lt.1e33 ) then
                            n = n + 1
                            s1 = s1 + cos(pi/180*px(j+4*(i-1),im))
                            s2 = s2 + sin(pi/180*px(j+4*(i-1),im))
                        end if
                    end do
                    if ( n.ne.4 ) then
                        eps(im,i) = 3e33
                    else
                        eps(im,i) = 180/pi*atan2(s2,s1)
                        if ( eps(im,i).lt.0 ) then
                            eps(im,i) = eps(im,i) + 360
                        end if
                    end if
                else
                    write(0,*) 'add_pluim: error: unknown var1 '
     +                   ,trim(var1)
                    call abort
                end if
            end do
        end do                  ! i
        if ( lwrite ) then
            print *,'Full ensemble'
            do im=1,km
                print *,im,(eps(im,i),i=1,15)
            end do
        end if
!
!       compute ensemble statistics
!
        if ( var.eq.'dd' ) then
            write(0,*) 'error: cannot handle wind direction yet'
            call abort
        end if
        do i=1,ksteps/4
!           skip the operational forecast
            call nrsort(km-1,eps(2,i))
            if ( .false. .and. lwrite ) then
                print *,'Day ',i
                do im=2,km
                    print *,eps(im,i)
                end do
            end if
            do j=-3,4
                call getcut1(stat(i,j),pcut(j),km-1,eps(2,i),lwrite)
            end do
        end do                  ! i
!
!       write out
!
        yr = kdate/1000000
        mo = mod(kdate/10000,100)
        dy = mod(kdate/100,100)
        hr = mod(kdate,100)
        jul0 = julday(mo,dy,yr)
        if ( hr.ne.0 ) then
            write(0,*) 'add_pluim: error: can only handle 00 runs'
            call abort
        end if
        write(outfile,'(a,i3.3,a,i10.10,a)') var1,mod(kstat,1000),'_'
     +       ,kdate,'_pluim.txt'
        open(1,file=outfile)
        write(1,'(a,i6,2f9.3)') '# station ',kstat,plon,plat
        write(1,'(5a,i6)') '# variable ',var1,' [',trim(units),'] ',kpar
        write(1,'(a)') '# date 5% 10% 25% 50% 75% 90% 95%'
        do i=1,ksteps/4
            jul1 = jul0 + i - 1
            call caldat(jul1,mo1,dy1,yr1)
            write(1,'(i4.4,2i2.2,8f10.1)')
     +           yr1,mo1,dy1,(stat(i,j),j=-3,3)
            if ( lwrite ) print *, yr1,mo1,dy1,(stat(i,j),j=-3,4)
        end do
        close(1)
!
!       copy at the end of observations
!
        do i=1,ksteps/4
            jul1 = jul0 + i - 1
            call caldat(jul1,mo1,dy1,yr1)
            do j=1,mo1-1
                dy1 = dy1 + dpm(j)
            end do
            if ( data(dy1,yr1).lt.1e33 ) then
                write(0,*) 'warning: already have obs ',yr1,dy1,
     +               data(dy1,yr1)
            else
                data(dy1,yr1) = stat(i,4)
            end if
        end do
        call copyheader(datfile,6)
        print '(a,f4.2,a,i10,a)','# added the ',pcut(4)
     +   	,'th percentile of the EPS ensemble ',kdate
     +       	,' for the next days'
        call printdatfile(6,data,npermax,nperyear,yrbeg,yrend)
!
        end

        SUBROUTINE PLUIMLEES(ku,kparx,px,ksteps,km,kdate,kstat,plat,plon
     +       ,lwrite)
c ----------------------------------------------------------------------
c     Reads opzet datafiles  created by opzet.f
c     Can be used for  all plume files, buth check fileformat
!     version adapted bu GJvO for monthly forecasts.
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
        logical lwrite
c       local array  to read time steps per member
        integer ifield(ntijdmax)
        
        integer i,j,jread,ipar
        real scale
        
        if ( ksteps.gt.ntijdmax ) then
            write(0,*) "make ntijdmax larger in pluimlees"
            call abort
        end if

c       0.  Initialization

c       0.1 Initialize array
        px = 3e33

c       0.2 Asssume already at begin of file 
CCCC    REWIND(ku)
        
c       1.  Read info ( station and coords ) 
        read(ku,'(i5,2F7.2)') istat,plat,plon
        if ( lwrite ) write(6,'("pluimlees",2I6,2F7.2)') kstat,istat
     +       ,plat,plon
        if ( istat.ne.kstat ) then
            write(*,*) 'pluimlees: error: istat != kstat: ',istat,kstat
            call abort
        end if
        
c       2.  Read , try 25 times to find the right parameter iparx
        if ( lwrite ) print *,'lloking for ',kparx
        do jread=1,25
c           2.1   Read info  ( parameter and date )
            read(ku,*,end=1000) ipar,kdate
            if ( lwrite ) write(*,*) 'trying block ',ipar,kdate
            if ( ipar.ne.kparx ) then
!               skip block
                do im=1,km
                    read(ku,'(a)')
                end do
            else
c               Read 1 block with operational, control en 50 members
c               independent of number of members or timesteps 
                do im=1,km
                    read(ku,'(60i4)') (ifield(it),it=1,ksteps)
                    px(1:ksteps,im) = ifield(1:ksteps)
                end do
                goto 800        ! no use searching further
            end if 
        end do                  !jread
        goto 1000
 800    continue
c 2.3   If you have found the selected parameter/station, do rescale 
        call tsf2mars(kparx,ipar)
        call mscale(px,ksteps,km,ipar)
        if ( lwrite ) write(6,'("Read:",2I7,2X,i10)') itsfpar,ipar,kdate

        return
1000    continue
        write(6,'(1h ,"Ehhhh , niks gevonden , foutje ",2i4)') 
     +     kparx,ipar 
        call abort
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
            px(i,j) = 3e33
          endif
        enddo
      enddo


      return
      end 

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

        subroutine var2tsf(var,kpar)
!
!       translate my 2-char string to TSF kpar
!       based on TSF2MARS above from pluim_lib by Robert Mureau.
!       checked with the MARS web interface
!
        implicit none
        character var*2
        integer kpar

        kpar = -999
c       wind components u,v and speed and direction and gust
        if ( var.eq.'u' ) kpar=11003 ! 10 metre U wind component
        if ( var.eq.'v' ) kpar=11004 ! 10 metre V wind component
        if ( var.eq.'dd' ) kpar=11011 ! windrichting
        if ( var.eq.'fg' ) kpar=11012 ! windsnelheid
        if ( var.eq.'fx' ) kpar=11041 ! 10 metre wind gust
c       T2m, dewpoint, Tmax and Tmin
        if ( var.eq.'tg' ) kpar=12004 ! 2 metre temperature
        if ( var.eq.'tdew' ) kpar=12006 ! 2 metre dewpoint temperature
        if ( var.eq.'tx' ) kpar=12199 ! Maximum temperature at 2 metres since previous post-processing
        if ( var.eq.'tn' ) kpar=12200 ! Minimum temperature at 2 metres since previous post-processing
c       Snowfall, rainfall
        if ( var.eq.'snowfall' ) kpar=13233 ! snowfall
        if ( var.eq.'rhacc' ) kpar=13011 ! total precipitation accumulated
        if ( var.eq.'rh' ) kpar=13021 ! neerslag som laatste 6 uur
        if ( var.eq.'cape' ) kpar=13241 ! CAPE
c       Cloudcover 
        if ( var.eq.'ng' ) kpar=20010 ! cloud cover
c       pressure
        if ( var.eq.'pg' ) kpar=10051 ! Mean sea level pressure
        end
