        program ninoweek2daily
*
*       convert the weekly NCEP NINO indices to daily .dat files
*
        implicit none
        integer yr,mo,dy,i,j,yr2,mo2,dy2,jul1,jul2
        real nino(2:5,2),alpha,dum
        character file*128,months*36,month*3
	logical myfile
        integer julday
        external julday
        data months /'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC'/

        open(1,file='wksst8110.for',status='old')
        do i=1,4
            read(1,'(a)')
        enddo
        do i=2,5
            write(file,'(a,i1,a)') 'nino',i,'_daily.dat'
            open(10+i,file=file,status='unknown')
            write(10+i,'(a,i2,3a)') '# NINO index #',i,' (5=3.4) from ',
     +           '<a href="http://www.cpc.noaa.gov/data/indices/">CPC',
     +           '</a>'
            write(10+i,'(a)')
     +            '# interpolated from weekly to daily values'
            write(10+i,'(a)') '# SSTa [Celsius]'
        enddo
        jul1 = -999
  100   continue
        read(1,'(i3,a3,i4,4(f9.1,f4.1))',end=800,err=900) dy2,month,yr2
     +        ,dum,nino(2,2),dum,nino(3,2),dum,nino(5,2),dum,nino(4,2)
        mo2 = (index(months,month)+2)/3
        if ( mo2.eq.0 ) then
            write(0,*) 'error: could not interpret month ',month
            call abort
        endif
        if ( jul1.gt.-999 ) then
            jul2 = julday(mo2,dy2,yr2)
            do j=1,jul2-jul1
                alpha = j/real(jul2-jul1)
                call caldat(jul1+j,mo,dy,yr)
                do i=2,5
                    write(10+i,'(i4,2i3,f9.2)') yr,mo,dy,
     +                    (1-alpha)*nino(i,1) + alpha*nino(i,2)
                enddo
            enddo
            jul1 = jul2
            do i=2,5
                nino(i,1) = nino(i,2)
            enddo
        endif
        goto 100
  800   continue
        close(1)
        goto 999
  900   continue
        print *,'error reading from wksst.for'
        close(1)
        goto 999
  999   continue
        end
