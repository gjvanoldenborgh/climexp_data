      subroutine geotoradar(lat,lon,ri,rj)
      implicit   none
      real       lat,lon,ri,rj
c=======================================================================
c                                                                   
c     purpose   transform geographic coordinates (lat,lon) to
c               stereographic radarpixel coordinates (i,j) 
c                                                                
c     input     lat = geographic latitude [ degrees ]
c               lon = geographic longitude [ degrees ]
c                                                                 
c     output    ri = i-coordinate radar pixels (kolom nummer)
c               rj = j-coordinate radar pixels (rij nummer)
c                                                                
c     methode   Wessels H.R.A (1990). Coordinate conversions for
c               presenting weather radar data. TR-129
c               Iwan Holleman, Projectie van 1-km radarbeelden
c                                                               
c     KNMI 08/05/1996                                          
c     R.M.van Westrhenen              update 15/11/2006
c=======================================================================
      integer   k                   ! loop variabelen
*
      real      re,                 ! equator-as in km (Hayford)     
     +          rp,                 ! pool-as in km (Hayford)     
     +          e,                  ! excentriciteit (Hayford)
     +          b,                  ! latitude in radialen
     +          i0,                 ! offset pixel count (oud =  40.0)
     +          j0,                 ! offset pixel count (oud = 260.0)
     +          p,                  ! pixel size in km at 60N
     +          pi,                 ! constante pi
     +          r,                  !
     +          rlon,               ! longitude in radialen
     +          rlon0,              ! reference longitude
     +          r60,                ! map scale 60 N breedte
     +          rb,                 ! distance
     +          sb,                 ! map scale       
     +          s60,                ! map scale 60 N breedte
     +          x,                  !
     +          y
c
      parameter(re=6378.137, rp=6356.752, e=0.0818187)
      parameter(i0=0.0, j0=452.7411, p=0.999954, rlon0=0.)
c
c     distance of point with latitude b (deg)
c
      rb(b)=2*(re*re/rp)*tan((45-b/2)*pi/180)*
     +      ( ((1-e)*(1+e*sin(b*pi/180)))/
     +        ((1+e)*(1-e*sin(b*pi/180))) )**(e/2)
c
c     scale (km/rad) at latitude b in polar stereographic map
c
      sb(b)=rb(b)*sqrt(1-(e*sin(b*pi/180))**2)/(re*cos(b*pi/180))
c
c     calculate pixel coordinates
c
      pi  = acos(-1.)
      s60 = sb(60.)
      r60 = rb(60.)
*
      rlon = lon*pi/180
      r    = rb(lat)/p/s60
      x    = r*sin(rlon-rlon0)
      y    = r*cos(rlon-rlon0)-r60/p/s60
      ri   = x-i0
      rj   = y-j0
c
      end
