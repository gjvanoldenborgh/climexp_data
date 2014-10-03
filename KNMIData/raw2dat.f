        program raw2dat
*
*       proglet to convert Guenther's file to my format
*
        implicit none
        integer i,j,year,month,yearold
        real x,invalid,data(12)
        parameter (invalid=999.9)
        character file*128
        integer iargc
        external iargc,getarg
*
        if ( iargc().ne.1 ) then
            print *,'usage: raw2dat infile'
            stop
        endif
        call getarg(1,file)
        open(1,file=file,status='old')
*
  100   continue
        read(1,'(a)') file
        if ( file(1:4).ne.'----') goto 100
*
        do i=1,5
            read(1,'(a)') file
            do j=len(file),1,-1
                if ( file(j:j).ne.' ' ) goto 110
            enddo
  110       continue
            print '(a)',file(1:j)
        enddo
*
        do i=1,12
            data(i) = invalid
        enddo
        yearold = -1
  200   continue
        read(1,'(a)',err=900,end=800) file
        x = invalid
        read(file,*,err=210,end=210) year,month,x
  210   continue
        if ( x.lt.0.9*invalid ) then
            if ( year.ne.yearold ) then
                if ( yearold.ne.-1 ) print '(i5,12f7.2)',yearold,data
                do i=1,12
                    data(i) = invalid
                enddo
                yearold = year
            endif
            data(month) = x
        endif
        goto 200
*
  800   continue
        print '(i5,12f7.2)',yearold,data        
        close(1)
        stop
*
  900   print *,'error reading data'
        print *,file
        end
