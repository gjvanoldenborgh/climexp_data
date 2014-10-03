      program surf_xyt_dy
c
c Read daily files like sst_xyt_dy.ascii, uwnd_xyt_dy.ascii, ...
c   from the TAO/TRITON data delivery page
c
      implicit none
c
      integer nx, ny, nt
      parameter(nx = 29, ny = 17, nt = 10000)
      real var(nx,ny,nt), lon(nx), lat(ny), flag
      integer iqual(nx,ny,nt), idate(nt)
c
      integer nlon, nlat, ntim
c
      integer i, j, n, iyr, imon, iday
c
      character*80 infile, header
c
c
c.......................................................................
c
      write(*,*) ' Enter the input file name'
      read(*,'(a)') infile
c
      open(1,file=infile,status='old',form='formatted')
c
c Read the missing data flag
c
      read(1,'(a)') header
      read(1,20) flag
   20 format(65x,f11.3)
      write(*,*) flag
c
c Read in the number of longitues, latitudes, and times
c
      read(1,22) nlon, nlat, ntim
   22 format(7x,i3, 8x,i3, 8x,i6)
      write(*,*) nlon, nlat, ntim
c
c Read in lon, lat, and depth axes
c
      read(1,23) (lon(i),  i=1,nlon)
      read(1,24) (lat(j),  j=nlat,1,-1)
   23 format(6x,<nlon>f6.1)
   24 format(6x,<nlat>f5.1)
c
      write(*,*) (lon(i),  i=1,nlon)
      write(*,*) (lat(j),  j=1,nlat)
c
c  Initialize ts array to flag and iqual array to 5.
c
      do i = 1, nx
        do j = 1, ny
          do n = 1, nt
              var(i,j,n) = flag
            iqual(i,j,n) = 5
          enddo
        enddo
      enddo
c
      do n = 1, ntim
        read(1,50) iyr, imon, iday
        idate(n) = iyr*10000 + imon*100 + iday
        do j = nlat, 1, -1
          read(1,*) (var(i,j,n),iqual(i,j,n),i=1,nlon)
        enddo
      enddo
   50 format(6x,i4,x,i2,x,i2)
c
      do n = 1, ntim
        write(*,*) idate(n)
        do j = nlat, 1, -1
          write(*,*) (var(i,j,n),iqual(i,j,n),i=1,nlon)
        enddo
      enddo
c
      end
