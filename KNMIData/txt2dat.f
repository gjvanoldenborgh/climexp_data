        program txt2dat
*
*       program to convert Albert's daily measurements to my .dat format
*
        implicit none
        integer i,j,dpm(12,2),istation,idatum,ival,dy,mo,yr,leap
        real val(31,12)
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31,
     +            31,29,31,30,31,30,31,31,30,31,30,31/
*       
        do i=1,12
            do j=1,31
                val(j,i) = -999.9
            enddo
        enddo
        open(1,'debilt_temp_daily.txt',status='old')
        dy = 1
        mo = 1
        yr = 1901
        leap = 1
  100   continue
        read(1,*,end=800,err=900) istation,idatum,ival
        if ( istation.ne.260 ) then
            print *,'error: istation = ',istation
            call abort
        endif
        if ( idatum.ne.dy+100*mo+10000*yr ) goto 100
        val(dy,mo) = ival/10.
        dy = dy + 1
        if ( dy.gt.dpm(mo,leap) ) then
            dy = dy-dpm(mo,leap)
            mo = mo + 1
            if ( mo.gt.12 ) then
                print '(i4,366f7.1)',yr,((val(j,i),j=1,dpm(i,leap)),i=1
     +                ,12)
                do i=1,12
                    do j=1,31
                        val(j,i) = -999.9
                    enddo
                enddo
                mo = mo - 12
                yr = yr + 1
                if ( mod(yr,4).eq.0 .and. ( mod(yr,100).ne.0 .or.
     +                mod(yr,400).eq.0 ) ) then
                    leap = 2
                else
                    leap = 1
                endif
            endif
        endif
        goto 100
  800   continue
        if ( mo.ne.1 .or. dy.ne.1 ) then
            print *,'end not at end of year',yr,mo,dy
            call abort
        endif
        stop
  900   continue
        print *,'error reading at ',yr,mo,dy
        end

