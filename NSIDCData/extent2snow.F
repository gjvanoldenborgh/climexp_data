        program extent2snow
!
!       read the NISE files converted into netcdf and extracts the snow
!       information, interpolates to a lat-lon grid and spews out new
!       netcdf files
!
        implicit none
#include "netcdf.inc"
        integer nx,ny
        parameter (nx=721,ny=721)
        integer ix,iy,status,ncid,ndims,nvars,ngatts,unlimitedid
        integer varid,xtype,ndimvar,dimids(nf_max_var_dims),natts
     +       ,start(4),count(4),ins
        real extent(ny,nx,2)
        character file*255,name*80
        logical lwrite
        lwrite = .true.

        call getarg(1,file)
        status = nf_open(trim(file),nf_nowrite,ncid)
        call getnumbers(ncid,ndims,nvars,ngatts,unlimdimid,lwrite)
        do varid=1,nvars
            status = nf_inq_var(ncid,varid,name,xtype,ndimvar,dimids
     +            ,natts)
            if ( lwrite ) then
                print *,'parsenc: variable: ',varid
                print *,'         name:     ',trim(name)
                print *,'         dims:     ',ndimvar,':',
     +                (dimids(i),i=1,ndimvar)
                print *,'         natts:    ',natts
            endif
            if ( trim(name).eq.'Extent1' ) then
                ins = 1
            else if ( trim(name).eq.'Extent2' ) then
                ins = 2
            else
                cycle
            end if
            start = 1
            count(1) = ny
            count(2) = nx
            status = nf_get_vara_real(ncid,varid,start,count
     +           ,extent(1,1,ins))
