        program test_schuurman
*
*       compute whether the 22.25 Schuurman cycles are more special than
*       others
*
        implicit none
        integer i,j,k,l,m,n,yr,nzero,minzero,ip,yrs(0:100)
        real period,phase,year,val,s,data(1706:2000),maxval,
     +       phasezero(50),cutoff
        character line*80
        cutoff = 1
*
*       read data
*
        open(1,file='ilabrijn_mean4.dat',status='old')
 100    continue
        read(1,'(a)') line
        if ( line(1:1).eq.'#' ) goto 100
        read(line,*) yr,val
        if ( yr.ne.1706 ) then
            print *,'error: expecting 1706, not ',trim(line)
            call abort
        endif
        data(1706) = max(0.,cutoff-val)
        do yr=1707,2000
            read(1,*) i,val
            if ( i.ne.yr ) then
                print *,'error: expecting ',yr,', not ',i
                call abort
            endif
            data(yr) = max(0.,cutoff-val)
        enddo
*
*       try all periods between 10 and 40 year
*
        do i=0,120
            period = 10 + 0.25*i
*
*           try all phases
*
            maxval = 0
            minzero = 999
            ip = 0
            do j=0,nint(4*period)-1
                phase = 0.25*j
                val = 0
                nzero = 0
                n = 0
                yrs = 0
                do k=0,100
                    year = 1706 + k*period + phase
                    if ( year.gt.2005 ) exit
                    s = 0
                    m = 0
                    do l=0,4
                        yr = nint(year-0.0001+l-1.5)
                        if ( abs(yr-year).gt.1.6 ) cycle
                        if ( yr.lt.1706 .or. yr.gt.2000 ) cycle
                        if ( data(yr).gt.s ) then
                            s = data(yr)
                            yrs(k) = yr
                        endif
                        m = m + 1
                    enddo
                    if ( m.eq.0 ) cycle
                    n = n + 1
                    if ( s.eq.0 ) then
                        nzero = nzero + 1
                    endif
                    val = val + s
                enddo
                if ( n.gt.0 ) then
                    maxval = max(maxval,val/n)
                    minzero = min(minzero,nzero)
                    if ( nzero.eq.0 ) then
                        ip = ip + 1
                        phasezero(ip) = phase
                        do k=0,100
                            if ( yrs(k).gt.0 ) then
                                if ( yrs(k).ge.1706 .and. yrs(k).le.2000
     +                               ) then
                                    print '(a,i4,f8.3)','# ',yrs(k)
     +                                   ,cutoff-data(yrs(k))
                                else
                                    write(0,*) 'error: yrs(',k,') = '
     +                                   ,yrs(k)
                                endif
                            endif
                        enddo
                    endif
                endif
            enddo
            print *,period,maxval,minzero,(phasezero(k),k=1,ip)
        enddo
        end
