        program saod2dat
!
!       convert the GISS stratospheric optical depth file to
!       Climate Explorer conventions
!
        implicit none
        integer yr,mo,i,j,k,ii(8)
        real fyr,vals(3)
        character reg(3)*2,region(3)*20
        data reg /'gl','nh','sh'/
        data region /'global','northern hemisphere',
     +       'southern hemisphere'/

        do i=1,3
            open(i,file='saod_'//reg(i)//'.dat')
            write(i,'(3a)') '# ',trim(region(i)),
     +           ' Optical Thickness at 550 nm'
            write(i,'(3a)') '# from <a href="http://data.giss.nasa.gov/'
     +           ,'modelforce/strataer/">NASA/GISS</a>'
            write(i,'(a)')
     +           '# AOD [1] stratospheric aerosol optical depth'
        end do
        open(10,file='tau_line.txt',status='old')
        do i=1,4
            read(10,'(a)')
        end do
 1      do while ( .true. )
            read(10,*,end=800) fyr,vals
            yr = int(fyr)
            mo = 1 + int(12*(fyr-yr))
            do i=1,3
                write(i,'(i4,i3,f6.3)') yr,mo,vals(i)
            end do
        end do
 800    continue
        call date_and_time(values=ii)
!       assume no volcano erupted the last few years...
        do i=yr,ii(1)
            do j=1,12
                if ( i.eq.yr .and. j.le.mo ) cycle
                if ( i.eq.ii(1) .and. j.ge.ii(2) ) cycle
                do k=1,3
                    write(k,'(i4,i3,f6.3)') i,j,0.
                end do
            end do
        end do
!
        end
