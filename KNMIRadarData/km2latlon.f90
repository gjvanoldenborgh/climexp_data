program km2latlon
!
!   regrid Aart's 1m radar data in a netcdf file to a latlon grid
!
    implicit none
    include 'netcdf.inc'
    integer,parameter :: nxmax=700,nymax=765,nzmax=1,ntmax=366*100,nensmax=0,mxmax=600,mymax=666,nvarmax=1
    real,parameter::  xmin=0.0075,xmax=8.9925,ymin=49.37,ymax=55.355
    integer :: i,j,ix,iy,iz,it,nx,ny,nz,nt,ncid,ncid1,status,ndims,nvars,ngatts,unlimdimid
    integer :: dimids(nf_max_var_dims),ivars(6,1),jvars(6,1),varid,nperyear,iperyear,ntvars
    integer :: nens1,nens2,ie,itimeaxis(366*100),yrbegin,mobegin,xtype,ntvarid,natts,ndimvar
    integer :: imin,imax,jmin,jmax
    real :: dx,dy,rlon,rlat,ri,rj,undef
    real*8 :: tt(ntmax),dtt
    real :: xx(nxmax),yy(nymax),zz(1),oldfield(nxmax,nymax)
    real :: xx1(mxmax),yy1(mymax),zz1(1),newfield(mxmax,mymax)
    logical :: lwrite,tdefined(ntmax)
    character :: infile*1023,outfile*1023,title*1023,history*10000,cell_methods(100)*100,lz(3)*40
    character :: vars(1)*40,lvars(1)*100,svars(1)*100,units(1)*40,name*(nf_max_name),ltime*100
    character :: metadata(2,100)*2000
    
    lwrite = .false.
    dx = (xmax-xmin)/(mxmax-1.d0)
    dy = (ymax-ymin)/(mymax-1.d0)
    if ( lwrite ) print *,'dx,dy = ',dx,dy
    
    call getarg(1,infile)
    call getarg(2,outfile)
    if ( outfile.eq.' ' ) then
        write(0,*) 'usage: km2latlon infile outfile'
        write(0,*) '       interpolates radargrid in km to latlon grid of about the same resolution'
        call exit(-1)
    end if
    
    status = nf_open(trim(infile),nf_nowrite,ncid)
    if ( status /= nf_noerr ) call handle_err(status,trim(infile))
    call gettitle(ncid,title,lwrite)
    call gettextattopt(ncid,nf_global,'history',history,lwrite)
    call getnumbers(ncid,ndims,nvars,ngatts,unlimdimid,lwrite)
    call getdims(ncid,ndims,ix,nx,nxmax,iy,ny,nymax,iz,nz,nzmax,it      &
    &   ,nt,ntmax,ie,nens1,nens2,nensmax,lwrite)
    ntvars = 0
    undef = 3e33
    xx(1) = 0
    yy(1) = 0
    zz(1) = 0
    do varid=1,nvars
!       get dimensions of variable
        status = nf_inq_var(ncid,varid,name,xtype,ndimvar,dimids,natts)
        if ( status.ne.nf_noerr ) call handle_err(status,'nf_inq_var')
        if ( lwrite ) then
            print *,'parsenc: variable: ',varid
            print *,'         name:     ',trim(name)
            print *,'         dims:     ',ndimvar,':',                   &
 &                (dimids(i),i=1,ndimvar)
            print *,'         natts:    ',natts
        endif
!       what kind of variable do we have?
        if ( ndimvar.eq.1 .and. dimids(1).eq.it ) then ! time axis
            status = nf_get_var_double(ncid,varid,tt)
            if ( status.ne.nf_noerr ) call handle_err(status,'nf_get_var_real(tt)')
            if ( lwrite ) print *,'tt(1-5) = ',(tt(i),i=1,min(nt,5))
            call getperyear(ncid,varid,tt,nt,mobegin,yrbegin              &
&               ,nperyear,iperyear,ltime,tdefined,ntmax,lwrite)
        end if
        if ( ndimvar.gt.1 ) then ! more than one dimension => field
            call addonevariable(ncid,varid,name,ntvars,1                  &
&                   ,ndimvar,dimids,ix,iy,iz,it,ie,vars,ivars,lvars       &
&                   ,svars,units,cell_methods,undef,lwrite)
        endif
    enddo
    do iy=1,mymax
        do ix=1,mxmax
            xx1(ix) = xmin + (ix-1)*dx
            yy1(iy) = ymin + (iy-1)*dy
        end do
    end do
    zz1(1) = 0
    lz = ' '
    if ( lwrite ) print *,'vars(1) = ',trim(vars(1))
    if ( infile(1:9) == 'radar_sum' ) then
        vars(1) = 'pr'
        units(1) = trim(units(1))//'/dy'
        lvars(1) = 'precipitation'
    else if ( infile(1:9) == 'radar_max' ) then
        vars(1) = 'pr'
        units(1) = trim(units(1))//'/hr'
        lvars(1) = 'daily maximum of hourly precipitation'
    end if
    svars = ' '
    metadata = ' '
    call enswritenc(outfile,ncid1,ntvarid,itimeaxis,ntmax,mxmax,xx1,mymax,yy1 &
     &       ,1,zz1,lz,nt,nperyear,yrbegin,mobegin,ltime,undef,title,history,1              &
     &       ,vars,jvars,lvars,svars,units,cell_methods,metadata,nens1,nens2)
 
    imin = mxmax
    imax = 0
    jmin = mymax
    jmax = 0
    do it=1,nt
        if ( lwrite ) print *,'time slice ',it,'/',nt
        call readncslice(ncid,ivars,it,oldfield,nx,ny,nz,lwrite)
        do iy=1,mymax
            do ix=1,mxmax
                rlon = xx1(ix)
                rlat = yy1(iy)
                call geotoradar(rlat,rlon,ri,rj)
                i = nint(ri)
                j = nint(rj)
                ! just nearest-neighbour, no interpolation or weighting
                !!!print *,'lon/lat ',ix,iy,xx1(ix),yy1(iy),' taken from km ',ri,rj,i,j
                if ( i.ge.1 .and. i.le.nxmax .and. j.ge.1 .and. j.le.nymax ) then
                    newfield(ix,iy) = oldfield(i,j)
                    if ( newfield(ix,iy).lt.undef/1.1 ) then
                        imin = min(imin,ix)
                        imax = max(imax,ix)
                        jmin = min(jmin,iy)
                        jmax = max(jmax,iy)
                    end if
                else
                    newfield(ix,iy) = undef
                end if
            end do
        end do
        call writencslice(ncid1,ntvarid,itimeaxis,ntmax,jvars,newfield  &
      &        ,mxmax,nymax,1,mxmax,mymax,1,it,1)
    end do
    status = nf_close(ncid)
    status = nf_close(ncid1)
    print *,'selindexbox,',imin,imax,jmin,jmax
end program