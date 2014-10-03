        program autocorrelation
!
!       compute the monthly autocorrelation of a daily Z500, Z200, SLP, ... field
!
        implicit none
#include "recfac.h"
        integer nac,window
        parameter (nac=10,window=91)
        integer yrbeg,yrend,nxmax,nymax,nzmax,nvmax,nx,ny,nz,yr,mo,dy,jx
     +       ,jy,i,j,m,ntnew,n,n2,dd,mm
        integer ncid,nt,nperyear,firstyr,firstmo,nvars,jvars(6),
     +       ivars(2,nac),dpm(12),yrmody(3,3*366)
        real rin(3*366),ac(10),undef
        real,allocatable :: xx(:),yy(:),zz(:),dfield(:,:,:,:),
     +       mfield(:,:,:,:),tmp(:),tmp2(:)
        logical lexist,lwrite,prevexist
        character file*255,datfile*255,title*10000,lvars(nac)*100,
     +       vars(nac)*40,units(nac)*40,variable*20,invar*40,inlvar*100
        integer,save :: init
        integer,external :: leap
        data init /0/
        data dpm /31,29,31,30,31,30,31,31,30,31,30,31/
        lwrite = .false.

        ntnew = 0

        yrbeg = 1979
        yrend = 2020
        nxmax = 512
        nymax = 256
        nzmax = 1
        nvmax = 1
        allocate(xx(nxmax),yy(nymax),zz(nzmax))

        call getarg(1,variable)
        if ( variable.eq.' ') then
            write(0,*) 'usage: autocorrelation variable'
            write(0,*) 'computes the autocorrelation per month of '//
     +           'variableyyyy.nc'
            call abort
        end if

        datfile=trim(variable)//'_autocor.grd'
        open(1,file=trim(datfile),form='unformatted',access='direct',
     +       recl=recfa4*nxmax*nymax*nac*12)

        allocate(dfield(nxmax,nymax,366,3),mfield(nxmax,nymax,nac,12))
        allocate(tmp(window))
        allocate(tmp2(window))
        dfield = 3e33
        mfield = 3e33

        prevexist = .true.
        do yr=yrbeg-1,yrend
            print *,'yr = ',yr
!
!           read file with daily data
!
            write(file,'(a,i4.4,a)') trim(variable),yr+1,'.nc'
            inquire(file=file,exist=lexist)
            if ( .not.lexist ) then
                if ( prevexist ) then
                    prevexist = .false.
                else
                    exit
                end if
            else
                print *,'reading yr = ',yr+1
                ncid = 0
                call parsenc(file,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax
     +               ,nz,zz,nt,nperyear,firstyr,firstmo,undef,title
     +               ,nvmax,nvars,vars,jvars,lvars,units)
                if ( firstyr.ne.yr+1 ) then
                    write(0,*) 'error: firstyr != yr: ',firstyr,yr+1
                    call abort
                end if
                if ( firstmo.ne.1 ) then
                    write(0,*) 'error: firstmo != 1: ',firstmo
                    call abort
                end if
                
                call readncfile(ncid,dfield(1,1,1,3),nxmax,nymax,nx,ny
     +               ,nperyear,yr+1,yr+1,firstyr,firstmo,nt,undef,lwrite
     +               ,yr+1,yr+1,jvars)
            end if
            if ( yr.lt.yrbeg ) goto 800
!
!           compute autocorrelation
!
            do jx=1,nx
                do jy=1,ny
                    n = 0
                    do i=1,3
                        dd = 0
                        mm = 1
                        do dy=1,366
                            dd = dd + 1
                            if ( dd.gt.dpm(mm) ) then
                                mm = mm + 1
                                dd = 1
                            end if
                            if ( dfield(jx,jy,dy,i).lt.1e33 ) then
                                if ( n.lt.3*366 ) then
                                    n = n + 1
                                    rin(n) = dfield(jx,jy,dy,i)
                                    yrmody(1,n) = yr - 2 + i
                                    yrmody(2,n) = mm
                                    yrmody(3,n) = dd
                                end if
                            end if
                        end do
                    end do
!
!                   compute autocorrelation per 3 months centered on yr-mo-15
!
                    do mo=1,12
                        ac = 3e33
                        do j=1,3*366 - window
                            if ( yrmody(1,j).eq.yr .and.
     +                           yrmody(2,j).eq.mo .and.
     +                           yrmody(3,j).eq.15 .and.
     +                           j-window/2 .gt.0 ) then
                                if ( jx.eq.nx/2 .and. jy.eq.ny/2 ) then
                                    print *,'calling autocor ',yr,mo,j
                                end if
                                call autocor(rin(j-window/2),window,
     +                               tmp,tmp2,ac,nac)
                                exit
                                if ( jx.eq.nx/2 .and. jy.eq.ny/2 ) then
                                    print *,'ac = ',ac
                                end if
                            end if
                        end do
                        do i=1,nac
                            if ( ac(i).lt.1e33 ) then
                                mfield(jx,jy,i,mo) = ! Fisher-z transform
     +                               0.5*log((1+ac(i))/(1-ac(i)))
                                ntnew = max(ntnew,12*(yr-yrbeg)+mo)
                            else
                                mfield(jx,jy,i,mo) = 3e33
                            end if
                        end do
                    end do
                end do          ! nx
            end do              ! ny
!
!           output data
!
            write(1,rec=yr-yrbeg+1) mfield
!
!           shift
!
 800        continue
            print *,'shifting'
            dfield(:,:,:,1) = dfield(:,:,:,2)
            dfield(:,:,:,2) = dfield(:,:,:,3)
            dfield(:,:,:,3) = 3e33
        end do                  ! yr
!
!       outout metadata
!
        title = 'autocorrelation of '//trim(variable)
        nvars = nac
        invar = vars(1)
        inlvar = lvars(1)
        do i=1,nac
            if ( i.lt.10 ) then
                write(vars(i),'(a,i1,2a)') 'ac',i,'_',trim(invar)
            else
                write(vars(i),'(a,i2,2a)') 'ac',i,'_',trim(invar)
            end if
            units(i) = '1'
            write(lvars(i),'(a,i2,a,i2,2a)') 'lag-',i,
     +           ' autocorrelations of ',i,'-day summed ',trim(inlvar)
            ivars(1,i) = 1
            ivars(2,i) = 99
        end do
        file=trim(variable)//'_autocor.ctl'
        inquire(file=trim(file),exist=lexist)
        if ( lexist ) then
            open(2,file=trim(file))
            close(2,status='delete')
        end if
        call writectl(file,datfile,nx,xx,ny,yy,nz,zz,ntnew,12
     +       ,yrbeg,1,3e33,title,nvars,vars,ivars,lvars,units)

        end program

        subroutine autocor(aa,n,tmp,tmp2,ac,nac)
!
!       compute autocorrelations of lag 1-nac overaged over 1-nac days
!
        implicit none
        integer n,nac
        real aa(n),ac(nac),tmp(n),tmp2(n)
        integer i,k,iac,offset
        real sxy,sxx,syy,sx,sy,sig(1),a,b,da,db,chi2,q
        logical lwrite
        lwrite = .false.
!
        do iac=1,nac
!           make n-day averages in tmp, skipping Feb 29
            do i=1,n-iac+1
                tmp(i) = 0
                offset = 0
                do k=1,iac
                    if ( aa(i+k-1).gt.1e33 ) then
                        offset = 1
                    end if
                    tmp(i) = tmp(i) + aa(i+k-1+offset)
                end do
            end do
            do i=n-iac+2,n
                tmp(i) = 3e33
            end do
!           linear detrending for spring and autumn...
            do i=1,n
                tmp2(i) = n
            end do
            call fit(tmp2,tmp,n-iac+1,sig,0,a,b,da,db,chi2,q)
            do i=1,n-iac+1
                tmp(i) = tmp(i) - b*tmp2(i) - a
            end do
            if ( lwrite .and. .false. ) then
                print *,'iac = ',iac
                do i=1,n
                    print *,i,aa(i),tmp(i)
                end do
            end if
            sx = 0
            sy = 0
            do i=1,n-2*iac+1
                sx = sx + tmp(i)
                sy = sy + tmp(i+iac)
            end do
            sx = sx / (n-2*iac+1)
            sy = sy / (n-2*iac+1)
            
            sxy = 0
            sxx = 0
            syy = 0
            do i=1,n-2*iac+1
                sxy = sxy + (tmp(i)-sx)*(tmp(i+iac)-sy)
                sxx = sxx + (tmp(i)-sx)**2
                syy = syy + (tmp(i+iac)-sy)**2
            end do
            if ( sxx.eq.0 .or. syy.eq.0 .or.
     +           sxx.gt.1e33 .or. syy.gt.1e33 ) then
                ac(iac) = 3e33
            else
                ac(iac) = sxy/sqrt(sxx*syy)
            end if
            if ( lwrite ) then
                if ( .false.) print *,'sxy,sxx,sxy = ',sxy,sxx,syy
                print *,'ac(',iac,') = ',ac(iac)
            end if
        end do
!
        end
