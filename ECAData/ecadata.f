        program eca
*
*       get ECA stations near a given coordinate, or with a given name,
*       or the data
*
        implicit none
        integer nn
        parameter(nn=1000000)
        double precision pi
        parameter (pi = 3.1415926535897932384626433832795d0)
        integer i,j,k,ii,jj,kk,n,ldir,istation,nmin(0:48),yr,nok,nlist
     +        ,ilat(3),ilon(3),idates(3),iecdold,isource
        integer iwmo(nn),iecd(nn),firstyr(nn),lastyr(nn),nyr(nn),ind(nn)
     +       ,list(nn),tmin,tmax,temp,prcp,mo,dy,ielev
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon
     +        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin
     +        ,rlatmax,val,elev(nn)
        logical blend,lwrite
        character name(nn)*40,country(nn)*2,pmlon*1,pmlat*1,gsn(nn)*3
     +       ,el*3,elem*40,element*2,elin*2,wmo*6,units*10,longname*40
        character string*200,line*500,sname*25
        character dir*256
        integer iargc,llen,rindex
! 01- 05 STAID  : Location identifier (see file location.txt for more info.)
! 07- 12 SOUID  : Source identifier
! 14- 53 SOUNAME: Source name
! 55- 56 CN     : Country code (ISO3116 country codes)
! 58- 66 LAT    : Latitude in degrees:minutes:seconds (+: North, -: South)
! 68- 76 LON    : Longitude in degrees:minutes:seconds (+: East, -: West)
! 78- 81 HGTH   : Height in meters
!       3i5 yr1,yr2,nyr (added by addyear)
        lwrite = .false.
        if ( iargc().lt.1 ) then
            print '(a)','usage: eca{tmin|temp|tmax|prcp} '//
     +            '[lat lon|name] [min years]'
            print *,'gives stationlist with years of data' 
            print '(a)','       eca{tmin|temp|tmax|prcp station_id'
            print *,'gives data station_id,'
            stop
        endif
        call getarg(0,string)
        if ( index(string,'ecatemp').ne.0 ) then
            element = 'tg'
        elseif ( index(string,'ecatmin').ne.0 ) then
            element = 'tn'
        elseif ( index(string,'ecatmax').ne.0 ) then
            element = 'tx'
        elseif ( index(string,'ecatave').ne.0 ) then
            element = 'tv'
        elseif ( index(string,'ecatdif').ne.0 ) then
            element = 'td'
        elseif ( index(string,'ecaprcp').ne.0 ) then
            element = 'rr'
        elseif ( index(string,'ecapres').ne.0 ) then
            element = 'pp'
        elseif ( index(string,'ecasnow').ne.0 ) then
            element = 'sd'
        elseif ( index(string,'ecaclou').ne.0 ) then
            element = 'cc'
        else
            print *,'do not know which database to use when running as '
     +            ,string(1:llen(string))
            call abort
        endif
        if ( element.eq.'rr' ) then
            units = '[mm/day]'
            longname = '24-hr summed precipittaion'
        elseif ( element.eq.'pp' ) then
            units = '[mb]'
            longname = 'sea-level pressure'
        elseif ( element.eq.'tg' ) then
            units = '[Celsius]'
            longname = 'daily mean temperature'
        elseif ( element.eq.'tn' ) then
            units = '[Celsius]'
            longname = 'daily minimukm temperature'
        elseif ( element.eq.'tx' ) then
            units = '[Celsius]'
            longname = 'daily maximum temperature'
        elseif ( element.eq.'sd' ) then
            units = '[m]'
            longname = 'snow depth'
        elseif ( element.eq.'cc' ) then
            units = '[1]'
            longname = 'cloud cover'
        endif
        i = rindex(string,'/')
        if ( string(i+1:i+4).eq.'beca' ) then
            blend = .true.
        elseif ( string(i+1:i+3).eq.'eca' ) then
            blend = .false.
        else
            write(0,*) 'ecanew: error: called as ',string
            write(*,*) 'ecanew: error: called as ',string
            call abort
        endif
        call getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation,1
     +        ,nmin,rmin,elevmin,elevmax,list,nn,nlist)
*       no monthly time information yet
        do i=1,48
            if ( nmin(i).ne.0 ) then
                nmin(0) = nmin(i)
                if ( istation.le.0 ) then
                    print *,'No monthly information yet, using years.'
                endif
            endif
        enddo
        if ( istation.eq.-1 ) then
            do i=1,nn
                dist(i) = 3e33
            enddo
        endif
*
        call getenv('DIR',dir)
        if ( dir.ne.' ' ) then
            ldir = llen(dir)
            dir(ldir+1:) = '/ECAData/'
        else
            dir = '/usr/people/oldenbor/NINO/ECAData/'
        endif
        ldir = llen(dir)
        if ( blend ) then
            write(line,'(4a)') dir(1:ldir),'ECA_blend_station_',
     +           element,'.txt.withyears'
        else
            write(line,'(4a)') dir(1:ldir),'ECA_nonblend_station_',
     +           element,'.txt.withyears'
        end if
        open(unit=1,file=trim(line),status='old')
*       skip headers
 10     continue
        read(1,'(a)') line
        if ( line(1:5).ne.'STAID' ) goto 10
        read(1,'(a)') string
        if ( string.ne.' ' ) then
            print *,'ecadata: error: header has changed!'
            print *,string
        endif
*
        i = 1
  100   continue
        read(1,'(a)',err=920,end=200) line
!!!        print '(a)',trim(line)
        read(line,1000,err=101) iecd(i),name(i),country(i),
     +       pmlat,ilat,pmlon,ilon,ielev,idates
 1000   format(i5,1x,a40,1x,a2,1x,
     +        a1,i2,1x,i2,1x,i2,1x,
     +        a1,i2,1x,i2,1x,i2,1x,
     +        i5,3i5)
        goto 102
!       they added stations with 3-digit longitude, try again with that format
 101    continue
!!!        write(0,*) 'error reading with old format, try new one'
        read(line,1001,err=950) iecd(i),name(i),country(i),
     +       pmlat,ilat,pmlon,ilon,ielev,idates
 1001   format(i5,1x,a40,1x,a2,1x,
     +        a1,i2,1x,i2,1x,i2,1x,
     +        a1,i3,1x,i2,1x,i2,1x,
     +        i5,x,3i5)
 102    continue
*
*       regularize name - often has '-N' added to it
        k = llen(name)
        if ( name(i)(k-1:k-1).eq.'-' ) then
             name(i)(k-1:k) = ' '
        endif
        firstyr(i) = idates(1)
        lastyr(i) = idates(2)
        nyr(i) = idates(3)
*
*       check that we have enough years of data
*       for the time being, this does not take missing years into account
*       note that missing = -9999 gives firstyr,lastyr=0
        if ( nmin(0).gt.0 ) then
            if ( nyr(i).lt.nmin(0) ) goto 100
        endif
*
*       check elevation
        elev(i) = ielev
        if ( elev(i).lt.elevmin .or. elev(i).gt.elevmax ) goto 100
        if ( ielev.eq.-9999 .and.
     +        (elevmin.gt.-1e33 .or. elevmax.lt.1e33) ) goto 100
*
*       search closest
        rlon(i) = ilon(1) + (ilon(2) + ilon(3)/60.)/60.
        if ( pmlon.eq.'-' ) then
            rlon(i) = -rlon(i)
        elseif ( pmlon.ne.'+' ) then
            !!!write(0,*) 'ecadata: error: sign lon = ',pmlon
            !!!write(*,*) 'ecadata: error: sign lon = ',pmlon
            !!!write(*,*) trim(line)
            goto 100
        endif
        rlat(i) = ilat(1) + (ilat(2) + ilat(3)/60.)/60.
        if ( pmlat.eq.'-' ) then
            rlat(i) = -rlat(i)
        elseif ( pmlat.ne.'+' ) then
            !!!write(0,*) 'ecadata: error: sign lat = ',pmlat
            !!!write(*,*) 'ecadata: error: sign lat = ',pmlat
            !!!write(*,'(i8,a)') i,trim(line)
            goto 100
        endif
        if ( nlist.gt.0 ) then
*           look for a station in the list
            do j=1,nlist
                if ( iecd(i).eq.list(j) ) then
                    if ( lwrite ) write(0,*) 'found station',i,j,iecd(i)
                    call updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax
     +                    ,rlon(i),rlat(i))
                    i = i + 1
                endif
            enddo
        elseif ( istation.eq.0 ) then
            dlon = min(abs(rlon(i)-slon),
     +            abs(rlon(i)-slon-360),
     +            abs(rlon(i)-slon+360))
            dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
            i = i + 1
        elseif ( istation.gt.0 ) then
            if ( iecd(i).eq.istation  ) then
                i = i + 1
                goto 200
            endif
        elseif ( sname.ne.' ' ) then
*           look for a station with sname as substring
            if (  index(name(i),sname(1:llen(sname))).ne.0 ) then
                i = i + 1
                if ( i.gt.nn ) then
                    print *,'Maximum ',nn,' stations'
                    stop
                endif
            else
                goto 100
            endif
        elseif ( slat1.lt.1e33 ) then
*           look for a station in the box
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
                    print *,'Maximum ',nn,' stations'
                    stop
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

        if ( nlist.eq.0 .and. (istation.eq.0 .or. slat1.lt.1e33) ) then
            call sortdist(i,n,dist,rlon,rlat,ind,rmin)
        else
            n = i
        endif
        if ( lwrite ) write(0,*) 'found ',n,' stations'
*
*       output
        if ( n.eq.0 ) then
            print '(a)','Cannot locate station'
            stop
        endif
        if ( istation.le.0 ) print '(a,i5,a)','Found ',n,' stations'
        if ( nlist.gt.0 ) then
            call printbox(rlonmin,rlonmax,rlatmin,rlatmax)
        endif
        nok = 0
        do j=1,n
            if (  nlist.eq.0 .and. (istation.eq.0 .or. slat1.lt.1e33) )
     +           then
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
            do k=1,llen(name(jj))
                if ( name(jj)(k:k).eq.' ' ) name(jj)(k:k) = '_'
            enddo
            if ( istation.le.0 ) then
                print '(4a)',name(jj),' (',
     +                country(jj)(1:llen(country(jj))),')' 
                print '(a,f6.2,a,f7.2,a,f8.1,a)','coordinates: ',
     +                rlat(jj),'N, ',rlon(jj),'E, ',elev(jj),'m'
                print '(a,i10,4a)','ECA station code: ',iecd(jj)
     +                ,' ',name(jj)(1:llen(name(jj)))
            else
                print '(6a)','# ',element,' ',trim(units),' '
     +               ,trim(longname)
                print '(a,f6.2,a,f7.2,a,f8.1,a,i10,10a)'
     +               ,'# coordinates: ',rlat(jj),'N, ',rlon(jj),'E, '
     +               ,elev(jj),'m; ECA station code: ',iecd(jj)
     +               ,' ',name(jj)(1:llen(name(jj))),' '
     +               ,country(jj)(1:llen(country(jj)))
            endif
            if ( istation.le.0 ) then
                print '(a,i4,a,i4,a,i4)','Found ',nyr(jj)
     +                ,' years of data in ',firstyr(jj),'-'
     +                ,lastyr(jj)
            else
                if ( blend ) then
                    write(dir(ldir+1:),'(2a,i6.6,a)') '/data/b',element,
     +                   iecd(jj),'.dat.gz'
                else
                    write(dir(ldir+1:),'(2a,i6.6,a)') '/data/',element,
     +                   iecd(jj),'.dat.gz'
                endif
                ldir = llen(dir)
                write(string,'(2a,i6.6,a)') '/tmp/',element,iecd(jj)
     +                ,'.dat'
                open(2,file=dir,status='old',err=940)
                close(2)
                call mysystem('gzip -d -c '//dir(1:ldir)//' > '
     +                //string(1:llen(string)),i)
                if ( i.ne.0 ) then
                    write(0,*) 'gunzipping failed, error code =',i
                    write(0,*) 'gzip -d -c '//dir(1:ldir)//' > '
     +                //string(1:llen(string))
                endif
                open(2,file=string(1:llen(string)),status='old',err=940)
*               read and print file minus the first line
                read(2,'(a)',end=690,err=930) string
  600           continue
                read(2,'(a)',end=690,err=930) string
                print '(a)',string(1:llen(string))
                goto 600
  690           continue
                close(2,status='delete')
            endif
 700        continue
        enddo
 800    continue
        if ( istation.le.0 ) print '(a)'
     +        ,'=============================================='
        goto 999
 920    print *,'error reading information, last station was ',
     +        country(i),name(i)
        call abort
 930    print *,'error reading data at/after line ',j,yr
        call abort
 940    print *,'error: cannot locate data file ',dir(1:ldir)
        write(0,*)'error: cannot locate data file ',dir(1:ldir)
        call abort
 950    continue
        !!!write(0,*) 'error reading data from line ',trim(line)
        !!!write(*,*) 'error reading data from line ',trim(line)
        goto 100
 999    continue
        end

      integer function rindex(string,pattern)
      implicit none
      character string*(*),pattern*(*)
      integer ls,lp,i
      ls = len(string)
      lp = len(pattern)
      if ( lp.le.0 .or.lp.gt.ls ) then
          rindex = 0
          return
      endif
      do i=ls-lp+1,1,-1
          if ( string(i:i+lp-1).eq.pattern ) then
              rindex = i
              return
          endif
      enddo
      rindex = 0
      end
