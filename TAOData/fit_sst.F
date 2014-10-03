        program fit_sst
*
*       fit Gerrit's SST equation
*       dT/dt = \alpha Z20 + \beta \tau_x + \gamma T
*       to Challenge data in the equatorial Pacific
*
        implicit none
        integer nx,ny,yrbeg,yrend,nxatm,nyatm,nens
        parameter (nx=19,ny=10,yrbeg=1980,yrend=2003,nxatm=19,nyatm=10
     +       ,nens=0)
        integer yr,mo,iens,i,j,yr1,yr2,irec,nz,nxp,nyp,mop1,mom1,ipiv(3)
     +       ,info,nn(nx,ny),yrp1,yrm1,ivars(2,3)
        real xx(nx),yy(ny),zz(1),xxatm(nxatm),yyatm(nyatm),xxp(nx)
     +       ,yyp(ny)
        real sstclim(nx,ny,12),z20clim(nx,ny,12),tauxclim(nx,ny,12)
        real sst(nx,ny,12,yrbeg:yrend),z20(nx,ny,12,yrbeg:yrend),
     +       taux(nx,ny,12,yrbeg:yrend)
        real sstsst(nx,ny),sstz20(nx,ny),ssttau(nx,ny),z20z20(nx,ny)
     +       ,z20tau(nx,ny),tautau(nx,ny),sstdsst(nx,ny),z20dsst(nx,ny)
     +       ,taudsst(nx,ny),alpha(nx,ny),beta(nx,ny),gamma(nx,ny)
        real dsst,ssta,z20a,taua,dt
        real a(3,3),b(3),c(3)
        character string*128,clag*1,ccenter*1,file*128,vars(3)*10
     +       ,lvars(3)*20
        logical lag,center
        integer iargc
        external iargc
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
*       compute climatology
*
        call makeclim('tao_sst.dat',sstclim,sst,nx,ny,yr1,yr2,nx,ny
     +       ,yrbeg,yrend,nn)
        call makeclim('tao_z20.dat',z20clim,z20,nx,ny,yr1,yr2,nx,ny
     +       ,yrbeg,yrend,nn)
        call makeclim('tao_tau_x.dat',tauxclim,taux,nxatm,nyatm,yr1
     +       ,yr2,nx,ny,yrbeg,yrend,nn)
        call interpu(sstclim,xx,yy,nx,ny,
     +           tauxclim,xxatm,yyatm,nxatm,nyatm,
     +           xxp,nxp,yyp,nyp,1,1,1,1,nx,ny,12,1,.false.)
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
*       compute covariances
*
        do j=1,ny
            do i=1,nx
                nn(i,j) = 0
                sstsst(i,j) = 0
                sstz20(i,j) = 0
                ssttau(i,j) = 0
                z20z20(i,j) = 0
                z20tau(i,j) = 0
                tautau(i,j) = 0
                sstdsst(i,j) = 0
                z20dsst(i,j) = 0
                taudsst(i,j) = 0
            enddo
        enddo
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
            call interpu(sst(1,1,1,yr1),xx,yy,nx,ny,
     +           taux(1,1,1,yr1),xxatm,yyatm,nxatm,nyatm,
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
            do yr=yr1,yr2
                do mo=1,12
                    do j=1,ny
                        do i=1,nx
                            if ( sst(i,j,mo,yr).gt.1e10 .or. z20(i,j,mo
     +                           ,yr).gt.1e10 .or. taux(i,j,mo,yr).gt
     +                           .1e10 ) goto 99
                            if ( yr.eq.yrbeg .and. mo.eq.1 ) then
                                goto 99
                            elseif ( yr.eq.yrend .and. mo.eq.12 ) then
                                goto 99
                            else
                                mop1 = mo + 1
                                call normon(mop1,yr,yrp1,12)
                                mom1 = mo - 1
                                call normon(mom1,yr,yrm1,12)
                                if ( center ) then
                                    if ( sst(i,j,mop1,yrp1).lt.1e33.and.
     +                                   sst(i,j,mom1,yrm1).lt.1e33.and.
     +                                   sstclim(i,j,mop1).lt.1e33.and.
     +                                   sstclim(i,j,mom1).lt.1e33)
     +                                   then
                                        dsst = (
     +                                       + sst(i,j,mop1,yrp1)
     +                                       - sstclim(i,j,mop1)
     +                                       - sst(i,j,mom1,yrm1)
     +                                       + sstclim(i,j,mom1) )/2
                                    else
                                        goto 99
                                    endif
                                else
                                    if ( sst(i,j,mom1,yrm1).lt.1e33.and.
     +                                   sstclim(i,j,mom1).lt.1e33)
     +                                   then
                                        dsst =
     +                                       + sst(i,j,mo,yr)
     +                                       - sstclim(i,j,mo)
     +                                       - sst(i,j,mom1,yrm1)
     +                                       + sstclim(i,j,mom1)
                                    else
                                        goto 99
                                    endif
                                endif
                            endif
                            if ( sst(i,j,mo,yr).lt.1e33 .and.
     +                           sstclim(i,j,mo).lt.1e33 ) then
                                ssta = sst(i,j,mo,yr) - sstclim(i,j,mo)
                            else
                                goto 99
                            endif
*                           fit by eye to zelle et al, Fig 2.
*                           only valid on the equator, really
                            if ( lag ) then
                                dt = 8e-8*(290-xx(i))**4
                            else
                                dt = 0
                            endif
                            mom1 = mo - nint(dt)
                            call normon(mom1,yr,yrm1,12)
                            if ( yrm1.gt.yrbeg ) then
                                if ( z20(i,j,mom1,yrm1).lt.1e33 .and.
     +                               z20clim(i,j,mom1).lt.1e33 ) then
                                    z20a = z20(i,j,mom1,yrm1)
     +                                   - z20clim(i,j,mom1)
                                else
                                    goto 99
                                endif
                            else
                                goto 99
                            endif
                            if ( taux(i,j,mo,yr).lt.1e33 .and.
     +                           tauxclim(i,j,mo).lt.1e33 ) then
                                taua =taux(i,j,mo,yr) - tauxclim(i,j,mo)
                            else
                                goto 99
                            endif
                            nn(i,j) = nn(i,j) + 1
                            sstsst(i,j) = sstsst(i,j) + ssta**2
                            sstz20(i,j) = sstz20(i,j) + ssta*z20a
                            ssttau(i,j) = ssttau(i,j) + ssta*taua
                            z20z20(i,j) = z20z20(i,j) + z20a**2
                            z20tau(i,j) = z20tau(i,j) + z20a*taua
                            tautau(i,j) = tautau(i,j) + taua**2
                            sstdsst(i,j) = sstdsst(i,j) + ssta*dsst
                            z20dsst(i,j) = z20dsst(i,j) + z20a*dsst
                            taudsst(i,j) = taudsst(i,j) + taua*dsst
 99                         continue
                        enddo
                    enddo
                enddo
            enddo
        enddo
        do j=1,ny
            do i=1,nx
                if ( nn(i,j).gt.100 ) then
                    sstsst(i,j) = sstsst(i,j)/nn(i,j)
                    sstz20(i,j) = sstz20(i,j)/nn(i,j)
                    ssttau(i,j) = ssttau(i,j)/nn(i,j)
                    z20z20(i,j) = z20z20(i,j)/nn(i,j)
                    z20tau(i,j) = z20tau(i,j)/nn(i,j)
                    tautau(i,j) = tautau(i,j)/nn(i,j)
                    sstdsst(i,j) = sstdsst(i,j)/nn(i,j)
                    z20dsst(i,j) = z20dsst(i,j)/nn(i,j)
                    taudsst(i,j) = taudsst(i,j)/nn(i,j)
                else
                    sstsst(i,j) = 3e33
                    sstz20(i,j) = 3e33
                    ssttau(i,j) = 3e33
                    z20z20(i,j) = 3e33
                    z20tau(i,j) = 3e33
                    tautau(i,j) = 3e33
                    sstdsst(i,j) = 3e33
                    z20dsst(i,j) = 3e33
                    taudsst(i,j) = 3e33
                endif
            enddo
        enddo
        if ( .false. ) then
            write(string,'(a,i4.4,a,i4.4,a)') 'covariances',yr1,'-',yr2
     +           ,'.dat'
            open(1,file=string,access='direct',recl=4*nx*ny)
            write(1,rec=1) ((sstsst(i,j),i=1,nx),j=1,ny)
            write(1,rec=2) ((sstz20(i,j),i=1,nx),j=1,ny)
            write(1,rec=3) ((ssttau(i,j),i=1,nx),j=1,ny)
            write(1,rec=4) ((z20z20(i,j),i=1,nx),j=1,ny)
            write(1,rec=5) ((z20tau(i,j),i=1,nx),j=1,ny)
            write(1,rec=6) ((tautau(i,j),i=1,nx),j=1,ny)
            write(1,rec=7) ((sstdsst(i,j),i=1,nx),j=1,ny)
            write(1,rec=8) ((z20dsst(i,j),i=1,nx),j=1,ny)
            write(1,rec=9) ((taudsst(i,j),i=1,nx),j=1,ny)
            close(1)
        endif
*
*       solve 3x3 set of equations
*
        do j=1,ny
            do i=1,nx
                if ( nn(i,j).gt.100 ) then
                    a(1,1) = z20z20(i,j)
                    a(1,2) = z20tau(i,j)
                    a(1,3) = sstz20(i,j)
                    a(2,1) = z20tau(i,j)
                    a(2,2) = tautau(i,j)
                    a(2,3) = ssttau(i,j)
                    a(3,1) = sstz20(i,j)
                    a(3,2) = ssttau(i,j)
                    a(3,3) = sstsst(i,j)
                    b(1) = z20dsst(i,j)
                    b(2) = taudsst(i,j)
                    b(3) = sstdsst(i,j)
                    info = 0
                    call sgesv(3,1,a,3,ipiv,b,3,info)
                    alpha(i,j) = b(1)
                    beta(i,j)  = b(2)
                    gamma(i,j) = b(3)
                else
                    alpha(i,j) = 3e33
                    beta(i,j)  = 3e33
                    gamma(i,j) = 3e33
                endif
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
        do i=1,3
            ivars(1,i) = 1
            ivars(2,i) = 99
        enddo
        call writectl(file,string,nx,xx,ny,yy,nz,zz,1,12,1,1,3e33,
     +       'TAO SST equation parameters',3,vars,ivars,lvars)
        end

        subroutine makeclim(file,clim,field,nx,ny,yr1,yr2,nxf,nyf,
     +       yrbeg,yrend,nn)
        implicit none
        integer nx,ny,yr1,yr2,nxf,nyf,yrbeg,yrend,nn(nx,ny)
        real clim(nxf,nyf,12),field(nxf,nyf,12,yrbeg:yrend)
        character file*(*)
        integer irec,i,j,mo,yr
        integer llen
        external llen
*
        print *,'opening ',file(1:llen(file))
        open(1,file=file,access='direct',recl=4*nx*ny,status='old')
        irec = 0
        do yr=yr1,yr2
            do mo=1,1
                do j=1,ny
                    do i=1,nx
                        field(i,j,mo,yr) = 3e33
                    enddo
                enddo
            enddo
        enddo
        do yr=yrbeg,yr2
            do mo=1,12
                irec = irec + 1
                read(1,rec=irec,err=9)((field(i,j,mo,yr),i=1,nx),j=1,ny)
            enddo
        enddo
 9      continue
        close(1)
        
        
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
            do yr=yr1,yr2
                do j=1,ny
                    do i=1,nx
                        if ( field(i,j,mo,yr).lt.1e33 ) then
                            nn(i,j) = nn(i,j) + 1
                            clim(i,j,mo) = clim(i,j,mo) + field(i,j,mo
     +                           ,yr)
                        endif
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
