        program aap
*
*       sum a triangle extending from -2weeks to +2weeks in column n
*
        implicit none
        integer i,j,k,n,yr,mn,dy,date,leap,dpm(12,2)
        real x(100),s,s0
        character string*256
        integer iargc
        external iargc,getarg
        data dpm 
     +        /31,28,31,30,31,30,31,31,30,31,30,31
     +        ,31,29,31,30,31,30,31,31,30,31,30,31/
*
*       arguments
*
        if ( iargc().ne.3 ) then
            print *,'usage: sumtriangle file yyyymmdd ncol'
            stop
        endif
        call getarg(1,string)
        open(1,file=string,status='old')
        call getarg(2,string)
        read (string,*) date
        call getarg(3,string)
        read (string,*) n
*
*       parse date
*
        yr = date/10000
        mn = mod(date/100,100)
        dy = mod(date,100)
        if ( mod(yr,4).ne.0 .or. 
     +        ( mod(yr,100).eq.0 .and. mod(yr,400).ne.0 ) ) then
            leap = 1
        else
            leap = 2
        endif
        if ( mn.lt.1 .or. mn.gt.12 ) then
            print *,'invalid month: ',mn,date
            stop
        endif
        if ( dy.lt.1 .or. dy.gt.dpm(mn,leap) ) then
            print *,'invalid day: ',mn,dy
            stop
        endif
*       
*       subtract 14 days
*       
        dy = dy-14
        if ( dy.lt.1 ) then
            mn = mn - 1
            if ( mn.lt.1 ) then
                mn = mn + 12
                yr = yr - 1
            endif
            dy = dy + dpm(mn,leap)
        endif
        date = dy + 100*(mn + 100*yr)
*       
*       scan through file to date
*       
  100   continue
        read(1,*) i
        if ( i.lt.date ) goto 100
        if ( i.gt.date ) then
            print *,'Date ',date,'  not found in file ',i
            stop
        endif
*       
*       sum triangle
*       
        s = 0
        do i=1,27
            dy = dy + 1
            if ( dy.gt.dpm(mn,leap) ) then
                dy = dy - dpm(mn,leap)
                mn = mn + 1
                if ( mn.gt.12 ) then
                    yr = yr + 1
                    mn = mn - 12
                endif
            endif
            date = dy + 100*(mn + 100*yr)
            read(1,*) k,(x(j),j=1,n)
            if ( k.ne.date ) then
                print *,'error: expected ',date,' but found ',k
                stop
            endif
            if ( i.le.14 ) then
                s0 = s0 + i/14.
                s = s + x(n)*i/14.
            else
                s0 = s0 + (28-i)/14.
                s = s + x(n)*(28-i)/14.
            endif
        enddo
        s = s/s0
        print *,'2week triangle gave ',s
        end
