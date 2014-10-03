        program geteuslp
*
*       Get SLP stations near a given coordinate or with a substring
*       Get SLP data when called with a station ID.
*
*       Geert Jan van Oldenborgh, KNMI, 2003
*
        implicit none
        integer nn
        parameter(nn=52)
	double precision pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,l,n,m,ldir,istation,isub,
     +        nyr(0:48),nmin(0:48),nok,nlist,yr1,yr2,nflag
        integer iwmo(nn),ielev(nn)
     +        ,ind(nn),list(nn),nrec,nstat
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon,d
     +        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin,rlatmax
        character name(nn)*18,country(nn)*18
        character string*80,sname*30,type*7
        character dir*256
        logical lmin
        integer iargc,llen
        external llen

c     iwmo=2 digit WMO station number
c     name=18 character station name
c     rlat=latitude in degrees.hundredths of degrees, negative = South of Eq.
c     rlon=longitude in degrees.hundredths of degrees, - = West
c     ielev=station elevation in meters, missing is -999
*
        if ( iargc().lt.1 ) then
            print '(a)','usage: geteuslp lat lon [number] [min years]'
            print '(a)','       geteuslp [name|station_id]'
            print *
     +          ,'gives historical SLP for station_id or when'
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
            print '(a,i5,a)','# Searching for station nr ',istation,
     +                ' in eurpres51.inv'
        endif
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = llen(dir)
            dir(ldir+1:) = '/CRUData/'
        else
            dir = '/usr/people/oldenbor/climexp/CRUData/'
        endif
        ldir = llen(dir)
*
        call getarg(0,string)
        if ( lmin ) then
	    do j=1,48
		if ( nmin(j).gt.0 ) then
		    write(0,*) 'error: cannot handle months yet'
		    call abort
		endif
	    enddo
        endif
        open(unit=1,file=dir(1:ldir)//'eurpres51.inv'
     +                ,status='old')
        type = 'euslp'
        if ( n.gt.1 ) print '(a)','Opening eurpres51.data'
        open(unit=2,file=dir(1:ldir)//'eurpres51.data',status='old',
     +		form='formatted',access='direct',recl=77)
        nrec  = 8857
        nstat = 51
*       
        i = 1
  100   continue
        read(1,1001,end=200) iwmo(i),name(i),country(i),
     +                rlat(i),rlon(i),ielev(i),yr1,yr2,nyr(0)
 1001   format(i3,2a,2f6.2,i4,3i5)
*
*       check that we have enough years of data
        if ( lmin ) then
            if ( nyr(0).lt.nmin(0) ) goto 100
        endif
*
*       check elevation
        if ( ielev(i).gt.-998 ) then
            if ( ielev(i).lt.elevmin .or. ielev(i).gt.elevmax ) 
     +            goto 100
        endif
*       
        if ( istation.eq.0 ) then
*           put everything in list, sort later
            dlon = min(abs(rlon(i)-slon),
     +            abs(rlon(i)-slon-360),
     +            abs(rlon(i)-slon+360))
            dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
            i = i + 1
        elseif ( istation.gt.0 ) then
            if ( iwmo(i).eq.istation ) then
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
        elseif ( nlist.gt.0 ) then
            do j=1,nlist
                if ( iwmo(i).eq.list(j) ) then
                    call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax
     +                    ,rlon(i),rlat(i))
                    i = i + 1
                endif
            enddo
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
            nok = nok + 1
            if ( nok.gt.n ) goto 800
            if ( istation.le.0 ) print '(a)'
     +            ,'=============================================='
            k = 0
  210       continue
            print '(5a)','# ',name(jj),'(',trim(country(jj)),')'
            do l=1,llen(name(jj))
                if ( name(jj)(l:l).eq.' ' ) name(jj)(l:l) = '_'
            enddo
            print '(a,f6.2,a,f7.2,a,i4,a,i4,a)','# coordinates: '
     +                ,rlat(jj),'N, ',rlon(jj),'E, ',ielev(jj),'m'
            print '(a,i5,2a)','# station code: ',iwmo(jj),' ',name(jj)
            if ( istation.le.0 ) then
                nflag = 999
            else
                nflag = 1
            endif
            call getdata(type,2,iwmo(jj),0,nflag,nyr,nrec,nstat,yr1,yr2)
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
