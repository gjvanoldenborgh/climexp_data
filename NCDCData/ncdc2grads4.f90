program ncdc2grads4

!    convert the NCDC v4 gridded files to grads format
!   NOT READY!!!!

    implicit none
    integer :: i,j,k,iyear,imon,n,ldataset,ii,yr,mo,yrbeg,yrend
    real :: data(72,36),missing
    character :: dataset*255,var*4,lvar*40,units*10,format(2)*40,version*10
    integer :: iargc,get_endian
    external get_endian
    yrend=2025

    if ( iargc() /= 1 ) then
        print *,'usage: ncdc2grads file'
        call abort
    endif
    version = '2'
    call getarg(1,dataset)
    open(1,file=dataset,status='old')
    var = 't'
    lvar = 'SST/T2m anomalies'
    units = 'Celsius'
    format(1) = '(2i5)'
    format(2) = '(72f10.4)'
    missing = -999.9
    yrbeg=1880
    open(2,file=trim(var)//'_anom.dat',form='unformatted',access='direct',recl=4*72*36)
    n = 0
    do yr=yrbeg,yrend
        do mo=1,12
            read(1,format(1),end=800) imon,iyear
            if ( iyear /= yr .or. imon /= mo ) then
                write(0,*) 'error in date: ',yr,mo,iyear,imon
                call exit(-1)
            endif
            read(1,format(2)) data
            do j=1,36
                do i=1,72
                    if ( data(i,j) < 0.9*missing ) then
                        data(i,j) = 3e33
                    end if
                end do      ! j
            end do          ! k
            n = n+1
            write(2,rec=n) data
        end do              ! mo
    end do                  ! yr
    write(0,*) 'error: further than ',yrend,'!'
800 continue
    close(1)
    close(2)
    open(1,file=trim(var)//'_anom.ctl')
    write(1,'(3a)') 'DSET ^',trim(var),'_anom.dat'
    write(1,'(4a)') 'TITLE NCDC Merged Land Ocean Global Surface Temperature Analysis v',trim(version)
    if ( get_endian() == -1 ) then
        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
    elseif ( get_endian() == +1 ) then
        write(1,'(a)') 'OPTIONS BIG_ENDIAN'
    endif
    write(1,'(a)') 'UNDEF 3e33'
    write(1,'(a)') 'XDEF 72 LINEAR 2.5 5'
    write(1,'(a)') 'YDEF 36 LINEAR -87.5 5'
    write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
    write(1,'(a,i5,a,i4,a)') 'TDEF ',n,' LINEAR 1JAN',yrbeg,' 1MO'
    write(1,'(a)') 'VARS 1'
    write(1,'(6a)') var,' 0 99 ',trim(lvar),' [',trim(units),']'
    write(1,'(a)') 'ENDVARS'
    close(1)

end program ncdc2grads4