        program sortdata
*
*       sort datafile into data and metadata
*
        implicit none
        integer iwmo,yr,mo,ivals(12),ivalid
        character line*80
        integer llen
        external llen

        open(1,file='eurpres51.dat',status='old')
        open(2,file='eurpres51.tmp')
        open(3,file='eurpres51.data')
        
  100   continue
        read(1,'(a)',end=200) line
        if ( line(1:1).eq.' ' ) then
            read(line,*) iwmo
            if ( iwmo.lt.10 ) then
                write(2,'(1x,a)') line(1:llen(line))
            else
                write(2,'(a)') line(1:llen(line))
            endif
        else
            read(line,'(i4,12i6)') yr,ivals
	    ivalid = 0
	    do mo=1,12
		if ( ivals(mo).eq.-10 ) then
		    ivals(mo) = -9999
		else
		    ivalid = ivalid + 1
		endif
	    enddo
	    if ( ivalid.gt.1 ) then
            	write(3,'(i8,i3,i1,i4,12i5)') iwmo,0,0,yr,
     +			(ivals(mo),mo=1,12)
	    endif
        endif
        goto 100
  200   continue
	write(3,'(i8,i3,i1,i4,12i5)') 0,0,0,0,(0,mo=1,12)
        end


