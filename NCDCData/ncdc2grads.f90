program ncdc2grads

!   convert the NCDC gridded files to grads format

    implicit none
    integer,parameter :: recfa4=4
    integer :: i,j,k,iyear,imon,n,ldataset,ii,idata(72,36),yr,mo,missing,yrbeg,yrend
    real :: data(72,36)
    character :: dataset*255,var*4,lvar*40,units*10,format(2)*40,version*10
    integer,external :: get_endian
    yrend=2030

    if ( command_argument_count() /= 1 ) then
        print *,'usage: ncdc2grads file'
        call exit(-1)
    endif
    version = '2'
    call get_command_argument(1,dataset)
    open(1,file=dataset,status='old')
    if ( index(dataset,'blended') /= 0 .or. &
    index(dataset,'merged') /= 0 ) then
        var = 't'
        lvar = 'SST/T2m anomalies'
        units = 'Celsius'
        format(1) = '(2i6)'
        format(2) = '(72i6)'
        missing = -9999
        yrbeg=1880
    else if ( index(dataset,'prcp') == 0 ) then
        var = 'temp'
        lvar = 'temperature anomalies'
        units = 'Celsius'
        j = index(dataset,'-v') + 2
        k = index(dataset,'.dat') -1
        version = dataset(j:k)
        format(1) = '(2i6)'
        format(2) = '(72i6)'
    !!!            format(1) = '(2i5)'
    !!!            format(2) = '(12i6)'
        missing = -9999
        yrbeg=1880
    else
        var = 'prcp'
        lvar = 'precipitation anomalies'
        units = 'mm/month'
        format(1) = '(2i5)'
        format(2) = '(12i7)'
        missing = -32768
        yrbeg=1900
    endif
    open(2,file=trim(var)//'_anom.dat',form='unformatted',access &
    ='direct',recl=72*36*recfa4)
    n = 0
    do yr=yrbeg,yrend
        do mo=1,12
            read(1,format(1),end=800) imon,iyear
        !!!print *,iyear,imon
            if ( iyear /= yr .or. imon /= mo ) then
                write(0,*) 'error in date: ',yr,mo,iyear,imon
                call exit(-1)
            endif
            read(1,format(2)) idata
            do j=1,36
                do i=1,72
                    if ( idata(i,37-j) == missing ) then
                        data(i,j)= 3e33
                    else
                        data(i,j) = idata(i,37-j)/100.
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
    write(1,'(4a)') 'TITLE NCDC gridded GHCN v',trim(version),' ', &
    trim(lvar)
    if ( get_endian() == -1 ) then
        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
    elseif ( get_endian() == +1 ) then
        write(1,'(a)') 'OPTIONS BIG_ENDIAN'
    endif
    write(1,'(a)') 'UNDEF 3e33'
    write(1,'(a)') 'XDEF 72 LINEAR -177.5 5'
    write(1,'(a)') 'YDEF 36 LINEAR -87.5 5'
    write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
    write(1,'(a,i5,a,i4,a)') 'TDEF ',n,' LINEAR 1JAN',yrbeg,' 1MO'
    write(1,'(a)') 'VARS 1'
    write(1,'(6a)') var,' 0 99 ',trim(lvar),' [',trim(units),']'
    write(1,'(a)') 'ENDVARS'
    close(1)

end program ncdc2grads
