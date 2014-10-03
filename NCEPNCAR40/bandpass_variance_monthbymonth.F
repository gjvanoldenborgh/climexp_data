        program bandpass_variance
!
!       compute the monthly bandpass variance of a daily Z500, Z200, SLP, ... field
!
        implicit none
#include "recfac.h"
#include "fftw3.f"
        integer nfft,twee
        parameter (nfft = 64, twee=2)
        integer yrbeg,yrend,nxmax,nymax,nzmax,nvmax,nx,ny,nz,yr,mo,dy,jx
     +       ,jy,i,j,ntnew,n,n2
        integer ncid,nt,nperyear,firstyr,firstmo,nvars,ivars(6),
     +       dpm(12)
        real undef,ave,adev,sdev,var,skew,curt,s,s1,period,minperiod
     +       ,maxperiod
        real,allocatable :: xx(:),yy(:),zz(:),dfield(:,:,:),
     +       mfield(:,:,:)
        real rin(nfft)
        complex cout(nfft/2+1)
        common /fft_com/ rin,cout ! primitive way to force alignement (I think)
        logical lexist,lwrite
        character file*255,datfile*255,title*10000,lvars*100,vars*40
     +       ,units*40,variable*20
        integer,save :: init
        integer*8,save :: plan28,plan29,plan30,plan31
        integer,external :: leap
        data init /0/
        data dpm /31,29,31,30,31,30,31,31,30,31,30,31/
        lwrite = .false.

        minperiod = 2
        maxperiod = 7

        yrbeg = 1948
        yrend = 2020
        nxmax = 144
        nymax = 73
        nzmax = 1
        nvmax = 1
        allocate(xx(nxmax),yy(nymax),zz(nzmax))

        call getarg(1,variable)
        if ( variable.eq.' ') then
            write(0,*) 'usage: bandpass_variance variable'
            write(0,*) 'computes the bandpass filtered variance of '//
     +           'variable.yyyy.nc'
            call abort
        end if

        datfile=trim(variable)//'var.grd'
        open(1,file=trim(datfile),form='unformatted',access='direct',
     +       recl=recfa4*nxmax*nymax*12)

        allocate(dfield(nxmax,nymax,366),mfield(nxmax,nymax,12))

        ntnew = 0
        do yr=yrbeg,yrend
!
!           read file with daily data
!
            write(file,'(2a,i4.4,a)') trim(variable),'.',yr,'.nc'
            inquire(file=file,exist=lexist)
            if ( .not.lexist ) exit
            call parsenc(file,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax
     +        ,nz,zz,nt,nperyear,firstyr,firstmo,undef,title,nvmax
     +        ,nvars,vars,ivars,lvars,units)
            if ( firstyr.ne.yr ) then
                write(0,*) 'error: firstyr != yr: ',firstyr,yr
                call abort
            end if
            if ( firstmo.ne.1 ) then
                write(0,*) 'error: firstmo != 1: ',firstmo
                call abort
            end if

            call readncfile(ncid,dfield,nxmax,nymax,nx,ny,nperyear
     +           ,yr,yr,firstyr,firstmo,nt,undef,lwrite,yr,yr,ivars)
!
!           compute variance
!
            do jx=1,nx
                do jy=1,ny
                    dy = 0
                    do mo=1,12
                        rin = 3e33
                        n = dpm(mo)
                        if ( mo.eq.2 .and. leap(yr).eq.1 ) then
                            n = n-1
                        end if
                        do i=1,n
                            if ( dfield(jx,jy,dy+i).lt.1e33 ) then
                                rin(i) = dfield(jx,jy,dy+i)
                                rin(2*n+1-i) = rin(i)
                                ntnew = max(ntnew,12*(yr-1948)+mo)
                            else
                                s = 3e33
                                goto 800
                            end if
                        end do
                        n2 = twee*n
                        if ( lwrite ) print *,'n2 = ',n2
                        if ( lwrite ) then
                            if ( .false. ) then
                                do i=1,n2
                                    print *,i,rin(i)
                                end do
                            end if
                            call moment(rin,n,ave,adev,sdev,var,skew
     +                           ,curt)
                            print *,'ave,var,sd = ',ave,var,sdev
                        end if
                        if ( init.eq.0 ) then
                            init = 1
                            call sfftw_plan_dft_r2c_1d(plan28,twee*28
     +                           ,rin,cout,FFTW_ESTIMATE)
                            call sfftw_plan_dft_r2c_1d(plan29,twee*29
     +                           ,rin,cout,FFTW_ESTIMATE)
                            call sfftw_plan_dft_r2c_1d(plan30,twee*30
     +                           ,rin,cout,FFTW_ESTIMATE)
                            call sfftw_plan_dft_r2c_1d(plan31,twee*31
     +                           ,rin,cout,FFTW_ESTIMATE)
                        end if
                        if ( n.eq.28 ) then
                            call sfftw_execute_dft_r2c(plan28,rin,cout)
                        else if ( n.eq.29 ) then
                            call sfftw_execute_dft_r2c(plan29,rin,cout)
                        else if ( n.eq.30 ) then
                            call sfftw_execute_dft_r2c(plan30,rin,cout)
                        else if ( n.eq.31 ) then
                            call sfftw_execute_dft_r2c(plan31,rin,cout)
                        end if
                        if ( lwrite ) then
!                           check variance
                            if ( .false. ) print *,1,cout(1)
                            s = 0
                            do i=2,n2/2+1
                                s = s + real(cout(i))**2 + imag(cout(i))
     +                               **2
                                if ( .false. ) print *,i,cout(i)
                            end do
                            s = 2*s/((n2-twee)*n2)
                            print *,'ave,var,sd = ',abs(cout(1))/(n2),s
     +                           ,sqrt(s),s/var
                        end if
                        s = 0
                        do i=1,n2/2+1
                            if ( i.eq.1 ) then
                                period = 3e33
                            else
                                period = real(n2)/real(i-1)
                            end if
                            s1 = real(cout(i))**2 + imag(cout(i))**2
                            if ( abs(period-minperiod).lt.0.02*period )
     +                           then
                                s = s + s1/2
                                if ( lwrite ) print *,i,period,cout(i),0
     +                               .5,s1
                            else if ( period.lt.maxperiod .and.
     +                           period.gt.minperiod ) then
                                s = s + s1
                                if ( lwrite ) print *,i,period,cout(i),1
     +                               ,s1
                            else
                                if ( lwrite ) print *,i,period,cout(i),0
     +                               ,s1
                            end if
                        end do
                        s = 2*s/((n2-twee)*n2)
  800                   continue
                        if ( lwrite ) print *,'bandpass var = ',s,s/var
                        mfield(jx,jy,mo) = s
!                       next month
                        dy = dy + dpm(mo)
                    end do
                end do
            end do
!
!           write output file
!
            write(1,rec=yr-1948+1) mfield
        end do
        
        title = '2-7dy bandpass filtered variance of '//trim(variable)
        vars = 'var_'//trim(vars)
        units = trim(units)//'^2'
        lvars = '2-7dy variance of '//trim(lvars)
        file=trim(variable)//'var.ctl'
        inquire(file=trim(file),exist=lexist)
        if ( lexist ) then
            open(2,file=trim(file))
            close(2,status='delete')
        end if
        call writectl(file,datfile,nx,xx,ny,yy,nz,zz,ntnew,12,yrbeg,1
     +       ,3e33,title,nvars,vars,ivars,lvars,units)

        end
