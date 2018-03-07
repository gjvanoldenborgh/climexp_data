program saod2dat

!   convert the GISS stratospheric optical depth file to Climate Explorer conventions

    implicit none
    integer :: yr,mo,i,j,k,ii(8)
    real :: fyr,vals(3)
    character :: reg(3)*2,region(3)*20,history*300,outfile*80
    data reg /'gl','nh','sh'/
    data region /'global','northern hemisphere','southern hemisphere'/

    call date_and_time(values=ii)
    history = '# history :: retrieved and converted'
    write(history(len_trim(history)+2:),'(i4,a,i2.2,a,i2.2)') ii(1),'-',ii(2),'-',ii(3)
    write(history(len_trim(history)+2:),'(i2,a,i2.2,a,i2.2)') ii(5),':',ii(6),':',ii(7)
    do i=1,3
        outfile = 'saod_'//reg(i)//'.dat'
        open(i,file=trim(outfile))
        write(i,'(3a)') '# ',trim(region(i)),' Optical Thickness at 550 nm'
        write(i,'(3a)') '# from <a href="http://data.giss.nasa.gov/' &
            ,'modelforce/strataer/">NASA/GISS</a>'
        write(i,'(a)') '# AOD [1] stratospheric aerosol optical depth'
        write(i,'(a)') '# institution :: NASA/GISS'
        write(i,'(a)') '# title :: GISS stratospheric aerosol optical depth at 550 nm'
        write(i,'(a)') '# contact :: https://www.giss.nasa.gov/staff/makiko_sato.html'
        write(i,'(a)') '# references :: Bourassa, A.E., A. Robock, et al. 2012: '// &
            'Large volcanic aerosol load in the stratosphere linked to Asian monsoon '// &
            'transport. Science 337, 78-81, doi:10.1126/science.1219371'
        write(i,'(a)') '# source_url :: https://data.giss.nasa.gov/modelforce/strataer/'
        write(i,'(a)') trim(history)
        write(i,'(a)') '# climexp_url :: https://climexp.knmi.nl/getindices.cgi?'//trim(outfile)
    end do
    open(10,file='tau_line.txt',status='old')
    do i=1,4
        read(10,'(a)')
    end do
    1 do while ( .true. )
        read(10,*,end=800) fyr,vals
        yr = int(fyr)
        mo = 1 + int(12*(fyr-yr))
        do i=1,3
            write(i,'(i4,i3,f6.3)') yr,mo,vals(i)
        end do
    end do
800 continue
!   assume no volcano erupted the last few years...
    do i=yr,ii(1)
        do j=1,12
            if ( i == yr .and. j <= mo ) cycle
            if ( i == ii(1) .and. j >= ii(2) ) cycle
            do k=1,3
                write(k,'(i4,i3,f6.3)') i,j,0.
            end do
        end do
    end do
end program saod2dat