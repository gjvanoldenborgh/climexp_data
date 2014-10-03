        program mslpnh2grads
*
*       convert file mslpnh.dat into a grads file
*       see http://www.cru.uea.ac.uk/cru/data/pressure.htm.
*
        implicit none
        integer nx,ny
        parameter (nx=36,ny=15)
        integer i,j,yr,mo,undef,idum1,idum2,idum3,month,year,idata(15)
     +        ,type
        real field(nx,ny),winter(nx,ny),absent
        character djfm*4
        parameter(absent=3e33)
*       
        djfm = 'DJFM'
        type = 4                ! 3: DJF, 4: DJFM
        undef = -32768
        open(1,file='mslpnh.dat',status='old')
        open(2,file='mslpnh'//djfm(1:type)//'.ext',status='new',form
     +        ='unformatted')
*       
        do j=1,ny
            do i=1,nx
                winter(i,j) = 0
            enddo
        enddo
        do yr=1873,1995
            do mo=1,12
                read(1,'(5i6)') idum1,idum2,month,year,idum3
                if ( month.ne.mo .or. year.ne.yr ) then
                    print *,'help! out of sync! ',year,month,yr,mo
                endif
                do i=1,36
                    read(1,'(16i6)') idum1,idata
                    do j=1,15
                        if ( idata(j).eq.undef ) then
                            field(i,j) = absent
                        else
                            field(i,j) = idata(j)/100. + 1000.
                        endif
                    enddo
                enddo
                if ( mo.eq.12 .or. mo.le.type-1 ) then
                    do j=1,ny
                        do i=1,nx
                            winter(i,j) = winter(i,j) + field(i,j)
                        enddo
                    enddo
                endif
                if ( mo.eq.type-1 ) then
                    do j=1,ny
                        do i=1,nx
                            if ( winter(i,j).lt.1e33 ) then
                                winter(i,j) = winter(i,j)/type
                            else
                                winter(i,j) = absent
                            endif
                        enddo
                    enddo
                    write(2) 100*yr,151,1,nx*ny
                    write(2) winter
                    do j=1,ny
                        do i=1,nx
                            winter(i,j) = 0
                        enddo
                    enddo
                endif
            enddo
        enddo
*
        end
