        program vulkaa2dat
*
*       convert Aad van Ulden's vulcano file to the standard .dat format
*
        implicit none
        integer i,j
        real date(5),forcing(5),forcm(12),a
        character line*80
*
*       5 header lines
*
        print '(2a)','Volcanic radiative forcming (W/m2) ',
     +        '(van Ulden and van Dorland,1999)'
        print '(3a)','Based on reconstruction of annual optical ',
     +        'depth by Sato et al.(1993), updated as in IPCC 1995. ',
     +        'Annual values were redistributed  over the 4 seasons,'
        print '(3a)','accounting for the dates of major eruptions. ',
     +        'Further updated to 1997, using the updated lunar eclips',
     +        ' data by Richard Keen (Science,222, 1011-1013), webpage.'
        print '(3a)','The radiative forcing is obtained according to ',
     +        'Lacis et al. (1992) by multiplying the visible optical ',
     +        'depth by 30 (as in IPCC 1995).'
        print '(a)'
*       
        open(1,file='vulkaan',status='old')
  100   continue
        read(1,'(a)') line
        if ( line(1:2).ne.'18' ) goto 100
        read(line,*) date(1),forcing(1)
        if ( abs(mod(date(1),1.)-.05).gt..01 ) then
            print '(2a)','error: can only handle starting dates on an ',
     +            'integer year (well, year.05)'
            stop
        endif
        i = 1
  200   continue
        i = i+1
        read(1,*,end=800,err=900) date(i),forcing(i)
***        print *,date(i),forcing(i)
        if ( i.eq.5 ) then
            do j=1,4
                forcm(3*(j-1)+1) = forcing(j)
                forcm(3*(j-1)+2) = 2/3.*forcing(j) + 1/3.*forcing(j+1)
                forcm(3*(j-1)+3) = 1/3.*forcing(j) + 2/3.*forcing(j+1)
            enddo
            print '(i5,12f8.4)',nint(date(1)),forcm
            date(1) = date(5)
            forcing(1) = forcing(5)
            i = 1
        endif
        goto 200
  900   continue
        write(0,*) 'error reading vulkaan!'
  800   continue
        do j=i+1,5
            forcing(j) = 3e33
        enddo
        do j=1,4
            forcm(3*(j-1)+1) = forcing(j)
            forcm(3*(j-1)+2) = 2/3.*forcing(j) + 1/3.*forcing(j+1)
            forcm(3*(j-1)+3) = 1/3.*forcing(j) + 2/3.*forcing(j+1)
        enddo
        do j=1,12
            if ( forcm(j).gt.1e10 ) forcm(j) = -999.9
        enddo
        print '(i5,12f12.4)',nint(date(1)),forcm
        stop
        end
