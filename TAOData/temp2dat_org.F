        program tao2dat
c
c       This program reads TAO anonymous FTP ascii-format temperature
c       files.  It interpolates the data in time, takes monthly averages
c       and next interpolates in depth and horizontally.
c
c       Based on temp_read by Dai McClurg, NOAA/PMEL/OCRD, April 1999
c
        implicit none
#include "recfac.h"
c
        integer nz, nt, nlat, nlon, firstyear, lastyear
        parameter(nz = 42, nt = 10000, nlat=10, nlon=19, firstyear=1980
     +        ,lastyear=2000)
c
        integer i,j,k,l,m,n,iq,yr,mn,dy,nrec
        integer nblock, nk, ndep, nn, nday, n1, n2, jdate, iqual(nz)
        integer kdep(nz),ldep(nz)
        integer ilat,ilon,lat,lon
        integer iwrite
        logical lexist
        real flag, depth(nz), t(nz), dtemp(nz,31,12,firstyear:lastyear),
     +        mtemp(nz,12,firstyear:lastyear,nlat,nlon)
        character infile*80, header*132, line*132, line2*132
        character ns*1, ew*1, string*80
        logical lintdep,lintlatlon
        integer iargc
        external iargc,getarg
#include "grid.h"
        iwrite = 0
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
                    print *,'tao2dat: unrecognized argument'
     +                    ,string(1:index(string,' ')-1)
                    stop
                endif
            enddo               ! loop over args
        else                    ! no args, defaults
            lintdep = .TRUE.
            lintlatlon = .TRUE.
        endif
*       open output file
        if ( iwrite.ge.0 ) print *,'Opening output file tao.dat'
        open(2,file='tao.dat',form='unformatted',
     +        access='direct',recl=recfa4*nlat*nlon*nz)
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
                    write(infile,'(i1,a,i3,a,a)') abs(lat),ns,i,ew
     +                    ,'.tmp'
                else
                    write(infile,'(i1,a,i2,a,a)') abs(lat),ns,i,ew
     +                    ,'.tmp'
                endif
                inquire(file=infile,exist=lexist)
                if ( .not.lexist ) then
                    print *,'file ',infile(1:index(infile,' ')-1)
     +                    ,' does not exist'
                    do yr=firstyear,lastyear
                        do mn=1,12
                            do k=1,nz
                                mtemp(k,mn,yr,ilat,ilon) = 3e33
                            enddo
                        enddo
                    enddo
                else
                    if ( iwrite.ge.0 ) print *,'Opening input file
     +                    ',infile(1:index(infile,' '))
                    open(1,file=infile,status='old',form='formatted')
c 
c       Read total number of days, depths and blocks of data.
c
                    read(1,10) nday, ndep, nblock
   10               format(49x,i5,6x,i3,8x,i3)
c
c       Read the missing data flag
c
                    read(1,20) flag
   20               format(40x,f7.2)
c       
c       Initialize t array to flag and iqual array to our undefined
c
                    do k = 1,nz
                        do yr=firstyear,lastyear
                            do mn=1,12
                                do dy=1,31
                                    dtemp(k,dy,mn,yr) = 3e33
                                enddo
                            enddo
                        enddo
                    enddo
c       
c       Read the data
c
                    do m = 1, nblock
                        read(1,30) n1, n2, nn, nk
                        if ( nk.gt.nz ) then
                            write(0,*) 'error: nk = ',nk,nz
                            stop
                        endif
   30                   format(50x,i6,3x,i6,x,i6,6x,i3)
                        read(1,40) (kdep(k),k=1,nk)
                        do k=1,nk
                            if ( kdep(k).lt.1 .or. kdep(k).gt.nz ) then
                                write(0,*) 'error: kdep(',k,') = '
     +                                ,kdep(k),nz
                                stop
                            endif
                        enddo
   40                   format(10x,<nk>i6)
                        read(1,'(a)') line
                        iq = index(line,'Q')
                        line2 = line(10:iq-1)
                        read(line2,*) (depth(kdep(k)),k=1,nk)
*       Added an extra lookup-table to convert to the same depths  for
c       all points
                        do k=1,nk
                            do l=1,nz
                                if ( depth(kdep(k)).eq.deps(l) ) then
                                    ldep(k) = l
                                endif
                            enddo
                        enddo
                        read(1,'(a)') header
                        do n = n1, n2
                            read(1,60) jdate, (t(ldep(k)),k=1,nk), 
     .                            (iqual(ldep(k)),k=1,nk)
   60                       format(x,i8,x,<nk>f6.2,x,<nk>i1)
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
                            do k=1,nk
                                if (  iqual(ldep(k)).ne.0 .and.
     +                                iqual(ldep(k)).le.3 ) then
                                    dtemp(ldep(k),dy,mn,yr) =
     +                                    t(ldep(k))
                                endif
                            enddo
                            if ( iwrite.ge.4 ) then
                                print '(i4,2i2.2,100f7.2)',yr,mn,dy
     +                                ,(dtemp(k,dy,mn,yr),k=1,nz)
                            endif
                        enddo   ! n lines (days)
                    enddo       ! m blocks
c
                    close(1)
                    call day2month(dtemp,mtemp(1,1,firstyear,ilat,ilon)
     +                    ,nz,firstyear,lastyear,0)
                    if ( lintdep ) then
                        do yr=firstyear,lastyear
                            do mn=1,12
                                if ( iwrite.ge.1 ) print *
     +                                ,'calling depint for ',yr,mn
                                call depint(mtemp(1,mn,yr,ilat,ilon)
     +                                ,deps,nz,0)
                            enddo ! months
                        enddo   ! years
                    endif       ! depth interpolation requested
                endif           ! file exists
            enddo               ! lon longitudes
        enddo                   ! lat latitudes
        if ( lintlatlon ) then
            call latlonint(mtemp,nz*12*(lastyear-firstyear+1),nlat,nlon
     +            ,lats,lons,iwrite,-2.,35.)
            call latlonint(mtemp,nz*12*(lastyear-firstyear+1),nlat,nlon
     +            ,lats,lons,iwrite,-2.,35.)
        endif
c
c       Write out the temperature array to a grads file
*       TODO: only write out selected depths, latitudes, longitudes.
c       
        nrec = 0
        do yr=firstyear,lastyear
            do mn=1,12
                nrec = nrec + 1
                write(2,rec=nrec) (((mtemp(k,mn,yr,ilat,ilon),
     +                ilon=1,nlon),ilat=1,nlat),k=1,nz)
            enddo
        enddo
c
        end
