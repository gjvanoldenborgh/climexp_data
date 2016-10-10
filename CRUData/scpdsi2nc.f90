program scpdsi2nc
!
!   convert Tim's ascii file to netcdf
!
    implicit none
    integer yrbeg,yrend,nx,ny,nz,ntmax
    parameter(yrbeg=1750,yrend=2003,ny=4,nx=6,nz=1,ntmax=12*(yrend-yrbeg+1))
    integer yr,mo,ix,iy,ivals(12)
    integer ncid,ntvarid,itimeaxis(ntmax),nt,nperyear,nvars,it,ivars(2,1)
    real data(nx,ny,12,yrbeg:yrend),xx(nx),yy(ny),zz(nz)
    real lat1,dlat,lon1,dlon,lat,lon
    character line*80,title*80,vars(1)*10,lvars(1)*80,units(1)*1
    lat1 = 42.5
    dlat = 5
    lon1 = -7.5
    dlon = 5
    
    open(1,file='scpdsi_Europe_IJC.dat',status='old')
1   continue
    read(1,'(a)',end=800) line
    read(line(10:),*) lon,lat
    ix = 1 + nint((lon-lon1)/dlon)
    iy = 1 + nint((lat-lat1)/dlat)
    do yr=yrbeg,yrend
        read(1,*) ivals
        do mo=1,12
            if ( ivals(mo) == -9999 ) then
                data(ix,iy,mo,yr) = 3e33
            else
                data(ix,iy,mo,yr) = real(ivals(mo))/100
            end if
        end do
    end do
    goto 1
800 continue
    close(1)

    do ix=1,nx
        xx(ix) = lon1 + dlon*(ix-1)
    end do
    do iy=1,ny
        yy(iy) = lat1 + (iy-1)*dlon
    end do
    zz(1) = 0
    nt = ntmax
    nperyear = 12
    nvars = 1
    title = 'CRU scPDSI Europe'
    vars(1) = 'scpdsi'
    lvars(1) = 'self-calibrating Palmer Drought Severity Index'
    units(1) = '1'
    ivars = 0
    call writenc('scpdsi_Europe_IJC.nc',ncid,ntvarid,itimeaxis,ntmax,nx,xx,ny,yy   &
    &   ,nz,zz,nt,nperyear,yrbeg,1,3e33,title,nvars,vars,ivars,lvars,units,0,0)
    it = 0
    do yr=yrbeg,yrend
        do mo=1,12
            it = it + 1
            call writencslice(ncid,ntvarid,itimeaxis,ntmax,ivars,data(1,1,mo,yr)   &
            &        ,nx,ny,nz,nx,ny,nz,it,1)
        end do
    end do
    call nf_close(ncid)

end program