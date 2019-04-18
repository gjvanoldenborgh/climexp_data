program sysu2nc
!
!	convert SYSU homogenised temperature dataset to netcdf format
!
	implicit none
    include 'netcdf.inc'
	integer,parameter :: yrbeg=1900,yrend=2025,ntmax=12*(yrend-yrbeg+1)
	integer :: month,year,mo,yr,i,j,k,ifile,yr1,yr2,irec,version,nx,ny,nz,itimeaxis(ntmax), &
	    nt,nperyear,ncid,iret,moend,nvars,ntvarid,ivars(2,1),it,ivar,ntypevars
	real :: t(72,36,12,yrbeg:yrend),xx(72),yy(36),zz(1),undef
	character :: outfile*19,infile*255,history*1000,metadata(2,100)*1000,lz(3)*20, &
	    vars(1)*40,lvars(1)*80,svars(1)*80,units(1)*80,cell_methods(1)*80,ltime*20,title*200, &
	    dir*20,type*8

    yr1 = yrbeg
    yr2 = yrend
    t = 3e33
    version = 20180101
    call getarg(1,type)
    if ( type(1:5) == 'CLSAT' ) then
        dir = 'CLSAT-Grid-5x5/'
        ntypevars = 3
    else if ( type(1:4) == 'CMST' ) then
        dir = 'CMST/'
        ntypevars = 1
    else
        write(0,*) 'usage: sysu2nc CLSAT | CMST'
        call exit(-1)
    end if
!
!	read data
!
    do ivar=1,ntypevars
        if ( ivar == 1 ) then
            if ( type(1:4) == 'CMST' ) then
                vars(1) = 'data'
            else
                vars(1) = 'tavg'
            end if
        else if ( ivar == 2 ) then
            vars(1) = 'tmin'
        else if ( ivar == 3 ) then
            vars(1) = 'tmax'
        end if

        do yr=yr1,yr2
            do mo=1,12
                write(infile,'(3a,i4.4,a,i4.4,i2.2,a)') &
                    trim(dir),trim(vars(1)),'/',yr,'/',yr,mo,'.txt'
                open(1,file=trim(infile),status='old',err=800)
                do j=1,36
                    read(1,*,end=800) (t(i,j,mo,yr),i=1,72)
                    do i=1,72   
                        if ( t(i,j,mo,yr) == 999.99 ) t(i,j,mo,yr) = 3e33
                    end do
                end do
                close(1)
            end do
        end do
    800	continue
        mo = mo - 1
        if ( mo <= 0 ) then
            mo = mo + 12
            yr = yr - 1
        end if
        write(0,*) 'sysu2nc: last month = ',yr,mo
!
!	    write data
!
        if ( vars(1) /= 'data' ) then
            outfile = 'CLSAT_13_'//trim(vars(1))//'.nc'
            title = 'C-LSAT 1.3: integrated and homogenized global monthly land surface air temperature'
            lvars(1) = 'near-surface air temperature anomaly'
            svars(1) = 'air_temperature_anomaly'
        else
            outfile = 'CMST.nc'
            vars(1) = 'T2mSST'
            title = 'CMST: integrated and homogenized global monthly land surface air temperature combined with ERSST v5'
            lvars(1) = 'near-surface air temperature anomaly / sea surface temperature'
            svars(1) = ' '
        end if
        nx = 72
        do i=1,nx
            xx(i) = 5*i - 2.5
        end do
        ny = 36
        do i=1,ny
            yy(i) = 5*i - 92.5
        end do
        nz = 1
        zz(1) = 2
        lz(1) = 'm'
        lz(2) = 'height'
        lz(3) = 'up'
        nt = 12*(yr-yr1) + mo
        nperyear = 12
        ltime = 'time'
        undef = 3e33
        history = 'received data by email'
        nvars = 1
        ivars(1,1) = 2
        vars(1) = trim(vars(1))//'_anomaly'
        if ( ivar == 1 ) then
            cell_methods(1) = 'monthly mean of daily mean'
        else if ( ivar == 2 ) then
            lvars(1) = 'daily minimum of near-surface air temperature anomaly'
            svars(1) = 'minimum_air_temperature_anomaly' ! not really standard
            cell_methods(1) = 'monthly mean of daily min'
        else if ( ivar == 3 ) then
            lvars(1) = 'daily maximum of near-surface air temperature anomaly'
            svars(1) = 'maximum_air_temperature_anomaly' ! not really standard
            cell_methods(1) = 'monthly mean of daily max'
        else
            write(0,*) 'error bvgfdsaqs'
            call exit(-1)
        end if
        units(1) = 'K'
        metadata = ' '
        metadata(1,1) = 'institution'
        metadata(2,1) = 'Sun Yat-Sen University, School of Atmospheric Sciences'
        metadata(1,2) = 'references'
        metadata(2,2) = 'Wenhui Xu, Qingxiang Li, Phil Jones, Xiaolan L. Wang, Blair Trewin, '// &
            'Su Yang, Chen Zhu, Panmao Zhai, Jinfeng Wang, Lucie Vincent, Aiguo Dai, Yun Gao, '// &
            'Yihui Ding, 2018. A new integrated and homogenized global monthly land surface '// &
            'air temperature dataset for the period since 1900, Clim. Dyn.50, 2513-2536. '// &
            'doi:10.1007/s00382-017-3755-1'
        metadata(1,3) = 'contact'
        metadata(2,3) = 'Qingxiang Li, liqingx5@mail.sysu.edu.cn'    
    
        call enswritenc(outfile,ncid,ntvarid,itimeaxis,ntmax,nx,xx,ny &
            ,yy,nz,zz,lz,nt,nperyear,yr1,1,ltime,undef,title &
            ,history,nvars,vars,ivars,lvars,svars,units,cell_methods &
            ,metadata,0,0)

        it = 0
        yr2 = yr
        moend = mo
        do yr=yr1,yr2
            do mo=1,12
                if ( yr == yr2 .and. mo > moend ) cycle
                it = it + 1
                call writencslice(ncid,ntvarid,itimeaxis,ntmax,ivars,t(1,1,mo,yr) &
                    ,nx,ny,nz,nx,ny,nz,it,1)
            end do
        end do
        iret = nf_close(ncid) ! do not forget
    end do ! variables
end program sysu2nc