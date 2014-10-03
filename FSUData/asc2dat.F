        program asc2dat
*
*       convert FSU ascii files to GrADS, based on anoplain by Gerrit Burgers
*
        implicit none
        integer iyfirst,iylast,iyear,m,iyyyy,month
        real taux(84,30),tauy(84,30) 
        real rmask(84,30)
        real w(30)
        character cyear*4, months(12)*3
        data months /'jan','feb','mar','apr','may','jun',
     +        'jul','aug','sep','oct','nov','dec'/

        iyfirst = 1961
        iylast  = 2020

        do iyear = iyfirst, iylast
            write(cyear,'(I4.4)') iyear
            write(6,*) 'reading:', iyear,' ',cyear//'pac.psv'
            open(1,file=cyear//'pac.psv',status='old',err=100)
            do m=1,12
                read (1,10) month,iyyyy,taux,tauy 
                if ( iyyyy.lt.1900 ) iyyyy = iyyyy + 1900
                if ( iyear.ne.iyyyy ) print *
     +                ,'error: years do not agree ',iyear,iyyyy
                if ( m.ne.month ) print *,'error: months do not agree '
     +                ,m,month
   10           format (2i5,14f5.1,/(16f5.1)) 
                call writeit(taux,tauy)
            enddo
            close(1)
            goto 200
  100       continue
            do m=1,12
                write(6,*) 'reading:', iyear,m,' ',
     +                months(m)//cyear(3:4)//'qpac.psv'
                open(1,file=months(m)//cyear(3:4)//'qpac.psv',status
     +                ='old',err=800)
                read (1,10,err=800) month,iyyyy,taux,tauy 
                close(1)
                if ( iyyyy.lt.1900 ) iyyyy = iyyyy + 1900
                if ( iyear.ne.iyyyy ) print *
     +                ,'error: years do not agree ',iyear,iyyyy
                if ( m.ne.month ) print *,'error: months do not agree '
     +                ,m,month
                call writeit(taux,tauy)
            enddo
  200       continue
        enddo
*
  800   continue
        end
        
        subroutine writeit(taux,tauy)
        implicit none
#include "recfac.h"
        real taux(84,30),tauy(84,30)
        integer nrec,ix,iy
        data nrec /0/
        if ( nrec.eq.0 ) then
            open(2,file='fsupactaux.dat',form='unformatted',access
     +            ='direct',recl=84*30*recfa4)
            open(3,file='fsupactauy.dat',form='unformatted',access
     +            ='direct',recl=84*30*recfa4)
        endif
        do iy=1,30
            do ix=1,84
                if ( taux(ix,iy).gt.900 ) then
                    taux(ix,iy) = 3e33
                endif
            enddo
        enddo
        do iy=1,30
            do ix=1,84
                if ( tauy(ix,iy).gt.900 ) then
                    tauy(ix,iy) = 3e33
                endif
            enddo
        enddo
        nrec = nrec + 1
        print *,'writing record ',nrec
        write(2,rec=nrec) taux
        write(3,rec=nrec) tauy
        end
