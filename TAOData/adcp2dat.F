      program adcp_xyzt_dy
c
c This program reads 4 dimensional TAO/TRITON and PIRATA ascii-format
c   ADCP files, for example adcp_xyzt_dy.ascii. It creates arrays 
c   u and v, which are evenly spaced in time.
c
c You can easily adapt this program to your needs.
c
c Programmed by Dai McClurg, NOAA/PMEL/OCRD, August 1999
c
      implicit none
c
c NOTE: you may want to reduce the parameters nx,ny,nz,nt to match
c   the dimensions at the top of your file (nlon,nlat,ndep,ntim),
c   to conserve memory. These are maximum values
c
#include "recfac.h"
        integer nx, ny, nz, yrbeg, yrend
        parameter(nx = 7, ny = 1, nz = 100, yrbeg=1988, yrend=2002)
c
        real  u(nx,ny,nz,31,12,yrbeg:yrend), 
     +        v(nx,ny,nz,31,12,yrbeg:yrend),
     +        mu(nx,ny,nz,12,yrbeg:yrend), 
     +        mv(nx,ny,nz,12,yrbeg:yrend),
     +        uk(nz),vk(nz)
        real lon(nx), lat(ny+1), depth(nz)
        integer nlon, nlat, ndep, ntim, init, iuv,nrec
        integer i,j,k,n,m,mm,k1,k2,ilon, jlat, yr,mo,dy,yr1,mo1,dy1
        integer nblock, nk, nn, ntimb, ndepb, n1, n2, nl
        real depthb(nz)
        integer kdep(nz), idep(nz)
        integer idate, ihms
        real flag
        character file*80, header*132
        integer llen
        external llen
*
        data init /0/
c
c .......................................................................
c
        open(1,file='currents/adcp_xyzt_dy.ascii',status='old')
c
c Read the missing data flag
c
        read(1,'(a)') header
        read(1,20) flag
   20   format(60x,f7.1)
        read(1,'(a)') header
c
c Read in the number of longitues, latitudes, depths, and times
c
        read(1,22) nlon, nlat, ndep, ntim
   22   format(7x,i3, 8x,i3, 8x,i3, 8x,i5)
c
c Read in lon, lat, and depth axes
c
        read(1,23) (lon(i),  i=1,nlon)
        read(1,24) (lat(j),  j=1,nlat)
        print *,'adjusted nlat to 1'
        nlat = 1
        nl = 1 + int(real(ndep) / 8.0)
        read(1,25) (depth(k),k=1,ndep)
   23   format(6x,<nlon>f4.0)
   24   format(6x,<nlat>f4.0)
   25   format(<nl>(13x,8f7.0,/))
  125   format(8x,i4,2i3,5x,i4,2i3)
        read(1,125) yr,mo,dy,yr1,mo1,dy1
  225   format(a,i4,2i3,a,i4,2i3)
        write(*,'(a,i4,2i2.2,a,i4,2i2.2)') 'Time = ', yr,mo,dy,' to '
     +        ,yr1,mo1,dy1
        if ( yr.lt.yrbeg ) then
            print *,'error: adjust yrbeg to ',yr
            call abort
        endif
        if ( yr1.gt.yrend ) then
            print *,'error: adjust yrbeg to ',yr1
            call abort
        endif
c       
        do iuv=1,2
            if ( iuv.eq.1 ) then
                file = 'tao_adcpu.ctl'
            else
                file = 'tao_adcpv.ctl'
            endif
            open(2,file=file)
            k = llen(file)
            file(k-2:k) = 'dat'
            write(2,'(2a)') 'DSET ^',file(1:k)
            write(2,'(a)') 'TITLE TAO ADCP current data'
            write(2,'(a)') 'OPTIONS BIG_ENDIAN'
            write(2,'(a)') 'UNDEF 3e33'
            write(2,'(a,i4,a,100i4)') 'XDEF ',nlon,' LEVELS ',
     +            (nint(lon(i)),i=1,nlon)
            write(2,'(a,i4,a,100i4)') 'YDEF ',nlat,' LEVELS ',
     +            (nint(lat(j)),j=1,nlat)
            write(2,'(a,i4,a,100i4)') 'ZDEF ',ndep,' LEVELS ',
     +            (nint(depth(k)),k=1,1)
            write(2,'(20i4)') (nint(depth(k)),k=2,ndep)
            write(2,'(a,i4,a,i4,a)') 'TDEF ',12*(yr1-yr+1)
     +            ,' LINEAR 15JAN',yr,' 1MO'
            write(2,'(a)') 'VARS 1'
            if ( iuv.eq.1 ) then
                write(2,'(a,i4,a)') 'u ',ndep,
     +                ' 99 zonal velocity [cm/s]'
            else
                write(2,'(a,i4,a)') 'v ',ndep,
     +                ' 99 meridional velocity [cm/s]'
            endif
            write(2,'(a)') 'ENDVARS'
            close(2)
        enddo
c       
c
c  Initialize arrays.
c
        do i = 1, nx
            do j = 1, ny
                do k = 1, nz
                    do dy=1,31
                        do mo=1,12
                            do yr=yrbeg,yrend
                                u(i,j,k,dy,mo,yr) = 3e33
                                v(i,j,k,dy,mo,yr) = 3e33
                            enddo
                        enddo
                    enddo
                enddo
            enddo
        enddo
c
        do mm = 1, 5000         ! large enough to be sure of getting all sites
c
c Read location indices, total number of days, depths and blocks of data.
c
            read(1,26,end=911) ilon, jlat, ntimb, ndepb, nblock
   26       format(21x,i2,x,i2,30x,i5,7x,i3,8x,i3)
            write(*,'(a,f7.0,a,f7.0,a,i7)') 'lat ',lat(jlat),' lon '
     +            ,lon(ilon),' #days ',ntimb
c       
c       Read the data
c       
            do m = 1, nblock
                read(1,30) n1, n2, nn, nk
                nl = int(real(nk) / 8.0)
                read(1,140) (kdep(k),k=1,nk)
                read(1,150) (idep(kdep(k)),k=1,nk)
                do k = 1, nk
                    depthb(kdep(k)) = real(idep(kdep(k)))
                enddo
                read(1,'(a)') header
                do n = n1, n2
                    nl = int(2*real(nk) / 8.0)
                    read(1,160) idate, ihms,
     +                    (uk(kdep(k)),vk(kdep(k)),k=1,nk)
                    if ( lat(jlat).ne.0 ) then
                        if ( init.eq.0 ) then
                            init = 1
                            print *,'skipping off-equatorial buoy at '
     +                            ,lat(jlat),lon(ilon)
                        endif
                    else
                        yr = idate/10000
                        mo = mod(idate,10000)/100
                        dy = mod(idate,100)
                        if ( ihms.ne.1200 ) then
                            print *,'warning: hms != 1200 but ',ihms
                        endif
                        do k=1,nk
                            if ( uk(kdep(k)).ne.flag ) 
     +                            u(ilon,jlat,kdep(k),dy,mo,yr) =
     +                            uk(kdep(k))
                            if ( vk(kdep(k)).ne.flag ) 
     +                            v(ilon,jlat,kdep(k),dy,mo,yr) =
     +                            vk(kdep(k))
                        enddo
                    endif
                enddo
            enddo
c       
        enddo
  911   close(1)
c
   30   format(50x,i6,3x,i6,x,i6,7x,i3)
  140   format(13x,8i7,<nl>(/,13x,8i7))
  150   format(13x,8i7,<nl>(/,13x,8i7))
  160   format(x,i8,x,i4,8f7.2,<nl>(/,14x,8f7.2))
c
c       check the depths are the same (should really be done each time
c       they are read in...)
c       
        do k=1,ndep
            if ( depth(k).ne.depthb(k) ) then
                print *,'error: depths do not agree: ',k,depth(k)
     +                ,depthb(k)
                call abort
            endif
        enddo
c       
c       convert to monthly arrays
c       
        print *,'computing monthly values'
        call day2month(u,mu,nx*ny*nz,yrbeg,yrend,0)
        call day2month(v,mv,nx*ny*nz,yrbeg,yrend,0)
c       
c       write to file
c       
        print *,'Writing to file'
        open(2,file='tao_adcpu.dat',access='direct',recl=nlon*nlat*ndep
     +       *recfa4)
        nrec = 0
        do yr=yrbeg,yrend
            do mo=1,12
                nrec = nrec + 1
                write(2,rec=nrec) (((mu(i,j,k,mo,yr),
     +               i=1,nlon),j=1,nlat),k=1,ndep)
            enddo
        enddo
        close(2)
        open(2,file='tao_adcpv.dat',access='direct',recl=nlon*nlat*ndep
     +       *recfa4)
        nrec = 0
        do yr=yrbeg,yrend
            do mo=1,12
                nrec = nrec + 1
                write(2,rec=nrec) (((mv(i,j,k,mo,yr),
     +               i=1,nlon),j=1,nlat),k=1,ndep)
            enddo
        enddo
        close(2)
*
        end
