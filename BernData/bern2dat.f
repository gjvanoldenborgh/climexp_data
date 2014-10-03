        program bern2dat
*       to make a standard .dat file from Juerg Luterbachers file
        implicit none
        integer i,j,yr,mo,yrold
        real nao(12,2),data(2)
        character line*80, months(12)*3, month*3
        data months /'Jan','Feb','Mar','Apr','May','Jun',
     +        'Jul','Aug','Sep','Oct','Nov','Dec'/
*
        open(10,file='nao.back1659.txt',status='old')
        open(1,file='luterbacher_NAO1.dat')
        open(2,file='luterbacher_NAO2.dat')
*
*       print comments
        do i=1,2
            write(i,'(a,i1,a)') 'NAO',i,' index from Juerg Luterbacher'
            write(i,'(2a)') 'Please e-mail juerg@giub.unibe.ch if ',
     +            'you use this data and cite'
            write(i,'(2a)') 'Luterbacher, J., C. Schmutz, ',
     +            'D. Gyalistras, E. Xoplaki, and H. Wanner, 1999'
            write(i,'(2a)') 'Reconstruction of monthly NAO and EU ',
     +            'indices back to AD 1675'
            write(i,'(2a)') 'Geophys. Res. Lett., 26, 2745-2748, ',
     +            'updated and revised'
        enddo
*
*       skip comments
  100   continue
        read(10,'(a)') line
        if ( line(1:13).ne.'Reconstructed') goto 100
        read(10,'(a)') line
        read(10,'(a)') line
*
*       read data
        yrold = 0
        do i=1,12
            nao(i,1) = -999.9
            nao(i,2) = -999.9
        enddo
  200   continue
        read(10,'(i4,x,a3,2f6.2)',end=800,err=900) yr,month,data
        do mo=1,12
            if ( month.eq.months(mo) ) goto 300
        enddo
        print *,'error: unknown month: ',month
        stop
  300   continue
        if ( yrold.eq.0 ) yrold = yr
        if ( yr.ne.yrold ) then
            do i=1,2
                write(i,'(i4,12f8.2)') yrold,(nao(j,i),j=1,12)
                do j=1,12
                    nao(j,i) = -999.9
                enddo
            enddo
            yrold = yr
        endif
        do i=1,12
            nao(mo,i) = data(i)
        enddo
        goto 200
*       
*       end game
  800   continue
        do i=1,2
            write(i,'(i4,12f8.2)') yr,(nao(j,i),j=1,12)
        enddo
        stop
*       
*       errors
  900   print *,'error reading data, last year,month = ',yr,mo
        end
