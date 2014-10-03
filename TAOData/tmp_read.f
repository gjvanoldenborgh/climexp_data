      program tmp_read
c
c This program reads TAO anonymous FTP ascii-format temperature
c   files, for example 8n110w.tmp. It creates an array called t, 
c   which is evenly spaced in time, and an array called iqual
c   which contains the data quality for each depth.
c
c You can easily adapt this program to your needs.
c
c Programmed by Dai McClurg, NOAA/PMEL/OCRD, April 1999
c
      implicit none
c
      integer nz, nt
      parameter(nz = 30, nt = 10000)
c
      integer k, n, m, iq
c
      integer nblock, nk, ndep, nn, nday, n1, n2
c
      integer kdep(nz), iqual(nz,nt), idate(nt)
c
      real flag, depth(nz), t(nz,nt)
c
      character infile*80, header*132, line*132, line2*132
c
c .......................................................................
c
      write(*,*) ' Enter the input tmp file name '
      read(*,'(a)') infile
c
      open(1,file=infile,status='old',form='formatted')
c 
c Read total number of days, depths and blocks of data.
c
      read(1,10) nday, ndep, nblock
   10 format(49x,i5,6x,i3,8x,i3)
c
      write(*,*) nday, ndep, nblock
c
c Read the missing data flag
c
      read(1,20) flag
   20 format(40x,f7.2)
c
      write(*,*) flag
c
c  Initialize t array to flag and iqual array to 5.
c
      do k = 1, nz
        do n = 1, nt
          t(k,n) = flag
          iqual(k,n) = 5
        enddo
      enddo
c
c Read the data
c
      do m = 1, nblock
        read(1,30) n1, n2, nn, nk
        read(1,40) (kdep(k),k=1,nk)
        read(1,'(a)') line
        iq = index(line,'Q')
        line2 = line(10:iq-1)
        read(line2,*) (depth(kdep(k)),k=1,nk)
        read(1,'(a)') header
        do n = n1, n2
          read(1,60) idate(n), (t(kdep(k),n),k=1,nk), 
     .                 (iqual(kdep(k),n),k=1,nk)
        enddo
      enddo
c
   30 format(50x,i6,3x,i6,x,i6,6x,i3)
   40 format(10x,<nk>i6)
   50 format(<nk>i6)
   60 format(x,i8,x,<nk>f6.2,x,<nk>i1)
c
      close(1)
c
c Write out the depth, temperature, and quality arrays to the 
c   standard output. 
c
      write(*,*) 'depth = ', (depth(k),k=1,ndep)
c
c For some files this statement may be too long for your max output
c   record length on your terminal. If so, comment out these lines.
c
      do n = 1, nday
        write(*,70) idate(n), (t(k,n),k=1,ndep),
     .                 (iqual(k,n),k=1,ndep), n
      enddo
c
   70 format(x,i8,x,<ndep>f6.2,x,<ndep>i1,i7)
c
      end
      
