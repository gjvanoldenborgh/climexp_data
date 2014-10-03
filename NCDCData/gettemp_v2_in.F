        program gettemp
*
*       Get temperature stations near a given coordinate or with a substring
*       Get temperature data when called with a station ID.
*       Call as gettmin, gettmax to search the min/max temperature databases
*
*       Geert Jan van Oldenborgh, KNMI, 1999-2000
*
        implicit none
        integer nn,ncountry
        parameter(nn=21000,ncountry=233)
	double precision pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,m,ldir,istation,isub,
     +        nyr(0:48),nyrmin(0:48),nyrmax(0:48),nmin(0:48),nok,nlist
        integer ic(nn),iwmo(nn),imod(nn),ielevs(nn),ielevg(nn)
     +        ,ipop(nn),iloc(nn),itowndis(nn),icountry(0:ncountry),nflag
     +        ,ind(nn),list(2,nn),nrec,nstat,yr1,yr2
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon,d
     +        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin,rlatmax
        character name(nn)*30,grveg(nn)*16,pop(nn)*1,topo(nn)*2
     +        ,stveg(nn)*2
        character stloc(nn)*2,airstn(nn)*1
        character*48 country(0:999)
        character string*80,sname*30,type*7,file*255
        character dir*256
        logical lmin,enough,okstation,lwrite
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
        lwrite = .false.
        if ( iargc().lt.1 ) then
            print '(a)','usage: gettemp lat lon [number] [min years]',
     +           ' [begin yr1] [end yr2]'
            print '(a)','       gettemp [name|station_id]'
            print *
     +          ,'gives historical temperature for station_id or when'
            print *,'number=1, otherwise stationlist with years of data' 
            stop
        endif
        call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,isub
     +        ,nmin,rmin,elevmin,elevmax,list,nn,nlist,yr1,yr2)
*       any minimum number of years requested?
        lmin = .FALSE.
        do i=0,48
            if ( nmin(i).gt.0 ) lmin = .TRUE.
        enddo
        do i=1,nn
            dist(i) = 3e33
        enddo
        if ( istation.gt.0 ) then
            if ( isub.eq.0 ) then
                print '(a,i5,a)','# Searching for station nr ',istation,
     +                ' in v2.temperature.inv'
            elseif ( isub.lt.10 ) then
                print '(a,i5,a,i1,a)','# Searching for substation nr '
     +                ,istation,'.',isub,' in v2.temperature.inv'
            else
                print '(a,i5,a,i2,a)','# Searching for substation nr '
     +                ,istation,'.',isub,' in v2.temperature.inv'
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
        file = trim(dir)//'v2.country.codes'
        if ( lwrite ) print *,'opening ',trim(file)
        open(1,file=trim(file),status='old')
        do k=1,ncountry
            read(1,'(a)',end=30) string
            if ( string.eq.' ' ) goto 30
            read(string,'(i3)',err=902) icountry(k)
            country(k) = string(5:)
        enddo
   30   continue
*
        call getarg(0,string)
        if ( index(string,'slp').ne.0 ) then
            if ( lmin ) then
                file = 'v2.slp.inv.withmonth'
            else
                file = 'v2.slp.inv'
            endif
        elseif ( index(string,'prcpall').ne.0 ) then
            if ( lmin ) then
                file = 'v2.prcp.inv.withmonth'
            else
                file = 'v2.prcp.inv'
            endif
        elseif ( index(string,'prcp ').ne.0 ) then
            if ( lmin ) then
                file = 'v2.prcp.adj.inv.withmonth'
            else
                file = 'v2.prcp.adj.inv'
            endif
        else
            if ( lmin ) then
                if ( index(string,'all ').ne.0 ) then
                    file = 'v2.temperature.inv.withmonth'
                else
                    file = 'v2.temperature_adj.inv.withmonth'
                endif
            else
                file = 'v2.temperature.inv'
            endif
        endif
        file = trim(dir)//file
        if ( lwrite ) print *,'opening ',trim(file)
        open(1,file=trim(file),status='old')
        if ( index(string,'getslp').ne.0 ) then
            type = 'slp'
            if ( n.gt.1 .or. lwrite ) print '(a)','Opening v2.slp'
            open(unit=2,file=dir(1:ldir)//'v2.slp',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_SLP
            nstat = NSTAT_SLP
        elseif ( index(string,'getprcpall').ne.0 ) then
            type = 'prcpall'
            if ( n.gt.1 .or. lwrite ) print '(a)','Opening v2.prcp'
            open(unit=2,file=dir(1:ldir)//'v2.prcp',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_PRCP_ALL
            nstat = NSTAT_PRCP_ALL
        elseif ( index(string,'getprcp').ne.0 ) then
            type = 'prcp'
            if ( n.gt.1 ) print '(a)','Opening v2.prcp_adj'
            open(unit=2,file=dir(1:ldir)//'v2.prcp_adj',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_PRCP_ADJ
            nstat = NSTAT_PRCP_ADJ
        elseif ( index(string,'gettempall').ne.0 ) then
            type = 'tempall'
            if ( n.gt.1 .or. lwrite ) print '(a)'
     +           ,'Opening v2.mean_nodup'
            open(unit=2,file=dir(1:ldir)//'v2.mean_nodup',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_MEAN_ALL
            nstat = NSTAT_MEAN_ALL
        elseif ( index(string,'gettemp').ne.0 ) then
            type = 'temp'
            if ( n.gt.1 .or. lwrite ) print '(a)'
     +           ,'Opening v2.mean_adj_nodup'
            open(unit=2,file=dir(1:ldir)//'v2.mean_adj_nodup',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_MEAN_ADJ
            nstat = NSTAT_MEAN_ADJ
        elseif ( index(string,'getminall').ne.0 ) then
            type = 'tminall'
            if ( n.gt.1 .or. lwrite ) print '(a)','Opening v2.min'
            open(unit=2,file=dir(1:ldir)//'v2.min',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_MIN_ALL
            nstat = NSTAT_MIN_ALL
        elseif ( index(string,'getmin').ne.0 ) then
            type = 'tmin'
            if ( n.gt.1 .or. lwrite ) print '(a)','Opening v2.min_adj'
            open(unit=2,file=dir(1:ldir)//'v2.min_adj',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_MIN_ADJ
            nstat = NSTAT_MEAN_ADJ
        elseif ( index(string,'getmaxall').ne.0 ) then
            type = 'tmaxall'
            if ( n.gt.1 .or. lwrite ) print '(a)','Opening v2.max'
            open(unit=2,file=dir(1:ldir)//'v2.max',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_MAX_ALL
            nstat = NSTAT_MAX_ALL
        elseif ( index(string,'getmax').ne.0 ) then
            type = 'tmax'
            if ( n.gt.1 .or. lwrite ) print '(a)','Opening v2.max_adj'
            open(unit=2,file=dir(1:ldir)//'v2.max_adj',status
     +            ='old',form='formatted',access='direct',recl=77)
            nrec  = NREC_MAX_ADJ
            nstat = NSTAT_MAX_ADJ
        else
            print *,'gettemp_v2: do not know which database to use '//
     +           'when running as ',trim(string)
            call abort
        endif
*       
        i = 1
  100   continue
        if ( type(1:4).eq.'prcp' .or. type(1:3).eq.'slp' ) then
            if ( lmin ) then
                read(1,1001,end=200)ic(i),iwmo(i),imod(i),name(i),
     +                rlat(i),rlon(i),ielevs(i),nyr,nyrmin,nyrmax
            else
                read(1,1001,end=200)ic(i),iwmo(i),imod(i),name(i),
     +                rlat(i),rlon(i),ielevs(i)
            endif
 1001       format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4,147i4)
        else
            if ( lmin ) then
                read(1,1000,end=200)ic(i),iwmo(i),imod(i),name(i),
     +                rlat(i),rlon(i),ielevs(i),ielevg(i),
     +                pop(i),ipop(i),topo(i),stveg(i),
     +                stloc(i),iloc(i),airstn(i),itowndis(i),
     +                grveg(i),nyr,nyrmin,nyrmax
            else
                read(1,1000,end=200)ic(i),iwmo(i),imod(i),name(i),
     +                rlat(i),rlon(i),ielevs(i),ielevg(i),
     +                pop(i),ipop(i),topo(i),stveg(i),
     +                stloc(i),iloc(i),airstn(i),itowndis(i),
     +                grveg(i)
            endif
 1000       format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4,
     +            1x,i4,a1,i5,3(a2),i2,a1,i2,a16,147i4)
        endif
*       note that some names are lowercase !
        call toupper(name(i))
        if ( lwrite ) print *,'processing station ',name(i)
*
*       check that we have enough years of data
        if ( lmin ) then
            call checknyr(type,nmin,nyr,nyrmin,nyrmax,enough)
            if ( .not.enough ) then
                if ( lwrite ) print *,'not enough data '
                goto 100
                    endif
        endif
*
*       check elevation
        if ( ielevs(i).gt.-998 ) then
            if ( ielevs(i).lt.elevmin .or. ielevs(i).gt.elevmax ) 
     +            goto 100
        elseif ( type(1:4).ne.'prcp' .or. type(1:3).eq.'slp' ) then
            if ( ielevg(i).lt.elevmin .or. ielevg(i).gt.elevmax ) 
     +            goto 100
        endif
*       
        okstation = .false.
        if ( istation.eq.0 ) then
*           put everything in list, sort later
            dlon = min(abs(rlon(i)-slon),
     +            abs(rlon(i)-slon-360),
     +            abs(rlon(i)-slon+360))
            dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
            okstation = .true.
        elseif ( istation.gt.0 ) then
            if ( iwmo(i).eq.istation .and. 
     +           imod(i).eq.isub ) then
                i = i + 1
                goto 200
            endif
        elseif ( sname.ne.' ' ) then
*           look for a station with sname as substring
            if ( index(name(i),sname(1:llen(sname))).ne.0 ) then
                okstation = .true.
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
                okstation = .true.
                endif
        elseif ( nlist.gt.0 ) then
            do j=1,nlist
                if ( 100000*ic(i) + iwmo(i).eq.list(1,j) .and.
     +               imod(i).eq.list(2,j) ) then
                    call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax
     +                    ,rlon(i),rlat(i))
                    okstation = .true.
                endif
            enddo
        else
            print *,'internal error 31459263'
            call abort
        endif
!
!       check range of years 
!
        if ( okstation .and. ( yr1.gt.0 .or. yr2.lt.3000 ) ) then
            call getdata(type,2,100000*ic(i)+iwmo(i),imod(i)
     +           ,0,nyr,nrec,nstat,yr1,yr2)
            if ( lmin ) then
                call checknyr(type,nmin,nyr,nyr,nyr,enough)
            else
                enough = .true.
            end if
            if ( .not.enough .or. nyr(0).lt.1) then
                if ( lwrite ) print *,'not enough data ',enough,nyr(0)
                okstation = .false.
            end if
        end if

        if ( okstation ) then
            i = i + 1
            if ( i.gt.nn ) then
                print *,'gettemp: error: too many stations (>',nn
     +               ,')'
                print *,'         use a more specific substring'
                call abort
            endif
        end if

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
        if ( istation.le.0 ) print '(a,i5,a)','Found ',n-1
     +      ,' stations'
        if ( nlist.gt.0 ) then
            call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
        endif
        nok = 0
        do j=1,nn
            if ( istation.eq.0 .or. slat1.lt.1e33 ) then
                jj = ind(j)
                if ( jj.eq.0 ) goto 700
                if ( dist(jj).gt.1e33 ) goto 700
            else
                jj = j
            endif
            if ( nlist.gt.0 ) then
                do i=1,nlist
!!!                    print *,'comparing ',100000*ic(jj) + iwmo(jj)
!!!     +                   ,imod(jj),' with ',list(1,i),list(2,i)
                    if ( 100000*ic(jj) + iwmo(jj) .eq. list(1,i) .and.
     +                   imod(jj).eq.list(2,i) ) then
!!!                        print *,'OK'
                        goto 201
                    end if
                end do
!               not in list
!!!                print *,'not in list',100000*ic(jj) + iwmo(jj),imod(jj)
                goto 700
            end if
 201        continue
            nok = nok + 1
            if ( nok.gt.n ) goto 800
            if ( istation.le.0 ) print '(a)'
     +            ,'=============================================='
            do k=1,ncountry
                if ( ic(jj).eq.icountry(k) ) goto 210
            enddo
            k = 0
  210       continue
            print '(3a,a,a)','# ',name(jj),'(',trim(country(k))
     +            ,')'
            if ( type(1:4).eq.'prcp' .or. type(1:3).eq.'slp' ) then
                print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','# coordinates: '
     +                ,rlat(jj),'N, ',rlon(jj),'E, ',ielevs(jj),'m'
            else
                print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','# coordinates: '
     +                ,rlat(jj),'N, ',rlon(jj),'E, ',ielevs(jj)
     +                ,'m (prob: ',ielevg(jj),'m)'
            endif
            call tidyname(name(jj),country(k))
            if ( imod(jj).eq.0 ) then
                print '(a,i5,2a)','# WMO station code: ',iwmo(jj),' '
     +                ,name(jj)
            elseif ( imod(jj).lt.10 ) then
                print '(a,i5,a,i1,2a)','# Near WMO station code: '
     +                ,iwmo(jj),'.',imod(jj),' ',name(jj)
            elseif ( imod(jj).lt.100 ) then
                print '(a,i5,a,i2,2a)','# Near WMO station code: '
     +                ,iwmo(jj),'.',imod(jj),' ',name(jj)
            else
                print '(a,i5,a,i3,2a)','# Near WMO station code: '
     +                ,iwmo(jj),'.',imod(jj),' ',name(jj)
            endif
            if ( type(1:4).ne.'prcp' .and. type(1:3).ne.'slp' ) then
                if ( istation.le.0 ) then
                    if ( pop(jj).eq.'R' ) then
                        print '(a)','Rural station'
                    elseif ( pop(jj).eq.'S' ) then
                        print '(a,i5,a)'
     +                        ,'Associated with small town (pop.'
     +                        ,ipop(jj)*1000,')'
                    elseif ( pop(jj).eq.'U' ) then
                        print '(a,i8,a)'
     +                        ,'Associated with urban area (pop.'
     +                        ,ipop(jj)*1000,')'
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
                        print'(a)'
     +                        ,'Station is located on a small island'
                    elseif ( stloc(jj).eq.'CO' ) then
                        print'(a,i2,a)','Station is located at ',iloc(jj
     +                        ),'km from coast'
                    elseif ( stloc(jj).eq.'LA' ) then
                        print'(a)'
     +                        ,'Station is located next to large lake'
                    elseif ( stloc(jj).ne.'no' ) then
                        print '(2a)','Unknown code ',stloc(jj)
                    endif
                endif
            endif
            if ( istation.le.0 ) then
                nflag = 999
            else
                nflag = 1
            endif
            call getdata(type,2,100000*ic(jj)+iwmo(jj),imod(jj)
     +            ,nflag,nyr,nrec,nstat,yr1,yr2)
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

        subroutine checknyr(type,nmin,nyr,nyrmin,nyrmax,enough)
        implicit none
        integer nmin(0:48),nyr(0:48),nyrmin(0:48),nyrmax(0:48)
        character type*(*)
        logical enough
        integer j
        enough = .true.
        if ( type(1:4).eq.'temp' .or. type(1:4).eq.'prcp' .or.
     +       type(1:3).eq.'slp' ) then
            do j=0,48
                if ( nmin(j).gt.0 ) then
                    if ( nyr(j).lt.nmin(j) ) enough = .false.
                end if
            end do
        else if ( type(1:4).eq.'tmin' ) then
            do j=0,48
                if ( nmin(j).gt.0 ) then
                    if ( nyrmin(j).lt.nmin(j) ) enough = .false.
                end if
            end do
        else if ( type(1:4).eq.'tmax' ) then
            do j=0,48
                if ( nmin(j).gt.0 ) then
                    if ( nyrmax(j).lt.nmin(j) ) enough = .false.
                end if
            end do
        else
            write(0,*) 'error: what is ',type,'?'
            call abort
        end if
        end subroutine
