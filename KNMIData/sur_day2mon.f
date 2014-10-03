        program sur_day2mon
*
*       convert the Surinam daily values to monthly values
*
        implicit none
        integer yrbeg,yrend,npermax
        parameter(yrbeg=1900,yrend=2003,npermax=12)
        integer yr,mn,dy,i1,i2,i3,i4,i,n,dpm(12,2)
        real data(npermax,yrbeg:yrend),daily(31)
        character string*1000,id8*8,id9*9,idold*9,datum*7,flag(31)*1
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31,
     +        31,29,31,30,31,30,31,31,30,31,30,31/
        integer leap
        external leap
        
        call makeabsent(data,npermax,yrbeg,yrend)
        yr = 1990
        mn = 0
  100   continue
        read(*,'(a)',end=800) string
        if ( string.eq.' ' .or. index(string,',,,,,,,,,,').ne.0 )
     +        goto 100
        do dy=1,31
            flag(dy) = ' '
            daily(dy) = -999.9
        enddo
        mn = mn + 1
        if ( mn.gt.12 ) then
            yr = yr + 1
            mn = mn - 12
        endif
        if ( string(2:6).eq.'Datum' ) then
            read(string,*) id8,id9,datum
        elseif ( string(3:3).eq.'''' .or. string(5:5).eq.'''' ) then
            read(string,*) i1,id8,i2,datum
        elseif ( string(4:4).eq.',' ) then
            read(string,*,err=901) i1,id9,i2,i3,datum
        else
            read(string,*,err=901) id8,datum
        endif
        read(datum(1:4),*) i
        if ( i.lt.yr ) then
            write(0,*) 'error: expecting year ',yr,', but found ',datum
            call abort
        elseif ( i.ne.yr ) then
            mn = mn - 12*(i-yr)
            yr = i
        endif
        read(datum(6:7),*) i
        if ( i.lt.mn ) then
            write(0,*) 'error: expecting month ',mn,', but found ',datum
            call abort
        elseif ( i.ne.mn ) then
            write(0,*) 'Could not find months ',yr,mn,' up to ',i
            mn = i
        endif
        write(0,*) datum
        if ( string(2:6).eq.'Datum' ) then
            read(string,*) id8,id9,datum,i1,i2,i3,i4,
     +            (daily(dy),dy=1,dpm(mn,leap(yr)))
        elseif ( string(3:3).eq.'''' .or. string(5:5).eq.'''' ) then
            read(string,*) i1,id8,i2,datum,
     +            (daily(dy),dy=1,dpm(mn,leap(yr)))
        elseif ( string(4:4).eq.',' ) then
            read(string,*,err=901) i1,id9,i2,i3,datum,
     +            (daily(i),flag(i),i=1,dpm(mn,leap(yr))-1),
     +            daily(dpm(mn,leap(yr)))
        else
            read(string,*,err=901) id8,datum,
     +            (daily(i),flag(i),i=1,31)
            do dy=1,31
                if ( flag(dy).eq.'0' .and. daily(dy).eq.-999.9 ) then
                    daily(dy) = 0
                endif
                if ( daily(dy).gt.0 ) then
                    daily(dy) = daily(dy)/10
                endif
            enddo
        endif
***        do dy=1,31
***            print '(i3,'' '',a,'' '',f12.2)',dy,flag(dy),daily(dy)
***        enddo
*       
*       average
        data(mn,yr) = 0
        n = 0
        do dy=1,dpm(mn,leap(yr))
            if ( daily(dy).ge.0 .and. 
     +            (flag(dy).eq.' ' .or. flag(dy).eq.'0') ) then
                n = n + 1
                data(mn,yr) = data(mn,yr) + daily(dy)            
            endif
        enddo
        if ( n.lt.dpm(mn,leap(yr))-3 ) then
            data(mn,yr) = 3e33
        elseif ( n.lt.dpm(mn,leap(yr)) ) then
            data(mn,yr) = data(mn,yr)*dpm(mn,leap(yr))/n
            write(0,*) yr,mn,': assumed ',dpm(mn,leap(yr))-n
     +            ,' missing data days to have the same average '//
     +            'precip as the rest of the month'
        endif
       
        goto 100
  800   continue
        do i=1,5
            print '(a)','# '
        enddo
        do yr=yrbeg,yrend
            do mn=1,12
                if ( data(mn,yr).lt.1e33 ) goto 810
            enddo
            goto 890
  810       continue
            do mn=1,12
                if ( data(mn,yr).gt.1e33 ) data(mn,yr) = -999.9
            enddo
            print '(i5,12i5)',yr,(nint(10*data(mn,yr)),mn=1,12)
  890       continue
        enddo

        goto 999
  901   print *,i1,id8,id9,i2,i3,datum,
     +        (daily(i),flag(i),i=1,dpm(i,leap(yr)))
        call abort
  999   continue
        end
