        subroutine myparsenc(file,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax
     +        ,nz,zz,nt,nperyear,firstyr,firstmo,undef,title,nvarmax
     +        ,ntvars,vars,ivars,lvars,units)
*
*       old entry point
*
        implicit none
        integer ncid,nxmax,nymax,nzmax,nx,ny,nz,nt,nperyear,firstyr
     +       ,firstmo,nvarmax,ntvars,ivars(6,nvarmax)
        real xx(nxmax),yy(nymax),zz(nzmax),undef
        character file*(*),title*(*),vars(nvarmax)*(*)
     +       ,lvars(nvarmax)*(*),units(nvarmax)*(*)
        integer kvars(6,100),nens1,nens2,i,j
        character lz(3)*20,svars(100)*100,ltime*120,history*10000,
     +       cell_methods(100)*100
	nens1 = 0
	nens2 = 0
        call ensparsenc(file,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax
     +       ,nz,zz,lz,nt,nperyear,firstyr,firstmo,ltime,nens1,nens2
     +       ,undef,title,history,nvarmax,ntvars,vars,kvars,lvars,svars
     +       ,units,cell_methods)
        if ( nens1.ne.0 .or. nens2.ne.0 ) then
            write(0,*) 'parsenc: error: found ensemble in file '
     +           ,trim(file)
            call abort
        endif
        do i=1,ntvars
            do j=1,5
                ivars(j,i) = kvars(j,i)
            enddo
        enddo
        end

        subroutine ensparsenc(file,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax
     +       ,nz,zz,lz,nt,nperyear,firstyr,firstmo,ltime,nens1,nens2
     +       ,undef,title,history,nvarmax,ntvars,vars,ivars,lvars,svars
     +       ,units,cell_methods)
*
*       extract field metainformation from NetCDF file
*       BUGS: cannot handle multiple latide,longitude axes yet.
*
        implicit none
#include "netcdf.inc"
        integer ntmax,nensmax
        parameter (ntmax=60000,nensmax=99)
*       arguments
        integer ncid,nxmax,nymax,nzmax,nx,ny,nz,nt,nperyear,firstyr
     +       ,firstmo,nens1,nens2,nvarmax,ntvars,ivars(6,nvarmax)
        real xx(nxmax),yy(nymax),zz(nzmax),undef
        character file*(*),title*(*),history*(*),lz(3)*(*),ltime*(*),
     +       vars(nvarmax)*(*),lvars(nvarmax)*(*),svars(nvarmax)*(*),
     +       units(nvarmax)*(*),cell_methods(nvarmax)*(*)
*       local variables
        integer status,ndims,nvars,ngatts,unlimdimid,varid,xtype
     +       ,ndimvar,dimids(nf_max_var_dims),natts,dimid,len,ix,iy,iz
     +       ,it,ie,i,j,n,l,iperyear
        real*8 tt(ntmax)
        character name*(nf_max_name),dimname*(nf_max_name),
     +       clwrite*10,axis*2
        logical lwrite,foundtime
        integer leap
*
        foundtime = .false.
        lwrite = .false.
        call getenv('PARSENC_LWRITE',clwrite)
        if ( index(clwrite,'T') + index(clwrite,'t') .gt.0 ) then
            lwrite = .true.
        endif
        xx(1) = 0
        yy(1) = 0
        zz(1) = 0
        lz = ' '
*
*       open file
*
        if ( ncid.eq.0 ) then
            if ( lwrite ) print *,'parsenc: opening file ',trim(file)
            status = nf_open(file,nf_nowrite,ncid)
            if ( status.ne.nf_noerr ) call handle_err(status,file)
            if ( lwrite ) print *,'parsenc: opened with ncid = ',ncid
        else
            if ( lwrite ) print *,'parsenc: already open with ncid = '
     +           ,ncid
        endif
        call gettitle(ncid,title,lwrite)
        call gettextattopt(ncid,nf_global,'history',history,lwrite)
        call getnumbers(ncid,ndims,nvars,ngatts,unlimdimid,lwrite)
        call getdims(ncid,ndims,ix,nx,nxmax,iy,ny,nymax,iz,nz,nzmax,it
     +       ,nt,ntmax,ie,nens1,nens2,nensmax,lwrite)
*
*       loop over variables
*
        ntvars = 0
        do varid=1,nvars
!           get axis information (if any)
            call gettextattopt(ncid,varid,'axis',axis,lwrite)
            call tolower(axis)
*           get dimensions of variable
            status = nf_inq_var(ncid,varid,name,xtype,ndimvar,dimids
     +            ,natts)
            if ( status.ne.nf_noerr ) call handle_err(status
     +            ,'nf_inq_var')
            if ( lwrite ) then
                print *,'parsenc: variable: ',varid
                print *,'         name:     ',trim(name)
                print *,'         dims:     ',ndimvar,':',
     +                (dimids(i),i=1,ndimvar)
                print *,'         natts:    ',natts
            endif
            if ( index(name,'_bnd').ne.0 ) then
                if ( lwrite ) print *,'parsenc: disregarding boundary '
     +               ,trim(name)
                cycle
            endif
*           what kind of variable do we have?
            if ( ndimvar.eq.1 .and. dimids(1).eq.ix ) then
                call getdiminfo('x',ncid,varid,xx,lwrite)
                call makelonreasonable(xx,nx)
            elseif ( ndimvar.eq.1 .and. dimids(1).eq.iy ) then
                call getdiminfo('y',ncid,varid,yy,lwrite)
            elseif ( ndimvar.eq.1 .and. dimids(1).eq.iz ) then
                call getzdiminfo('z',ncid,varid,zz,lz,lwrite)
            elseif ( ndimvar.eq.1 .and. dimids(1).eq.ie ) then
                if ( lwrite ) print *,'renumbering ensemble members'//
     +               ' to 0 ... nens-1'
            elseif ( ndimvar.eq.1 .and. dimids(1).eq.it .and. 
     +               .not.foundtime .and. ( axis.eq.'t' .or.
     +               name(1:4).eq.'time' .or. name(1:4).eq.'TIME' .or. 
     +               name.eq.'T' .or. name.eq.'t' .or. name.eq.'T1' .or.
     +               name(1:2).eq.'t_' )) then
                foundtime = .TRUE.
*               (it could have been a timeseries)
                if ( lwrite ) print *,'parsenc: found time axis'
                status = nf_get_var_double(ncid,varid,tt)
                if ( status.ne.nf_noerr ) call handle_err(status
     +               ,'nf_get_var_real(tt)')
                if ( lwrite ) print *,'tt(1-5) = ',(tt(i),i=1,min(nt,5))
            else
                n = 0
                do i=1,ndimvar
                    if ( it.ne.0 .and. dimids(i).eq.it ) then
                        n = n+1
                        if ( lwrite ) print *
     +                       ,'parsenc: time-varying variable ',varid
                    endif
                enddo
                if ( lwrite ) then
                    print *,'         checking for a lat-lon var'
                    print *,'         it,n          = ',it,n
                    print *,'         ndimvar,ix,iy = ',ndimvar,ix,iy
                    print *,'         dimids(1,2)   = ',dimids(1)
     +                   ,dimids(2)
                endif
                if ( it.le.0 .and. n.eq.0 .and. ndimvar.eq.2
     +               .and. ix.ne.0 .and. iy.ne.0 .and.
     +               ( dimids(1).eq.ix .and. dimids(2).eq.iy .or.
     +                 dimids(2).eq.ix .and. dimids(1).eq.iy ) ) then
                    n = n+1
                    if ( lwrite ) print *
     +                    ,'parsenc: lat-lon variable ',varid
                endif
                if ( n.eq.1 ) then
                    call addonevariable(ncid,varid,name,ntvars,nvarmax
     +                   ,ndimvar,dimids,ix,iy,iz,it,ie,vars,ivars,lvars
     +                   ,svars,units,cell_methods,undef,lwrite)
                endif           ! one time variable?
            endif               ! variable-recognition case
        enddo
!
!       the rest cannot handle nz=0
!
        if ( nz.eq.0 ) then
            nz = 1
            zz(1) = 0
        endif
        end

