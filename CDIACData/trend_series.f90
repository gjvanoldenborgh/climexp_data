program trend_sres
!
!   compute trends in SRES scenario CO2 concentrations based on the 10-yearly values
!
    implicit none
    integer iset,yr
    real val1(12),val2(12)
    character file*20,string*500
    do iset=1,2
        if ( iset == 1 ) then
            file = 'tar-isam.txt'
        else
            file = 'tar-bern.txt'
        end if
        open(1,file=trim(file),status='old')
        file = 'd'//file
        open(2,file=trim(file))
        write(2,'(a)') '# first derivative taken'
        val1 = 3e33
        val2 = 3e33
        do
            read(1,'(a)',end=800) string
            if ( string(1:1) == '#' ) then
                write(2,'(a)') trim(string)
            else
                val1 = val2
                read(string,*) yr,val2
                if ( val1(1) < 1e33 ) then
                    !!!write(2,'(i7,12f8.2)') yr-10,(val2-val1)/10
                    !!!write(2,'(i7,12f8.2)') yr,(val2-val1)/10
                    write(2,'(i7,12f8.2)') yr-5,(val2-val1)/10
                end if
            end if 
        end do
800     continue
    end do
end program