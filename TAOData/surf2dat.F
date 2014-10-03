        program surf2dat
c
c       This program reads TAO anonymous FTP ascii-format surface data
c       files.  It interpolates the data in time, takes monthly averages
c       and next interpolates horizontally.
c
c       Based on met_read, temp_read by Dai McClurg, NOAA/PMEL/OCRD, April 1999
c
        implicit none
c
        integer nz, nt, nlat, nlon, firstyear
        parameter(nz = 42, nt = 10000, nlat=10, nlon=19, firstyear=1980)
c
        integer i,j,k,l,m,n,iq,yr,mn,dy,nrec
        integer nblock, nk, nn, nday, n1, n2, jdate, iqual(6)
        integer depuwnd,depvwnd,deprh,depairt,depsst
        integer ilat,ilon,lat,lon,ntimes,lastyear,ii(8)
        integer iwrite
        logical lexist
        real flag, t(nz), rlat,rlon,data(5)
        real, allocatable ::
     +        dwindu(:,:,:),mwindu(:,:,:,:),
     +        dwindv(:,:,:),mwindv(:,:,:,:),
     +        drh(:,:,:),mrh(:,:,:,:),
     +        dairt(:,:,:),mairt(:,:,:,:),
     +        dsst(:,:,:),msst(:,:,:,:)
        character infile*80, header*132, line*132, line2*132
        character ns*1, ew*1, string*80, extension*8
        logical lintlatlon
        integer iargc
        external getarg
#include "grid.h"
        iwrite = 0
        call date_and_time(values=ii)
        lastyear = ii(1)
	allocate(dwindu(31,12,firstyear:lastyear))
	allocate(mwindu(12,firstyear:lastyear,nlat,nlon))
	allocate(dwindv(31,12,firstyear:lastyear))
	allocate(mwindv(12,firstyear:lastyear,nlat,nlon))
	allocate(drh(31,12,firstyear:lastyear))
	allocate(mrh(12,firstyear:lastyear,nlat,nlon))
	allocate(dairt(31,12,firstyear:lastyear))
	allocate(mairt(12,firstyear:lastyear,nlat,nlon))
	allocate(dsst(31,12,firstyear:lastyear))
	allocate(msst(12,firstyear:lastyear,nlat,nlon))
c
c .......................................................................
*
*       process arguments
        if ( iargc().gt.0 ) then
            lintlatlon = .FALSE.
            do i=1,iargc()
                call getarg(i,string)
                if ( string(1:6).eq.'latlon' ) then
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
            lintlatlon = .TRUE.
        endif
*       loop over latitudes
        do ilat=1,nlat
            lat = lats(ilat)
*           loop over longitudes
            do ilon=1,nlon
                lon = lons(ilon)
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
                    call makefieldabsent(mwindu(1,firstyear,ilat,ilon)
     +                    ,12*(lastyear-firstyear+1))
                    call makefieldabsent(mwindv(1,firstyear,ilat,ilon)
     +                    ,12*(lastyear-firstyear+1))
                    call makefieldabsent(mrh(1,firstyear,ilat,ilon)
     +                    ,12*(lastyear-firstyear+1))
                    call makefieldabsent(mairt(1,firstyear,ilat,ilon)
     +                    ,12*(lastyear-firstyear+1))
                    call makefieldabsent(msst(1,firstyear,ilat,ilon)
     +                    ,12*(lastyear-firstyear+1))
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
c       Initialize arrays to our undefined
c
                    call makefieldabsent(dwindu,
     +                    31*12*(lastyear-firstyear+1))
                    call makefieldabsent(dwindv,
     +                    31*12*(lastyear-firstyear+1))
                    call makefieldabsent(drh,
     +                    31*12*(lastyear-firstyear+1))
                    call makefieldabsent(dairt,
     +                    31*12*(lastyear-firstyear+1))
                    call makefieldabsent(dsst,
     +                    31*12*(lastyear-firstyear+1))
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
                            if (  iqual(2).ne.0 .and.
     +                            iqual(2).le.3 .and.
     +                            iqual(3).ne.0 .and.
     +                            iqual(3).le.3 ) then
                                if ( data(1).ne.flag ) 
     +                                dwindu(dy,mn,yr) = data(1)
                                if ( data(2).ne.flag )
     +                                dwindv(dy,mn,yr) = data(2)
                            endif
                            if (  iqual(4).ne.0 .and.
     +                            iqual(4).le.3 ) then
                                if ( data(3).ne.flag )
     +                                drh(dy,mn,yr) = data(3)
                            endif
                            if (  iqual(5).ne.0 .and.
     +                            iqual(5).le.3 ) then
                                if ( data(4).ne.flag )
     +                                dairt(dy,mn,yr) = data(4)
                            endif
                            if (  iqual(6).ne.0 .and.
     +                            iqual(6).le.3 ) then
                                if ( data(5).ne.flag )
     +                                dsst(dy,mn,yr) = data(5)
                            endif
                            if ( iwrite.ge.4 ) then
                                print '(i4,2i2.2,5f7.2)',yr,mn,dy,data
                            endif
  200                       continue ! comefrom: drifted
                        enddo   ! n lines (days)
                    enddo       ! m blocks
c
                    close(1)
                    call day2month1(dwindu,mwindu(1,firstyear,ilat,ilon)
     +                    ,1,firstyear,lastyear,iwrite)
                    call day2month1(dwindv,mwindv(1,firstyear,ilat,ilon)
     +                    ,1,firstyear,lastyear,iwrite)
                    call day2month1(drh,mrh(1,firstyear,ilat,ilon)
     +                    ,1,firstyear,lastyear,iwrite)
                    call day2month(dairt,mairt(1,firstyear,ilat,ilon)
     +                    ,1,firstyear,lastyear,iwrite)
                    call day2month(dsst,msst(1,firstyear,ilat,ilon)
     +                    ,1,firstyear,lastyear,iwrite)
                endif           ! file exists
            enddo               ! lon longitudes
        enddo                   ! lat latitudes
        if ( lintlatlon ) then
            print *,'Interpolating latlon'
            do k=1,2
                ntimes = 12*(1+lastyear-firstyear)
                call latlonint(mwindu,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,-20.,20.)
                call latlonint(mwindv,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,-10.,10.)
                call latlonint(mrh,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,0.,100.)
                call latlonint(mairt,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,10.,35.)
                call latlonint(msst,ntimes,ntimes,nlat,nlon,lats,lons
     +               ,iwrite,10.,35.)
            enddo               ! repeat interpolation twice
        endif
c
c       Write out the temperature array to a grads file
*       TODO: only write out selected depths, latitudes, longitudes.
c
*       write output files
        if ( lintlatlon ) then
            extension='.dat'
        else
            extension='_raw.dat'
        endif
        call writeit('tao_windu'//extension,mwindu,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
        call writeit('tao_windv'//extension,mwindv,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
        call writeit('tao_rh'//extension,mrh,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
        call writeit('tao_airt'//extension,mairt,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
        call writeit('tao_sst'//extension,msst,1,firstyear,lastyear,
     +        nlat,nlon,iwrite)
c
        end
        

        subroutine writeit(name,field,nk,firstyear,lastyear,nlat,nlon
     +        ,iwrite)
        implicit none
#include "recfac.h"
        integer nk,firstyear,lastyear,nlat,nlon,iwrite
        real field(nk,12,firstyear:lastyear,nlat,nlon)
        character name*(*)
*
        integer nrec,yr,mn,ilat,ilon,k,lastyr,lastmn
*
        do lastyr=lastyear,firstyear,-1
            do lastmn=12,1,-1
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
        if ( iwrite.ge.0 ) print *,'Opening output file ',name
     +        ,', recl = ',recfa4*nlat*nlon*nk
        open(2,file=name,form='unformatted',
     +        access='direct',recl=recfa4*nlat*nlon*nk)
        nrec = 0
        do yr=firstyear,lastyr
            do mn=1,12
                if ( yr.eq.lastyr .and. mn.gt.lastmn ) exit
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

