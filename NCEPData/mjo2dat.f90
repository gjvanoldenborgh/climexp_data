program mjo2dat

!       convert the CPC pentad MJO indices file to my conventions
!       interpolate to a dayly dataset for my convenience

    implicit none
    integer :: yr,mo,dy,i,j,yr2,mo2,dy2,jul1,jul2,yrold,npentad
    real :: mjo(10,2),alpha,data(73,10)
    character :: file*128,history*1000
    integer :: julday
    external julday

    open(1,file='proj_norm_order.ascii',status='old')
    read(1,'(a)')
    read(1,'(a)')
    history = ' '
    call extend_history(history)
    do i=1,10
        write(file,'(a,i2.2,a)') 'cpc_mjo',i,'_daily.dat'
        open(10+i,file=file,status='unknown')
        write(10+i,'(a,i2,4a)') '# MJO index #',i,' from ' &
            ,'<a href="http://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_mjo_index/mjo_index.html">' &
            ,'CPC</a>'
        write(10+i,'(a)') '# interpolated from pentads to daily values'
        write(10+i,'(a)') '# institution :: NOAA/NCEP/CPC'
        write(10+i,'(a)') '# contact :: Jon.Gottschalck@noaa.gov'
        write(10+i,'(a)') '# source :: http://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_mjo_index/proj_norm_order.ascii'
        write(10+i,'(2a)') '# history :: ',trim(history)
        write(file,'(a,i2.2,a)') 'cpc_mjo',i,'.dat'
        open(20+i,file=file,status='unknown')
        write(20+i,'(a,i2,4a)') '# MJO index #',i,' from ', &
            '<a href="http://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_mjo_index/mjo_index.html">' &
            ,'CPC</a>'
        write(20+i,'(a)') '# original pentad (5-daily) values'
        write(20+i,'(a)') '# institution :: NOAA/NCEP/CPC'
        write(20+i,'(a)') '# contact :: Jon.Gottschalck@noaa.gov'
        write(20+i,'(a)') '# source :: http://www.cpc.ncep.noaa.gov/products/precip/CWlink/daily_mjo_index/proj_norm_order.ascii'
        write(20+i,'(2a)') '# history :: ',trim(history)
    enddo
    jul1 = 2**30
    yrold = -9999
    npentad = 0
100 continue
    read(1,'(i4,2i2,10f9.2)',end=800,err=900) yr2,mo2,dy2, &
        mjo(9,2),mjo(10,2),(mjo(i,2),i=1,8)
    jul2 = julday(mo2,dy2,yr2)
    if ( jul1 < 2**30 ) then
        do j=1,jul2-jul1
            alpha = j/real(jul2-jul1)
            call caldat(jul1+j,mo,dy,yr)
            do i=1,10
                write(10+i,'(i4,2i3,f9.2)') yr,mo,dy, &
                    (1-alpha)*mjo(i,1) + alpha*mjo(i,2)
            enddo
        enddo
    endif
    jul1 = jul2
    do i=1,10
        mjo(i,1) = mjo(i,2)
    enddo
    if ( yrold == -9999 ) then
        yrold = yr2
        npentad = 0
    endif
    npentad = npentad + 1
    do i=1,10
        data(npentad,i) = mjo(i,2)
    enddo
    if ( yr2 /= yrold ) then
        write(0,*) 'error: yr2 /= yrold!',yr2,yrold
        call abort
    endif
    if ( npentad == 73 ) then
        do i=1,10
            write(20+i,'(i4,73f9.2)') yr2,(data(j,i),j=1,73)
            do j=1,73
                data(j,i) = -999.9
            enddo
        enddo
        yrold = -9999
    endif
    goto 100
800 continue
    close(1)
    goto 999
900 continue
    print *,'error reading from proj_norm_order.ascii'
    close(1)
    goto 999
999 continue
    if ( data(1,1) /= -999.9 ) then
        do i=1,10
            write(20+i,'(i4,73f9.2)') yr2,(data(j,i),j=1,73)
        enddo
    endif
end program mjo2dat
