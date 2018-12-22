program bandpass_variance

!   compute the monthly bandpass variance of a daily Z500, Z200, SLP, ... field

    implicit none
    include 'fftw3.f'
    integer,parameter :: recfa4=4,nfft=1024,maxplan=20
    real,parameter :: pi=3.14159265358979323844
    integer :: yrbeg,yrend,nxmax,nymax,nzmax,nvmax,nx,ny,nz,yr,mo,dy,jx &
        ,jy,i,j,m,ntnew,n,n2,dd,mm
    integer :: ncid,nt,nperyear,firstyr,firstmo,nvars,ivars(6), &
        dpm(12),iplan,nplan,nn(maxplan),yrmody(3,nfft)
    real :: undef,ave,adev,sdev,var,skew,curt,s,s1,period,minperiod &
        ,maxperiod
    real,allocatable :: xx(:),yy(:),zz(:),dfield(:,:,:,:),mfield(:,:,:)
    real :: rin(nfft)
    complex :: cout(nfft/2+1)
    common /fft_com/ rin,cout ! primitive way to force alignement (I think)
    logical :: lexist,lwrite,prevexist
    character file*255,datfile*255,title*10000,lvars*100,vars*40 &
        ,units*40,variable*20
    integer,save :: init
    integer*8,save :: plan(2,maxplan)
    integer,external :: leap
    data init /0/
    data dpm /31,29,31,30,31,30,31,31,30,31,30,31/
    lwrite = .false. 

    ntnew = 0
    minperiod = 2
    maxperiod = 7

    yrbeg = 1948
    yrend = 2020
    nxmax = 144
    nymax = 73
    nzmax = 1
    nvmax = 1
    allocate(xx(nxmax),yy(nymax),zz(nzmax))

    call get_command_argument(1,variable)
    if ( variable == ' ') then
        write(0,*) 'usage: bandpass_variance variable'
        write(0,*) 'computes the bandpass filtered variance of '// &
        'variable.yyyy.nc'
        call exit(-1)
    end if

    datfile=trim(variable)//'var.grd'
    open(1,file=trim(datfile),form='unformatted',access='direct', &
        recl=recfa4*nxmax*nymax*12)

    allocate(dfield(nxmax,nymax,366,3),mfield(nxmax,nymax,12))
    dfield = 3e33
    mfield = 3e33

    nplan = 0
    prevexist = .true. 
    do yr=yrbeg,yrend
        print *,'yr = ',yr
    
!       read file with daily data
    
        write(file,'(2a,i4.4,a)') trim(variable),'.',yr,'.nc'
        inquire(file=file,exist=lexist)
        if ( .not. lexist ) then
            if ( prevexist ) then
                prevexist = .false. 
            else
                exit
            end if
        else
            print *,'reading yr = ',yr
            ncid = 0
            call parsenc(file,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax &
                ,nz,zz,nt,nperyear,firstyr,firstmo,undef,title &
                ,nvmax,nvars,vars,ivars,lvars,units)
            if ( firstyr /= yr ) then
                write(0,*) 'error: firstyr != yr: ',firstyr,yr
                call exit(-1)
            end if
            if ( firstmo /= 1 ) then
                write(0,*) 'error: firstmo != 1: ',firstmo
                call exit(-1)
            end if
                            
            call readncfile(ncid,dfield(1,1,1,3),nxmax,nymax,nx,ny &
                ,nperyear,yr,yr,firstyr,firstmo,nt,undef,lwrite,yr &
                ,yr,ivars)
            if ( yr == yrbeg ) go to 800
        end if
    
!       compute FFT
    
        do jx=1,nx
            do jy=1,ny
                n = 0
                do i=1,3
                    dd = 0
                    mm = 1
                    do dy=1,366
                        dd = dd + 1
                        if ( dd > dpm(mm) ) then
                            mm = mm + 1
                            dd = 1
                        end if
                        if ( dfield(jx,jy,dy,i) < 1e33 ) then
                            if ( n < nfft ) then
                                n = n + 1
                                rin(n) = dfield(jx,jy,dy,i)
                                yrmody(1,n) = yr - 3 + i
                                yrmody(2,n) = mm
                                yrmody(3,n) = dd
                            end if
                        end if
                    end do
                end do
                if ( .false. ) then
                    open(21,file='in.txt')
                    do j=1,n
                        write(21,*) j,rin(j)
                    end do
                    close(21)
                end if
                do iplan=1,nplan
                    if ( n == nn(iplan) ) exit
                end do
                if ( iplan > nplan ) then
                    nplan = nplan + 1
                    print *,'new plan ',nplan,n
                    if ( nplan > maxplan ) then
                        write(0,*) 'error: increase maxplan'
                        call exit(-1)
                    end if
                    nn(nplan) = n
                    call sfftw_plan_dft_r2c_1d(plan(1,nplan),n &
                        ,rin,cout,FFTW_ESTIMATE)
                    call sfftw_plan_dft_c2r_1d(plan(2,nplan),n &
                        ,cout,rin,FFTW_ESTIMATE)
                end if
                call sfftw_execute_dft_r2c(plan(1,iplan),rin,cout)
                if ( lwrite ) then
                    open(21,file='fft.txt')
                    do j=1,n/2+1
                        write(21,*) j,real(cout(j)),imag(cout(j)) &
                        ,abs(cout(j))
                    end do
                end if
            
!               band pass filter
            
                do j=1,n/2+1
                    if ( j == 1 ) then
                        period = 3e33
                    else
                        period = real(n)/real(j-1)
                    end if
                    if ( period > maxperiod .or. &
                    period < minperiod ) then
                        cout(j) = 0
                    end if
                end do
            
!               inverse FFT
            
                call sfftw_execute_dft_c2r(plan(2,iplan),cout,rin)
                rin = rin/n
                if ( .false. ) then
                    open(21,file='out.txt')
                    do j=1,n
                        write(21,*) j,rin(j)
                    end do
                    close(21)
                end if
            
!               compute variance per month
            
                do mo=1,12
                    s = 0
                    m = 0
                    do j=1,n
                        if ( yrmody(1,j) == yr-1 .and. &
                        yrmody(2,j) == mo ) then
                            m = m + 1
                            s = s + rin(j)**2
                        end if
                    end do
                    if ( m > 24 ) then
                        mfield(jx,jy,mo) = s/m
                        ntnew = max(ntnew,12*(yr-1-yrbeg)+mo)
                    else
                        mfield(jx,jy,mo) = 3e33
                    end if
                end do
            end do          ! nx
        end do              ! ny

!       output data
    
        write(1,rec=yr-1948) mfield
    
!       shift
    
    800 continue
        print *,'shifting'
        dfield(:,:,:,1) = dfield(:,:,:,2)
        dfield(:,:,:,2) = dfield(:,:,:,3)
        dfield(:,:,:,3) = 3e33
    end do                  ! yr

!   outout metadata

    title = '2-7dy bandpass filtered variance of '//trim(variable)
    vars = 'var_'//trim(vars)
    units = trim(units)//'^2'
    lvars = '2-7dy variance of '//trim(lvars)
    file=trim(variable)//'var.ctl'
    inquire(file=trim(file),exist=lexist)
    if ( lexist ) then
        open(2,file=trim(file))
        close(2,status='delete')
    end if
    call writectl(file,datfile,nx,xx,ny,yy,nz,zz,ntnew,12 &
        ,yrbeg,1,3e33,title,nvars,vars,ivars,lvars,units)

end program
