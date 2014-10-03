        program asc2dat
*
*       average the daily Space Absolute Radiometric Reference 
*       into a monthly mean .dat file 
*
        implicit none
        integer i,n,yr,mo,dy,dpm(12,0:1),leap
        real d,s,val(12),data(-730:15000)
        character*80 line
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31,
     +            31,29,31,30,31,30,31,31,30,31,30,31/
*
        line = 'composite_d19.asc'
        open(1,file=line,status='old')
*
*       headers
*
        print '(a)',line
        print '(2a)','Space_Absolute_Radiometric_Reference [W/m2] from '
     +        ,'<a href="http://www.pmodwrc.ch">PMOD</a>'
        i = 0
   10   continue
        read(1,'(a)') line
        if ( line.eq.' ' ) goto 10
        i = i + 1
        if ( i.eq.7 .or. i.eq.8 .or. i.eq.9 ) then
            print '(a)',trim(line(2:))
        endif
        if ( line(1:1).eq.';' ) goto 10
*
*       read data
*
        do i=-730,15000
            data(i) = -999.9
        enddo
  100   continue
        read(line,'(f12.2,f12.4)',err=900,end=800) d,s
        i = nint(d)
        if ( abs(i-d).gt.0.01 ) then
            print *,'error: not on an integer day: ',d
        endif
	if ( i.lt.-730 .or. i.gt.15000 ) then
            write(0,*) 'error: enlarge array ',i
            call abort
	endif
        if ( s.ge.0 ) data(i) = s
  110   continue
        read(1,'(a)',err=900,end=800) line
	if ( line.eq.' ' ) goto 110
        goto 100
  800   continue
*
*       average
*
        n = -730                ! 1-jan-1978
        do yr=1978,2005
            if ( mod(yr,4).eq.0 ) then
                leap = 1
            else
                leap = 0
            endif
            do mo=1,12
                val(mo) = 0
                i = 0
                do dy=1,dpm(mo,leap)
                    if ( data(n).gt.0 ) then
                        val(mo) = val(mo) + data(n)
                        i = i + 1
                    endif
                    n = n + 1
		    print *,dy,mo,yr,n
                    if ( n.gt.15000 ) then
			write(0,*) 'error: n>15000',n
			call abort
		    endif
                enddo
                if ( i.gt.0 ) then
                    val(mo) = val(mo)/i
                else
                    val(mo) = -999.9
                endif
            enddo
            do i=1,12
                if ( val(i).ne.-999.9 ) then
                    print '(i5,12f10.4)',yr,val
                    goto 200
                endif
            enddo
  200       continue
        enddo
        stop
*
*       error messages
*
  900   print *,'error reading data at ',d,s
        end
