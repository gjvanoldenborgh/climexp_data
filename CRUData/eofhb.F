c  #[ prog
c23456789012345678901234567890123456789012345678901234567890123456789012
c     Hans Bonekamp 1998

      program eofhb
      
      implicit none
      integer  mxy,mcol
 
c     ------------------------------------------------ 
c      average of timeseries is subtracted to create anomalies
c      eigenvalues are calculated from the scatter matrix

c     i loops  fields       ( with absents ndim, without, nred)
c     j loops  timeseries   (length ncol)


c      npc0 = min (ncol,nred)   Max # EOFS
C      npc                      required # EOFS (input)

c      501   w*w                eigenvalue      
c      502   w*w/ncol           variances 
c      503   amat(.,.)          npc eigenvectors os scatter matrix (EOF patterns)
c      504   timeseries         belong to first npc EOFS
c      505   percentages        belong to the npc0 EOFS
c      506   cum. percentages   belong to the npc0 EOFS
c      507   averages         
c      525   recalculation of mean  for the npc0 ts 
c      526   recalculation of explained  variance for the npc0 EOFS
c      527   difference    of explained  variance for the npc0 EOFS 
c
c      603   = 503        multiplied with corresponding standard deviation 
c      604   = 504        divided by  corresponding standard deviation 
c
c      705  percentages (euclidean)     
c      706  cummulative percentages  (euclidean)
c      725   = 525  (euclidean)
c      726   = 526  (euclidean)
c      727   =  527  (euclidean) - w*w/ncol
c      728   =  variance  (euclidean) - (corrected) 
c     ------------------------------------------------ 

#include "absent.h"

      parameter(mxy=4000)
      parameter(mcol=500)      

      integer       ncol,long,lati,numdat,iinput
      integer       minper,ndim,nred,npc, npc0
      integer       i,j,k,i1,i2,i3,i4,ierr
      integer       icnt(mxy),iadres(mxy), indx(mcol)
      real          xvar7(mcol), xvar5(mcol)
      real          finput, f4(mxy), rla0,dla
      real          pi,pl0,pdl
      real          f(mxy),dummy(mxy)
      real          totvar5,rtotvar5,totvar7,rtotvar7
      real          w(mcol),dotpro(mxy),amat(mxy,mcol),aavg(mxy)
      real          absen,sum,sume,perc,rncol,rndim
      character*7   mode   
      character*128 outfile,infile,ainput 
      logical       ex

c     -------------------------------------------------------------------

      absen   =0.9*absent
      mode    = 'nocorre'
      call inputt(5,numdat)
      infile  = ainput()
      outfile = ainput()
      minper  = iinput()
      npc     = iinput()
      mode    = ainput()
      write(6,*) 'EOFSVD        '
      write(6,*) '------------- '
      write(6,*) 'in     ',  infile
      write(6,*) 'out    ',  outfile
      write(6,*) 'perc   ',  minper
      write(6,*) 'npc    ',  npc 
      write(6,*) 'mode   ',  mode
      write(6,*) 'absent ',  absent

c     ---------------------------------

      open(1,file=infile,form='unformatted')
      read(1) i1,i2,i3,i4
      rewind(1)
      ndim = i4
      if (ndim.gt.mxy) then
        write(6,*)  'mxy too small '
        call abort
      endif

      do i=1,ndim
        icnt(i)=0
        aavg(i)=0.0d0
      enddo

      ncol = 0
      do j=1,mcol+1
        read(1,end=999) i1,i2,i3,i4
        read(1) (f4(i),i=1,i4)
        do i=1,i4
          f(i) = f4(i)*1.0d0
        enddo
        do i=1,i4
          if (f(i).lt.absen) then 
             icnt(i) = icnt(i)+1
             aavg(i) = aavg(i)+f(i)           
          endif
        enddo
        ncol = ncol + 1
      enddo       
      write(6,*)  'mcol too small '
      call abort
999   continue
      rewind(1)

      rncol = real(ncol) 
      rndim = real(ndim)
      nred = 0
      do i=1,ndim
        if (icnt(i).ne.0) then     
          aavg(i) = aavg(i) / real(icnt(i))
          perc = 100.0* (real(icnt(i))/ rncol ) 
          if ( perc.ge.real(minper) ) then
            nred=nred+1
            iadres(nred)=i
          endif
        else  
          aavg(i) = absent 
        endif
      enddo

      npc0 = min(nred,ncol)
      write(6,*) '# length timeseries      : ',ncol
      write(6,*) '# full    dimension      : ',ndim
      write(6,*) '# reduced dimension      : ',nred
      write(6,*) '# max # eigenvalues <> 0 : ',npc0


c     LATITUDINAL CORRECTION
c     ------------------------

      if ( mode(1:7).eq.'laticor') then
        call inputt(5,numdat)
        long = iinput()
        lati = iinput()
        rla0 = finput()
        dla  = finput()
        pi   = 3.1415926535898
        pl0  = rla0*pi/180.
        pdl  = dla*pi/180.

        write(6,12) long,lati,rla0,dla,
     ,            rla0+(lati-1)*dla,
     ,            (sqrt(cos(pl0+(j-1)*pdl)),j=1,lati)
 12     format('# longitude:',i4,' # latitude:',i4,/,
     ,       'latitude of first row:',f10.4,' increment:',f10.4,/,
     ,       'latitude of last row:',f10.4,/,
     ,       'Latitudinal weights:',(t21,10f6.2))
      
        if (long*lati.ne.ndim) then
           write(6,*) 'inconsistency long/lati <-> dimension '
           call abort
        end if
        k=0
        do j=1,lati
          do i=1,long
            k=k+1
            dotpro(k)=cos(pl0+(j-1)*pdl)
          enddo
        enddo
      else
        do k=1,ndim
          dotpro(k)=1.0
        enddo
        write(6,*) 'DOTPRO(*) = 1.0 '
      endif


c     FILL MATRIX
c     ------------
      call compress(dotpro,mxy,ndim,nred,iadres)
      do j=1, ncol
        read(1) i1,i2,i3,i4
        read(1) (f4(i),i=1,i4)
        do i=1,i4
          f(i) = f4(i)*1.0d0
          f(i) = f(i) - aavg(i)
        enddo
          
        call compress(f,mxy,ndim,nred,iadres)       
        do i=1,nred
          amat(i,j)=sqrt(dotpro(i))*f(i)   
        enddo 
      enddo
      rewind(1)


c     SVD
c     ------------
      call svd(mxy,nred,ncol,amat,w,.true.,amat,.false.,
     &          amat,ierr,dummy)
      write(6,*)  'eofsvd: SVD error code ierr=',ierr


c     SORT and go back to Euclidean space
c     ------------      

      write(6,*)  'eofsvd: sorting... :'

      call inx(w,indx,ncol)

      do j=1,ncol
        dummy(j)=w(j)
      enddo
      do  j=1,ncol
        w(j)=dummy(indx(j))
      enddo

      do  i=1,nred
        do  j=1,ncol
          dummy(j)=amat(i,j)
        enddo
        do  j=1,ncol
          if  (dotpro(i).gt.0.0d0) then  
             amat(i,j)=dummy(indx(j))/sqrt(dotpro(i))
          else  
             amat(i,j)=0.0d0
          endif
        enddo
      enddo 

c     DECOMPRESS
c     ------------      

      call decompress(dotpro,mxy,ndim,nred,iadres)
      do j=1,npc0
        call decompress(amat(1,j),mxy,ndim,nred,iadres)
      enddo

c     output
c     ----------------------------------------

      npc= min(npc,npc0)
      do j=1,npc0
        xvar5(j) = 0.0d0
        xvar7(j) = 0.0d0
      enddo    


      open(2,file=outfile,form='unformatted')

*     inner product and average field
      write(2) 1,507,0,ndim
      write(2) ( aavg(i) ,i=1,ndim)
      write(2) 1,508,999,ndim
      write(2) (dotpro(i),i=1,ndim)

      do j=1,npc
*       eigenvectors
        write(2) j,503,999,ndim
        write(2) (amat(i,j),i=1,ndim)
*       patterns normalized with standard deviation
*       patterns normalized with standard deviation
        do i=1,ndim
          if (amat(i,j).le.absen) then 
            dummy(i)=amat(i,j)*w(j)/sqrt(rncol)
          else 
            dummy(i) = absent
          endif
        enddo 
        write(2) j,603,999,ndim
        write(2) (dummy(i),i=1,ndim)     
      enddo

 
c     coefficients and calculation of variances

      rewind(1)
      do k=1,ncol

         read(1,end=30) i1,i1,i1,i4
         read(1) (f4(i),i=1,i4)
         do i=1,i4
           f(i) = f4(i)*1.0d0
           f(i) = f(i)-aavg(i)
         enddo

         do j=1,npc0
           dummy(j)= 0.0d0
           do i=1,ndim
              if (f(i).le.absen.and.dotpro(i).le.absen) then
                 dummy(j)=dummy(j) + dotpro(i)*amat(i,j)*f(i)
              endif
           enddo
           xvar5(j) = xvar5(j) + dummy(j)*dummy(j)
         enddo

*        ts belonging to eigenvectors
         write(2) k,504,999,npc
         write(2) (dummy(j),j=1,npc)

*        ts belonging to patterns normalized with standard deviation
         write(2) k,604,999,npc
         write(2) (dummy(j)*sqrt(rncol)/w(j),j=1,npc)

         do j=1,npc0
           dummy(j)=0.0d0
           do i=1,ndim
               if (f(i).le.absen.and.dotpro(i).le.absen) then
                 dummy(j) = dummy(j) + amat(i,j)*f(i)
               endif
           enddo
           xvar7(j) = xvar7(j) + dummy(j)*dummy(j)
         enddo

*        ts: Euclidean projection of field on the eigenvector
         write(2) k,704,999,npc
         write(2) (dummy(j),j=1,npc)

         do i=1,ndim
           if (f(i).le.absen.and.dotpro(i).le.absen) then
             totvar5 = totvar5  + dotpro(i)*f(i)*f(i)
             rtotvar5= rtotvar5 + 1.0d0
             totvar7 = totvar7  + f(i)*f(i)
             rtotvar7= rtotvar7 + 1.0d0
           endif
         enddo

      enddo 
30    continue



c     (cummulative)  scatter/variance
c     -------------------------------

      totvar5 = totvar5/rncol
      totvar7 = totvar7/rncol
      do j=1,npc0
        sum=0.0d0
        sume=0.0d0
        do i=1,ndim
          if (f(i).le.absen.and.dotpro(i).le.absen) then
             sum = sum + dotpro(i)
             sume = sume + 1.0d0
          endif
        enddo
        xvar5(j) = xvar5(j)/rncol
        xvar7(j) = (sum/sume)*xvar7(j)/rncol
      enddo    

      sume=xvar5(1)
      dummy(1) = w(1)*w(1)
      do i =2,npc0
         dummy(i) =  dummy(i-1) +  w(i)*w(i) 
         sume =  sume+xvar5(i)
      enddo
      sum = dummy(npc0)


*     eigenvalue
      write(2) 1,501,999,npc0
      write(2) ( w(i)*w(i) ,i=1,npc0)
*     variances
      write(2) 1,502,999,npc0
      write(2) ( w(i)*w(i)/rncol, i=1,npc0)
*     percentages
      write(2) 1,505,999,npc0
      write(2) ( w(i)*w(i)*(100.0/sum),i=1,npc0)
*     cummulative percentages
      write(2) 1,506,999,npc0
      write(2) ( dummy(i)*(100.0/sum),i=1,npc0)
c     variance projection
      write(2) k,526,999,npc
      write(2) (xvar5(i),i=1,npc0)
c     variance difference 
      write(2) k,527,999,npc
      write(2) (xvar5(i) - w(i)*w(i)/rncol,i=1,npc0)

      write(6,*)'TOTAL VARIANCE:'
      write(6,*) '     ', sume
      write(6,*)'TOTAL  VARIANCE: EOFS '
      write(6,*) '     ', sum/rncol
      write(6,*)'TOTAL PROJECTION VARIANCE: '
      write(6,*) '     ', totvar5
      write(6,*)'TOTAL VARIANCE - TOTAL VARIANCE EOFS '
      write(6,*) '     ', sume - sum/rncol
      write(6,*)'TOTAL PROJECTION VARIANCE - TOTAL VARIANCE EOFS '
      write(6,*) '     ', totvar5-sum/rncol
      write(6,*)'TOTAL PROJECTION VARIANCE - TOTAL VARIANCE'
      write(6,*) '     ', totvar5-sume
      write(6,*),'PERCENTAGES :'      
      write(6,'(8f10.4)') ( w(i)*w(i)*(100.0/sum),i=1,npc0)
      write(6,*)'CUMMULATIVE PERCENTAGES :'      
      write(6,'(8f10.4)') ( dummy(i)*(100.0/sum),i=1,npc0)
      write(6,*)'EIGENVALUES :  #= ', npc0  
      write(6,'(8e10.3)') (w(i)*w(i),i=1,npc0)
      write(6,*)'VARIANCES :  #= ', npc0  
      write(6,'(8e10.3)') (w(i)*w(i)/rncol,i=1,npc0)
      write(6,*)'PROJECTION VARIANCES :  #= ', npc0  
      write(6,'(8e10.3)') (xvar5(i),i=1,npc0)
      write(6,*)'VARIANCE DIFF with  w*w/ncol: '
      write(6,'(8e10.3)') (xvar5(i)- w(i)*w(i)/rncol,i=1,npc0) 


*     total Euclidean variance by sommation
c     --------------------------------------------
      dummy(1) = xvar7(1)
      do i =2,npc0
         dummy(i) =  dummy(i-1) + xvar7(i) 
      enddo
      sume = dummy(npc0)

*     percentages (euclidean)
      write(2) 1,705,999,npc0
      write(2) (  xvar7(i)*(100.0/sume),i=1,npc0)
*     cummulative percentages  (euclidean)
      write(2) 1,706,999,npc0
      write(2) ( dummy(i)*(100.0/sume),i=1,npc0)
c     variance Euclidean projection
      write(2) k,726,999,npc
      write(2) (xvar7(i),i=1,npc0)
c     variance difference:  Euclidean - w*w/ncol
      write(2) k,727,999,npc
      write(2) (xvar7(i) - w(i)*w(i)/rncol,i=1,npc0)
c     variance difference: Euclidean - projection var.
      write(2) k,728,999,npc
      write(2) (xvar7(i)- xvar5(i),i=1,npc0)

      write(6,*)'TOTAL EUCLIDEAN VARIANCE:'
      write(6,*) '    ', sume
      write(6,*)'TOTAL EUCLIDEAN PROJECTION VARIANCE: '
      write(6,*) '     ', totvar7
      write(6,*)'TOTAL EUCLIDEAN VARIANCE DIFF '
      write(6,*) '     ', totvar7-sume
      write(6,*),'PERCENTAGES (euclidean) :'      
      write(6,'(8f10.4)') ( xvar7(i)*(100.0/sume),i=1,npc0)
      write(6,*)'CUMMULATIVE PERCENTAGES (euclidean):'      
      write(6,'(8f10.4)') ( dummy(i)*(100.0/sume),i=1,npc0)
      write(6,*)'PROJECTION VARIANCES (euclidean):  #= ', npc0  
      write(6,'(8e10.3)') (xvar7(i),i=1,npc0)
      write(6,*)'VARIANCE DIFF: Euclidean with  w*w/ncol: '
      write(6,'(8e10.3)') (xvar7(i)- w(i)*w(i)/rncol,i=1,npc0) 
      write(6,*)'VARIANCE DIFF: Euclidean with projection variance: '
      write(6,'(8e10.3)') (xvar7(i)-xvar5(i),i=1,npc0) 


*  #]
      close(1)

      end
      
c  #] prog 



c  #[ compress            
      

c23456789012345678901234567890123456789012345678901234567890123456789012      

      subroutine decompress(f,mxy,ndim,nred,iadres)
      implicit none

#include "absent.h"      
      integer  mxy
      real*8    absen
        integer mxymax
        parameter (mxymax=4000)
      integer  ndim,nred,iadres(*),i
      real*8     f(*),g(mxymax)
      
      absen=0.9*absent
      
        if ( mxy.gt.mxymax ) then
            print *,'decompress: increase mxymax to ',mxy
            stop
        endif
      do i=1,mxy
        g(i)=f(i)
        f(i)=absent
      enddo
      
      do i=1,nred
        f(iadres(i))=g(i)
      enddo

      return
      end

      
      
c23456789012345678901234567890123456789012345678901234567890123456789012      


      subroutine compress(f,mxy,ndim,nred,iadres)
      implicit none
      
#include "absent.h"
      integer  mxy
      real*8    absen
      
      integer  ndim,nred,iadres(*),i
      real*8     f(*)      

      absen=0.9*absent
      
      do i=1,nred
        f(i)=f(iadres(i))
      enddo

      return
      end

c  #] compress            
c  #[ inx
c23456789012345678901234567890123456789012345678901234567890123456789012      

      subroutine inx(ra,indx,n)
      implicit none


      integer   indx(*),i,j,n,l,ir,indxt      
      real*8       ra(*),q

      
      do 10 j=1,n
        indx(j)=j
   10 continue
      l=n/2+1
      ir=n
  100 continue
        if (l.gt.1) then
          l=l-1
          indxt=indx(l)
          q=ra(indxt)
        else
          indxt=indx(ir)
          q=ra(indxt)
          indx(ir)=indx(1)
          ir=ir-1
          if (ir.eq.1) then
            indx(1)=indxt
            return
          end if
        end if
        i=l
        j=l+l
  200   if (j.le.ir) then
          if (j.lt.ir) then
            if (ra(indx(j)).gt.ra(indx(j+1))) j=j+1
          end if
          if (q.gt.ra(indx(j))) then
            indx(i)=indx(j)
            i=j
            j=j+j
          else
            j=ir+1
          end if
          goto 200
        end if
        indx(i)=indxt

      goto 100

      end
 

c  #] inx
c  #[ svd  routine
      subroutine svd(nm,m,n,a,w,matu,u,matv,v,ierr,rv1)


      implicit none

chb
chb   originally just the value 30 in code, I have put it in this  constant  

      integer itsmax
      parameter (itsmax =2000)

chb 

      integer i,j,k,l,m,n,ii,i1,kk,k1,ll,l1,mn,nm,its,ierr
      real*8 a(nm,*),w(*),u(nm,*),v(nm,*),rv1(*)
      real*8 c,f,g,h,s,x,y,z,scale,anorm
      logical matu,matv


c
c     this subroutine is a translation of the algol procedure svd,
c     num. math. 14, 403-420(1970) by golub and reinsch.
c     handbook for auto. comp., vol ii-linear algebra, 134-151(1971).
c
c     this subroutine determines the singular value decomposition
c          t
c     a=usv  of a real m by n rectangular matrix.  householder
c     bidiagonalization and a variant of the qr algorithm are used.
c
c     on input.
c
c        nm must be set to the row dimension of two-dimensional
c          array parameters as declared in the calling program
c          dimension statement.  note that nm must be at least
c          as large as the maximum of m and n.
c
c        m is the number of rows of a (and u).
c
c        n is the number of columns of a (and u) and the order of v.
c
c        a contains the rectangular input matrix to be decomposed.
c
c        matu should be set to .true. if the u matrix in the
c          decomposition is desired, and to .false. otherwise.
c
c        matv should be set to .true. if the v matrix in the
c          decomposition is desired, and to .false. otherwise.
c
c     on output.
c
c        a is unaltered (unless overwritten by u or v).
c
c        w contains the n (non-negative) singular values of a (the
c          diagonal elements of s).  they are unordered.  if an
c          error exit is made, the singular values should be correct
c          for indices ierr+1,ierr+2,...,n.
c
c        u contains the matrix u (orthogonal column vectors) of the
c          decomposition if matu has been set to .true.  otherwise
c          u is used as a temporary array.  u may coincide with a.
c          if an error exit is made, the columns of u corresponding
c          to indices of correct singular values should be correct.
c
c        v contains the matrix v (orthogonal) of the decomposition if
c          matv has been set to .true.  otherwise v is not referenced.
c          v may also coincide with a if u is not needed.  if an error
c          exit is made, the columns of v corresponding to indices of
c          correct singular values should be correct.
c
c        ierr is set to
c          zero       for normal return,
c          k          if the k-th singular value has not been
c                     determined after itsmax iterations.
c
c        rv1 is a temporary storage array.
c
c     questions and comments should be directed to b. s. garbow,
c     applied mathematics division, argonne national laboratory
c
c     modified to eliminate machep
c
      ierr = 0
c
      do 100 i = 1, m
c
         do 100 j = 1, n
            u(i,j) = a(i,j)
  100 continue


c      write (6,*) 'householder reduction to bidiagonal form '

c     .......... householder reduction to bidiagonal form ..........

      g = 0.0
      scale = 0.0
      anorm = 0.0
c
      do 300 i = 1, n
         l = i + 1
         rv1(i) = scale * g
         g = 0.0
         s = 0.0
         scale = 0.0
         if (i .gt. m) go to 210
c
         do 120 k = i, m
  120    scale = scale + abs(u(k,i))
c
         if (scale .eq. 0.0) go to 210
c
         do 130 k = i, m
            u(k,i) = u(k,i) / scale
            s = s + u(k,i)**2
  130    continue
c
         f = u(i,i)
         g = -sign(sqrt(s),f)
         h = f * g - s
         u(i,i) = f - g
         if (i .eq. n) go to 190
c
         do 150 j = l, n
            s = 0.0
c
            do 140 k = i, m
  140       s = s + u(k,i) * u(k,j)
c
            f = s / h
c
            do 150 k = i, m
               u(k,j) = u(k,j) + f * u(k,i)
  150    continue
c
  190    do 200 k = i, m
  200    u(k,i) = scale * u(k,i)
c
  210    w(i) = scale * g
         g = 0.0
         s = 0.0
         scale = 0.0
         if (i .gt. m .or. i .eq. n) go to 290
c
         do 220 k = l, n
  220    scale = scale + abs(u(i,k))
c
         if (scale .eq. 0.0) go to 290
c
         do 230 k = l, n
            u(i,k) = u(i,k) / scale
            s = s + u(i,k)**2
  230    continue
c
         f = u(i,l)
         g = -sign(sqrt(s),f)
         h = f * g - s
         u(i,l) = f - g
c
         do 240 k = l, n
  240    rv1(k) = u(i,k) / h
c
         if (i .eq. m) go to 270
c
         do 260 j = l, m
            s = 0.0
c
            do 250 k = l, n
  250       s = s + u(j,k) * u(i,k)
c
            do 260 k = l, n
               u(j,k) = u(j,k) + s * rv1(k)
  260    continue
c
  270    do 280 k = l, n
  280    u(i,k) = scale * u(i,k)
c
c  290    anorm = amax1(anorm,abs(w(i))+abs(rv1(i)))
  290    anorm = max(anorm,abs(w(i))+abs(rv1(i)))
  300 continue


c      write (6,*) 'accumulation of right-hand transformation '


c     .......... accumulation of right-hand transformations ..........
      if (.not. matv) go to 410
c     .......... for i=n step -1 until 1 do -- ..........
      do 400 ii = 1, n
         i = n + 1 - ii
         if (i .eq. n) go to 390
         if (g .eq. 0.0) go to 360
c
         do 320 j = l, n
c     .......... double division avoids possible underflow ..........
  320    v(j,i) = (u(i,j) / u(i,l)) / g
c
         do 350 j = l, n
            s = 0.0
c
            do 340 k = l, n
  340       s = s + u(i,k) * v(k,j)
c
            do 350 k = l, n
               v(k,j) = v(k,j) + s * v(k,i)
  350    continue
c
  360    do 380 j = l, n
            v(i,j) = 0.0
            v(j,i) = 0.0
  380    continue
c
  390    v(i,i) = 1.0
         g = rv1(i)
         l = i
  400 continue

c      write (6,*) 'accumulation of left-hand transformation '

c     .......... accumulation of left-hand transformations ..........
  410 if (.not. matu) go to 510
c     ..........for i=min(m,n) step -1 until 1 do -- ..........
      mn = n
      if (m .lt. n) mn = m
c
      do 500 ii = 1, mn
         i = mn + 1 - ii
         l = i + 1
         g = w(i)
         if (i .eq. n) go to 430
c
         do 420 j = l, n
  420    u(i,j) = 0.0
c
  430    if (g .eq. 0.0) go to 475
         if (i .eq. mn) go to 460
c
         do 450 j = l, n
            s = 0.0
c
            do 440 k = l, m
  440       s = s + u(k,i) * u(k,j)
c     .......... double division avoids possible underflow ..........
            f = (s / u(i,i)) / g
c
            do 450 k = i, m
               u(k,j) = u(k,j) + f * u(k,i)
  450    continue
c
  460    do 470 j = i, m
  470    u(j,i) = u(j,i) / g
c
         go to 490
c
  475    do 480 j = i, m
  480    u(j,i) = 0.0
c
  490    u(i,i) = u(i,i) + 1.0
  500 continue



c     .......... diagonalization of the bidiagonal form ..........
c     .......... for k=n step -1 until 1 do -- ..........




  510 do 700 kk = 1, n
         k1 = n - kk
         k = k1 + 1
         its = 0
c     .......... test for splitting.
c                for l=k step -1 until 1 do -- ..........
  520    do 530 ll = 1, k
            l1 = k - ll
            l = l1 + 1
            if (abs(rv1(l)) + anorm .eq. anorm) go to 565
c     .......... rv1(1) is always zero, so there is no exit
c                through the bottom of the loop ..........
            if (abs(w(l1)) + anorm .eq. anorm) go to 540
  530    continue
c     .......... cancellation of rv1(l) if l greater than 1 ..........
  540    c = 0.0
         s = 1.0
c
         do 560 i = l, k
            f = s * rv1(i)
            rv1(i) = c * rv1(i)
            if (abs(f) + anorm .eq. anorm) go to 565
            g = w(i)
            h = sqrt(f*f+g*g)
            w(i) = h
            c = g / h
            s = -f / h
            if (.not. matu) go to 560
c
            do 550 j = 1, m
               y = u(j,l1)
               z = u(j,i)
               u(j,l1) = y * c + z * s
               u(j,i) = -y * s + z * c
  550       continue
c
  560    continue
c     .......... test for convergence ..........
  565    z = w(k)
         if (l .eq. k) go to 650
c     .......... shift from bottom 2 by 2 minor ..........
         if (its .eq. itsmax) go to 1000
         its = its + 1
         x = w(l)
         y = w(k1)
         g = rv1(k1)
         h = rv1(k)
         f = ((y - z) * (y + z) + (g - h) * (g + h)) / (2.0 * h * y)
         g = sqrt(f*f+1.0)
         f = ((x - z) * (x + z) + h * (y / (f + sign(g,f)) - h)) / x
c     .......... next qr transformation ..........
         c = 1.0
         s = 1.0
c
         do 600 i1 = l, k1
            i = i1 + 1
            g = rv1(i)
            y = w(i)
            h = s * g
            g = c * g
            z = sqrt(f*f+h*h)
            rv1(i1) = z
            c = f / z
            s = h / z
            f = x * c + g * s
            g = -x * s + g * c
            h = y * s
            y = y * c
            if (.not. matv) go to 575
c
            do 570 j = 1, n
               x = v(j,i1)
               z = v(j,i)
               v(j,i1) = x * c + z * s
               v(j,i) = -x * s + z * c
  570       continue
c
  575       z = sqrt(f*f+h*h)
            w(i1) = z
c     .......... rotation can be arbitrary if z is zero ..........
            if (z .eq. 0.0) go to 580
            c = f / z
            s = h / z
  580       f = c * g + s * y
            x = -s * g + c * y
            if (.not. matu) go to 600
c
            do 590 j = 1, m
               y = u(j,i1)
               z = u(j,i)
               u(j,i1) = y * c + z * s
               u(j,i) = -y * s + z * c
  590       continue
c
  600    continue
c
         rv1(l) = 0.0
         rv1(k) = f
         w(k) = x
         go to 520
c     .......... convergence ..........
  650    if (z .ge. 0.0) go to 700
c     .......... w(k) is made non-negative ..........
         w(k) = -z
         if (.not. matv) go to 700
c
         do 690 j = 1, n
  690    v(j,k) = -v(j,k)
c

  700 continue


c

      go to 1001
c     .......... set error -- no convergence to a
c                singular value after itsmax iterations ..........
 1000 continue
   

      write(6,*) 'its .eq. itsmax:', its ,' eq ' ,itsmax
      ierr = k




 1001 return
      end




c  #]
