        program normalize_wksst
*
*       renormalzies the weekly NINO indices from NCEP to 
*       a 1979-1996 climatology, and change the dates back
*       to week numbers for easier plotting.
*
        implicit none
        integer i,j,k,day,week,month,year,lmonth(12),ndate,mdate,jj(12)
     +        ,m1,m2,date(3,2000)
        real nino(2,2:5,2000),clim(2:5,12),mnino(2,2:5,2000),a,t
        character line*128,amonth*3,months*48,weekfile*256,monthfile*256
        integer iargc
        data months /'JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC '/
        data lmonth /31,28,31,30,31,30,31,31,30,31,30,31/
*
*       process arguments
*
        if ( iargc().lt.1 ) then
            print *,'usage: normalize_wksst weekfile monthfile'
            stop
        endif
        call getarg(1,weekfile)
        if ( iargc().ge.2 ) then
            call getarg(2,monthfile)
        else
            monthfile = ' '
        endif
*
*       read data
*
        open(1,file=weekfile,status='old')
        do i=1,4
            read(1,'(a)',err=900,end=100) line
        enddo
        do i=1,2000
            read(1,'(a)',err=900,end=100) line
 2000       format(i3,a3,i4,f9.1,f4.1,f9.1,f4.1,f9.1,f4.1,f9.1,f4.1)
            read(line,2000,err=902) 
     +          day,amonth,year,((nino(k,j,i),k=1,2),j=2,5)
            month = index(months,amonth)/4 + 1
            date(1,i) = day
            date(2,i) = month
            date(3,i) = year
        enddo
  100   continue
        ndate = i-1
        close(1)
        if ( monthfile.ne.' ') then
            open(2,file=monthfile,status='old')
            read(2,'(a)') line
            do i=1,2000
                read(2,*,err=901,end=200) year,month,
     +                ((mnino(k,j,i),k=1,2),j=2,3),
     +                (mnino(k,5,i),k=1,2),(mnino(k,4,i),k=1,2)
                if (year.ne.(i-1)/12+50 .or. mod(month,12).ne.mod(i,12)
     +                )then
                    print *,'error: year,month not correct: '
                    print *,'expecting ',(i-1)/12+50,mod(i,12)
                    print *,'      got ',year,mod(month,12)
                endif
            enddo
  200       continue
            close(2)
            mdate = i-1
*
*       compute climatology 
*
            do j=1,12
                jj(j) = 0
            enddo
            do i=1+12*(1979-1950),12*(1997-1950)
                j = mod(i,12)
                if ( j.eq.0 ) j = 12
                jj(j) = jj(j) + 1
                do k=2,5
                    clim(k,j) = clim(k,j) + mnino(1,k,i)
                enddo
            enddo
            do j=1,12
                do k=2,5
                    clim(k,j) = clim(k,j)/jj(j)
                enddo
            enddo
            if ( .false. ) then
                print *,'Climatologies: '
                do j=1,12
                    print *,(clim(k,j),k=2,5)
                enddo
            endif
        endif
*
*       write out with new climatlogy
*
        print '(a)','# Weekly SST data starts week centered on 3Jan1990'
        if ( monthfile.ne.' ' ) then
            print '(a)','# climatology defined on 1979-1996'
        else
            print '(a)','# original climatology'
        endif
        print '(a)'
     +        ,'#          Nino1+2     Nino3      Nino34       Nino4'
        print '(a)'
     +        ,'# week   SST  SSTA   SST  SSTA   SST  SSTA   SST  SSTA'
        do i=1,ndate
            if ( monthfile.ne.' ' ) then
                if ( date(1,i).lt.lmonth(i)/2.+0.5 ) then
                    m1 = date(2,i) - 1
                    if ( m1.le.0 ) m1 = 12
                    m2 = date(2,i)
                    a = 2*(lmonth(m2)/2. + 0.5 - date(1,i))/(lmonth(m2)
     +                    +lmonth(m1))
                else
                    m1 = date(2,i)
                    m2 = date(2,i) + 1
                    if ( m2.gt.12 ) m2 = 1
                    a = 2*(date(1,i) - lmonth(m1)/2. - 0.5)/(lmonth(m2)
     +                    +lmonth(m1))
                    a = 1-a
                endif
                if ( .false. ) then
                    print *,'interpolating ',date(1,i),date(2,i)
                    print *,'as ',a,'*(month',m1,') + ',1-a,'*(month',m2
     +                    ,')'
                endif
                do k=2,5
                    t = a*clim(k,m1) + (1-a)*clim(k,m2)
                    nino(2,k,i) = nino(1,k,i) - t
                enddo
            endif
            print '(i4,8f6.2,i4,a3,i4)',i,((nino(j,k,i),j=1,2),k=2,5)
     +            ,date(1,i),months(4*(date(2,i)-1)+1:4*(date(2,i)-1)+3)
     +            ,date(3,i)
        enddo
*
*       error messages
*
        goto 999
  900   print *,'error reading weekly data on file '
     +        ,weekfile(1:index(weekfile,' ')-1)
        goto 999
  901   print *,'error reading monthly data on file '
     +        ,monthfile(1:index(monthfile,' ')-1)
        goto 999
  902   print *,'error reading data from line ',trim(line)
  999   continue
        end
