        program gettemp
*
*       Get temperature stations near a given coordinate or with a substring
*       Get temperature data when called with a station ID.
*       Call as gettmin, gettmax to search the min/max temperature databases
*
*       Geert Jan van Oldenborgh, KNMI, 1999-2000
*
        implicit none
        integer nn
        parameter(nn=7500)
	double precision pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,m,ldir,istation,nyr(0:48),nyrmin(0:48)
     +        ,nyrmax(0:48),nmin(0:48),nok
        integer ic(nn),iwmo(nn),imod(nn),ielevs(nn),ielevg(nn)
     +        ,ipop(nn),iloc(nn),itowndis(nn),iwmo1(208),iwmo2(208)
     +        ,nflag,ind(nn),firstrec(nn),lastrec(nn),firstrecmin(nn)
     +        ,lastrecmin(nn),firstrecmax(nn),lastrecmax(nn)
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon,d
     +        ,rmin
        character name(nn)*30,grveg(nn)*16,pop(nn)*1,topo(nn)*2
     +        ,stveg(nn)*2
        character stloc(nn)*2,airstn(nn)*1
        character*48 country(0:999)
        character string*80,sname*30,type*4
        character dir*256
        integer iargc,llen
        external iargc,getarg,llen

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
            print '(a)','usage: gettemp lat lon [number] [min years]'
            print '(a)','       gettemp [name|station_id]'
            print *
     +          ,'gives historical temperature for station_id or when'
            print *,'number=1, otherwise stationlist with years of data' 
            stop
        endif
        call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,10
     +        ,nmin,rmin)
        do i=1,nn
            dist(i) = 3e33
        enddo
        if ( istation.gt.0 ) then
            if ( mod(istation,10).eq.0 ) then
                print '(a,i5,a)','Searching for station nr ',istation
     +                /10,' in v2.temperature.inv'
            else
                print '(a,f7.1,a)','Searching for substation nr '
     +                ,istation/10.,' in v2.temperature.inv'
            endif
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
        do k=1,208
            read(1,'(a)',end=30) string
            if ( string.eq.' ' ) goto 30
            read(string,'(i5,1x,i5,1x,i3)',err=902) i,j,m
            iwmo1(k) = i
            iwmo2(k) = j
            country(k) = string(18:)
        enddo
   30   continue
*
        open(unit=1,file=dir(1:ldir)//'v2.temperature.inv.withmonth'
     +        ,status='old')
        call getarg(0,string)
        if ( index(string,'gettemp').ne.0 ) then
            type = 'temp'
            if ( n.gt.1 ) print '(a)','Opening v2.mean_adj_nodup'
            open(unit=2,file=dir(1:ldir)//'v2.mean_adj_nodup',status
     +            ='old',form='formatted',access='direct',recl=77)
        elseif ( index(string,'getmin').ne.0 ) then
            type = 'tmin'
            if ( n.gt.1 ) print '(a)','Opening v2.min_adj_nodup'
            open(unit=2,file=dir(1:ldir)//'v2.min_adj_nodup',status
     +            ='old',form='formatted',access='direct',recl=77)
        elseif ( index(string,'getmax').ne.0 ) then
            type = 'tmax'
            if ( n.gt.1 ) print '(a)','Opening v2.max_adj_nodup'
            open(unit=2,file=dir(1:ldir)//'v2.max_adj_nodup',status
     +            ='old',form='formatted',access='direct',recl=77)
        else
            print *,'do not know which database to use when running as '
     +            ,string(1:llen(string))
            call abort
        endif
*       
        i = 1
  100   continue
        read(1,1000,end=200) ic(i),iwmo(i),imod(i),name(i),rlat(i)
     +        ,rlon(i),ielevs(i),ielevg(i),pop(i),ipop(i),topo(i)
     +        ,stveg(i),stloc(i),iloc(i),airstn(i),itowndis(i),grveg(i)
     +        ,firstrec(i),lastrec(i),firstrecmin(i),lastrecmin(i)
     +        ,firstrecmax(i),lastrecmax(i),nyr,nyrmin,nyrmax
 1000   format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4,
     +        1x,i4,a1,i5,3(a2),i2,a1,i2,a16,6i8,147i4)
*       note that some names are lowercase !
        call toupper(name(i))
*
*       check that we have enough years of data
        if (  type.eq.'temp' ) then
            do j=0,48
                if ( nmin(j).gt.0 ) then
                    if ( nyr(j).lt.nmin(j) ) goto 100
                endif
            enddo
        elseif ( type.eq.'tmin' ) then
            do j=0,48
                if ( nmin(j).gt.0 ) then
                    if ( nyrmin(j).lt.nmin(j) ) goto 100
                endif
            enddo
        elseif ( type.eq.'tmax' ) then
            do j=0,48
                if ( nmin(j).gt.0 ) then
                    if ( nyrmax(j).lt.nmin(j) ) goto 100
                endif
            enddo
        endif
        if ( istation.eq.0 ) then
*           put everything in list, sort later
            dlon = min(abs(rlon(i)-slon),
     +            abs(rlon(i)-slon-360),
     +            abs(rlon(i)-slon+360))
            dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
            i = i + 1
        elseif ( istation.gt.0 ) then
            if ( iwmo(i).eq.istation/10 .and. 
     +           imod(i).eq.mod(istation,10) ) then
                i = i + 1
                goto 200
            endif
        elseif ( sname.ne.' ' ) then
*           look for a station with sname as substring
            if ( index(name(i),sname(1:llen(sname))).ne.0 ) then
                i = i + 1
                if ( i.gt.nn ) then
                    print *,'gettemp: error: too many stations (>',nn
     +                    ,')'
                    print *,'         use a more specific substring'
                    call abort
                endif
            endif
        elseif ( slat1.lt.1e33 ) then
            if ( (slon1.gt.slon .and. 
     +            rlon(i).gt.slon .and. rlon(i).lt.slon1
     +            .or.
     +            slon1.lt.slon .and.
     +            (rlon(i).lt.slon1 .or. rlon(i).gt.slon)
     +            ) .and. (
     +            rlat(i).gt.min(slat,slat1) .and.
     +            rlat(i).lt.max(slat,slat1) )
     +            ) then
                dist(i) = i
                n = i
                i = i + 1
                if ( i.gt.nn ) then
                    print *,'gettemp: error: too many stations (>',nn
     +                    ,')'
                    print *,'         use a smaller region or demand'
                    print *,'         more years of data'
                    call abort
                endif
            endif
        else
            print *,'internal error 31459263'
            call abort
        endif
        goto 100
*       
*       we read all interesting stations in memory
  200   continue
        i = i - 1

        if ( istation.eq.0 .or. slat1.lt.1e33 ) then
            call sortdist(i,n,dist,rlon,rlat,ind,rmin)
        else
            n = i
        endif
*
*       output
        if ( istation.le.0 ) print '(a,i5,a)','Found ',n,' stations'
        nok = 0
        do j=1,nn
            if ( istation.eq.0 .or. slat1.lt.1e33 ) then
                jj = ind(j)
                if ( dist(jj).gt.1e33 ) goto 700
            else
                jj = j
            endif
            nok = nok + 1
            if ( nok.gt.n ) goto 800
            if ( istation.le.0 ) print '(a)'
     +            ,'=============================================='
            do k=1,208
                if ( iwmo(jj).ge.iwmo1(k) .and. iwmo(jj).le.iwmo2(k) )
     +                goto 210
            enddo
            k = 0
  210       continue
            print '(2a,a,a)',name(jj),'(',country(k)(1:llen(country(k)))
     +            ,')' 
            print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','coordinates: ',rlat(jj)
     +            ,'N, ',rlon(jj),'E, ',ielevs(jj),'m (prob: ',
     +            ielevg(jj),'m)'
            call tidyname(name(jj),country(j))
            if ( imod(jj).eq.0 ) then
                print '(a,i5,2a)','WMO station code: ',iwmo(jj),' '
     +                ,name(jj)
            else
                print '(a,i5,a,i1,2a)',' Near WMO station code: '
     +                ,iwmo(jj),'.',imod(jj),' ',name(jj)
            endif
            if ( istation.le.0 ) then
                if ( pop(jj).eq.'R' ) then
                    print '(a)','Rural station'
                elseif ( pop(jj).eq.'S' ) then
                    print '(a,i5,a)','Associated with small town (pop.',
     +                    ipop(jj)*1000,')'
                elseif ( pop(jj).eq.'U' ) then
                    print '(a,i8,a)','Associated with urban area (pop.',
     +                    ipop(jj)*1000,')'
                else
                    print '(2a)','Unknown population code ',pop(jj)
                endif
                string = 'Terrain: '
                if ( topo(jj).eq.'FL' ) then
                    string(10:) = 'flat'
                elseif ( topo(jj).eq.'HI' ) then
                    string(10:) = 'hilly'
                elseif ( topo(jj).eq.'MT' ) then
                    string(10:) = 'mountain top'
                elseif ( topo(jj).eq.'MV' ) then
                    string(10:) = 'mountain valley'
                else
                    string(10:) = 'code '//topo(jj)
                endif
                if ( stveg(jj).eq.'MA' ) then
                    string(26:) = 'marsh'
                elseif ( stveg(jj).eq.'FO' ) then
                    string(26:) = 'forest'
                elseif ( stveg(jj).eq.'IC' ) then
                    string(26:) = 'ice'
                elseif ( stveg(jj).eq.'DE' ) then
                    string(26:) = 'desert'
                elseif ( stveg(jj).eq.'CL' ) then
                    string(26:) = 'open'
                elseif ( stveg(jj).ne.'xx' ) then
                    string(26:) = 'code '//stveg(jj)
                endif
                print '(2a)',string(1:32),grveg(jj)
                if ( stloc(jj).eq.'IS' ) then
                    print'(a)','Station is located on a small island'
                elseif ( stloc(jj).eq.'CO' ) then
                    print'(a,i2,a)','Station is located at ',iloc(jj)
     +                    ,'km from coast'
                elseif ( stloc(jj).eq.'LA' ) then
                    print'(a)','Station is located next to large lake'
                elseif ( stloc(jj).ne.'no' ) then
                    print '(2a)','Unknown code ',stloc(jj)
                endif
            endif
            if ( istation.le.0 ) then
                nflag = 999
            else
                nflag = 1
                print '(2a)','temp from v2.mean_adj_nodup in ',
     +                    'degree celsius'
            endif
            if ( type.eq.'temp' ) then
                call fastgetdata(2,(100000*ic(jj)+iwmo(jj))*10+imod(jj)
     +                ,firstrec(jj),lastrec(jj))
            elseif ( type.eq.'tmin' ) then
                call fastgetdata(2,(100000*ic(jj)+iwmo(jj))*10+imod(jj)
     +                ,firstrecmin(jj),lastrecmin(jj))
            elseif ( type.eq.'tmin' ) then
                call fastgetdata(2,(100000*ic(jj)+iwmo(jj))*10+imod(jj)
     +                ,firstrecmax(jj),lastrecmax(jj))
            endif
  700       continue
        enddo
  800       continue
        if ( istation.le.0 ) print '(a)'
     +        ,'=============================================='
        goto 999
  900   print *,'please give latitude in degrees N, not ',string
        call abort
  901   print *,'please give longitude in degrees E, not ',string
        call abort
  902   print *,'error reading country.codes',string
        call abort
  903   print *,'please give number of stations to find, not ',string
        call abort
  904   print *,'please give station ID or name, not ',string
        call abort
 999    continue
        end
*  #[ fastgetdata:
        subroutine fastgetdata(iu,ii,firstrec,lastrec)
*
*       print precip data from the direct access file 
*       open on unit iu
*
        implicit none
        integer iu,ii,firstrec,lastrec
        integer i,j,i0,md,yr,data(12)
        logical lwrite
        parameter (lwrite=.FALSE.)
*
        if ( lwrite ) print *,'looking for station ',ii,firstrec,lastrec
        if ( firstrec.le.0 .or. lastrec.le.0 .or. firstrec.gt.lastrec )
     +        then
            print '(a)','Cannot locate any data'
            return
        endif
        do i=firstrec,lastrec
 1012       format(i8,i3,i1,i4,12i5)
            read(iu,1012,rec=i) i0,md,j,yr,data
            if ( lwrite ) print *,'read record ',i,i0
            if ( 10*i0+md.ne.ii ) then
                write(0,*) 'gettemp: error in index, expected station '
     +                ,ii,' but got ',10*i0+md
            endif
            print '(i5,12f7.1)',yr,(data(j)/10.,j=1,12)
        enddo
        end
*  #] fastgetdata:
