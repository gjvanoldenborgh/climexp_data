        program update_nao
!
!       updates the NAO based on Tim Osborn's web page
!
        implicit none
        integer yrbeg,yrend
        parameter(yrbeg=1800,yrend=2020)
        integer yr,mo,n,i,j,j1,j2,yrold
        real data(12,yrbeg:yrend)
        character line*128,var*40,units*40
        logical lwrite
        lwrite = .false.
        yrold = -1

        call readseries('nao_base.dat',data,12,yrbeg,yrend,n,var,units,
     +       .false.,lwrite)
        open(1,file='naoi.htm')
 100    continue
        read(1,'(a)') line
        call tolower(line)
        i = index(line,'<tr><th>2')
        if ( i.eq.0 ) goto 100
!       found table, read year
        i = i + 8
        read(line(i:i+3),*) yr
        if ( yr.lt.yrold ) goto 800
        yrold = yr
!       read 2 times 6 monthly values
        do mo=1,12
            j1 = index(line(i:),'+')
            j2 = index(line(i:),'-')
            if ( j1.eq.0 ) then
                if ( j2.eq.0 ) then
                    goto 800
                else
                    j = j2
                endif
            else
                if ( j2.eq.0 ) then
                    j = j1
                else
                    j = min(j1,j2)
                endif
            endif
            j = -1 + i + j
            read(line(j:j+4),*) data(mo,yr)
            i = j + 5
            if ( mo.eq.6 ) then
                read(1,'(a)') line
                i = 1
            end if
        end do
        goto 100

!       end of table
 800    continue
        close(1)
        do yr=yrbeg,yrend
            do mo=1,n
                if ( data(mo,yr).lt.-90 ) data(mo,yr) = 3e33
            end do
        end do
        call copyheader('nao_base.dat',6)
        call printdatfile(6,data,12,12,yrbeg,yrend)
        end

