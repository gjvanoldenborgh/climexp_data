        program ecanew
*
*       get ECA stations near a given coordinate, or with a given name,
*       or the data.  Now via DODS.
*
        implicit none
#include "recfac.h"
        integer nn,yrbeg,yrend
        parameter(nn=2000,yrbeg=1775,yrend=2020)
	double precision pi
	parameter (pi = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,ldir,istation,nmin(0:48),yr,nok,nlist
     +        ,ilat(3),ilon(3),idates(10),irec
        integer iwmo(nn),firstyr(nn),lastyr(nn),nyr(nn),ind(nn),list(nn)
     +        ,type,mo,dy,ielev,nperyear
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon
     +        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin
     +        ,rlatmax,val,elev(nn)
        real t1(366,yrbeg:yrend),t2(366,yrbeg:yrend)
        logical blended
        character name(nn)*40,country(nn)*40,pmlon*1,pmlat*1
        character string*200,line*500,sname*40,rcountry*40,rname*40
        character dir*256,types(0:4)*2,tmpfile*30
        integer iargc,llen,system,firstnonspace,getpid,rindex
        external iargc,getarg,llen,system,firstnonspace,getpid,rindex
        data types /'pp','tn','tg','tx','rr'/
c
c       FILE FORMAT (MISSING VALUE CODE IS -9999)
c
c       01- 04 LOC    : Location-ID
c       06- 35 COUNTRY: Country name
c       37- 66 LOCNAME: Location name
c       68- 73 LAT    : Latitude in decimal degrees 
c       (positive: North, negative: South)
c       75- 81 LON    : Longitude in decimal degrees
c       (positive: East, negative: West)
c       83- 88 HEIGHT : Height of location in meters
c       yyyymmdd begin date tn
c       yyyymmdd end date tn
c       yyyymmdd begin date tg
c       yyyymmdd end date tg
c       yyyymmdd begin date tx
c       yyyymmdd end date tx
c       yyyymmdd begin date pp
c       yyyymmdd end date pp
c       yyyymmdd begin date rr
c       yyyymmdd end date rr
c
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
            type = 2
        elseif ( index(string,'ecatmin').ne.0 ) then
            type = 1
        elseif ( index(string,'ecatmax').ne.0 ) then
            type = 3
        elseif ( index(string,'ecatave').ne.0 ) then
            type = 5
        elseif ( index(string,'ecatdif').ne.0 ) then
            type = 6
        elseif ( index(string,'ecaprcp').ne.0 ) then
            type = 4
        elseif ( index(string,'ecapres').ne.0 ) then
            type = 0
        else
            print *,'do not know which database to use when running as '
     +            ,string(1:llen(string))
            call abort
        endif
        i = rindex(string,'/')
        if ( string(i+1:i+4).eq.'beca' ) then
            blend =.true.
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
                if ( istation.lt.0 ) then
                    print *,'No monthly information yet, using years.'
                endif
            endif
        enddo
        if ( istation.eq.0 ) then
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
        if ( istation.gt.0 ) then
            if ( type.le.4 ) then
                write(string,'(4a,i10.10,a)') 'zcat ',dir(1:ldir)
     +               ,'data/',types(type),istation,'.dat.gz'
                i = system(string)
            elseif ( type.eq.5 .or. type.eq.6 ) then
                write(tmpfile,'(a,i10.10)') '/tmp/ecat',getpid()
                write(string,'(4a,i10.10,2a)') 'zcat ',dir(1:ldir)
     +               ,'data/',types(1),istation,'.dat.gz > ',tmpfile
                i = system(string)
                call makeabsent(t1,366,yrbeg,yrend)
                call readdat(t1,366,nperyear,yrbeg,yrend,tmpfile)
                write(string,'(4a,i10.10,2a)') 'zcat ',dir(1:ldir)
     +               ,'data/',types(3),istation,'.dat.gz > ',tmpfile
                i = system(string)
                call makeabsent(t2,366,yrbeg,yrend)
                call readdat(t2,366,nperyear,yrbeg,yrend,tmpfile)
                if ( type.eq.5 ) then
                    do yr=yrbeg,yrend
                        do dy=1,366
                            if ( t1(dy,yr).lt.1e30 .and. 
     +                           t2(dy,yr).lt.1e30 ) then
                                t1(dy,yr) = (t1(dy,yr) + t2(dy,yr))/2
                            endif
                        enddo
                    enddo
                    write(string,'(4a,i10.10,2a)') 'zcat ',dir(1:ldir)
     +                   ,'data/',types(2),istation,'.dat.gz > ',tmpfile
                    i = system(string)
*                   overwrite!
                    call readdat(t1,366,nperyear,yrbeg,yrend,tmpfile)
                elseif ( type.eq.6 ) then
                    do yr=yrbeg,yrend
                        do dy=1,366
                            if ( t1(dy,yr).lt.1e30 .and. 
     +                           t2(dy,yr).lt.1e30 ) then
                                t1(dy,yr) = t2(dy,yr) - t1(dy,yr)
                            endif
                        enddo
                    enddo                    
                endif
                open(1,file=tmpfile,status='old')
                do i=1,5
                    read(1,'(a)') string
                    if ( i.ne.2 ) then
                        print '(a)',string(1:llen(string))
                    elseif ( type.eq.5 ) then
                        print '(a)',
     +                       '# tave: tg if availble, else (tn+tx)/2'
                    elseif ( type.eq.6 ) then
                        print '(a)','# tdif = (tx-tn)/2'
                    else
                        print *,'error6785415'
                        call abort
                    endif
                enddo
                call printdatfile(6,t1,366,nperyear,yrbeg,yrend)
                close(1,status='delete')
            else
                write(0,*) 'not yet ready'
                write(*,*) 'not yet ready'
                call abort
            endif
            goto 999
        endif
        ldir = llen(dir)
        open(unit=1,file=dir(1:ldir)//'ECA_locations_all.withyears'
     +       ,status='old')
*
        i = 1
  100   continue
        read(1,1000,err=920,end=200) iwmo(i),rcountry,rname
     +        ,rlat(i),rlon(i),ielev,idates
 1000   format(i4,1x,a40,1x,a40,1x,f6.2,1x,f7.2,1x,i6,1x,10(i8,1x))
*       shift names to the left
        country(i) = rcountry(firstnonspace(rcountry):)
        name(i) = rname(firstnonspace(rname):)
*       check that we have enough years of data
        if ( type.gt.0 .and. type.le.4 ) then
            firstyr(i) = idates(2*type-1)/10000
            lastyr(i) = idates(2*type)/10000
        elseif ( type.eq.5 ) then
            if ( idates(3).eq.-9999 ) idates(3) = +99999999
            firstyr(i) = min(idates(3),max(idates(1),idates(5)))/10000
            lastyr(i) = max(idates(4),min(idates(2),idates(6)))/10000
        elseif ( type.eq.6 ) then
            firstyr(i) = max(idates(1),idates(5))/10000
            lastyr(i) = min(idates(2),idates(6))/10000
        elseif ( type.eq.0 ) then
            firstyr(i) = idates(9)/10000
            lastyr(i) = idates(10)/10000
        else
            print *,'error'
            call abort
        endif
*       for the time being, this does not take missing years into account
*       note that missing = -9999 gives firstyr,lastyr=0
        if ( firstyr(i).eq.0 .or. firstyr(i).gt.lastyr(i) ) then
            goto 100
        else
            nyr(i) = lastyr(i) - firstyr(i) + 1
        endif
        if ( nmin(0).gt.0 ) then
            if ( nyr(i).lt.nmin(0) ) goto 100
        endif
*
*       check elevation
        elev(i) = ielev         ! /10. bug in header
        if ( elev(i).lt.elevmin .or. elev(i).gt.elevmax ) goto 100
        if ( ielev.eq.-9999 .and.
     +        (elevmin.gt.-1e33 .or. elevmax.lt.1e33) ) goto 100
*
*       search closest
        if ( istation.eq.0 ) then
            dlon = min(abs(rlon(i)-slon),
     +            abs(rlon(i)-slon-360),
     +            abs(rlon(i)-slon+360))
            dist(i) = (rlat(i)-slat)**2 + (dlon*cos(slat/180*pi))**2
            i = i + 1
        elseif ( istation.gt.0 ) then
            if ( iwmo(i).eq.istation  ) then
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
*       look for a station in the box
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
        elseif ( nlist.gt.0 ) then
*           look for a station in the list
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
        if ( n.eq.0 ) then
            print '(a)','Cannot locate station'
            stop
        endif
        if ( istation.lt.0 ) print '(a,i5,a)','Found ',n,' stations'
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
            do k=1,llen(name(jj))
                if ( name(jj)(k:k).eq.' ' ) name(jj)(k:k) = '_'
            enddo
            if ( istation.le.0 ) then
                print '(4a)',name(jj),' (',
     +                country(jj)(1:llen(country(jj))),')' 
                print '(a,f6.2,a,f7.2,a,f8.1,a)','coordinates: ',
     +                rlat(jj),'N, ',rlon(jj),'E, ',elev(jj),'m'
                print '(a,i10,4a)','ECA station code: ',iwmo(jj)
     +                ,' ',name(jj)(1:llen(name(jj)))
            else
                print '(a,f6.2,a,f7.2,a,f8.1,a,i10,4a)'
     +                ,'coordinates: ',rlat(jj),'N, ',rlon(jj),'E, '
     +                ,elev(jj),'m; ECA station code: ',iwmo(jj)
     +                ,' ',name(jj)(1:llen(name(jj)))
            endif
            if ( istation.le.0 ) then
                print '(a,i4,a,i4,a,i4)','Found ',nyr(jj)
     +                ,' years of data in ',firstyr(jj),'-'
     +                ,lastyr(jj)
            else                
                write(0,*) 'ecanew: should not come here'
                write(*,*) 'ecanew: should not come here'
                call abort
            endif
  700       continue
        enddo
  800   continue
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
  920   print *,'error reading information, last station was ',
     +        country(i),name(i)
        call abort
  930   print *,'error reading data at/after line ',j,yr
        call abort
  940   print *,'error: cannot locate data file ',dir(1:ldir)
        write(0,*)'error: cannot locate data file ',dir(1:ldir)
        call abort
  999   continue
        end

        integer function firstnonspace(string)
        implicit none
        character string*(*)
        do firstnonspace=1,len(string)
            if ( string(firstnonspace:firstnonspace).ne.' ' ) goto 100
        enddo
 100    continue
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
