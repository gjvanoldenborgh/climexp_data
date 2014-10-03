        program interpolate
!
!       interpolate the data that is given once every 10 years to annual values
!
        implicit none
#include "netcdf.inc"
#include "recfac.h"
        integer nxmax,nymax,nzmax,ntmax,nensmax,nvarmax,yrbeg,yrend
        parameter(nxmax=720,nymax=360,nzmax=1,ntmax=12*210,nvarmax=1
     +       ,nensmax=1,yrbeg=1850,yrend=2100)
        integer yr,yr1,mo,i,j,status,nx,ny,nz,nt,ncid,ntvars,
     +       ivars(6,nvarmax),firstmo,firstyr,nperyear,irec
        real field(nxmax,nymax,12,27),mofield(nxmax,nymax)
     +       ,xx(nxmax),yy(nymax),zz(nzmax),undef
        character rcp*5,species*10,string*255,file*50,datfile*50,
     +       title*1000,history*10000,units*100
        character vars(nvarmax)*20,lvars(nvarmax)*120
        logical lwrite,lz,foundtime
        integer iargc

        lwrite = .true.
        if ( iargc().ne.2 ) then
            write(0,*) 'usage: interpolate species rcp'
            call abort
        end if
        call getarg(1,species)
        call getarg(2,rcp)
        field = 3e33
!
!       historical data
!
        write(file,'(2a)') trim(species),'.nc'
        print *,'reading ',trim(file)
        status = nf_open(file,nf_nowrite,ncid)
        if ( status.ne.nf_noerr ) then
            write(0,*) 'error: cannot iopen file ',trim(file)
            call abort
        end if
!
!       parse metadata except nperyear
!
        call myparsenc(file,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax
     +        ,nz,zz,nt,nperyear,firstyr,firstmo,undef,title,nvarmax
     +        ,ntvars,vars,ivars,lvars,units)
        if ( nx.ne.nxmax .or. ny.ne.nymax ) then
            write(0,*) 'error in diminesions ',nx,ny,nxmax,nymax
            call abort
        end if
!
!       read data in memory
!
        status = nf_get_var_real(ncid,ivars(1,1),field)
        status = nf_close(ncid)
!
!       RCP data
!
        write(file,'(4a)') rcp,'_',trim(species),'.nc'
        print *,'reading ',trim(file)
        status = nf_open(file,nf_nowrite,ncid)
        if ( status.ne.nf_noerr ) then
            write(0,*) 'error: cannot iopen file ',trim(file)
            call abort
        end if
!
!       parse metadata except nperyear
!
        call myparsenc(file,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax
     +        ,nz,zz,nt,nperyear,firstyr,firstmo,undef,title,nvarmax
     +        ,ntvars,vars,ivars,lvars,units)
        if ( nx.ne.nxmax .or. ny.ne.nymax ) then
            write(0,*) 'error in diminesions ',nx,ny,nxmax,nymax
            call abort
        end if
!
!       read data in memory
!
        status = nf_get_var_real(ncid,ivars(1,1),field(1,1,1,17))
        status = nf_close(ncid)
!
!       interpolate
!
        i = index(file,'.nc')
        file(i:) = '_yr.ctl'
        datfile=file
        datfile(i:) = '_yr.grd'
        title(len_trim(title)+1:) = ', interpolated in time'
        call writectl(file,datfile,nx,xx,ny,yy,1,zz,12*(yrend-yrbeg+1)
     +       ,12,yrbeg,1,undef,title,1,vars,ivars,lvars,units)
        open(1,file=trim(datfile),access='direct',recl=recfa4*nx*ny)
        irec = 0
        do yr=yrbeg,yrend
            i = 1 + (yr-yrbeg)/10
            if ( i.ge.16 ) i = i + 1 ! 2000 is in both datasets
            yr1 = 10*(yr/10)
            do mo=1,12
                if ( yr.eq.yr1 ) then
                    mofield = field(:,:,mo,i)
                else
                    mofield = ((yr-yr1)*field(:,:,mo,i+1)
     +                   + (yr1+10-yr)*field(:,:,mo,i))/10.
                end if
                irec = irec + 1
                write(1,rec=irec) mofield
                print *,yr,mo,mofield(10,284)
            end do
        end do
        close(1)
        if ( irec.ne.(yrend-yrbeg+1)*12 ) then
            write(0,*) 'error: irec != nt ',irec,(yrend-yrbeg+1)*12
            call abort
        end if
        end
