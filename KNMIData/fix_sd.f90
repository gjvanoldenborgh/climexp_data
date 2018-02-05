program fix_sd

!   currently (02-feb-2018) teh KNMI snow depth data contain coding errors in teh years 1996-2003.
!   Trying to fix these here.
    implicit none
    integer,parameter :: yrbeg=1900,yrend=2020,npermax=366
    integer :: i,yr,mo,dy,nperyear,iswrong(yrbeg:yrend),nold,nnew
    real :: sd(npermax,yrbeg:yrend),old2new(0:9)
    logical :: lstandardunits,lwrite
    character :: file*1000,var*40,units*80
    data old2new /0,3.,9.,10.,20.,40.,80.,150.,230.,3e33/
    
    lwrite = .false.
    lstandardunits = .false.
    call getarg(1,file)
    if ( file == ' ' ) then
        write(0,*) ' usage: fix_sd infile > outfile'
        call exit(-1)
    end if
    call readseries(file,sd,npermax,yrbeg,yrend,nperyear, &
        var,units,lstandardunits,lwrite)
    iswrong = 0
    do yr=1996,2000 ! according to e-mail Rudmer dd 2018-jan-30 the new codes were introduced 1-apr-2003
                    ! However, I do not find old codes after summer 2000, so these seem to have been converted already
        nold = 0
        nnew = 0
        do dy=1,366
            if ( yr == 2000 .and. dy > 180 ) exit
            if ( sd(dy,yr) > 1e33 ) cycle
            if ( sd(dy,yr) == 30 .or. sd(dy,yr) == 50 .or. sd(dy,yr) == 60 .or. sd(dy,yr) == 70 &
                .or. sd(dy,yr) == 90 ) then
                nold = nold + 1
            else if ( sd(dy,yr) > 100 .or. &
                ( mod(nint(sd(dy,yr)),10) /= 0 .and. sd(dy,yr) /= 3 .and. sd(dy,yr) /= 7 ) ) then
                nnew = nnew + 1
                write(0,*) 'found new code at ',yr,dy,sd(dy,yr)
            end if
        end do
        if ( yr == 2000 ) then ! apply to all stations
            if ( nold == 0 ) then
                iswrong(yr) = 0 ! convert nothing
            else
                iswrong(yr) = 2 ! in any case not the last months
            end if
        elseif ( yr == 2001 ) then
            if ( nold == 0 ) then
                iswrong(yr) = 0 ! convert nothing
            else
                iswrong(yr) = 3 ! in any case not the first months
            end if
        elseif ( yr == 2003 ) then
            iswrong = 0 ! at a few stations there are new codes, force upon all.
        elseif ( nnew == 0 .and. nold > 0 ) then
            iswrong(yr) = 1
        else if ( nnew >= 0 .and. nold == 0 ) then
            iswrong(yr) = 0
        else 
            write(0,*) 'fix_sd: found both old and new codes in ',yr,nold,nnew
            call exit(-1)
        end if
    end do
    
    do yr=1996,2003
        do dy=1,366
            if ( iswrong(yr) == 1 .or. &
                 iswrong(yr) == 2 .and. dy < 180 .or. &
                 iswrong(yr) == 3 .and. dy > 180 ) then
                if ( sd(dy,yr) < 1e33 ) then
                    i = sd(dy,yr)/10
                    if ( i < 0 .or. i > 9 ) then
                        write(0,*) 'fix_sd: error: cannot convert code ',sd(dy,yr)
                        call exit(10)
                    end if
                    sd(dy,yr) = old2new(i)
                end if
            end if
        end do
    end do
    
    call copyheader(file,6)
    print '(a)','# Fixed erroneous codes'
    call printdatfile(6,sd,npermax,nperyear,yrbeg,yrend)

end program fix_sd