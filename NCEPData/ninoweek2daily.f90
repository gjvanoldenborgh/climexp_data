program ninoweek2daily

!   convert the weekly NCEP NINO indices to daily .dat files

    implicit none
    integer :: yr,mo,dy,i,j,yr2,mo2,dy2,jul1,jul2,idatum(8)
    real :: nino(2:5,2),alpha,dum
    character :: file*128,months*36,month*3,line*80,ninoname(2:5)*2
    logical :: myfile
    integer :: julday
    external julday
    data months /'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC'/
    data ninoname /'12','3 ','4 ','34'/

    open(1,file='wksst8110.for',status='old')
    do i=1,4
        read(1,'(a)')
    enddo
    call date_and_time(values=idatum)
    line = '# history :: retrieved from NCEP and converted'
    write(line(len_trim(line)+2:),'(i4,a,i2.2,a,i2.2)') idatum(1),'-',idatum(2),'-',idatum(3)
    write(line(len_trim(line)+2:),'(i2,a,i2.2,a,i2.2)') idatum(5),':',idatum(6),':',idatum(7)
    do i=2,5
        write(file,'(3a)') 'nino',trim(ninoname(i)),'_weekly.dat'
        open(10+i,file=file,status='unknown')
        write(10+i,'(5a)') '# Nino',trim(ninoname(i)),' [K] Nino',trim(ninoname(i)),' index'
        write(10+i,'(2a)') '# interpolated from weekly data from ', &
            '<a href="http://www.cpc.noaa.gov/data/indices/">CPC</a>'
        write(10+i,'(a)') '# institution :: NOAA/NCEP/CPC'
        write(10+i,'(a)') '# references :: http://www.cpc.noaa.gov/data/indices/'
        write(10+i,'(a)') '# source_url :: http://www.cpc.ncep.noaa.gov/data/invdices/wksst8110.for'
        write(10+i,'(a)') trim(line)
    end do
    jul1 = -999
100 continue
    read(1,'(a)',end=800) line
!!!print *,trim(line)
    read(line,'(i3,a3,i4,4(f9.1,f4.1))',err=900) dy2,month,yr2 &
        ,dum,nino(2,2),dum,nino(3,2),dum,nino(5,2),dum,nino(4,2)
    mo2 = (index(months,month)+2)/3
    if ( mo2 == 0 ) then
        write(0,*) 'error: could not interpret month ',month
        call exit(-1)
    end if
    jul2 = julday(mo2,dy2,yr2)
!!!print *,'jul1,jul2 = ',jul1,jul2
    if ( jul1 > -999 ) then
        do j=1,jul2-jul1
            alpha = j/real(jul2-jul1)
            call caldat(jul1+j,mo,dy,yr)
            do i=2,5
                write(10+i,'(i4,2i2.2,f9.2)') yr,mo,dy,(1-alpha)*nino(i,1) + alpha*nino(i,2)
            end do
        end do
        do i=2,5
            nino(i,1) = nino(i,2)
        end do
    endif
    jul1 = jul2
    goto 100
800 continue
    close(1)
    go to 999
900 continue
    print *,'error reading from wksst.for'
    print *,trim(line)
    close(1)
    go to 999
999 continue
end program ninoweek2daily
