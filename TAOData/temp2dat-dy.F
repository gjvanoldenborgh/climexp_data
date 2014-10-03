        program tao2dat
        implicit none
#include "recfac.h"
        integer nz,nlat,nlon,firstyear
        parameter(nz = 42, nlat=10, nlon=19, firstyear=1980)
        integer ilat,ilon,i,j,k,l,m,n,n1,n2,nn,nk,yr,mn,dy,nday,ndep,day
     +        ,nblock,iq,jdate,iqual(nz),lat,lon,kdep(nz),ldep(nz),irec
     +        ,ihms,ihmsold,nmax,dpm(12),nt,lastyear,ii(8)
        integer iwrite,maxnt,ntimes
        real flag,depth(nz),t(nz)
        real,allocatable :: temp(:,:,:,:)
        logical lexist,lintdep,lintlatlon
        character infile*80, header*132, line*256
        character ns*1, ew*1, string*80, formatstring*40
#include "grid.h"
        data dpm /31,29,31,30,31,30,31,31,30,31,30,31/
        lintdep = .TRUE.
        lintlatlon = .TRUE.
        iwrite = 1
        ihmsold = -1

        call date_and_time(values=ii)
        lastyear = ii(1)
        nt = 366*(lastyear-firstyear+1)+1
        allocate(temp(nt,nz,nlat,nlon))
c
c       Initialize t array to flag and iqual array to our undefined
c
        temp = 3e33
*
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
                    write(infile,'(a,i1,a,i3,a,a)') 'temp/',abs(lat),ns
     +                    ,i,ew,'.tmp'
                else
                    write(infile,'(a,i1,a,i2,a,a)') 'temp/',abs(lat),ns
     +                    ,i,ew,'.tmp'
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
                    read(1,10) nday, ndep, nblock
   10               format(49x,i7,7x,i3,8x,i3)
c
c       Read the missing data flag
c
                    read(1,20) flag
   20               format(40x,f7.3)
c       
c       Read the data
c
                    do m = 1, nblock
                        read(1,30) n1, n2, nn, nk
   30                   format(50x,i8,3x,i8,x,i8,7x,i3)
                        if ( nk.gt.nz ) then
                            write(0,*) 'error: nk = ',nk,nz
                            stop
                        endif
                        read(1,40) (kdep(k),k=1,nk)
   40                   format(15x,1000i7)
                        do k=1,nk
                            if ( kdep(k).lt.1 .or. kdep(k).gt.nz ) then
                                write(0,*) 'error: kdep(',k,') = '
     +                                ,kdep(k),nz
                                stop
                            endif
                        enddo
                        read(1,'(a)') line
                        read(line(15:),*,end=901,err=901) 
     +                        (depth(kdep(k)),k=1,nk)
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
                            write(formatstring,'(a,i2,a,i2,a)') 
     +                           '(x,i8,x,i4,x,',nk,'f7.3,x,',nk,'i1)'
                            read(1,formatstring) jdate,ihms,(t(ldep(k))
     +                           ,k=1,nk),(iqual(ldep(k)),k=1,nk)
                            yr = jdate/10000
                            mn = mod(jdate,10000)/100
                            dy = mod(jdate,100)
                            if ( ihmsold.eq.-1 ) ihmsold = ihms
                            if ( ihms.ne.ihmsold ) then
                                write(0,*) 'error: hms was ',ihmsold,
     +                                ' but is ',ihms
                            endif
                            ihmsold = ihms
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
                            day = dy
                            do i=1,mn-1
                                day = day + dpm(i)
                            enddo
                            day = day + 366*(yr-firstyear)
                            do k=1,nk
                                if ( iqual(ldep(k)).ne.0 .and.
     +                               iqual(ldep(k)).le.3 ) then
                                    temp(day,ldep(k),ilat,ilon) =
     +                                t(ldep(k))
                                endif
                            enddo
                            if ( iwrite.ge.4 ) then
                                print '(i4,2i2.2,100f7.2)',yr,mn,dy
     +                               ,(temp(day,k,ilat,ilon),k=1,nz)
                            endif
                        enddo   ! n lines (days)
                    enddo       ! m blocks
                    close(1)
                    if ( lintdep ) then
                        do i=1,nt
                            do k=1,nz
                                t(k) = temp(i,k,ilat,ilon)
                            enddo
                            call depint(t,deps,nz,0)
                            do k=1,nz
                                temp(i,k,ilat,ilon) = t(k)
                            enddo
                        enddo   ! 5-day intervals
                    endif       ! depth interpolation requested
                endif           ! does file exist?
            enddo               ! lon longitudes
        enddo                   ! lat latitudes
        if ( lintlatlon ) then
            call latlonint(temp,nz*nt,nz*nt,nlat,nlon,lats,lons,iwrite,
     +           -2.,35.)
            call latlonint(temp,nz*nt,nz*nt,nlat,nlon,lats,lons,iwrite,
     +           -2.,35.)
        endif
*
*       find last year, month with data
*
        do nmax=366*(lastyear-firstyear+1),1,-1
            do ilat=1,nlat
                do ilon=1,nlon
                    do k=1,nk
                        if ( temp(nmax,k,ilat,ilon).lt.1e33 ) then
                            print *,'found first defined point at ',
     +                           nmax,k,ilat,ilon,temp(nmax,k,ilat,ilon)
                            goto 100
                        endif
                    enddo
                enddo
            enddo
        enddo
 100    continue
        open(1,file='tao-dy.dat',form='unformatted',access='direct'
     +        ,recl=nlon*nlat*nz*recfa4)
        irec = 0
        do n=1,nmax
            yr = firstyear + (n-1)/366
            if ( mod(yr,4).ne.0 .and. mod(n,366).eq.60 ) cycle
            irec = irec + 1
            write(1,rec=irec) (((temp(n,k,j,i),i=1,nlon),j=1,nlat),
     +           k=1,nz)
        enddo
        print *,'wrote ',irec,' records'
        close(1)
        stop
  901   print *,'error reading ',nk,' values from line ',line
        call abort
        end

