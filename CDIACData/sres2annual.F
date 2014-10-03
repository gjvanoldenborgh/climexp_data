        program sres2annual
!
!       convert the file tar-isam.txt to annual-mean values for climexp
!       using a simple linear interpolation
!
        implicit none
        integer yr,i,i0,i1,j,isres
        real sres(12,15),co2(1000:2100)
        character line*255,names(6)*4
        data names /'A1B ','A1T ','A1FI','A2  ','B1  ','B2  '/

        print *,'opening tar-isam.txt'
        open(1,file='tar-isam.txt',status='old')
        i = 1
        sres = 3e33
 100    continue
        read(1,'(a)',end=190) line
        if ( line(1:1).eq.'#' ) goto 100
        read(line,*) yr,(sres(j,i),j=1,12)
        if ( yr.ne.1960+10*i ) then
            write(0,*) 'error: expecting yr ',1960+10*i,', found ',yr
            call abort
        end if
        i = i + 1
        goto 100
 190    continue
        close(1)
        
        print *,'opening co2_annual.dat'
        open(1,file='co2_annual.dat',status='old')
        i = 1000
        co2 = 3e33
 200    continue
        read(1,'(a)',end=290) line
        if ( line(1:1).eq.'#' ) goto 200
        read(line,*) yr,co2(i)
        if ( yr.ne.i ) then
            write(0,*) 'error: expecting yr ',i,', found ',yr
            call abort
        end if
        i = i + 1
        if ( i.gt.2000 ) goto 290
        goto 200
 290    continue
        close(1)
        yr = i - 1

        do isres=1,6
            open(1,file=trim(names(isres))//'.dat')
            write(1,'(a,i4,a)') '# 1850-',yr
     +           ,' observed CO2 concentrations'
            write(1,'(a,i4,3a)') '# ',yr+1,'-2100: SRES '
     +           ,trim(names(isres)),' scenario'
            write(1,'(a)') '# CO2 [ppm] CO2 concentration'
            do i=1850,yr
                if ( co2(i).lt.1e33 ) then
                    write(1,'(i4,f8.2)') i,co2(i)
                else
                    write(0,*) 'warning: year ',' is undefined'
                end if
            end do
            do i=yr+1,2100
                i0 = 10*(i/10)
                i1 = i0 + 10
                co2(i) = ((i1-i)*sres(isres,i0/10-196)
     +               + (i-i0)*sres(isres,i1/10-196))/(i1-i0)
                write(1,'(i4,f8.2)') i,co2(i)
            end do
            close(1)
        end do
        end
