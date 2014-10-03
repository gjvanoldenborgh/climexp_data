        program surf2dat
c
c       This program reads TAO anonymous FTP ascii-format surface data
c       files.  It interpolates the data in time
c       and next interpolates horizontally.
c
c       Based on met_read, temp_read by Dai McClurg, NOAA/PMEL/OCRD, April 1999
c
        implicit none
c
        integer nz, nt, nlat, nlon, firstyear
        parameter(nz = 42, nt = 10000, nlat=10, nlon=19, firstyear=1980)
c
        integer i,j,k,l,m,n,iq,yr,mn,dy,day,nrec,dpm(12)
        integer nblock, nk, nn, nday, n1, n2, jdate, iqual(6)
        integer depuwnd,depvwnd,deprh,depairt,depsst
        integer ilat,ilon,lat,lon,maxnt,ntimes,lastyear,ii(8)
        integer iwrite
        logical lexist
        real flag, t(nz), rlat,rlon,data(5)
        real, allocatable ::
     +        windu(:,:,:,:),
     +        windv(:,:,:,:),
     +        rh(:,:,:,:),
     +        airt(:,:,:,:),
     +        sst(:,:,:,:)
        character infile*80, header*132, line*132, line2*132
        character ns*1, ew*1, string*80, extension*8
        logical lintdep,lintlatlon
        integer iargc
        external iargc,getarg
#include "grid.h"
        data dpm /31,29,31,30,31,30,31,31,30,31,30,31/
        iwrite = 0
        call date_and_time(values=ii)
        lastyear = ii(1)
	allocate(windu(366,firstyear:lastyear,nlat,nlon))
	allocate(windv(366,firstyear:lastyear,nlat,nlon))
	allocate(rh(366,firstyear:lastyear,nlat,nlon))
	allocate(airt(366,firstyear:lastyear,nlat,nlon))
	allocate(sst(366,firstyear:lastyear,nlat,nlon))
c
c .......................................................................
*
*       process arguments
        if ( iargc().gt.0 ) then
            lintdep = .FALSE.
            lintlatlon = .FALSE.
            do i=1,iargc()
                call getarg(i,string)
                if ( string(1:3).eq.'dep' ) then
                    lintdep = .TRUE.
                elseif ( string(1:5).eq.'nodep' ) then
                    lintdep = .FALSE.
                elseif ( string(1:6).eq.'latlon' ) then
                    lintlatlon = .TRUE.
                elseif ( string(1:8).eq.'nolatlon' ) then
                    lintlatlon = .FALSE.
                else
                    print *,'surf2dat: unrecognized argument'
     +                    ,string(1:index(string,' ')-1)
                    stop
                endif
            enddo               ! loop over args
        else                    ! no args, defaults
            lintdep = .TRUE.
            lintlatlon = .TRUE.
        endif
*       loop over latitudes
        do ilat=1,nlat
            lat = lats(ilat)
*           loop over longitudes
            do ilon=1,nlon
                lon = lons(ilon)
                call makefieldabsent(windu(1,firstyear,ilat,ilon)
     +               ,366*(lastyear-firstyear+1))
                call makefieldabsent(windv(1,firstyear,ilat,ilon)
     +               ,366*(lastyear-firstyear+1))
                call makefieldabsent(rh(1,firstyear,ilat,ilon)
     +               ,366*(lastyear-firstyear+1))
                call makefieldabsent(airt(1,firstyear,ilat,ilon)
     +               ,366*(lastyear-firstyear+1))
                call makefieldabsent(sst(1,firstyear,ilat,ilon)
     +               ,366*(lastyear-firstyear+1))
*
*               construct filename
                if ( lat.lt.0 ) then
                    ns='s'
                else
                    ns='n'
                endif
                if ( lon.lt.180 ) then
                    ew='e'
                    i = lon
                else
                    ew='w'
                    i = 360-lon
                endif
                if ( i.ge.100 ) then
                    write(infile,'(a,i1,a,i3,a,a)') 'surface/',abs(lat)
     +                    ,ns,i,ew,'.met'
                else
                    write(infile,'(a,i1,a,i2,a,a)') 'surface/',abs(lat)
     +                    ,ns,i,ew,'.met'
                endif
                inquire(file=infile,exist=lexist)
                if ( .not.lexist ) then
                    print *,'file ',infile(1:index(infile,' ')-1)
     +                    ,' does not exist'
                else
                    if ( iwrite.ge.0 ) print *,'Opening input file
     +                    ',infile(1:index(infile,' '))
                    open(1,file=infile,status='old',form='formatted')
c 
c       Read total number of days, depths and blocks of data.
c
                    read(1,10) nday, nblock
   10               format(49x,i5,6x,i3)
c
c       Read the missing data flag
c
                    read(1,20) flag
   20               format(59x,f6.1)
c
c       Read the data
c
                    do m = 1, nblock
                        read(1,30) n1, n2, nn
   30                   format(50x,i6,3x,i6,x,i6)
                        read(1,'(a)') line
                        line2 = line(25:55)
                        read(line2,*) depuwnd, depvwnd, deprh, depairt,
     +                        depsst
                        read(1,'(a)') header
                        do n = n1, n2
                            read(1,'(a)') line
 59                         continue
                            i = index(line,'******')
                            if ( i.ne.0 ) then
                                line(i:i+5) = '-99.90'
                                goto 59
                            endif
                            read(line,60) jdate, rlat,ns,rlon,ew,data
     +                           ,iqual
   60                       format(x,i8,x,f6.2,a1,f7.2,a1,3f6.1,2f6.2,x
     +                            ,6i1)
                            if ( ns.eq.'S' .and. rlat.ne.flag ) 
     +                            rlat = -rlat
                            if ( ew.eq.'W' .and. rlon.ne. flag ) 
     +                            rlon = 360 - rlon
                            yr = jdate/10000
                            mn = mod(jdate,10000)/100
                            dy = mod(jdate,100)
                            if ( yr.lt.firstyear .or. yr.gt.lastyear )
     +                            then
                                write(0,*) 'error: yr = ',yr,firstyear
     +                                ,lastyear
                                stop
                            endif
                            if ( mn.lt.1 .or. mn.gt.12 ) then
                                write(0,*) 'error: mn = ',mn
                                stop
                            endif
                            if ( dy.lt.1 .or. dy.gt.31 ) then
                                write(0,*) 'error: dy = ',dy
                                stop
                            endif
                            if ( rlat.eq.-99.9 .or. rlon.eq.-99.9 )
     +                            goto 200
                            if ( abs(rlat-lat).gt.0.3 .or. abs(rlon-lon)
     +                            .gt.3 ) then
                                print *,'discarded point: buoy drifted '
     +                                ,rlat,rlon,lat,lon
                                goto 200
                            endif
                            day = dy
                            do i=1,mn-1
                                day = day + dpm(i)
                            enddo
                            if (  iqual(2).ne.0 .and.
     +                            iqual(2).le.3 .and.
     +                            iqual(3).ne.0 .and.
     +                            iqual(3).le.3 ) then
                                if ( data(1).ne.flag ) 
     +                               windu(day,yr,ilat,ilon) = data(1)
                                if ( data(2).ne.flag )
     +                               windv(day,yr,ilat,ilon) = data(2)
                            endif
                            if (  iqual(4).ne.0 .and.
     +                            iqual(4).le.3 ) then
                                if ( data(3).ne.flag )
     +                               rh(day,yr,ilat,ilon) = data(3)
                            endif
                            if (  iqual(5).ne.0 .and.
     +                            iqual(5).le.3 ) then
                                if ( data(4).ne.flag )
     +                               airt(day,yr,ilat,ilon) = data(4)
                            endif
                            if (  iqual(6).ne.0 .and.
     +                            iqual(6).le.3 ) then
                                if ( data(5).ne.flag )
     +                               sst(day,yr,ilat,ilon) = data(5)
                            endif
                            if ( iwrite.ge.4 ) then
                                print '(i4,2i2.2,5f7.2)',yr,mn,dy,data
                            endif
  200                       continue ! comefrom: drifted
                        enddo   ! n lines (days)
                    enddo       ! m blocks
c
                    close(1)
                endif           ! file exists
            enddo               ! lon longitudes
        enddo                   ! lat latitudes
        if ( lintlatlon ) then
            do k=1,2
                ntimes = 366*(lastyear-firstyear+1)
                print *,'calling latlonint for windu'
                call latlonint(windu,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,-20.,20.)
                print *,'calling latlonint for windv'
                call latlonint(windv,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,-10.,10.)
                print *,'calling latlonint for rh'
                call latlonint(rh,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,0.,100.)
                print *,'calling latlonint for airt'
                call latlonint(airt,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,10.,35.)
                print *,'calling latlonint for SST'
                call latlonint(sst,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,10.,35.)
            enddo               ! repeat interpolation twice
        endif
c
c       Write out the temperature array to a grads file
*       TODO: only write out selected depths, latitudes, longitudes.
c
*       write output files
        if ( lintlatlon ) then
            extension='-dy.dat'
        else
            extension='-dy_raw.dat'
        endif
        call writeit('tao_windu'//extension,windu,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
        call writeit('tao_windv'//extension,windv,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
        call writeit('tao_rh'//extension,rh,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
        call writeit('tao_airt'//extension,airt,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
        call writeit('tao_sst'//extension,sst,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
c
        end
        

        subroutine writeit(name,field,nk,firstyear,lastyear,nlat,nlon
     +        ,iwrite)
        implicit none
#include "recfac.h"
        integer nk,firstyear,lastyear,nlat,nlon,iwrite
        real field(nk,366,firstyear:lastyear,nlat,nlon)
        character name*(*)
        integer,external :: leap
*
        integer nrec,yr,mn,ilat,ilon,k,lastyr,lastmn
*
        do lastyr=lastyear,firstyear,-1
            do lastmn=366,1,-1
                do ilat=1,nlat
                    do ilon=1,nlon
                        do k=1,nk
                            if ( field(k,lastmn,lastyr,ilat,ilon).lt
     +                           .1e33 ) then
                                print *,'found first defined point at '
     +                               ,k,lastmn,lastyr,ilat,ilon,field(k
     +                               ,lastmn,lastyr,ilat,ilon)
                                goto 100
                            endif
                        enddo
                    enddo
                enddo
            enddo
        enddo
 100    continue
*
        print *,'Opening output file ',name
     +        ,', recl = ',recfa4*nlat*nlon*nk
        open(2,file=name,form='unformatted',
     +        access='direct',recl=recfa4*nlat*nlon*nk)
        nrec = 0
        do yr=firstyear,lastyr
            do mn=1,366
                if ( yr.eq.lastyr .and. mn.gt.lastmn ) exit
                if ( leap(yr).eq.1 .and. mn.eq.31+29 ) cycle
                nrec = nrec + 1
                write(2,rec=nrec) (((field(k,mn,yr,ilat,ilon),
     +                ilon=1,nlon),ilat=1,nlat),k=1,nk)
            enddo
        enddo
        print *,'wrote ',nrec,' records'
        end
        
        subroutine makefieldabsent(field,n)
        implicit none
        integer i,n
        real field(n)
        do i=1,n
            field(i) = 3e33
        enddo
        end

	integer function leap(yr)
	implicit none
	integer yr
	if ( mod(yr,4).ne.0 ) then
	    leap = 1
	elseif ( mod(yr,100).ne.0 ) then
	    leap = 2
	elseif ( mod(yr,400).ne.0 ) then
	    leap = 1
	else	
	    leap = 2
	endif
	end


