        program fit_sst
*
*       fit Gerrit's SST equation
*       dT/dt = \alpha Z20 + \beta \tau_x - \gamma T
*       using an integral formulation
*
        implicit none
        integer nx,ny,yrbeg,yrend,nxatm,nyatm,nens,nobsmax
        parameter (nx=19,ny=10,yrbeg=1980,yrend=2003,nxatm=19,nyatm=10
     +       ,nens=0,nobsmax=(nens+1)*(1+12*(yrend-yrbeg+1)))
        integer yr,mo,iens,i,j,yr1,yr2,irec,nz,nxp,nyp,mop1,mom1,ipiv(3)
     +       ,info,nn(nx,ny),yrp1,yrm1,ivars(2,4),iter,k,l,nsst,nz20
     +       ,ntau
        real xx(nx),yy(ny),zz(1),xxatm(nxatm),yyatm(nyatm),xxp(nx)
     +       ,yyp(ny)
        real sstclim(nx,ny,12),z20clim(nx,ny,12),tauxclim(nx,ny,12)
        real sst(nx,ny,12,yrbeg:yrend,0:nens),
     +       z20(nx,ny,12,yrbeg:yrend,0:nens),
     +       taux(nx,ny,12,yrbeg:yrend,0:nens)
        real alpha(nx,ny),beta(nx,ny),gamma(nx,ny),cost(nx,ny),
     +       p(4,3),y(4),q(3),tol
        character string*128,clag*1,ccenter*1,file*128,vars(4)*10
     +       ,lvars(4)*20
        integer nobs
        real sstobs(nobsmax),z20obs(nobsmax),tauobs(nobsmax)
        real sstobsclim,z20obsclim,tauobsclim
        real lat,lon
        logical lag,center
        common /fitcom/ sstobs,z20obs,tauobs,nobs,lag,center,lat,lon
        integer iargc
        real fitfun
        external iargc,fitfun
*
        if ( iargc().lt.2 ) then
            print *,'usage: fit_sst yr1 yr2 [[no]lag] [[no]center]'
            stop
        endif
        call getarg(1,string)
        read(string,*) yr1
        yr1 = max(yrbeg,yr1)
        call getarg(2,string)
        read(string,*) yr2
        yr2 = min(yrend,yr2)
        print *,'Considering years ',yr1,' to ',yr2
        lag = .true.
        center = .true.
        do i=3,iargc()
            call getarg(i,string)
            if ( string(1:3).eq.'lag' ) then
                lag = .true.
            endif
            if ( string(1:5).eq.'nolag' ) then
                lag = .false.
            endif
            if ( string(1:3).eq.'cen' ) then
                center = .true.
            endif
            if ( string(1:5).eq.'nocen' ) then
                center = .false.
            endif
        enddo
*
*       grids
*
        call getxydef('tao_sst.ctl',xx,nx,yy,ny)
        call getxydef('tao_tau_x.ctl',xxatm,nxatm,yyatm,nyatm)
*
        do iens=0,nens
            string = 'tao_sst.dat'
            call readonefile(string,iens,sst,nx,ny,yr1,yr2,nx,ny
     +           ,yrbeg,yrend)
            string = 'tao_z20.dat'
            call readonefile(string,iens,z20,nx,ny,yr1,yr2,nx,ny
     +           ,yrbeg,yrend)
            string = 'tao_tau_x.dat'
            call readonefile(string,iens,taux,nxatm,nyatm,yr1,yr2,nx,ny
     +           ,yrbeg,yrend)
            call interpu(sst(1,1,1,yr1,iens),xx,yy,nx,ny,
     +           taux(1,1,1,yr1,iens),xxatm,yyatm,nxatm,nyatm,
     +           xxp,nxp,yyp,nyp,yr1,yr2,yr1,yr2,nx,ny,12,1,.false.)
            if ( nxp.ne.nx .or.xxp(1).ne.xx(1) .or. xxp(nxp).ne.xx(nx)
     +           ) then
                print *,'error in interpolation',nxp,nx,xxp(1),xx(1)
     +               ,xxp(nxp),xx(nx)
                call abort
            endif
            if ( nyp.ne.ny .or.yyp(1).ne.yy(1) .or. yyp(nyp).ne.yy(ny)
     +           ) then
                print *,'error in interpolation',nyp,ny,yyp(1),yy(1)
     +               ,yyp(nyp),yy(ny)
                call abort
            endif
        enddo
*
*       compute climatology
*
        call makeclim(sstclim,sst,nx,ny,yr1,yr2,nx,ny
     +       ,yrbeg,yrend,nens,nn)
        call makeclim(z20clim,z20,nx,ny,yr1,yr2,nx,ny
     +       ,yrbeg,yrend,nens,nn)
        call makeclim(tauxclim,taux,nx,ny,yr1,yr2,nx,ny,
     +       yrbeg,yrend,nens,nn)
        if ( .false. ) then
            write(string,'(a,i4.4,a,i4.4,a)') 'climatology_',yr1,'-',yr2
     +           ,'.dat'
            open(1,file=string,access='direct',recl=4*nx*ny)
            irec = 0
            do mo=1,12
                irec = irec + 1
                write(1,rec=irec) ((sstclim(i,j,mo),i=1,nx),j=1,ny)
                irec = irec + 1
                write(1,rec=irec) ((z20clim(i,j,mo),i=1,nx),j=1,ny)
                irec = irec + 1
                write(1,rec=irec) ((tauxclim(i,j,mo),i=1,nx),j=1,ny)
            enddo
            close(1)
        endif
*
        do j=1,ny
            lat = yy(j)
            do i=nx,1,-1
                lon = xx(i)
                nobs = 0
                nsst = 0
                nz20 = 0
                ntau = 0
                sstobsclim = 0
                z20obsclim = 0
                tauobsclim = 0
                do iens=0,nens
                    do yr=yr1,yr2
                        do mo=1,12
                            nobs = nobs + 1
                            if ( sst(i,j,mo,yr,iens).lt.1e33 .and.
     +                           sstclim(i,j,mo).lt.1e33 ) then
                                nsst = nsst + 1
                                sstobs(nobs) = sst(i,j,mo,yr,iens)
     +                               - sstclim(i,j,mo)
                                sstobsclim = sstobsclim + sstobs(nobs)
                            else
                                sstobs(nobs) = 3e33
                            endif
                            if ( z20(i,j,mo,yr,iens).lt.1e33 .and.
     +                           z20clim(i,j,mo).lt.1e33 ) then
                                nz20 = nz20 + 1
                                z20obs(nobs) = z20(i,j,mo,yr,iens)
     +                               - z20clim(i,j,mo)
                                z20obsclim = z20obsclim + z20obs(nobs)
                            else
                                z20obs(nobs) = 3e33
                            endif
                            if ( taux(i,j,mo,yr,iens).lt.1e33 .and.
     +                           tauxclim(i,j,mo).lt.1e33 ) then
                                ntau = ntau + 1
                                tauobs(nobs) = taux(i,j,mo,yr,iens)
     +                               - tauxclim(i,j,mo)
                                tauobsclim = tauobsclim + tauobs(nobs)
                            else
                                tauobs(nobs) = 3e33
                            endif
                        enddo
                    enddo
*                   signal end of ensemble member
                    nobs = nobs + 1                    
                    sstobs(nobs) = 3e33
                    z20obs(nobs) = 3e33
                    tauobs(nobs) = 3e33
                enddo
                if ( nsst.gt.0 ) then
                    if ( sstobsclim/nsst.gt.0.001*sqrt(real(nobs)) )
     +                   then
                        write(*,*) 'warning: average sst anomalies are '
     +                       ,sstobsclim/nsst
                    endif
                endif
                if ( nz20.gt.0 ) then
                    if ( z20obsclim/nz20.gt.0.01*sqrt(real(nobs)) )
     +                   then
                        write(*,*) 'warning: average z20 anomalies are '
     +                       ,z20obsclim/nz20
                    endif
                endif
                if ( ntau.gt.0 ) then
                    if ( tauobsclim/ntau.gt.0.001*sqrt(real(nobs)) )
     +                   then
                        write(*,*) 'warning: average tau anomalies are '
     +                       ,tauobsclim/ntau
                    endif
                endif
                if ( nsst.lt.100 ) then
                    alpha(i,j) = 3e33
                    beta(i,j)  = 3e33
                    gamma(i,j) = 3e33
                    goto 200
                endif
                alpha(i,j) = 0.04
                beta(i,j)  = 10
                gamma(i,j) = 0.5
                p(1,3) = alpha(i,j)
                p(1,2) = beta(i,j)
                p(1,1) = gamma(i,j)
                do k=2,4
                    do l=1,3
                        p(k,l) = p(1,l)
                    enddo
                    p(k,k-1) = 2*p(k,k-1)
                enddo
                do k=1,4
                    do l=1,3
                        q(l) = p(k,l)
                    enddo
                    y(k) = fitfun(q)
                enddo
                tol = 1e-4
                call amoeba(p,y,4,3,3,tol,fitfun,iter)
                alpha(i,j) = p(1,3)
                beta(i,j)  = p(1,2)
                gamma(i,j) = p(1,1)
                do l=1,3
                    q(l) = p(1,l)
                enddo
                cost(i,j) = fitfun(q)
 200            continue
                print '(a,2i4,2f5.0,3f12.4,i8,f12.4)','=>',i,j,xx(i),
     +               yy(j),alpha(i,j),beta(i,j),gamma(i,j),nsst,
     +               cost(i,j)
            enddo
        enddo

        if ( lag ) then
            clag = 'l'
        else
            clag = '0'
        endif
        if ( center ) then
            ccenter = 'c'
        else
            ccenter = 'f'
        endif
        write(string,'(4a,i4.4,a,i4.4,a)') 'parameters_',clag,ccenter
     +       ,'_',yr1,'-',yr2,'.dat'
        open(1,file=string,access='direct',recl=4*nx*ny)
        write(1,rec=1) ((alpha(i,j),i=1,nx),j=1,ny)
        write(1,rec=2) ((beta(i,j),i=1,nx),j=1,ny)
        write(1,rec=3) ((gamma(i,j),i=1,nx),j=1,ny)
        write(1,rec=4) ((cost(i,j),i=1,nx),j=1,ny)
        close(1)
        file = string
        i = index(file,'.dat')
        file(i:) = '.ctl'
        open(1,file=file,status='old',err=800)
        close(1,status='delete')
 800    continue
        zz(1) = 0.
        nz = 1
        vars(1) = 'alpha'
        lvars(1) = 'coefficient of z20'
        vars(2) = 'beta'
        lvars(2) = 'coefficient of taux'
        vars(3) = 'gamma'
        lvars(3) = 'damping'
        vars(4) = 'cost'
        lvars(4) = 'cost function'
        do i=1,4
            ivars(1,i) = 1
            ivars(2,i) = 99
        enddo
        call writectl(file,string,nx,xx,ny,yy,nz,zz,1,12,1,1,3e33,
     +       'TAO SST equation parameters',4,vars,ivars,lvars)
        end

        subroutine makeclim(clim,field,nx,ny,yr1,yr2,nxf,nyf,
     +       yrbeg,yrend,nens,nn)
        implicit none
        integer nx,ny,yr1,yr2,nxf,nyf,yrbeg,yrend,nens,nn(nx,ny)
        real clim(nxf,nyf,12),field(nxf,nyf,12,yrbeg:yrend,0:nens)
        integer iens,i,j,mo,yr
        integer llen
        external llen
*
        do mo=1,12
            do j=1,ny
                do i=1,nx
                    clim(i,j,mo) = 0
                enddo
            enddo
        enddo

        do mo=1,12
            do j=1,ny
                do i=1,nx
                    nn(i,j) = 0
                enddo
            enddo
            do iens=0,nens
                do yr=yr1,yr2
                    do j=1,ny
                        do i=1,nx
                            if ( field(i,j,mo,yr,iens).lt.1e33 ) then
                                nn(i,j) = nn(i,j) + 1
                                clim(i,j,mo) = clim(i,j,mo)
     +                               + field(i,j,mo,yr,iens)
                            endif
                        enddo
                    enddo
                enddo
            enddo
            do j=1,ny
                do i=1,nx
                    if ( nn(i,j).gt.10 ) then
                        clim(i,j,mo) = clim(i,j,mo)/nn(i,j)
                    else
                        clim(i,j,mo) = 3e33
                    endif
                enddo
            enddo
        enddo

        end

        subroutine readonefile(file,iens,field,nx,ny,yr1,yr2,nxf,nyf,
     +       yrbeg,yrend)
        implicit none
        integer iens,nx,ny,yr1,yr2,nxf,nyf,yrbeg,yrend
        real field(nxf,nyf,12,yrbeg:yrend)
        character file*(*)
        integer i,j,mo,yr,irec
        integer llen
        external llen
*
        i = index(file,'%%')
        if ( i.ne.0 ) then
            write(file(i:i+1),'(i2.2)') iens
        endif
        print *,'opening ',file(1:llen(file))
        do yr=yr1,yr2
            do mo=1,12
                do j=1,ny
                    do i=1,nx
                        field(i,j,mo,yr) = 3e33
                    enddo
                enddo
            enddo
        enddo
        open(1,file=file,access='direct',recl=4*nx*ny,status='old')
        irec = 0
        do yr=yrbeg,yr2
            do mo=1,12
                irec = irec + 1
                read(1,rec=irec,err=9)((field(i,j,mo,yr),i=1,nx),j=1,ny)
                do j=1,ny
                    do i=1,nx
                        if ( field(i,j,mo,yr).gt.1e25 ) then
                            field(i,j,mo,yr) = 3e33
                        endif
                    enddo
                enddo
            enddo
        enddo
 9      continue
        close(1)
        end

        subroutine getxydef(file,xx,nx,yy,ny)
        implicit none
        integer nx,ny
        real xx(nx),yy(ny)
        character file*(*)
        integer i
        character*256 string
        open(1,file=file,status='old')
 100    continue
        read(1,'(a)') string
        if ( index(string,'XDEF').ne.0 ) then
            call getdef(1,string,xx,i,nx)
            if ( i.ne.nx ) then
                write(0,*) 'error: ',i,nx
                call abort
            endif
        elseif ( index(string,'YDEF').ne.0 ) then
            call getdef(1,string,yy,i,ny)
            if ( i.ne.ny ) then
                write(0,*) 'error: ',i,ny
                call abort
            endif
            goto 110
        endif
        goto 100
 110    continue
        end

        real function fitfun(q)
*
*       discrepancy between modeled SST and observed SST
*
        implicit none
        real q(3)
        integer nx,ny,yrbeg,yrend,nxatm,nyatm,nens,nobsmax
        parameter (nx=19,ny=10,yrbeg=1980,yrend=2003,nxatm=19,nyatm=10
     +       ,nens=0,nobsmax=(nens+1)*(1+12*(yrend-yrbeg+1)))
        integer nobs
        real sstobs(nobsmax),z20obs(nobsmax),tauobs(nobsmax)
        real lat,lon
        logical lag,center
        common /fitcom/  sstobs,z20obs,tauobs,nobs,lag,center,lat,lon
        integer i,j,n
        real cost,sstmod,lonold,sstold,alpha,beta,gamma
        real sstsav(nobsmax)
        character file*128
        logical lfile,firstguess
        save lonold,firstguess
        data lonold /-1./
*
        alpha = q(3)
        beta  = q(2)
        gamma = q(1)
*
        if ( lat.ge.0 .and. lat.lt.0.5 ) then
            lfile = .true.
        else
            lfile = .false.
        endif
        if ( lfile ) then
            if ( lon.ne.lonold .or. firstguess ) then
                if ( lonold.ne.-1 ) then
                    if ( firstguess ) then
                        write(file,'(a,i3.3,a)') 'sstmod_',nint(lonold)
     +                       ,'E_0.txt'
                    elseif ( lonold.ne.-1 ) then
                        write(file,'(a,i3.3,a)') 'sstmod_',nint(lonold)
     +                       ,'E_1.txt'
                    endif
                    open(1,file=file)
                    do i=1,nobs
                        if ( sstsav(i).lt.100 .and. sstsav(i).gt.-100 )
     +                       then
                            write(1,'(i6,2f6.2)') i,sstobs(i),sstsav(i)
                        else
                            write(1,'(i6,2f6.2)')
                        endif
                    enddo
                    close(1)
                endif
                if ( firstguess ) firstguess = .false.
                if ( lonold.ne.lon ) firstguess = .true.
                lonold = lon
            endif
        endif
        n = 0
        cost = 0
        sstmod = 3e33
        do i=1,nobs
            if ( sstobs(i).lt.-1e33 ) then
*               new ensemble member
                sstmod = 3e33
                goto 100
            endif
            if ( sstobs(i).gt.1e33 ) then
*               reset sstmod
                sstmod = 3e33
                goto 100
            endif
            if ( sstmod.gt.1e33 ) then
*               initialize with observed value
                sstmod = sstobs(i)
                if ( lfile ) sstsav(i) = sstmod
                goto 100
            endif
*           next modeled value
            if ( center ) then
                sstold = sstmod
                if ( lag ) then
                    j = i - nint(8e-8*(290-lon)**4)
                else
                    j = i
                endif
                if ( j.gt.1 ) then
                    if ( z20obs(j).lt.1e33 .and.
     +                   abs(z20obs(j-1)).lt.1e33 ) then
                        sstmod = sstmod+alpha*(z20obs(j)+z20obs(j-1))/2
                    endif
                endif
                if ( tauobs(i).lt.1e33 .and. abs(tauobs(i-1)).lt.1e33 )
     +               then
                    sstmod = sstmod + beta*(tauobs(i)+tauobs(i-1))/2
                endif
                if ( sstobs(i).lt.1e33 .and. abs(sstobs(i-1)).lt.1e33 )
     +               then
                    sstmod = sstmod - gamma*(sstold+sstmod)/2
                endif
                n = n + 1
                cost = cost + (sstobs(i) - sstmod)**2
                if ( lfile ) then
                    sstsav(i) = sstmod
                endif
            else
*               forward scheme
                n = n + 1
                cost = cost + (sstobs(i) - sstmod)**2         
                if ( lag ) then
                    j = i - nint(8e-8*(290-lon)**4)
                else
                    j = i
                endif
                if ( lfile ) then
                    sstsav(i) = sstmod
                endif
                if ( j.gt.0 ) then
                    if ( z20obs(j).lt.1e33 ) then
                        sstmod = sstmod + alpha*z20obs(j)
                    endif
                endif
                if ( tauobs(i).lt.1e33 ) then
                    sstmod = sstmod - beta*tauobs(i)
                endif
                if ( sstobs(i).lt.1e33 ) then
                    sstmod = sstmod - gamma*sstmod
                endif
            endif
            if ( sstmod.gt.100 .or. sstmod.lt.-100 ) then
*               quite often, I get an unstable model.
*               kill before it spirals out of control
                fitfun = 3e33
                return
            endif
            if ( .false. ) then
                print '(2i6,5f12.6)',i,j,cost,sstobs(i),z20obs(j)
     +               ,tauobs(i),sstmod
            endif
 100        continue
        enddo
        if ( n.gt.0 ) then
            fitfun = cost/n
        else
            fitfun = 3e33
        endif
        if ( .false. ) then
            print '(4g12.3)',q,cost
        endif
        end
