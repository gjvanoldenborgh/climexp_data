program txt2dat

!   convert the ECA database formart to my standard format

    implicit none
    integer :: yrbeg,yrend
    parameter (yrbeg=1700,yrend=2020)
    integer :: i,j,n,yr,mo,dy,qq,id,datum,val, &
        yr1(2:3),yr2(2:3),nyr(2:3),lastyr(2:3),iblend,sourceid
    character :: infile*128,outfile*13,line*200,element*2
    integer :: iargc

    if ( iargc() /= 1 ) then
        print *,'usage: txt2dat infile'
        print *,'creates a file number.dat, prints number to stdout'
        stop
    endif
    call getarg(1,infile)
    open(1,file=infile,status='old')
    i = index(infile,'_')
    j = index(infile,'.')
!   changed 27-oct-2004 to TX_LOCIDnnnnnn.txt ...
!   changed jul-2009 to    RR_STAIDnnnnnn.txt ...
    read(infile(i+6:j-1),*) n
    element = infile(i-2:i-1)
    call tolower(element)
    do iblend=2,3
        if ( iblend == 2 ) then
            write(outfile,'(a,i6.6,a)') element,n,'.dat'
        else
            write(outfile,'(2a,i6.6,a)') 'b',element,n,'.dat'
        endif
        open(iblend,file=outfile)
        write(iblend,'(2a)') '# ',infile(1:index(infile,' ')-1)
    enddo
100 continue
    read(1,'(a)') line
    i = index(line,'sta-ID')
    if ( i /= 0 ) then
        j = i + index(line(i:),')') - 1
        read(line(i+7:j-1),*) id
        if ( id /= n ) then
            write(0,*) 'warning: sta-ID does not match file name'
            write(0,*) 'sta-ID       = ',id
            write(0,*) 'ID from file = ',n
            n = id
        end if
    end if
    if ( index(line,'SOUID,') == 0 ) goto 100
    yr1=9999
    yr2=-9999
    nyr = 0
    lastyr = -9999
200 continue
    read(1,'(i6,1x,i6,1x,i8,1x,i5,1x,i5)',end=800) id,sourceid,datum,val,qq
    yr = datum/10000
    do iblend=2,3
        if ( qq /= 0 ) goto 200 ! throw away all suspect data
        if ( iblend == 2 .and. sourceid >= 900000 ) goto 190 ! synop data has SOUID>900000
        if ( val == -999 .or. val == -9999 ) goto 200 ! these should have qq > 0, just to make sure
        yr1(iblend) = min(yr1(iblend),yr)
        yr2(iblend) = max(yr2(iblend),yr)
        if ( yr /= lastyr(iblend) ) then
            lastyr(iblend) = yr
            nyr(iblend) = nyr(iblend) + 1
        end if
        if ( element == 'sd' ) then
            if ( val /= 999 .and. val /= 998 ) then
                write(iblend,'(i4,2i3,f7.2)') datum/10000,mod(datum &
                    /100,100),mod(datum,100),val/100.
            endif
        elseif ( element == 'cc' ) then
            if ( val < 0 .or. val > 8 ) then
                write(0,*) 'error: val = ',val,' octas!'
            endif
            write(iblend,'(i4,2i3,f6.3)') datum/10000,mod(datum/100,100),mod(datum,100),val/8.
        else
            write(iblend,'(i4,2i3,f8.1)') datum/10000,mod(datum/100,100),mod(datum,100),val/10.
        endif
    190 continue
    enddo
    goto 200
800 continue
    print '(i6.6,6i5)',n,(yr1(iblend),yr2(iblend),nyr(iblend),iblend=2,3)
end program txt2dat

                
