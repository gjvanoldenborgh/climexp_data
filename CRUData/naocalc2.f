      program naocalc2
* calculates nao with respect to "arbitray base period"
* Iceland - Azores difference
* NB Standarisation on annual standard deviation!!
      parameter(long=3000)
      real th(long), da(long)
      real at(long), ad(long), so(long)
*
      nydat = 133
      ny1 =  97
      ny2 = 127
      iskip = 45
      open(1,file='nao_ice.dat')
      do i=1,iskip
         read(1,*)
      enddo
      do i=1,nydat
         read(1,*) ry, (da(12*(i-1)+k),k=1,12)
         if(i.eq.1.or.i.eq.nydat) write(6,*) ry
      enddo
      close(1)
*     
      iskip = 1 
      open(1,file='nao_azo.dat')
      do i=1,iskip
         read(1,*)
      enddo
      do i=1,nydat
         read(1,*) ry, (th(12*(i-1)+k),k=1,12)
         if(i.eq.1.or.i.eq.nydat) write(6,*) ry
         if(i.eq.ny1) iy1 = ry
         if(i.eq.ny2) iy2 = ry
      enddo
      iyend = ry
      iybeg = ry-nydat+1
      close(1)
*
      nm = 12*nydat
      do i=1,nm
         ad(i) = da(i)
         at(i) = th(i)
      enddo
      call       seasan(at,nm,ny1,ny2)
      call       seasan(ad,nm,ny1,ny2)
      do i=1,nm
         so(i) = at(i)-ad(i)
      enddo
      call       seasan(so,nm,ny1,ny2)
*
      open(3,file='naocalc2.dat')
      write(3,'(A,A/A,I4,A,I4,A)')'# NAO from Iceland and Azores    ',
     .  'pressure data.',
     .           '# calculated using ',iy1  ,'-',iy2  ,
     .           ' base period.'
      write(3,'(A)') '# standarisation as in SOI '
      write(3,*)
      iy = iybeg
      do i=1,nydat
         write(6,'(I4,12F6.1)') iy, (so(12*(i-1)+k),k=1,12)
         write(3,'(I4,12F6.1)') iy, (so(12*(i-1)+k),k=1,12)
         iy = iy + 1
      enddo
*
      end 

      subroutine seasan(x,n,n1,n2)
* calculates monthly anomalies, 
* either full (istan=0) or standarized (istan=1)
* with respect to the period n1 - n2 (years)
* for the months 1 - n 
      parameter(istan=1)
      real x(*)
      real bias(13),var(13)
*
      m1 = 12*(n1-1)+1
      m2 = 12*n2
*
      rt12 = real(n2-n1+1)
      rt   = 12*rt12
      write(6,*) rt12,rt
* 
      do mm=1,13
         bias(mm) = 0.
         var(mm)  = 0.
      enddo
* 
      mm = 1
      do i=m1,m2
         bias(mm) = bias(mm) + x(i)
         bias(13) = bias(13) + x(i)
         mm = mm + 1
         if(mm.eq.13) mm = 1
      enddo
      do mm=1,12
         bias(mm) = bias(mm)/rt12
      enddo
         bias(13) = bias(13)/rt
*
      mm = 1
      do i=1,n
         x(i) = x(i)-bias(mm)
         mm = mm + 1
         if(mm.eq.13) mm = 1
      enddo
*
      if(istan.eq.1) then
      mm = 1
      do i=m1,m2
         var(mm) = var(mm)+x(i)**2
         var(13) = var(13)+x(i)**2
         mm = mm + 1
         if(mm.eq.13) mm = 1
      enddo
      do mm=1,12
          var(mm) =  var(mm)/rt12
          write(6,*) mm, sqrt(var(mm))
      enddo
          var(13) =  var(13)/rt
*
      mm = 1
      do i=1,n
*++      x(i) = x(i)/sqrt(var(mm))
         x(i) = x(i)/sqrt(var(13))
         mm = mm + 1
         if(mm.eq.13) mm = 1
      enddo
      endif
*
      end


