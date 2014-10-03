        program curldiv
*
*       compute the curl and divergence of the FSU wind stress fields
*
        implicit none
#include "recfac.h"
        integer nxmax,nymax,nzmax,nvarmax
        parameter (nxmax=84,nymax=30,nzmax=1,nvarmax=1)
        integer i,j,k,nx,ny,nz,nt,yrbegin,mobegin,nvars,ivars(2,nvarmax)
        real xx(nxmax),yy(nymax),zz(nzmax),undef,pi,taux(nxmax,nymax)
     +        ,tauy(nxmax,nymax),curl(nxmax,nymax),div(nxmax,nymax)
        character datfile*255,vars(nvarmax)*10,
     +        lvars(nvarmax)*40,title*80
*       
        pi = 4*atan(1d0)
        call parsectl('fsupactaux.ctl',datfile,nxmax,nx,xx,nymax,ny,yy
     +        ,nzmax,nz,zz,nt,yrbegin,mobegin,undef,title,nvarmax,nvars
     +        ,vars,ivars,lvars)
        open(1,file=datfile,form='unformatted',status='old',
     +        access='direct',recl=nx*ny*recfa4)
        if ( undef.ne.3e33 ) then
            print *,'expecting undef = 3e33'
            stop
        endif
*       lets assume all numbers are the same in these two files
        call parsectl('fsupactauy.ctl',datfile,nxmax,nx,xx,nymax,ny,yy
     +        ,nzmax,nz,zz,nt,yrbegin,mobegin,undef,title,nvarmax,nvars
     +        ,vars,ivars,lvars)
        open(2,file=datfile,form='unformatted',status='old',
     +        access='direct',recl=nx*ny*recfa4)
        open(3,file='fsucurltau.dat',form='unformatted',status='new',
     +        access='direct',recl=nx*ny*recfa4)
        open(4,file='fsudivtau.dat',form='unformatted',status='new',
     +        access='direct',recl=nx*ny*recfa4)
        do k=1,nt
            read(1,rec=k) taux
            read(2,rec=k) tauy
            call border(curl,nx,ny)
            call border(div,nx,ny)
            do j=2,ny-1
                do i=2,nx-1
                    if (  taux(i,j+1).lt.1e33 .and. taux(i,j-1).lt.1e33
     +                    .and.
     +                    tauy(i+1,j).lt.1e33 .and. tauy(i-1,j).lt.1e33
     +                    ) then
                        curl(i,j) = -
     +                        (taux(i,j+1) - taux(i,j-1))
     +                        /(yy(j+1)-yy(j-1)) +
     +                        (tauy(i+1,j) - tauy(i-1,j))
     +                        /((xx(i+1)-xx(i-1))*cos(pi*yy(j)/180))
                    else
                        curl(i,j) = 3e33
                    endif
                    if (  tauy(i,j+1).lt.1e33 .and. tauy(i,j-1).lt.1e33
     +                    .and.
     +                    taux(i+1,j).lt.1e33 .and. taux(i-1,j).lt.1e33
     +                    ) then
                        div(i,j) =
     +                        (tauy(i,j+1) - tauy(i,j-1))
     +                        /(yy(j+1)-yy(j-1)) +
     +                        (taux(i+1,j) - taux(i-1,j))
     +                        /((xx(i+1)-xx(i-1))*cos(pi*yy(j)/180))
                    else
                        div(i,j) = 3e33
                    endif
                enddo
            enddo
            write(3,rec=k) curl
            write(4,rec=k) div
        enddo
        call writectl('fsucurltau.ctl','fsucurltau.dat',nx,xx,ny,yy,nz
     +        ,zz,nt,yrbegin,mobegin,undef,'curl of FSU tau',1,'curltau'
     +        ,ivars,'curl of FSU tau')
        call writectl('fsudivtau.ctl','fsudivtau.dat',nx,xx,ny,yy,nz,zz
     +        ,nt,yrbegin,mobegin,undef,'divergence of FSU tau',1
     +        ,'divtau',ivars,'divergence of FSU tau')
        end
        subroutine border(field,nx,ny)
        implicit none
        integer nx,ny
        real field(nx,ny)
        integer i
        do i=1,ny
            field(1,i) = 3e33
        enddo
        do i=1,ny
            field(nx,i) = 3e33
        enddo
        do i=2,nx-1
            field(i,1) = 3e33
        enddo
        do i=2,nx-1
            field(i,ny) = 3e33
        enddo
        end
