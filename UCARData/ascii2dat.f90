    program ascii2dat

!       as the netCDF file is unreadable by my routines I convert
!       the ASCII version to GrADS format.  Boring.

    implicit none
    integer,parameter :: recfa4=4
    integer,parameter :: nx=72,ny=16
    integer :: i,j,k,yr,mo
    real :: data(nx,ny)
    character(1000) :: line

    open(2,file='ds010_1.ascii',status='old')
    open(1,file='ds010_1.dat',access='direct',recl=nx*ny*recfa4)
    do yr=1899,2020
        do mo=1,12
            do j=1,ny
                do i=1,nx
                    data(i,j) = 3e33
                enddo
            enddo
!**                if ( yr.eq.1899 .and. mo.eq.1 ) goto 800
!**                if ( yr.eq.1944 .and. mo.eq.12 ) goto 800
            read(2,'(a)',end=900) line
            k = index(line,'Date:') + 6
            if ( k == 6 ) then
                write(0,*) 'error: cannot find ''Date:'' in ',line
                call exit(-1)
            endif
        100 read(line(k:),'(i4,x,i2)') i,j
            if ( i /= yr .or. j /= mo ) then
                if ( j < mo ) then
!                   we have one duplicate month :-(
                110 read(2,'(a)',end=900) line
                    k = index(line,'Date:') + 6
                    if ( k == 6 ) go to 110
                    goto 100
                endif
                write(0,*) 'error: yr,mo do not agree: ',yr,mo,i,j
            endif
            read(2,'(a)') line
            k = index(line,'Pole:') + 7
            if ( k == 7 ) then
                write(0,*) 'error: cannot find ''Pole:'' in ',line
                call exit(-1)
            endif
            if ( index(line(k:k+10),'N/A') == 0 ) then
                read(line(k:),'(f6.1)') data(1,16)
                do i=2,nx
                    data(i,16) = data(1,16)
                enddo
            endif
            read(2,'(a)') line
            print '(2a)','skipping ',line(1:20)
            do k=1,4
                do i=1,3
                    read(2,'(a)') line
                    print '(2a)','skipping ',line(1:20)
                enddo
                do j=ny-1,1,-1
                    read(2,'(a)') line
                    print '(2a)','reading  ',line(1:20)
                    read(line,'(i3)') i
                    if ( i /= 5*j+10 ) then
                        write(0,*) 'error: read latitude ',i,5*j+10
                        call exit(-1)
                    endif
                    read(line(7:),'(18f8.1)') (data(i,j),i=18*(k-1)+1,18*k)
                enddo
            enddo
            do j=1,ny
                do i=1,nx
                    if ( data(i,j) == 0 ) data(i,j) = 3e33
                    if ( data(i,j) < 1e33 .and. &
                    ( data(i,j) < 950 .or. data(i,j) > 1060 ) ) then
                        write(0,*) 'error: data(',i,j,')=',data(i,j)
                    endif
                enddo
            enddo
            read(2,'(a)') line
        800 continue
            write(*,*) yr,mo
            do k=1,4
                do j=16,1,-1
!**                        write(*,'(18f8.1)') (data(i,j),i=18*k-17,18*k)
                enddo
            enddo
            write(1,rec=mo+12*(yr-1899)) data
        enddo
    enddo
900 continue
    close(1)
    close(2)
    print *,'yr,mo = ',yr,mo
    open(1,file='ds010_1.ctl')
    write(1,'(a)') 'DSET ^ds010_1.dat'
    write(1,'(a)') 'TITLE Trenberth Northern Hemisphere Monthly SLP'
    write(1,'(a)') 'UNDEF 3e33'
    write(1,'(a)') 'XDEF 72 LINEAR 0 5'
    write(1,'(a)') 'YDEF 16 LINEAR 15 5'
    write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
    write(1,'(a,i4,a)') 'TDEF ',-1+mo+12*(yr-1899),' LINEAR 15JAN1899 1MO'
    write(1,'(a)') 'VARS 1'
    write(1,'(a)') 'slp 0 99 observed sealevel pressure [mb]'
    write(1,'(a)') 'ENDVARS'
    close(1)
end program ascii2dat

