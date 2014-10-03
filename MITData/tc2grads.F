        program tc2grads
*
*       read Kerry Emanuel's netcdf files and produces maps of yearly
*       - number of storms per grid box
*       - max wind speed per grid box
*       - PDI per grid box (\int dt vmax^3)
*       and time series of numbers of tcs, hurricane, severe hurricanes
*
        implicit none
#include "netcdf.inc"
        integer nstorms,nobs,nx,ny,yrbeg,yrend
        parameter (nstorms=2000,nobs=120,nx=360/5,ny=180/5,yrbeg=1851
     +       ,yrend=2014)
        integer i,j,yr,mo,dy,hr,istorm,iobs,ncid,status,iocean,nstorm
     +       ,len,ivar,xtype,ndimvar,dimids(nf_max_var_dims),natts,irec
     +       ,ifile,ii,i1,jj,n
        integer tsflag(nx,ny),tcflag(nx,ny),ntype,yrmax,momax,yrmaxp
     +       ,momaxp
        real yrs(nstorms),mos(nobs,nstorms),dys(nobs,nstorms),
     +       hrs(nobs,nstorms),ids(nstorms),d,vmaxstorm
        real lats(nobs,nstorms),lons(nobs,nstorms),vmaxs(nobs,nstorms),
     +       pcs(nobs,nstorms)
        real tstracks(nx,ny,12,yrbeg:yrend),
     +       tctracks(nx,ny,12,yrbeg:yrend),
     +       vmax(nx,ny,12,yrbeg:yrend),
     +       pc(nx,ny,12,yrbeg:yrend),
     +       pdi(nx,ny,12,yrbeg:yrend),nn(12,yrbeg:yrend,4,0:5)
        real nts(720,360,yrbeg:yrend),ntc(720,360,yrbeg:yrend)
        character files(5)*11,outfiles(5)*11,name*40,tcfiles(2)*3
     +       ,types(4)*2
        integer get_endian
        data files /'attracks.nc','eptracks.nc','iotracks.nc'
     +       ,'shtracks.nc','wptracks.nc'/
        data outfiles /'tstracks','tctracks','vmax','pc','pdi'/
        data tcfiles /'nts','ntc'/
        data types /'ts','tc','ss','vs'/
*
*       init
*
        tstracks = 0
        tctracks = 0
        vmax = 0
        pc = 0
        pdi = 0
        nts = 0
        ntc = 0
        nn = 3e33
        yrmaxp = 0
        yrmax = 0
        momaxp = 0
        momax = 0
*
*       read data
*
        do iocean=1,5
            status = nf_open(files(iocean),nf_nowrite,ncid)
            if ( status.ne.nf_noerr ) call handle_err(status
     +           ,files(iocean))
*
*           dims
*
            status = nf_inq_dim(ncid,1,name,len)
            if ( status.ne.nf_noerr ) call handle_err(status
     +           ,'nf_inq_dim 1')
            if ( name.ne.'stormnum' ) then
                write(0,*) 'dim 1 is not stormnum but ',trim(name)
                call abort
            endif
            nstorm = len
            if ( nstorm.gt.nstorms ) then
                write(0,*) 'arrays too small, increase nstorms to '
     +               ,nstorm
                call abort
            endif
            status = nf_inq_dim(ncid,2,name,len)
            if ( status.ne.nf_noerr ) call handle_err(status
     +           ,'nf_inq_dim 2')
            if ( name.ne.'obstime' ) then
                write(0,*) 'dim 2 is not obstime but ',trim(name)
                call abort
            endif
            if ( len.ne.nobs ) then
                write(0,*) 'dim 2 is not ',nobs,' but ',len
                call abort
            endif
*
*           vars
*
            do ivar=1,8
                status = nf_inq_var(ncid,ivar,name,xtype,ndimvar,dimids
     +            ,natts)
                if ( status.ne.nf_noerr ) call handle_err(status
     +               ,'nf_inq_var')
                print *,'reading ',trim(name)
                if ( name.eq.'nsic' ) then
                    status = nf_get_var_real(ncid,ivar,ids)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real hourmc')
                elseif ( name.eq.'hourmc' ) then
                    status = nf_get_var_real(ncid,ivar,hrs)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real hourmc')
                elseif ( name.eq.'daymc' ) then
                    status = nf_get_var_real(ncid,ivar,dys)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real daymc')
                elseif ( name.eq.'monthmc' ) then
                    status = nf_get_var_real(ncid,ivar,mos)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real monthmc')
                elseif ( name.eq.'yearic' ) then
                    status = nf_get_var_real(ncid,ivar,yrs)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real yearic')
                elseif ( name.eq.'latmc' ) then
                    status = nf_get_var_real(ncid,ivar,lats)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real latmc')
                elseif ( name.eq.'longmc' ) then
                    status = nf_get_var_real(ncid,ivar,lons)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real longmc')
                elseif ( name.eq.'vsmc' ) then
                    status = nf_get_var_real(ncid,ivar,vmaxs)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real vsmc')
                elseif ( name.eq.'pcmc' ) then
                    status = nf_get_var_real(ncid,ivar,pcs)
                    if ( status.ne.nf_noerr ) call handle_err(status
     +                   ,'nf_get_var_real pcmc')
                else
                    write(0,*) 'error: unexpected name ',trim(name)
                    call abort
                endif
            enddo               ! ivar
*
*           fill my arrays
*
            do istorm=1,nstorm
                tsflag = 0
                tcflag = 0
                ntype = 1
                vmaxstorm = 0                
                do iobs=1,nobs
                    if ( mos(iobs,istorm).eq.0 ) cycle
                    yr = nint(yrs(istorm))
!                   the high-resolution annual datasets
                    i = 1 + int(2*lons(iobs,istorm))
                    j = 1 + int(2*(lats(iobs,istorm)+90))
                    do ii=i-4,i+4
                        do jj=max(1,j-4),min(360,j+4)
                            d = ((lons(iobs,istorm)-(ii-0.5)/2)*
     +                           cos(atan(1.)*lats(iobs,istorm)/45))**2
     +                           + (lats(iobs,istorm)+90-(jj-0.5)/2)**2
                            if ( d.lt.(160*90/10000.)**2 ) then
                                i1 = ii
                                if ( i1.le.0 ) i1 = i1 + 720
                                if ( i1.gt.720 ) i1 = i1 - 720
                                nts(i1,jj,yr) = 1
***                                print *,'nts(',ii,jj,yr,') = ',
***     +                               nts(ii,jj,yr)
                                if ( vmaxs(iobs,istorm).gt.32.5 ) then
***                                    if ( iocean.eq.1 .and. yr.eq.1961 )
***     +                                   then
***                                        if ( ntc(i1,jj,yr).eq.0 ) then
***                                            print *,'TC near ',i1,jj,(i1
***     +                                           -0.5)/2,-90+(jj-0.5)/2
***                                        endif
***                                    endif
                                    ntc(i1,jj,yr) = 1
                                endif
                            endif
                        enddo   ! jj
                    enddo       ! ii
!                   the low-resolution monthly datasets
!                   note the SH definition of year...
                    i = 1 + int(lons(iobs,istorm)/(360/nx))
                    if ( i.gt.nx ) i = i - nx
                    j = 1 + int((lats(iobs,istorm)+90)/(180/ny))
                    mo = nint(mos(iobs,istorm))
                    if ( iocean.eq.4 .and. mo.gt.6 ) then
                        yr = yr - 1
                    endif
                    if ( tsflag(i,j).eq.0 ) then
                        tsflag(i,j) = 1
                        tstracks(i,j,mo,yr) = tstracks(i,j,mo,yr) + 1
                    endif
                    if ( tcflag(i,j).eq.0 .and. 
     +                   vmaxs(iobs,istorm).gt.32.5 ) then 
                        tcflag(i,j) = 1
                        tctracks(i,j,mo,yr) = tctracks(i,j,mo,yr) + 1
                    endif
                    vmax(i,j,mo,yr) = max(vmax(i,j,mo,yr),
     +                   vmaxs(iobs,istorm))
                    pc(i,j,mo,yr) = min(pc(i,j,mo,yr),
     +                   pcs(iobs,istorm))
                    pdi(i,j,mo,yr) = pdi(i,j,mo,yr) + 3600*6*
     +                   vmaxs(iobs,istorm)**3
                    if ( vmaxstorm.eq.0 .or.
     +                   vmaxs(iobs,istorm).gt.vmaxstorm ) then
                        vmaxstorm = vmaxs(iobs,istorm)
                        if ( iocean.eq.1 .and. yr.eq.yrmaxp .and. 
     +                       mo.lt.momaxp .and. mo.eq.1 ) then
                            print *,'adjusting January to December',
     +                           yr,mo,yrmaxp,momaxp
                            yrmax = yr
                            momax = 12
!                           the alternative is yrmax = yr + 1,
!                           but then the annual sums do not work out
!                           and jan-(yrend+1) gives an arraybound error :-)
                        else
                            yrmax = yr
                            momax = mo
                        endif
                        yrmaxp = yrmax
                        momaxp = momax
                    endif
                enddo           ! iobs
                if ( vmaxstorm.gt.32.5 ) ntype = 2
                if ( vmaxstorm.gt.49.5 ) ntype = 3
                if ( vmaxstorm.gt.57.5 ) ntype = 4
                do i=1,ntype
                    if ( nn(momax,yrmax,i,iocean) .gt.1e33 ) then
                        nn(1:12,yrmax:yrend,i,iocean) = 0
                    endif
                    nn(momax,yrmax,i,iocean) = 
     +                   nn(momax,yrmax,i,iocean) + 1
                enddo
                if ( vmaxstorm.eq.0 ) then
                    nn(momax,yrmax,2,iocean) = 3e33
                    nn(momax,yrmax,3,iocean) = 3e33
                    nn(momax,yrmax,4,iocean) = 3e33
                endif
                if ( .false. .and. iocean.eq.4 ) then
                    print *,istorm,nint(yrs(istorm)),nint(mos(istorm)),
     +                   yrmax,momax,ntype,vmaxstorm
                endif
            enddo               ! istorm
        enddo                   ! iocean
*
*       time series
*
*       end effects
*
        nn(7:12,yrend,1:4,4) = 3e33
        do yr=yrend,yrend-2,-1
            do iocean=1,5
                if ( iocean.ne.4 ) then
                    n = 0
                    do mo=1,12
                        n = n + nn(mo,yr,1,iocean)
                    enddo
                    if ( n.eq.0 ) then
*                       no data yet
                        nn(1:12,yr,1:4,iocean) = 3e33
                    endif
                else
                    n = 0
                    do mo=1,6
                        n = n + nn(mo,yr,1,iocean)
                    enddo
                    do mo=7,12
                        n = n + nn(mo,yr-1,1,iocean)
                    enddo
                    if ( n.eq.0 ) then
*                       no data yet
                        nn(1:6,yr,1:4,iocean) = 3e33
                        nn(7:12,yr-1,1:4,iocean) = 3e33
                    endif
                endif
            enddo               ! iocean
        enddo                   ! yr
*
*       sum oceans
*
        do ntype=1,4
            do yr=yrbeg,yrend
                do mo=1,12
                    nn(mo,yr,ntype,0) = 0
                    do iocean = 1,5
                        nn(mo,yr,ntype,0) =  nn(mo,yr,ntype,0)
     +                       + nn(mo,yr,ntype,iocean)
                    enddo
                enddo
            enddo
        enddo
        do iocean=0,5
            do ntype=1,4
                if ( iocean.eq.0 ) then
                    open(1,file=types(ntype)//'.dat')
                else
                    open(1,file=types(ntype)//files(iocean)(1:2)//'.dat'
     +                   )
                endif
                if ( ntype.eq.1 ) then
                    write(1,'(a)') '# number of tropical storms'
                elseif ( ntype.eq.2 ) then
                    write(1,'(2a)') '# number of tropical cyclones ',
     +                   '(vmax above 32.5m/s, cat 1-5)'
                elseif ( ntype.eq.3 ) then
                    write(1,'(2a)')
     +                   '# number of severe tropical cyclones '
     +                   ,'(vmax above 49.5m/s, cat 3-5)'
                elseif ( ntype.eq.3 ) then
                    write(1,'(2a)')
     +                   '# number of very severe tropical cyclones '
     +                   ,'(vmax above 57.5m/s, cat 4-5)'
                endif
                if ( iocean.eq.0 ) then
                    write(1,'(a)') '# in the whole world'
                elseif ( iocean.eq.1 ) then
                    write(1,'(a)') '# over the Atlantic Ocean'
                elseif ( iocean.eq.2 ) then
                    write(1,'(a)') '# over the East Pacific Ocean'
                elseif ( iocean.eq.3 ) then
                    write(1,'(a)') '# over the Indian Ocean'
                elseif ( iocean.eq.4 ) then
                    write(1,'(a)') '# in the southern hemisphere'
                elseif ( iocean.eq.5 ) then
                    write(1,'(a)') '# over the West Pacific Ocean'
                else
                    write(0,*) 'error',iocean
                    call abort
                endif
                write(1,'(3a)') '# based on data provided by ',
     +               '<a href="http://wind.mit.edu/~emanuel/home.html">'
     +               ,'Kerry Emanual</a>'
                write(1,'(a)')
     +               '# (any errors in the conversion are mine)'
                call printdatfile(1,nn(1,yrbeg,ntype,iocean),12,12,
     +               yrbeg,yrend)
            enddo
        enddo
*
*       begin and end effects: only ATl is defined for the first few
*       years and 2005
*       Note: EP starts in 1949, rather than 1945, so I should
*       check this separately.
*
        do yr=yrbeg,yrend
            if ( all(nn(1:12,yr,1,5).gt.1e33) ) then
                write(0,*) 'putting non-atl to undef in ',yr
                call undef_non_atl_mo(tstracks,nx,ny,yrbeg,yrend,yr)
                call undef_non_atl_mo(tctracks,nx,ny,yrbeg,yrend,yr)
                call undef_non_atl_mo(vmax,nx,ny,yrbeg,yrend,yr)
                call undef_non_atl_mo(pc,nx,ny,yrbeg,yrend,yr)
                call undef_non_atl_mo(pdi,nx,ny,yrbeg,yrend,yr)
                call undef_non_atl_yr(nts,720,360,yrbeg,yrend,yr)
                call undef_non_atl_yr(ntc,720,360,yrbeg,yrend,yr)
            endif
        enddo
*
*       write grids
*
        do ifile=1,5
            open(1,file=trim(outfiles(ifile))//'.grd',access='direct'
     +           ,form='unformatted',recl=4*nx*ny)
            irec = 0
            do yr=yrbeg,yrend
                do mo=1,12
                    irec = irec + 1
                    if ( ifile.eq.1 ) then
                        write(1,rec=irec) ((tstracks(i,j,mo,yr),i=1,nx),
     +                       j=1,ny)
                    elseif ( ifile.eq.2 ) then
                        write(1,rec=irec) ((tctracks(i,j,mo,yr),i=1,nx),
     +                       j=1,ny)
                    elseif ( ifile.eq.3 ) then
                        write(1,rec=irec) ((vmax(i,j,mo,yr),i=1,nx),
     +                       j=1,ny)
                    elseif ( ifile.eq.4 ) then
                        write(1,rec=irec) ((pc(i,j,mo,yr),i=1,nx),
     +                       j=1,ny)
                    elseif ( ifile.eq.5 ) then
                        write(1,rec=irec) ((pdi(i,j,mo,yr),i=1,nx),
     +                       j=1,ny)
                    endif
                enddo           ! mo
            enddo               ! yr
            close(1)
            call mysystem('gzip -f '//trim(outfiles(ifile))//'.grd',i)
            open(1,file=trim(outfiles(ifile))//'.ctl')
            write(1,'(a)') 'DSET ^'//trim(outfiles(ifile))//'.grd'            
            if ( get_endian().eq.-1 ) then
                write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
            elseif ( get_endian().eq.+1 ) then
                write(1,'(a)') 'OPTIONS BIG_ENDIAN'
            endif
            write(1,'(a)') 'UNDEF 3e33'
            write(1,'(a,i3,a,2f8.3)') 'XDEF ',nx,' LINEAR ',
     +           360./nx/2,360./nx
            write(1,'(a,i3,a,2f8.3)') 'YDEF ',ny,' LINEAR ',
     +           -90+180./ny/2,180./ny
            write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
            write(1,'(a,i4,a,i4,a)') 'TDEF ',12*(yrend-yrbeg+1)
     +           ,' LINEAR 15JAN',yrbeg,' 1MO'
            write(1,'(a)') 'VARS 1'
            if ( ifile.eq.1 ) then
                write(1,'(a)')
     +               'tstracks 0 99 number of TS tracks in grid box [1]'
            elseif ( ifile.eq.2 ) then
                write(1,'(a)')
     +               'tctracks 0 99 number of TC tracks in grid box [1]'
            elseif ( ifile.eq.3 ) then
                write(1,'(a)')
     +               'vmax 0 99 maximum 1-minute wind speed at 10m '//
     +               'in grid box [m/s]'
            elseif ( ifile.eq.4 ) then
                write(1,'(a)')
     +               'pc 0 99 minimum core pressure in grid box [mb]'
            elseif ( ifile.eq.5 ) then
                write(1,'(a)')
     +               'pdi 0 99 power dissipation index [m3/s2]'
            endif
            write(1,'(a)') 'ENDVARS'
            close(1)
        enddo
        do ifile=1,2
            open(1,file=tcfiles(ifile)//'.grd',access='direct'
     +           ,form='unformatted',recl=4*720*360)
            irec = 0
            do yr=yrbeg,yrend
                irec = irec + 1
                if ( ifile.eq.1 ) then
                    write(1,rec=irec) ((nts(i,j,yr),i=1,720),j=1,360)
                elseif ( ifile.eq.2 ) then
                    write(1,rec=irec) ((ntc(i,j,yr),i=1,720),j=1,360)
                endif
            enddo
            close(1)
            call mysystem('gzip -f '//tcfiles(ifile)//'.grd',i)
            open(1,file=tcfiles(ifile)//'.ctl')
            write(1,'(a)') 'DSET ^'//tcfiles(ifile)//'.grd'            
            if ( get_endian().eq.-1 ) then
                write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
            elseif ( get_endian().eq.+1 ) then
                write(1,'(a)') 'OPTIONS BIG_ENDIAN'
            endif
            write(1,'(a)') 'UNDEF 3e33'
            write(1,'(a,i3,a,2f8.3)') 'XDEF ',720,' LINEAR ',
     +           0.25,0.5
            write(1,'(a,i3,a,2f8.3)') 'YDEF ',360,' LINEAR ',
     +           -89.75,0.5
            write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
            write(1,'(a,i4,a,i4,a)') 'TDEF ',yrend-yrbeg+1
     +           ,' LINEAR 15MAR',yrbeg,' 1YR'
            write(1,'(a)') 'VARS 1'
            if ( ifile.eq.1 ) then
                write(1,'(a)')
     +               'nts 0 99 tropical storm within 160km [1]'
            elseif ( ifile.eq.2 ) then
                write(1,'(a)')
     +               'ntc 0 99 tropical cyclone within 160km [1]'
            endif
            write(1,'(a)') 'ENDVARS'
            close(1)
        enddo
        end

        subroutine handle_err(status,string)
        implicit none
#include "netcdf.inc"
        integer status
        character*(*) string
        if ( status.ne.nf_noerr ) then
            write(0,*)'netcdf error: ',status,string,nf_strerror(status)
            call abort
        endif
        end

        subroutine undef_non_atl_mo(field,nx,ny,yrbeg,yrend,yr)
        implicit none
        integer nx,ny,yrbeg,yrend,yr
        real field(nx,ny,1:12,yrbeg:yrend)
        integer i,j
        if ( nx.ne.360/5 .or. ny.ne.180/5 ) then
            write(0,*) 'error in undef_non_atl_mo',nx,ny
            call abort
        endif
        field(7:50,1:36,1:12,yr) = 3e33
        field(1:72,1:18,1:12,yr) = 3e33
        do i=51,56
            do j=19,18+0.75*(57-i)
                field(i,j,1:12,yr) = 3e33
            enddo
        enddo
        end

        subroutine undef_non_atl_yr(field,nx,ny,yrbeg,yrend,yr)
        implicit none
        integer nx,ny,yrbeg,yrend,yr
        real field(nx,ny,yrbeg:yrend)
        integer i,j
        if ( nx.ne.720 .or. ny.ne.360 ) then
            write(0,*) 'error in undef_non_atl_yr',nx,ny
            call abort
        endif
        field(70:520,1:360,yr) = 3e33
        field( 1:720,1:180,yr) = 3e33
        do i=501,560
            do j=181,180+0.75*(570-i)
                field(i,j,yr) = 3e33
            enddo
        enddo
        end
