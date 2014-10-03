      program read_inv

      character name*30,grveg*16,pop*1,topo*2,stveg*2
      character stloc*2,airstn*1

c     ic=3 digit country code; the first digit represents WMO region/continent
c     iwmo=5 digit WMO station number
c     imod=3 digit modifier; 000 means the station is probably the WMO
c          station; 001, etc. mean the station is near that WMO station
c     name=30 character station name
c     rlat=latitude in degrees.hundredths of degrees, negative = South of Eq.
c     rlong=longitude in degrees.hundredths of degrees, - = West
c     ielevs=station elevation in meters, missing is -999
c     ielevg=station elevation interpolated from TerrainBase gridded data set
c     pop=1 character population assessment:  R = rural (not associated
c         with a town of >10,000 population), S = associated with a small
c         town (10,000-50,000), U = associated with an urban area (>50,000)
c     ipop=population of the small town or urban area (needs to be multiplied
c         by 1,000).  If rural, no analysis:  -9.
c     topo=general topography around the station:  FL flat; HI hilly,
c         MT mountain top; MV mountainous valley or at least not on the top
c         of a mountain.
c     stveg=general vegetation near the station based on Operational 
c         Navigation Charts;  MA marsh; FO forested; IC ice; DE desert;
c         CL clear or open;
c         not all stations have this information in which case: xx.
c     stloc=station location based on 3 specific criteria:  
c         Is the station on an island smaller than 100 km**2 or
c            narrower than 10 km in width at the point of the
c            station?  IS; 
c         Is the station is within 30 km from the coast?  CO;
c         Is the station is next to a large (> 25 km**2) lake?  LA;
c         A station may be all three but only labeled with one with
c             the priority IS, CO, then LA.  If none of the above: no.
c     iloc=if the station is CO, iloc is the distance in km to the coast.
c          If station is not coastal:  -9.
c     airstn=A if the station is at an airport; otherwise x
c     itowndis=the distance in km from the airport to its associated
c          small town or urban center (not relevant for rural airports
c          or non airport stations in which case: -9)
c     grveg=gridded vegetation for the 0.5x0.5 degree grid point closest
c          to the station from a gridded vegetation data base. 16 characters.
c     A more complete description of these metadata are available in
c          other documentation


      open(unit=1,file='v2.inv')

 100  continue
      read(1,102,end=200)ic,iwmo,imod,name,rlat,rlong,ielevs,ielevg,
     +pop,ipop,topo,stveg,stloc,iloc,airstn,itowndis,grveg

 102  format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4,
     +1x,i4,a1,i5,3(a2),i2,a1,i2,a16)

      go to 100
 200  continue
      write(*,*)'done'
      end








