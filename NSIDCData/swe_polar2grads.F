        program polar2grads
!
!       convert the NSIODC polar stereographic coordinate files
!       to Grads latlon files
!
        implicit none
#include "recfac.h"
        integer yrbeg,yrend,latmin,nmax
        parameter (yrbeg=1978,yrend=2020,latmin=45,nmax=40)
        integer i,j,ix,iy,isn,irec,nll(360,latmin:89),nx(-1:1),ny(-1:1)
        integer mo,yr,k,krec,n,yr1,mo1,x1(-1:1),y1(-1:1)
        integer xyll(nmax,2,360,latmin:89)
        real conxy(316,448),conll(360,latmin:89)
        real x,y,alat,alon,sgn,slat,e,re,e2
        character file*255,csn(-1:1),cval,infile*255,months(12)*3
        logical lexist,lwrite
        integer,external :: get_endian
!
        data nx /721,0,721/
        data ny /721,0,721/
        data x1 /3950,0,3850/
        data y1 /4350,0,5850/
        data csn /'s','?','n'/
        data months /'JAN','FEB','MAR','APR','MAY','JUN','JUL',
     +       'AUG','SEP','OCT','NOV','DEC'/
        lwrite = .false.
!
!       set up grid conversion arrays
!
        SLAT = 70.              ! Standard latitude for the SSM/I grids is 70 degrees.
        RE = 6378.273           ! Radius of the earth in kilometers.
        E2 = .006693883         ! Eccentricity squared
        E =  sqrt(E2)           ! Eccentricity of the Hughes ellipsoid        
!
        do isn=-1,+1,2              ! -1: south, +1: north
            yr1 = -1
            mo1 = -1
            nll = 0
            if (isn.eq.-1 ) then
                print *,'South Pole'
            elseif ( isn.eq.+1 ) then
                print *,'North Pole'
            else
                call abort
            endif
            sgn = isn
!
!           first determine which (small, 25km) polar grid boxes sit 
!           inside a large (1x1) lat-lon box
!
            print *,'set up interpolation'
            if ( .true. ) then
            do ix=1,nx(isn)
                do iy=1,ny(isn)
                    x = -x1(isn) + 25*(ix-0.5)
                    y =  y1(isn) - 25*(iy-0.5)
                    call mapxy(x,y,alat,alon,slat,sgn,e,re)
                    if ( lwrite ) print *,ix,iy,x,y,' => ',alon,alat
                    if ( isn.eq.-1 ) alat = -alat
                    i = 1 + int(alon)
                    if ( i.lt.1 ) i = i + 360
                    if ( i.gt.360 ) i = i - 360
                    j = int(alat)
                    if ( j.eq.90 ) j = 89
                    if ( j.lt.latmin ) cycle
                    nll(i,j) = nll(i,j) + 1
                    if ( nll(i,j).gt.nmax ) then
                        write(0,*) 'error: increase nmax'
                        call abort
                    end if
                    xyll(nll(i,j),1,i,j) = ix
                    xyll(nll(i,j),2,i,j) = iy
                    if ( lwrite ) print *,i,j,ix,iy,nll(i,j)
                end do          ! iy
            end do              ! ix
            end if
!
!           next fill out small (near pole) lat-lon boxes that were left out
!
            if ( .true. ) then
            do j=latmin,89
                do i=1,360
                    if ( nll(i,j).eq.0 ) then
                        alon = i - 0.5
                        alat = j + 0.5
                        call mapll(x,y,alat,alon,slat,sgn,e,re)
                        ix = nint((x+x1(isn))/25-0.5)
                        iy = nint((y1(isn)-y)/25-0.5)
                        if ( ix.lt.1 .or. ix.gt.nx(isn) ) cycle
                        if ( iy.lt.1 .or. iy.gt.ny(isn) ) cycle
                        nll(i,j) = 1
                        xyll(1,1,i,j) = ix
                        xyll(1,2,i,j) = iy
                    end if
                end do          ! i
            end do              ! j
            end if
!
!           read data
!
            if ( isn.eq.-1 ) then
                file='conc_s.ctl'
            elseif ( isn.eq.+1 ) then
                file='conc_n.ctl'
            else
                call abort
            endif
            open(2,file=file)
            file(index(file,'.ctl'):) = '.grd'
            open(1,file=file,access='direct',form='unformatted',
     +               recl=recfa4*360*(90-latmin))
            irec = 0
            do yr=yrbeg,yrend
                do mo=1,12
                    do k=50,1,-1
                        write(infile,'(a,i4,i2.2,a,i2.2,a,a,a)')
     +                       'nt_',yr,mo,'_n',k,'_v01_',csn(isn),'.bin'
                        inquire(file=infile,exist=lexist)
                        if ( lexist ) exit
                        write(infile,'(a,i4,i2.2,a,i2.2,a,a,a)')
     +                       'nt_',yr,mo,'_f',k,'_v01_',csn(isn),'.bin'
                        inquire(file=infile,exist=lexist)
                        if ( lexist ) exit
                        write(infile,'(a,i4,i2.2,a,i2.2,a,a,a)')
     +                       'nt_',yr,mo,'_f',k,'_pre_',csn(isn),'.bin'
                        inquire(file=infile,exist=lexist)
                        if ( lexist ) exit
                        write(infile,'(a,i4,i2.2,a,i2.2,a,a,a)')
     +                       'nt_',yr,mo,'_f',k,'_nrt_',csn(isn),'.bin'
                        inquire(file=infile,exist=lexist)
                        if ( lexist ) exit
                    end do
                    if ( .not.lexist ) cycle
                    if ( yr1.lt.0 ) then
                        yr1 = yr
                        mo1 = mo
                    end if
                    print *,'opening ',trim(infile)
                    open(3,file=infile,access='direct',recl=recfa4/4)
                    krec = 300
                    do iy=1,ny(isn)
                        do ix=1,nx(isn)
                            krec = krec + 1
                            read(3,rec=krec) cval
                            if ( ichar(cval).gt.250 ) then
                                conxy(ix,iy) = 3e33
                            else
                                conxy(ix,iy) = real(ichar(cval))/250
                            end if
                        end do  ! ix
                    end do      ! iy
                    close(3)
                    if ( lwrite ) then
                        do iy=1,ny(isn)
                            print '(500i1)',(int(10*conxy(ix,iy)),ix=1
     +                           ,min(200,nx(isn)))
                        end do  ! iy
                    end if
!
!                   interpolate
!
                    conll = 0
                    do j=latmin,89
                        do i=1,360
                            n = 0
                            do k=1,nll(i,j)
                                ix = xyll(k,1,i,j)
                                iy = xyll(k,2,i,j)
                                if ( lwrite .and. conxy(ix,iy).ne.0 ) 
     +                               print '(5i4,f6.2)',i,j,ix,iy,k
     +                               ,conxy(ix,iy)
                                if ( conxy(ix,iy).lt.1e33 ) then
                                    n = n + 1
                                    conll(i,j) = conll(i,j)
     +                                   + conxy(ix,iy)
                                end if
                            end do ! k
                            if ( n.gt.0 .and. n.ge.nll(i,j)/2 ) then
                                conll(i,j) = conll(i,j)/n
                            else
                                conll(i,j) = 3e33
                            endif
                        end do  ! i
                    end do      ! j
                    irec = irec + 1
                    if ( isn.eq.-1 ) then
                        write(1,rec=irec) ((conll(i,j),i=1,360),
     +                       j=89,latmin,-1)
                    else
                        write(1,rec=irec) ((conll(i,j),i=1,360),
     +                       j=latmin,89)
                    endif
                end do          ! mo
            end do              ! yr
 800        continue
            close(1)
            write(2,'(2a)') 'DSET ^',trim(file)
            write(2,'(a)') 'TITLE NSIDC sea ice concentrations'
            if ( get_endian().eq.-1 ) then
                write(2,'(a)') 'OPTIONS LITTLE_ENDIAN'
            elseif ( get_endian().eq.+1 ) then
                write(2,'(a)') 'OPTIONS BIG_ENDIAN'
            endif
            write(2,'(a)') 'UNDEF 3e33'
            if ( isn.eq.+1 ) then
                write(2,'(a)') 'XDEF 360 LINEAR -44.5 1'
                write(2,'(a,i2,a,f5.1,a)') 'YDEF ',90-latmin,' LINEAR '
     +               ,latmin+0.5,' 1'
            else
                write(2,'(a)') 'XDEF 360 LINEAR 0.5 1'
                write(2,'(a,i2,a,f5.1,a)') 'YDEF ',90-latmin,' LINEAR '
     +               ,-89.5,' 1'
            endif
            write(2,'(a)') 'ZDEF 1 LINEAR 0 1'
            write(2,'(a,i4,2a,i4,a)') 'TDEF ',irec,' LINEAR 15'
     +           ,months(mo1),yr1,' 1MO'
            write(2,'(a)') 'VARS 1'
            write(2,'(a)') 'ice 1 99 sea ice concetration [1]'
            write(2,'(a)') 'ENDVARS'
        end do                  ! isn
        end

      SUBROUTINE MAPLL (X,Y,XLAT,XLONG,SLAT,SGN,E,RE)
*  #[ mapll:
C$*****************************************************************************
C$                                                                            *
C$                                                                            *
C$    DESCRIPTION:                                                            *
C$                                                                            *
C$    This subroutine converts from geodetic latitude and longitude to Polar  *
C$    Stereographic (X,Y) coordinates for the polar regions.  The equations   *
C$    are from Snyder, J. P., 1982,  Map Projections Used by the U.S.         *
C$    Geological Survey, Geological Survey Bulletin 1532, U.S. Government     *
C$    Printing Office.  See JPL Technical Memorandum 3349-85-101 for further  *
C$    details.                                                                *
C$                                                                            *
C$                                                                            *
C$    ARGUMENTS:                                                              *
C$                                                                            *
C$    Variable    Type        I/O    Description                              *
C$                                                                            *
C$    ALAT       REAL*4        I     Geodetic Latitude (degrees, +90 to -90)  *
C$    ALONG      REAL*4        I     Geodetic Longitude (degrees, 0 to 360)   *
C$    X          REAL*4        O     Polar Stereographic X Coordinate (km)    *
C$    Y          REAL*4        O     Polar Stereographic Y Coordinate (km)    *
C$                                                                            *
C$                                                                            *
C$                  Written by C. S. Morris - April 29, 1985                  *
C$                  Revised by C. S. Morris - December 11, 1985               *
C$                                                                     	      *
C$                  Revised by V. J. Troisi - January 1990                    *
C$                  SGN - provides hemisphere dependency (+/- 1)              *
C$		    Revised by Xiaoming Li - October 1996                     *
C$		    Corrected equation for RHO                                *
C$*****************************************************************************
      REAL*4 X,Y,XLAT,XLONG,E,E2,CDR,PI,SLAT,MC
C$*****************************************************************************
C$                                                                            *
C$    DEFINITION OF CONSTANTS:                                                *
C$                                                                            *
C$    Conversion constant from degrees to radians = 57.29577951.              *
      CDR=57.29577951
      E2=E*E
C$    Pi=3.141592654.                                                         *
      PI=3.141592654
C$                                                                            *
C$*****************************************************************************
C     Compute X and Y in grid coordinates.
        alat = xlat*pi/180
        along = xlong*pi/180
      IF (ABS(ALAT).LT.PI/2.) GOTO 250
      X=0.0
      Y=0.0
      GOTO 999
  250 CONTINUE
      T=TAN(PI/4.-ALAT/2.)/((1.-E*SIN(ALAT))/(1.+E*SIN(ALAT)))**(E/2.)
      IF (ABS(90.-SLAT).LT.1.E-5) THEN
      RHO=2.*RE*T/((1.+E)**(1.+E)*(1.-E)**(1.-E))**(1/2.)
      ELSE
      SL=SLAT*PI/180.
      TC=TAN(PI/4.-SL/2.)/((1.-E*SIN(SL))/(1.+E*SIN(SL)))**(E/2.)
      MC=COS(SL)/SQRT(1.0-E2*(SIN(SL)**2))
      RHO=RE*MC*T/TC
      END IF
      Y=-RHO*SGN*COS(SGN*ALONG)
      X= RHO*SGN*SIN(SGN*ALONG)
  999 CONTINUE
      END
*  #] mapll:
      SUBROUTINE MAPXY (X,Y,ALAT,ALONG,SLAT,SGN,E,RE)
*  #[ mapxy:
C$*****************************************************************************
C$                                                                            *
C$                                                                            *
C$    DESCRIPTION:                                                            *
C$                                                                            *
C$    This subroutine converts from Polar Stereographic (X,Y) coordinates     *
C$    to geodetic latitude and longitude for the polar regions. The equations *
C$    are from Snyder, J. P., 1982,  Map Projections Used by the U.S.         *
C$    Geological Survey, Geological Survey Bulletin 1532, U.S. Government     *
C$    Printing Office.  See JPL Technical Memorandum 3349-85-101 for further  *
C$    details.                                                                *
C$                                                                            *
C$                                                                            *
C$    ARGUMENTS:                                                              *
C$                                                                            *
C$    Variable    Type        I/O    Description                              *
C$                                                                            *
C$    X          REAL*4        I     Polar Stereographic X Coordinate (km)    *
C$    Y          REAL*4        I     Polar Stereographic Y Coordinate (km)    *
C$    ALAT       REAL*4        O     Geodetic Latitude (degrees, +90 to -90)  *
C$    ALONG      REAL*4        O     Geodetic Longitude (degrees, 0 to 360)   *
C$                                                                            *
C$                                                                            *
C$                  Written by C. S. Morris - April 29, 1985                  *
C$                  Revised by C. S. Morris - December 11, 1985               *
C$                                                                            *
C$                  Revised by V. J. Troisi - January 1990
C$                  SGN - provide hemisphere dependency (+/- 1)
C$
C$*****************************************************************************
      REAL*4 X,Y,ALAT,ALONG,E,E2,CDR,PI
C$*****************************************************************************
C$                                                                            *
C$    DEFINITION OF CONSTANTS:                                                *
C$                                                                            *
C$    Conversion constant from degrees to radians = 57.29577951.              *
      CDR=57.29577951
      E2=E*E
C$    Pi=3.141592654.                                                         *
      PI=3.141592654
C$                                                                            *
C$*****************************************************************************
      SL = SLAT*PI/180.
  200 RHO=SQRT(X**2+Y**2)
      IF (RHO.GT.0.1) GOTO 250
      ALAT=90.*SGN
      ALONG=0.0
      GOTO 999
  250 CM=COS(SL)/SQRT(1.0-E2*(SIN(SL)**2))
      T=TAN((PI/4.0)-(SL/(2.0)))/((1.0-E*SIN(SL))/
     C(1.0+E*SIN(SL)))**(E/2.0)
      IF (ABS(SLAT-90.).LT.1.E-5) THEN
      T=RHO*SQRT((1.+E)**(1.+E)*(1.-E)**(1.-E))/2./RE
      ELSE
      T=RHO*T/(RE*CM)
      END IF
      CHI=(PI/2.0)-2.0*ATAN(T)
      ALAT=CHI+((E2/2.0)+(5.0*E2**2.0/24.0)+(E2**3.0/12.0))*SIN(2*CHI)+
     C((7.0*E2**2.0/48.0)+(29.0*E2**3/240.0))*SIN(4.0*CHI)+
     C(7.0*E2**3.0/120.0)*SIN(6.0*CHI)
      ALAT=SGN*ALAT
      ALONG=ATAN2(SGN*X,-SGN*Y)
      ALONG=SGN*ALONG
        along = along*180/pi
        alat = alat*180/pi
  999 CONTINUE
      END
C
C
*  #] mapxy:
        integer function get_endian()
*
*       try to figure out whether I/O is big-endian or little-endian
*
        implicit none
        integer endian,grib,birg,iu
        integer*4 i
        save endian
        data endian /0/
        data grib,birg /1196575042,1112101447/

        if ( endian.eq.0 ) then
            call rsunit(iu)
            open(iu,file='/tmp/get_endian',form='unformatted')
            write(iu) 'GRIB'
            rewind(iu)
            read(iu) i
            close(iu,status='delete')
            if ( i.eq.grib ) then
                endian = +1
            elseif ( i.eq.birg ) then
                endian = -1
            endif
        endif
        get_endian = endian
        end
*  #[ rsunit:
	subroutine rsunit(irsunit)
*
*       find a free unit number below 100
*
	implicit none
	integer irsunit
	logical lopen
	do irsunit=99,10,-1
	    inquire(irsunit,opened=lopen)
	    if ( .not.lopen ) goto 20
	enddo
	print '(a)','rsunit: error: no free units under 100!'
	call abort
   20	continue
*  #] rsunit:
	end
