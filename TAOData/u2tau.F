        program u2tau
*
*       rough conversion from wind speed to wind stress
*
        implicit none
#include "recfac.h"
        integer nxmax,nymax,nzmax,nvmax
        parameter(nxmax=19,nymax=10,nzmax=42,nvmax=4)
        integer i,j,n,nx,ny,nz,nt,nperyear,yrbegin,mobegin,endian,nvars
     +        ,ivars(2,nvmax)
        real u(nxmax,nymax), v(nxmax,nymax), tx(nxmax,nymax), 
     +        ty(nxmax,nymax), u10(nxmax,nymax), v10(nxmax,nymax)
        real xx(nxmax),yy(nymax),zz(nzmax),undef
        character file*256,datfile*256,title*80,vars(nvmax)*10
     +        ,lvars(nvmax)*40,units(nvmax)*20
        integer iargc,llen,get_endian
*
*       arguments
*
        if ( iargc().eq.0 ) then
  100       continue
            read(*,'(i9,16x,2f6.1)',end=800) i,u(1,1),v(1,1)
            call computestress(u(1,1),v(1,1),tx(1,1),ty(1,1),u10(1,1)
     +            ,v10(1,1))
            write(*,'(i9,4f8.3)') i,tx(1,1),ty(1,1),u10(1,1),v10(1,1)
            goto 100
  800       continue
            stop
        endif
        if ( iargc().ne.2 ) then
            write(0,*) 'usage: u2tau ufield.ctl vfield.ctl'
            stop
        endif
        call getarg(1,file)
        call parsectl(file,datfile,nxmax,nx,xx,nymax,ny,yy,nzmax
     +        ,nz,zz,nt,nperyear,yrbegin,mobegin,undef,endian,title
     +        ,1,nvars,vars,ivars,lvars,units)
        open(1,file=datfile,form='unformatted',access='direct',
     +        recl=nx*ny*recfa4,status='old')
*       
        i = index(datfile,'windu')
        if ( i.eq.0 ) then
            print *,'expected windu somewhere in ',datfile(1:llen(file))
            stop
        endif
        datfile(i:i+4) = 'tau_x'
        open(3,file=datfile,form='unformatted',access='direct',
     +        recl=nx*ny*recfa4)
        i = index(file,'windu')
        if ( i.eq.0 ) then
            print *,'expected windu somewhere in ',file(1:llen(file))
            stop
        endif
        file(i:i+4) = 'tau_x'
        title = 'tau_x computed with a simplistic formula'
        nvars = 1
        vars(1) = 'tx'
        lvars(1) = 'zonal wind stress'
        ivars(1,1) = 0
        ivars(2,1) = 0
        units(1) = 'N/m2'
        call writectl(file,datfile,nx,xx,ny,yy,nz,zz,nt,nperyear,yrbegin
     +        ,mobegin,undef,title,nvars,vars,ivars,lvars,units)
*
        call getarg(2,file)
        call parsectl(file,datfile,nxmax,nx,xx,nymax,ny,yy,nzmax
     +        ,nz,zz,nt,nperyear,yrbegin,mobegin,undef,endian,title
     +        ,1,nvars,vars,ivars,lvars,units)
        open(2,file=datfile,form='unformatted',access='direct',
     +        recl=nx*ny*recfa4,status='old')
        i = index(datfile,'windv')
        if ( i.eq.0 ) then
            print *,'expected windv somewhere in ',datfile(1:llen(file))
            stop
        endif
        datfile(i:i+4) = 'tau_y'
        open(4,file=datfile,form='unformatted',access='direct',
     +        recl=nx*ny*recfa4)
        i = index(file,'windv')
        if ( i.eq.0 ) then
            print *,'expected windv somewhere in ',file(1:llen(file))
            stop
        endif
        file(i:i+4) = 'tau_y'
        title = 'tau_y computed with a simplistic formula'
        nvars = 1
        vars(1) = 'ty'
        lvars(1) = 'meridional wind stress'
        ivars(1,1) = 0
        ivars(2,1) = 0
        units(1) = 'N/m2'
        call writectl(file,datfile,nx,xx,ny,yy,nz,zz,nt,nperyear,yrbegin
     +        ,mobegin,undef,title,nvars,vars,ivars,lvars,units)
*       
*       cycle over all months
*
        do n=1,nt
            read(1,rec=n) ((u(i,j),i=1,nx),j=1,ny)
            read(2,rec=n) ((v(i,j),i=1,nx),j=1,ny)
            if ( endian.ne.get_endian() ) then
                call swapbyte4(u,nxmax*nymax)
                call swapbyte4(v,nxmax*nymax)
            endif
            do j=1,ny
                do i=1,nx
                    call computestress(u(i,j),v(i,j),tx(i,j),ty(i,j)
     +                    ,u10(i,j),v10(i,j))
                enddo
            enddo
            write(3,rec=n) ((tx(i,j),i=1,nx),j=1,ny)
            write(4,rec=n) ((ty(i,j),i=1,nx),j=1,ny)
        enddo
        close(1)
        close(2)
        close(3)
        close(4)
        end
        
        subroutine computestress(u,v,tx,ty,u10,v10)
        implicit none
        real u,v,tx,ty,u10,v10
        integer i
        real alpha, kappa, ustar, uz, z, z0, g, rho, x, tau, su10
        logical lwrite
*       
        lwrite = .FALSE.
        z = 4
        g = 9.82
        kappa = 0.4
        alpha = 0.018
        rho = 1
*       
        if ( u.gt.1e33 .or. v.gt.1e33 ) then
            tx = 3e33
            ty = 3e33
            u10 = 3e33
            v10 = 3e33
            return
        endif
*
        uz = sqrt(u**2 + v**2)
        ustar = uz/30
*       backsubstitution
        i = 0
  200   continue
        i = i + 1
        x = ustar
        z0 = alpha*ustar**2/g
        ustar = kappa*uz/log(z/z0)
        if ( abs(x-ustar).gt.1e-5 .and. i.lt.30 ) goto 200
        su10 = uz*log(10/z0)/log(z/z0)
        tau = rho*ustar**2
*       
        if ( lwrite ) then
            print '(a,f10.3)','uz = ',uz
            print '(a,f10.3)','u* = ',ustar
            print '(a,f10.3)','tau= ',rho*ustar**2
            print '(a,f10.6)','z0 = ',z0
            print '(a,f10.3)','u10= ',su10
            print '(a,f10.6)','CD = ',ustar**2/su10**2
        endif
*       
        tx = tau*u/uz
        ty = tau*v/uz
        u10 = su10*u/uz
        v10 = su10*v/uz
*
        end
