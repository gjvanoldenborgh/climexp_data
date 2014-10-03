program asc2grads
  !
  ! convert the GIDMaPS files to grads and from there to netcdf
  !
  implicit none
  integer,parameter :: nxmax=1000,nymax=500
  integer :: yr,mo,ix,iy,nx,ny,nz,nt,ntmax,irec,nrec,ncid,ntvarid,nperyear, &
  & yrbegin,mobegin,nvars,ivars(2,1),status,i,j
  integer,allocatable :: itimeaxis(:)
  real :: xx(nxmax),yy(nymax),zz(1),xmin,ymin,d,undef
  real,allocatable :: field(:,:,:,:)
  logical lexist
  character file*1023,var*3,dataset*10,line*80,title*1023,vars(1)*80, &
       & lvars(1)*120,units(1)*40,format*20
  integer,external :: nf_close
  call getarg(1,var)
  call getarg(2,dataset)
  if ( var == ' ' .or. dataset == ' ' ) then
     print *,'usage: asc2grads vat dataset'
     call abort
  end if
  nrec = 0
  do yr=1949,2100
     do mo=1,12
        if ( mo.lt.10 ) then
           format = '(5a,i4,i1,a)'
        else
           format = '(5a,i4,i2,a)'
        end if
        write(file,format) trim(var),'_',trim(dataset),'/',trim(var),yr,mo,'.asc'
        inquire(file=trim(file),exist=lexist)
        if ( .not.lexist ) then
           if ( yr.lt.2000 ) cycle
           if ( yr.gt.2001 ) exit
           write(0,*) 'asc2grads: error: cannot find file ',trim(file)
           call abort
        end if
        if ( mo.eq.1 ) print *,'opening ',trim(file)
        open(1,file=file)
        read(1,'(a)') line
        if ( line(1:5).eq.'X,Y,D' ) then
            if ( nrec == 0 ) then
               do ix=1,nxmax
                  do iy=1,nymax
                      read(1,*,err=100,end=100) xmin,ymin
                      if ( ix.eq.1 .and. iy.eq.1 ) then
                         nx = 1
                         xx(nx) = xmin
                         ny = 1
                         yy(ny) = ymin
                      end if
                      if ( xmin == xx(1) ) then
                         if ( ymin /= yy(ny) ) then
                            ny = ny + 1
                            yy(ny) = ymin
                            !!!print *,'found yy(',ny,') = ',yy(ny)
                         end if
                      end if
                      if ( xmin /= xx(nx) ) then
                         nx = nx + 1
                         xx(nx) = xmin
                         !!!print *,'found xx(',nx,') = ',xx(nx)
                      end if
                  end do
               end do
100            continue
               allocate(field(nx,ny,12,yr:2100))
               nz = 1
               zz(1) = 0
               yrbegin = yr
               mobegin = mo
               undef = -9999.0000
               rewind(1)
               ! skip first line
               read(1,'(a)') line
            end if
            nrec = nrec + 1
            do ix=1,nx
               do iy=1,ny
                  read(1,*) xmin,ymin,field(ix,iy,mo,yr)
                  if ( xmin /= xx(ix) ) then
                     write(0,*) 'error: xmin /= xx(ix): ',ix,xmin,xx(ix)
                     call abort
                  end if
                  if ( ymin /= yy(iy) ) then
                     write(0,*) 'error: ymin /= yy(iy): ',iy,ymin,yy(iy)
                     call abort
                  end if
               end do
            end do
        else
            read(line(6:),*) nx
            read(1,'(a)') line
            read(line(6:),*) ny
            read(1,'(a)') line
            read(line(10:),*) xmin
            read(1,'(a)') line
            read(line(10:),*) ymin
            read(1,'(a)') line
            read(line(10:),*) d
            read(1,'(a)') line
            read(line(13:),*) undef
            if ( nrec == 0 ) then
               allocate(field(nx,ny,12,yr:2100))
               do ix=1,nx
                  xx(ix) = xmin + (ix-1)*d
               end do
               do iy=1,ny
                  yy(iy) = ymin + (iy-1)*d
               end do
               nz = 1
               zz(1) = 0
               yrbegin = yr
               mobegin = mo
            end if
            nrec = nrec + 1
            do iy=1,ny
                read(1,*) (field(ix,ny-iy+1,mo,yr),ix=1,nx)
            end do
         end if
        close(1)
     end do
  end do

  file = trim(var)//'_'//trim(dataset)//'.nc'
  ntmax = nrec
  allocate(itimeaxis(ntmax))
  nt = nrec
  nperyear = 12
  title = trim(var)//' based on '//trim(dataset)//' <a href="http://drought.eng.uci.edu/">GIDMaPS</a>'
  nvars = 1
  vars(1) = var
  lvars(1) = var
  units(1) = '1'
  ivars(1,1) = 0
  call writenc(file,ncid,ntvarid,itimeaxis,ntmax,nx,xx,ny,yy       &
     &       ,nz,zz,nt,nperyear,yrbegin,mobegin,undef,title,nvars  &
     &       ,vars,ivars,lvars,units,0,0)
  yr = yrbegin
  mo = mobegin
  do irec = 1,nrec
     call writencslice(ncid,ntvarid,itimeaxis,ntmax,ivars,         &
     &        field(1,1,mo,yr),nx,ny,nz,nx,ny,nz,irec,0)
     mo = mo + 1
     if ( mo.gt.12 ) then
        mo = mo - 12
        yr = yr + 1
     end if
  end do
  status = nf_close(ncid) ! DO NOT FORGET
end program
