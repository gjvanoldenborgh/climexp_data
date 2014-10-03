        program daily2monthly
*
*       proglet to convert Albert's daily reading to monthly files that
*       the climatologist is more happy with.
*       
*       assumed input format:
*       stationno. yyyymmdd  10*value
*       
*       output format
*       5 lines
*       yyyy v1 v2 ... v12
*       
        implicit none
        integer i,j,yr,mo,dy,yr1,mo1,dy1,dat,num,dpm(12,2),leap,vlag
        real x,val(12),val2(12)
        character string*80
        integer iargc
        external iarcg,getarg
        data dpm 
     +        /31,28,31,30,31,30,31,31,30,31,30,31
     +        ,31,29,31,30,31,30,31,31,30,31,30,31/
*       
        if ( iargc().ne.1 ) then
            print *,'usage: daily2monthly infile'
            stop
        endif
        call getarg(1,string)
        open(1,file=string,status='old')
        do i=1,12
            val(i) = -999.9
        enddo
        print '(a)','converted from daily to monthly by daily2monthly'
        print '(2a)','input file ',string(1:index(string,' ')-1)
        do i=1,3
            print '(a)','This line intentionally left blank'
        enddo
        yr1 = -1
        mo1 = -1
        dy1 = -1
*       
  100   continue
        read(1,*,err=900,end=800) num,dat,x
        yr = dat/10000
        mo = mod(dat/100,100)
        dy = mod(dat,100)
        if ( mo.lt.1 .or.mo.gt.12 ) goto 901
        if ( mod(yr,4).eq.0 .and. 
     +        (mod(yr,100).ne.0 .or. mod(yr,400).eq.0 ) ) then
            leap = 2
        else
            leap = 1
        endif
        if ( dy.lt.1 .or. dy.gt.dpm(mo,leap) ) goto 902
        if ( mo.eq.mo1 .and. dy.ne.dy1+1 ) then
            if ( dy.eq.10 .or. dy.eq.20 ) then
*               decade-gemiddelde
                goto 100
            endif
            if ( dy.eq.dpm(mo,leap) ) then
                vlag = vlag + 1
                if ( vlag.eq.2 ) then
                    val2(mo) = x/10
                    if ( mo.eq.12 ) then
                        write(99,1001) yr,val2
                    endif
                endif
                goto 100
            endif
            goto 903
        else
            vlag = 0
        endif
        if ( mo.ne.mo1 .and. dy.ne.1 ) goto 904
        x = x/10
        if ( x.lt.-20 .or. x .gt.40 ) goto 905
*       
        if ( dy.eq.1 ) val(mo) = 0
        val(mo) = val(mo) + x
        if ( dy.eq.dpm(mo,leap) ) then
            val(mo) = val(mo)/dy
            if ( mo.eq.12 ) then
                print 1000,yr,val
                do i=1,12
                    val(i) = -999.9
                enddo
            endif
        endif
        yr1 = yr
        mo1 = mo
        dy1 = dy
        goto 100
  800   continue
        if ( mo.ne.12 ) then
            if ( dy.ne.dpm(mo,leap) ) then
                val(mo) = -999.9
            endif
            print 1000,yr,val
        endif
        stop
*       
 1000   format(i5,12f8.2)
 1001   format(i5,12f8.1)
*
  900   print *,'error reading from file ',string(1:index(string,' '))
        stop
  901   print *,'error: wrong month: ',dat
        stop
  902   print *,'error: wrong day: ',dat
        stop
  903   print *,'error: non-consecutive days: ',yr1,mo1,dy1,yr,mo,dy
        stop
  904   print *,'error: does not start at first of month: ',yr1,mo1,dy1
     +        ,yr,mo,dy
        stop
  905   print *,'error: temperature outside -20 .. +40 ',x
        stop
        end
