      program cur_read
c
c This program reads site files of daily or hourly TAO/TRITON fixed 
c   depth currents, for example, cur0n110w_dy.ascii. It creates 
c   arrays u and v, which are evenly spaced in time, and arrays 
c   iuqual and ivqual which contain the data quality for each depth.
c
c You can easily adapt this program to your needs.
c
c Programmed by Dai McClurg, NOAA/PMEL/OCRD, August 1999
c
      implicit none
c
c NOTE: you may want to adjust the parameters nz,nt to match
c   the dimensions of your data
c
      integer nz, nt
      parameter(nz = 15, nt = 10000)
c
      real  u(nz,nt), v(nz,nt), s(nz,nt), d(nz,nt)
      integer iq1(nz,nt), iq2(nz,nt), isrc(nz,nt)
c
      real depth(nz)
      integer idate(nt), ihms(nt)
      integer kdep(nz), idep(nz), idum
c
      integer ndep, ntim
      integer k, n, m
      integer nblock, nk, nn, n1, n2
c
      real flag
c
      character infile*80, header*132, frmt*160
c
c .......................................................................
c
      write(*,*) ' Enter the input current file name'
      read(*,'(a)') infile
c
      open(1,file=infile,status='old',form='formatted')
c
c Read location indices, total number of days, depths and blocks of data.
c
      read(1,26) ntim, ndep, nblock
   26 format(55x,i5,7x,i3,8x,i3)
c
      write(*,*) ntim, ndep, nblock
c
c Read the missing data flag
c
      read(1,20) flag
   20 format(39x,f7.1)
      write(*,*) flag
c
c  Initialize arrays
c
      do k = 1, nz
        do n = 1, nt
           u(k,n) = flag
           v(k,n) = flag
           s(k,n) = flag
           d(k,n) = flag
          iq1(k,n) = 5
          iq2(k,n) = 5
          isrc(k,n) = 0
        enddo
      enddo
c
c Read the data
c
      do m = 1, nblock
        read(1,30) n1, n2, nn, nk
        call blank(frmt)
        write(frmt,140) 4*nk
        read(1,frmt) (kdep(k),idum,idum,idum,k=1,nk)
        call blank(frmt)
        write(frmt,150) 4*nk
        read(1,frmt) (idep(kdep(k)),idum,idum,idum,k=1,nk)
        do k = 1, nk
          depth(kdep(k)) = real(idep(kdep(k)))
        enddo
        read(1,'(a)') header
        call blank(frmt)
        write(frmt,160) 4*nk,3*nk
        write(*,'(a)') frmt
        do n = n1, n2
          read(1,frmt) idate(n), ihms(n), 
     .      (u(kdep(k),n),  v(kdep(k),n),
     .       s(kdep(k),n),  d(kdep(k),n),k=1,nk), 
     .    (iq1(kdep(k),n),iq2(kdep(k),n),isrc(kdep(k),n),k=1,nk)
        enddo
      enddo
c
  911 close(1)
c
   30 format(50x,i6,3x,i6,1x,i6,7x,i3)
c
c  140 format(15x,<4*nk>i6)
c  150 format(15x,<4*nk>i6)
c  160 format(x,i8,x,i4,x,<4*nk>f6.1,x,<3*nk>i1)
c
  140 format('(15x,',i3,'i6)')
  150 format('(15x,',i3,'i6)')
  160 format('(1x,i8,1x,i4,1x,',i3,'f6.1,1x,',i3,'i1)')
c
c Write out the depth, data, and quality arrays to the 
c   standard output. 
c
      write(*,*) 'depth = ', (depth(k),k=1,ndep)
c
c For some files this statement may be too long for your max output
c   record length on your terminal. If so, comment out these lines.
c
      call blank(frmt)
      write(frmt,70) 4*ndep, 3*ndep
c
      do n = 1, ntim
        write(*,frmt) idate(n), ihms(n),
     .             (   u(k,n),k=1,ndep),
     .             (   v(k,n),k=1,ndep),
     .             (   s(k,n),k=1,ndep),
     .             (   d(k,n),k=1,ndep),
     .             ( iq1(k,n),k=1,ndep),
     .             ( iq2(k,n),k=1,ndep), 
     .             (isrc(k,n),k=1,ndep),n
      enddo
c
   70 format('(1x,i8,1x,i6,1x,',i3,'f6.1,1x,',i3,'i1,i7)')
c
      end
c
c..............................................................
c
      subroutine blank(string)
c
c blank out the string from 1 to its declared length
c
      character*(*) string
c
      integer i
c
      do i = 1, len(string)
        string(i:i) = ' '
      enddo
c
      return
      end
