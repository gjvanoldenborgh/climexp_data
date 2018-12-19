program oi2grads

!       convert the NCEP v2 OI data to GrADS files
!       based on the example in the file README
!                        Geert Jan van Oldenborgh, KNMI, nov-2000

    implicit none
    integer,parameter :: recfa4=4
    integer :: i,j,yr,mo,iyrst,imst,idst,iyrend,imend,idend,ndays,index ,irec,iyr1,imn1,iret,mobegin
    real :: sst(360,180),ls(360,180),ice(360,180)
    character :: cyyyymm*6,months(12)*3,file*14,cice(360,180)*1
    logical :: lexist,lgzip,lafter
    integer :: system
    data months /'JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'/

    open(4,file='lstags.onedeg.dat',form='unformatted',access='direct',recl=360*180*recfa4,status='old')
    read (4,rec=1) ls
    close(4)

    open(2,file='sstoi_v2.dat',form='unformatted',access='direct',recl=360*180*recfa4)
    open(3,file='iceoi_v2.dat',form='unformatted',access='direct',recl=360*180*recfa4)
    irec = 0

    lafter = .false. 
    iyr1 = 1981
    mobegin = 11
    do yr=iyr1,2030
        do mo=1,12
            if ( yr == iyr1 .and. mo < mobegin ) cycle
            write(file,'(a,i4,i2.2)') 'oiv2mon.',yr,mo
            inquire(file=file,exist=lexist)
            if ( .not. lexist ) then
                inquire(file=file//'.gz',exist=lexist)
                if ( .not. lexist ) then
                    print *,'wget ftp://ftp.emc.ncep.noaa.gov/cmb/sst/oimonth_v2/'//file//'.gz'
                    iret = system('wget ftp://ftp.emc.ncep.noaa.gov/cmb/sst/oimonth_v2/'//file//'.gz')
                    inquire(file=file//'.gz',exist=lexist)
                    if ( .not. lexist ) then
                        if ( yr < 2000 ) then
                            write(0,*) '@@@',yr,mobegin
                            mobegin = mo+1
                            cycle
                        endif
                        print *,'cannot find ',file
                        if ( lafter ) go to 800
                        do j=1,180
                            do i=1,360
                                sst(i,j) = 3e33
                            enddo
                        enddo
                        irec = irec + 1
                        write(2,rec=irec) sst
                        write(3,rec=irec) sst
                        goto 700
                    else
                        lgzip = .true. 
                    endif
                else
                    lgzip = .true. 
                endif
                if ( lgzip ) then
                    iret =system('gunzip -c '//file//'.gz > '//file)
                endif
            else
                lgzip = .false. 
            endif
            lafter = .true. 
            open(1,file=file,form='unformatted',convert='big_endian',status='old')
            read(1) iyrst,imst,idst,iyrend,imend,idend,ndays,index
            if ( iyrst /= yr .or. imst /= mo ) then
                write(0,*) 'error in dates ',yr,mo,iyrst,imst
                call exit(-1)
            endif
            read(1) ((sst(i,j),i=1,360),j=1,180)
            read(1) ((cice(i,j),i=1,360),j=1,180)
        !       Print date info and SST at one location for each month
            print 7,irec+1,iyrst,imst,idst,iyrend,imend,idend,sst(70,80)
        7   format (i4,' DATES =',i4,2I2.2,' - ',I4,2i2.2,3X,'SST (110.5W,10.5S) =',F6.2)
            do j=1,180
                do i=1,360
                    if ( ls(i,j) == 0 ) then
                        sst(i,j) = 3e33
                    endif
                enddo
            enddo
            do j=1,180
                do i=1,360
                    if ( ichar(cice(i,j)) == 122 ) then
                        ice(i,j) = 3e33
                    else
                        ice(i,j) = ichar(cice(i,j))/100.
                    endif
                enddo
            enddo
            irec = irec + 1
            write(2,rec=irec) ((sst(i,j),i=1,360),j=1,180)
            write(3,rec=irec) ((ice(i,j),i=1,360),j=1,180)
            close(1)
        700 continue
        enddo
    enddo
800 continue
    close(2)
    close(3)

    open(1,file='sstoi_v2.ctl')
    write(1,'(a)') 'DSET ^sstoi_v2.dat'
    write(1,'(a)') 'TITLE Reynolds OI SST'
    write(1,'(a)') 'UNDEF 3e33'
    write(1,'(a)') 'XDEF 360 LINEAR 0.5 1'
    write(1,'(a)') 'YDEF 180 LINEAR -89.5 1'
    write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
    write(1,'(a,i4,2a,i4,a)') 'TDEF ',irec,' LINEAR 15',months(mobegin),iyr1,' 1MO'
    write(1,'(a)') 'VARS 1'
    write(1,'(a)') 'sst 0 99 Reynolds OI SST [Celsius]'
    write(1,'(a)') 'ENDVARS'
    close(1)
    open(1,file='iceoi_v2.ctl')
    write(1,'(a)') 'DSET ^iceoi_v2.dat'
    write(1,'(a)') 'TITLE Reynolds OI SST'
    write(1,'(a)') 'UNDEF 3e33'
!**#if defined(sun) || defined(__sun__) || defined (__NeXT__) || defined (__sgi)
    write(1,'(a)') 'OPTIONS BIG_ENDIAN'
!**#elif defined(__alpha) || defined(linux)
!**        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
!**#endif
    write(1,'(a)') 'XDEF 360 LINEAR 0.5 1'
    write(1,'(a)') 'YDEF 180 LINEAR -89.5 1'
    write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
    write(1,'(a,i4,2a,i4,a)') 'TDEF ',irec,' LINEAR 15',months(mobegin),iyr1,' 1MO'
    write(1,'(a)') 'VARS 1'
    write(1,'(a)') 'ice 0 99 Reynolds OI ice cover [1]'
    write(1,'(a)') 'ENDVARS'
    close(1)
end program oi2grads