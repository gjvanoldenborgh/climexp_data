        program getstation
*
*       get stations near a given coordinate
*
        implicit none
        integer nn
        parameter(nn=100)
	double precision pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
        integer i,j,k,n,ldir,id
        integer ic(0:nn),iwmo(0:nn),imod(0:nn),ielevs(0:nn),ielevg(0:nn)
     +        ,ipop(0:nn),iloc(0:nn),itowndis(0:nn),iwmo1(0:999)
     +        ,iwmo2(0:999)
        real rlat(0:nn),rlon(0:nn),slat,slon,dist(0:nn),dlon
        character name(0:nn)*30,grveg(0:nn)*16,pop(0:nn)*1,topo(0:nn)*2
     +        ,stveg(0:nn)*2
        character stloc(0:nn)*2,airstn(0:nn)*1
        character*48 country(0:999)
        character string*80
        character dir*256
        integer iargc,llen
        external llen

c     ic=3 digit country code; the first digit represents WMO region/continent
c     iwmo=5 digit WMO station number
c     imod=3 digit modifier; 000 means the station is probably the WMO
c          station; 001, etc. mean the station is near that WMO station
c     name=30 character station name
c     rlat=latitude in degrees.hundredths of degrees, negative = South of Eq.
c     rlon=longitude in degrees.hundredths of degrees, - = West
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
c       other documentation
*        
        if ( iargc().lt.1 ) then
            print '(a)','usage: getstation lat lon [number]'
            print '(a)','       getstation id'
            stop
        endif
        if ( iargc().eq.1 ) then
            call getarg(1,string)
            read(string,*,err=904) id
            n = 1
        else
            id = 0
            call getarg(1,string)
            read(string,*,err=900) slat
            if ( slat.lt. -90 .or. slat.gt.90 ) goto 900
            call getarg(2,string)
            read(string,*,err=901) slon
            if ( slon.gt.180 ) slon = slon-180
            if ( slat.lt. -180 .or. slat.gt.180 ) goto 901
            if ( iargc().eq.3 ) then
                call getarg(3,string)
                read(string,*,err=903) n
                if ( n.gt.nn ) then
                    print '(a)','recompile with nn larger'
                    call abort
                endif
            else
                n = 10
            endif
            print '(a,i4,a)','Looking up ',n,' stations'
            do i=1,n
                dist(i) = 3e33
            enddo
        endif
*
*       read countrycode from file
        do j=0,999
            country(j) = ' '
        enddo
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = llen(dir)
            dir(ldir+1:) = '/NCDCData/'
        else
            dir = '/usr/people/oldenbor/NINO/NCDCData/'
        endif
        ldir = llen(dir)
        open(1,file=dir(1:ldir)//'country.codes',status='old')
   20   continue
        read(1,'(a)',end=30) string
        if ( string.eq.' ' ) goto 30
        read(string,'(i5,1x,i5,1x,i3)',err=902) i,j,k
        iwmo1(k) = i
        iwmo2(k) = j
        country(k) = string(18:)
        goto 20
   30   continue
*
        if ( id.eq.0 ) then
            print '(a,f7.2,a,f7.2,a)','Searching for stations near '
     +            ,slat,'N, ',slon,'E'
        else
            print '(a,i10)','Searching for station nr ',id
        endif
        print '(a)','Searching v2.inv'
        open(unit=1,file=dir(1:ldir)//'v2.inv',status='old')
*
  100   continue
        read(1,1000,end=200)ic(0),iwmo(0),imod(0),name(0),rlat(0)
     +        ,rlon(0),ielevs(0),ielevg(0),pop(0),ipop(0),topo(0)
     +        ,stveg(0),stloc(0),iloc(0),airstn(0),itowndis(0),grveg(0)
 1000   format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4,
     +        1x,i4,a1,i5,3(a2),i2,a1,i2,a16)
*       
*       search closest
        if ( id.eq.0 ) then
            dlon = min(abs(rlon(0)-slon),
     +            abs(rlon(0)-slon-360),
     +            abs(rlon(0)-slon+360))
            dist(0) = (rlat(0)-slat)**2 + (dlon*cos(slat/180*pi))**2
            do i=1,n
                if ( dist(0).lt.dist(i) ) goto 110
            enddo
            go to 100
        else
            if ( iwmo(0).eq.id ) then
                i = 1
                goto 110
            else
                goto 100
            endif
        endif
*
*       insert in ordered list
  110   continue
***        print *,'Found closer station ',name(0),i
        do j=n,i+1,-1
            call moveit(n,j-1,j,dist,ic,iwmo,imod,name,rlat
     +            ,rlon,ielevs,ielevg,pop,ipop,topo
     +            ,stveg,stloc,iloc,airstn,itowndis,grveg)
        enddo
        call moveit(n,0,i,dist,ic,iwmo,imod,name,rlat
     +        ,rlon,ielevs,ielevg,pop,ipop,topo
     +        ,stveg,stloc,iloc,airstn,itowndis,grveg)
        if ( id.eq.0 ) goto 100
  200   continue
*
*       output
        if ( id.ne.1 ) print '(a,i3,a)','The ',n,' closest stations are'
        do i=1,n
            print '(a)','=============================================='
            do j=1,999
                if ( iwmo(i).ge.iwmo1(j) .and. iwmo(i).le.iwmo2(j) )
     +                goto 210
            enddo
            j = 0
  210       continue
            print '(2a,a,a)',name(i),'(',country(j)(1:llen(country(j))),
     +            ')' 
            print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','Coordinates: ',rlat(i)
     +            ,'N, ',rlon(i),'E, ',ielevs(i),'m (prob: ',
     +            ielevg(i),'m)'
            if ( imod(i).eq.0 ) then
                print '(a,i5)','WMO station code: ',iwmo(i)
            else
                print '(i3,a,i5)',imod(i),' near WMO station ',iwmo(i)
            endif
            if ( pop(i).eq.'R' ) then
                print '(a)','Rural station'
            elseif ( pop(i).eq.'S' ) then
                print '(a,i5,a)','Associated with small town (pop.',
     +                ipop(i)*1000,')'
            elseif ( pop(i).eq.'U' ) then
                print '(a,i8,a)','Associated with urban area (pop.',
     +                ipop(i)*1000,')'
            else
                print '(2a)','Unknown population code ',pop(i)
            endif
            string = 'Terrain: '
            if ( topo(i).eq.'FL' ) then
                string(10:) = 'flat'
            elseif ( topo(i).eq.'HI' ) then
                string(10:) = 'hilly'
            elseif ( topo(i).eq.'MT' ) then
                string(10:) = 'mountain top'
            elseif ( topo(i).eq.'MV' ) then
                string(10:) = 'mountain valley'
            else
                string(10:) = 'code '//topo(i)
            endif
            if ( stveg(i).eq.'MA' ) then
                string(26:) = 'marsh'
            elseif ( stveg(i).eq.'FO' ) then
                string(26:) = 'forest'
            elseif ( stveg(i).eq.'IC' ) then
                string(26:) = 'ice'
            elseif ( stveg(i).eq.'DE' ) then
                string(26:) = 'desert'
            elseif ( stveg(i).eq.'CL' ) then
                string(26:) = 'open'
            elseif ( stveg(i).ne.'xx' ) then
                string(26:) = 'code '//stveg(i)
            endif
            print '(2a)',string(1:32),grveg(i)
            if ( stloc(i).eq.'IS' ) then
                print'(a)','Station is located on a small island'
            elseif ( stloc(i).eq.'CO' ) then
                print'(a,i2,a)','Station is located at ',iloc(i)
     +                ,'km from coast'
            elseif ( stloc(i).eq.'LA' ) then
                print'(a)','Station is located next to large lake'
            elseif ( stloc(i).ne.'no' ) then
                print '(2a)','Unknown code ',stloc(i)
            endif
        enddo
        print '(a)','=============================================='
        goto 999
  900   print *,'please give latitude in degrees N, not ',string
        call abort
  901   print *,'please give longitude in degrees E, not ',string
        call abort
  902   print *,'error reading country.codes',string
        call abort
  903   print *,'please give number of stations to find, not ',string
        call abort
  904   print *,'please give station ID, not ',string
        call abort
 999    continue
        end
        integer function llen(a)
        character*(*) a
        do 10 i=len(a),1,-1
            if(a(i:i).ne.'?' .and. a(i:i).ne.' ')goto 20
   10   continue
        llen=len(a)
   20   continue
        llen = i
        end
        subroutine moveit(nn,i,j,dist,ic,iwmo,imod,name,rlat
     +        ,rlon,ielevs,ielevg,pop,ipop,topo
     +        ,stveg,stloc,iloc,airstn,itowndis,grveg)
*       
*       move record i to j
        implicit none
        integer nn,i,j
        integer ic(0:nn),iwmo(0:nn),imod(0:nn),ielevs(0:nn),ielevg(0:nn)
     +        ,ipop(0:nn),iloc(0:nn),itowndis(0:nn)
        real rlat(0:nn),rlon(0:nn),dist(0:nn)
        character name(0:nn)*30,grveg(0:nn)*16,pop(0:nn)*1,topo(0:nn)*2
     +        ,stveg(0:nn)*2
        character stloc(0:nn)*2,airstn(0:nn)*1
*       
*       boring...
        ic(j) = ic(i)
        iwmo(j) = iwmo(i)
        imod(j) = imod(i)
        ielevs(j) = ielevs(i)
        ielevg(j) = ielevg(i)
        ipop(j) = ipop(i)
        iloc(j) = iloc(i)
        itowndis(j) = itowndis(i)
        rlat(j) = rlat(i)
        rlon(j) = rlon(i)
        dist(j) = dist(i)
        name(j) = name(i)
        grveg(j) = grveg(i)
        pop(j) = pop(i)
        topo(j) = topo(i)
        stveg(j) = stveg(i)
        stloc(j) = stloc(i)
        airstn(j) = airstn(i)
*
        end
