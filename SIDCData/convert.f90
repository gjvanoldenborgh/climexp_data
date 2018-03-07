program convert

!   convert http://sidc.oma.be/DATA/monthssn.dat into standard sunspot.dat file

    implicit none
    integer :: yr,mn,i,j,idatum(8)
    real :: xyr,s,ss(12)
    character :: line*100

    open(1,file='SN_m_tot_V2.0.txt',status='old')
    open(2,file='sunspots.dat',status='new')

    write(2,'(a)') '# sunspot [1] monthly mean sunspot number'
    write(2,'(a)') '# from <a href="http://sidc.oma.be/">SIDC</a>'
    write(2,'(a)') '# institution :: WDC-SILSO, Royal Observatory of Belgium, Brussels'
    write(2,'(a)') '# source :: http://sidc.oma.be/silso/home'
    write(2,'(a)') '# source_url :: http://sidc.oma.be/silso/DATA/SN_m_tot_V2.0.txt'
    write(2,'(a)') '# contact :: silso.info@oma.be'
    call date_and_time(values=idatum)
    line = '# history :: retrieved and converted'
    write(line(len_trim(line)+2:),'(i4,a,i2.2,a,i2.2)') idatum(1),'-',idatum(2),'-',idatum(3)
    write(line(len_trim(line)+2:),'(i2,a,i2.2,a,i2.2)') idatum(5),':',idatum(6),':',idatum(7)
    write(2,'(a)') trim(line)
    write(2,'(a)') '# climexp_url :: https://climexp.knmi.nl/getindices.cgi?SIDCData/sunspots'

    do yr=1749,2100
        do mn=1,12
            read(1,*,end=800) i,j,xyr,ss(mn)
            if ( i /= yr ) then
                print *,'error in year: ',yr,mn,i
                stop
            endif
            if (j /= mn ) then
                print *,'error in month ',yr,mn,i
                stop
            endif
        enddo
        write(2,'(i5,12f7.1)') yr,ss
    enddo
    write(0,*) 'time flies...'
    call exit(-1)
800 continue
    if ( mn /= 1 ) then
        do i=mn,12
            ss(i) = -999.9
        enddo
        write(2,'(i5,12f7.1)') yr,ss
    endif
    stop
end program convert
