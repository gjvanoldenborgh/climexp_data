        program txt2dat
*
*       convert the ASCII version of the spreadsheets (*&^%$#@!) Gunther 
*       mailed me to good'ol monthly .dat file of mean, min, max runoff
*
        implicit none
        integer nyrmax
        parameter (nyrmax=200)
        integer i,j,k,n,nyr,day,month,years(nyrmax),leap(nyrmax),nrleap
        real valday(31,12,nyrmax),valmean(12,nyrmax),valmin(12,nyrmax)
     +        ,valmax(12,nyrmax:nyrmax)
        character file*255, line*2000
        integer iargc,llen
        external iargc,getarg,llen

        if ( iargc().ne.1 ) then
            write(0,*) 'usage: txt2dat file'
            stop
        endif
        
        do i=1,nyrmax
            do month=1,12
                do day=1,31
                    valday(day,month,i) = -999
                enddo
            enddo
        enddo

        call getarg(1,file)
        open(1,file=file,status='old')
        i = index(file,'.txt')
        if ( i.eq.0 ) i = llen(file) + 1
        file(i:) = '_mean.dat'
        open(10,file=file)
        write(10,'(a)') 'computing monthly mean values'
        file(i:) = '_min.dat'
        open(11,file=file)
        write(11,'(a)') 'computing monthly minimum values'
        file(i:) = '_max.dat'
        open(12,file=file)
        write(12,'(a)') 'computing monthly maximum values'
        file(i:) = ' '
        do j=10,12
            write(j,'(2a)') 'using file ',file(1:llen(file))
            do i=1,2
                write(j,'(a)') '.'
            enddo
        enddo

  100   continue
        read(1,'(a)',end=800) line
***        print '(a)',line(1:llen(line))
*
*       headers
*
***        print '(a)',line(1:3)
        if ( line(1:3).eq.'dag' ) then
            do i=1,nyrmax
                years(i) = 0
            enddo
            i = index(line,'1')
            j = i + index(line(i:),'dag') - 2
            print '(a)',line(i:j)
            read(line(i:j),*,end=200) years
  200       continue
            do i=1,nyrmax
                if ( years(i).eq.0 ) then
                    nyr = i - 1
                    goto 290
                endif
            enddo
            write(0,*) 'Error.  Increase nyrmax'
            call abort
  290       continue
            do j=10,12
                write(j,'(a,i3,a,i4,a,i4)') 'Found ',nyr
     +                ,' years of data in ',years(1),'-',years(nyr)
            enddo
            nrleap = 0
            do i=1,nyr
                if ( mod(years(i),4).eq.0 .and. 
     +                (.not.mod(years(i),100).eq.0 .or. 
     +                mod(years(i),400).eq.0 ) ) then
                    nrleap = nrleap + 1
                    leap(nrleap) = i
                endif
            enddo
***            print *,'Found ',nrleap,' leap years: ',(years(leap(j)),j=
***     +            1,nrleap)
            goto 100
        endif
*
*       data
*
        if (  ichar(line(1:1)).lt.ichar('0') .or. 
     +        ichar(line(1:1)).gt.ichar('9') ) goto 100
        read(line,*) i,month,day
        if ( day.eq.29 .and. month.eq.2 ) then
            read(line,*,err=901) i,month,day,(valday(day,month,leap(j))
     +            ,j=1,nrleap)
        else
            read(line,*,err=901) i,month,day,(valday(day,month,j),j=1
     +            ,nyr)
        endif
        print *,i,day,month
        goto 100

  800   continue
*
*       sum, min, max
*       
        do i=1,nyr
            do month=1,12
                n = 0
                valmean(month,i) = 0
                valmin(month,i) = 3e33
                valmax(month,i) = -3e33
                do day=1,31
                    if ( valday(day,month,i).ge.0 ) then
                        n = n + 1
                        valmean(month,i) = valmean(month,i) + 
     +                        valday(day,month,i)
                        valmin(month,i) = min(valmin(month,i),
     +                        valday(day,month,i))
                        valmax(month,i) = max(valmax(month,i),
     +                        valday(day,month,i))
                    endif
                enddo
                if ( n.gt.10 ) then
                    valmean(month,i) = valmean(month,i)/n
                else
                    valmean(month,i) = -9999
                    valmin(month,i) = -9999
                    valmax(month,i) = -9999
                endif
            enddo
        enddo
*       
*       print out
*       
        do i=1,nyr
            write(10,'(i4,12f10.2)') years(i),(valmean(j,i),j=1,12)
            write(11,'(i4,12f10.2)') years(i),(valmin(j,i),j=1,12)
            write(12,'(i4,12f10.2)') years(i),(valmax(j,i),j=1,12)
        enddo
        close(10)
        close(11)
        close(12)
        goto 999
*       
  901   print *,'error reading from line'
        print *,line
        call abort
  999   continue
        end
