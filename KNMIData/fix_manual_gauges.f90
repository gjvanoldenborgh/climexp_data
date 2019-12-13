program fix_manual_gauges
!
!   second-order correction as long as the final one has not yet been released, see HNcorrectie_v5.docx
!   approximation: linear trend from begin to end date.
!  
    implicit none
    integer,parameter :: nidsmax=800,npermax=366,yrbeg=1900,yrend=2025,nleak=548
    integer :: i,ii,j,jj,k,n,id,nids,ids(nidsmax),iwo,nwo,wodates(2,nidsmax),woids(nidsmax), &
        yr,mo,dy,nperyear,iret,dy1,mo1,yr1,dy2,mo2,yr2,jj1,jj2
    real :: fac,data(npermax,yrbeg:yrend),wofacs(2,nidsmax)
    logical adjusted(nidsmax),lstandardunits,lwrite,ldebilt
    character :: line*80,names(nidsmax)*50,wonames(nidsmax)*50,file*254
    character :: var*80,units*40
!   
!   open staton list (from my system) to connect names with station IDs.
!
    lwrite = .false.
    lstandardunits = .false.
    ids = -999
    woids = -999
    names = ' '
    adjusted = .false.
    ldebilt = .false.
!
    nids = 0
    open(1,file='list_rr.txt',status='old')
100 continue
    read(1,'(a)',end=200) line
    if ( index(line,'station code') == 0 ) goto 100
    nids = nids + 1
    if ( nids > nidsmax ) then
        write(0,*) 'too many stations'
        call exit(-1)
    end if
    read(line(15:17),'(i3)') ids(nids)
    names(nids) = line(19:)
    call tolower(names(nids))
!   delete brackets
    do j=1,2
        i = index(names(nids),' (')
        if ( i /= 0 ) then
            names(nids)(i+1:) = names(nids)(i+2:)
            i = index(names(nids),')')
            names(nids)(i:i) = ' '
        end if
    end do
    do j=1,len_trim(names(nids))
        if ( names(nids)(j:j) == '_' .or. names(nids)(j:j) == '-' ) names(nids)(j:j) = ' '
    end do
    !!!print *,'@@@',trim(names(nids))
!   get last year with data
    read(1,'(a)') line
    i = index(line,'-')
    if ( i == 0 ) then
        write(0,*) 'cannot find - in line ',trim(line)
        call exit(-1)
    end if
    read(line(i+1:),'(i4)') yr
    if ( yr < 2012 ) then ! no adjustment necessary
        nids = nids - 1
    end if
    go to 100 ! next line
200 continue
    close(1)
    print *,'read ',nids,' station ids/names with data in 2012 or later from list_rr.txt'
!
!   read dates from .csv file from WO
!
    file = 'regenmeters_correctie_65.txt'
    open(1,file=trim(file),status='old')
    nwo = 0
310 continue
    read(1,'(a)',end=400) line
    nwo = nwo + 1
    if ( nwo > nidsmax ) then
        write(0,*) 'too many mutations'
        call exit(-1)
    end if    
    i = index(line,';')
    read(line(1:i-1),*) woids(nwo)
    i = i + index(line(i+1:),';')
    read(line(i+1:i+17),'(i8,x,i8)') wodates(1,nwo),wodates(2,nwo)
    i = i + 18
    read(line(i+1:i+11),'(f5.3,x,f5.3)') wofacs(1,nwo),wofacs(2,nwo)
    goto 310
400 continue
    close(1)
    print *,'read ',nwo,' mutations from file ',trim(file)
!
!   do adjustment
!
    do iwo=1,nwo
        ! search by name in my list
        do id=1,nids
            if ( ids(id) == woids(iwo) ) then
                exit
            end if
        end do
        if ( id > nids ) then
            cycle
        end if
        if ( .not.adjusted(iwo) ) then ! only do the correction once'
            adjusted(iwo) = .true.
            print *,'adjusting station ',ids(id),' ',names(id)
            write(file,'(a,i3.3,a)') 'rr',ids(id),'.dat'
            call mysystem('mv '//trim(file)//' '//trim(file)//'.unadjusted; sleep 1',iret)
            call readseries(trim(file)//'.unadjusted',data,npermax,yrbeg,yrend,nperyear, &
                var,units,lstandardunits,lwrite)
            yr1 = wodates(1,iwo)/10000
            mo1 = mod(wodates(1,iwo)/100,100)
            dy1 = mod(wodates(1,iwo),100)
            call invgetdymo(dy1,mo1,jj1,nperyear)
            yr2 = wodates(2,iwo)/10000
            mo2 = mod(wodates(2,iwo)/100,100)
            dy2 = mod(wodates(2,iwo),100)
            call invgetdymo(dy2,mo2,jj2,nperyear)
            k = 0
            do yr=yr1,yr2
                do dy=1,366
                    if ( yr == yr1 .and. dy < jj1 .or. &
                         yr == yr2 .and. dy > jj2 ) cycle
                    k = k + 1
                    ! neglect leap year effects
                    n = 366*(yr2 - yr1) + jj2 - jj1
                    if ( wofacs(1,iwo) == wofacs(2,iwo) ) then
                        fac = wofacs(1,iwo)
                    else
                        ! assume a linearly increasing function
                        fac = ((n-k)*wofacs(2,iwo) + k*wofacs(1,iwo))/n
                    end if
                    if ( data(dy,yr) < 1e33 ) then
                        data(dy,yr) = fac*data(dy,yr)
                    end if
                end do
            end do
            open(1,file=trim(file),status='new')
            call copyheader(trim(file)//'.unadjusted',1)
            if ( wofacs(1,iwo) == wofacs(2,iwo) ) then
                write(1,'(a,f5.3,a,i8,a,i8)') '# with a correction factor compensating leakage of ', &
                    wofacs(1,iwo),' over ',wodates(1,iwo),' to ',wodates(2,iwo)
            else
                write(1,'(2a,f5.3,a,i8,a,f5.3,a,i8i8,a)') '# with a correction factor compensating leakage decreasing ', &
                    'linearly from ',wofacs(2,iwo),' on date ',wodates(1,iwo),' to ',wofacs(1,iwo), &
                    ' on ',wodates(2,iwo)
            end if
            call printdatfile(1,data,npermax,nperyear,yrbeg,yrend)
            close(1)
        end if
    end do
!
!   end game
!
    do iwo=1,nwo
        if ( .not.adjusted(iwo) ) then
            print *,'no adjustment of station ',woids(iwo)
        end if
    end do
!
!   finito
!
end program fix_manual_gauges