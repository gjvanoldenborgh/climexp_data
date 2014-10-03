      program anoplain
      dimension taux(84,30),tauy(84,30) 
      dimension tauxc(84,30,12),tauyc(84,30,12) 
      real rmask(84,30)
      real w(30)
      character*4 cyear

      iyfirst = 1966
*     iylast  = 1994
*     iylast1 = 1995
*     imlast1 = 12
      iylast  = 1998
      iylast1 = 1998
      imlast1 = 12 

      iswitch=1
      if(iswitch.eq.0) then
         write(cyear,'(I4.4)') iyfirst
         open(1,file='../'//cyear//'pac.psv')
         read (1,11) month,iyear,taux,tauy 
   11    format (2i5,14f5.1,/(16f5.1)) 
         write(6,*) taux(1,1)
         write(6,*) taux(42,15)
         do j=1,30
         do i=1,84
            if(taux(i,j).gt.900) then
               rmask(i,j)=0.
            else
               rmask(i,j)=1.
            endif
         enddo
         enddo
         open(11,form='unformatted')
         write(11) rmask
         write(15,*) rmask
         write(6,*) rmask(42,15)
         close(11)
         close(1)
         stop
      endif

      open(11,form='unformatted')
      read(11) rmask
      close(11)

      ivar=1 
      ilev=1
      idim = 2*84*30
*
          do m=1,12
             do j=1,30
             do i=1,84
                tauxc(i,j,m) = 0.
                tauyc(i,j,m) = 0.
             enddo
             enddo
          enddo
*
      rfact = 1./real(iylast-iyfirst+1)
      do iyear = iyfirst, iylast
          write(cyear,'(I4.4)') iyear
          write(6,*) 'First loop:', iyear,' ',cyear//'pac.psv'
          open(1,file='../'//cyear//'pac.psv')

          do m=1,12
             read (1,10) month,iyyyy,taux,tauy 
   10        format (2i5,14f5.1,/(16f5.1)) 
             do j=1,30
             do i=1,84
                tauxc(i,j,m) = rfact*taux(i,j)+tauxc(i,j,m)
                tauyc(i,j,m) = rfact*tauy(i,j)+tauyc(i,j,m)
             enddo
             enddo
          enddo
          close(1) 
      enddo
*
      open(2,file='pacano00.ext',form='unformatted')
      do iyear = iyfirst-2, iylast1
          write(cyear,'(I4.4)') iyear
          if(iyear.lt.iylast1-1) then
             write(6,*) 'Last loop:', iyear,' ',cyear//'pac.psv'
             open(1,file='../'//cyear//'pac.psv')
          else
             write(6,*) 'Last loop:', iyear,' ',cyear//'qpac.psv'
             open(1,file='../quick/'//cyear//'qpac.psv')
          endif

          imlast = 12
          if(iyear.eq.iylast1) imlast=imlast1
          write(6,*) ' iyear iylast1 imlast ', iyear,iylast1,imlast
          do m=1,imlast
             read (1,10) month,iyyyy,taux,tauy 
             do j=1,30
             do i=1,84
                taux(i,j) = rmask(i,j)*(taux(i,j)-tauxc(i,j,m))
                tauy(i,j) = rmask(i,j)*(tauy(i,j)-tauyc(i,j,m))
             enddo
             enddo
             write(2) 100*iyear+month, ivar, ilev, idim
             write(2) taux,tauy
          enddo
          close(1) 
      enddo
      close(2) 
*
      end 
