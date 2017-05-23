program fix_manual_gauges
!
!   First order fix for the problem with the new manual gauges introduced since 2012,
!   awaiting homogenised series from KA
! 
! De ingenieursbenadering:
!  
! Vermenigvuldig vanaf het moment dat een nieuwe regenmeter geplaatst is de dagneerslagen 
! van de betreffende locatie met een factor die lineair afloopt van 1 (op het moment van
! plaatsing) tot een minimum van 0.94 (1.5 jaar na plaatsing), daarna blijft de factor 
! constant op 0.94.
!   
! Aannames: (a)  nieuwe regenmeters zijn op moment van plaatsing OK, (b)daarna raken ze 
! geleidelijk lek waardoor er teveel neerslag  in het reservoir komt waarbij de lekkage 
! maximaal is na een periode van 1.5 jaar, (c) alle regenmeters gedragen zich na plaatsing 
! hetzelfde, (d) de correctie is gelijk verdeeld over het jaar, (e) nieuwe neerslagmeters 
! die gerepareerd zijn na plaatsing zijn nog net zo  lek als daarvoor, en (f) de AWS 
! neerslag van de afgelopen 10 jaar mag als referentie gebruikt worden.  
!  
    implicit none
    integer,parameter :: nidsmax=800,npermax=366,yrbeg=1900,yrend=2025,nleak=548
    integer :: i,ii,j,jj,k,id,nids,ids(nidsmax),iwo,nwo,wodates(nidsmax),woids(nidsmax), &
        yr,mo,dy,nperyear,iret
    real :: fac,data(npermax,yrbeg:yrend)
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
    file = '20170405_overzicht_vervanging_handregenmeters.csv'
    open(1,file=trim(file),status='old')
300 continue
    read(1,'(a)') line
    if ( index(line,'STATION') == 0 ) goto 300
    nwo = 0
310 continue
    read(1,'(a)') line
    if ( line(1:3) == ';;;' ) goto 400
    nwo = nwo + 1
    if ( nwo > nidsmax ) then
        write(0,*) 'too many mutations'
        call exit(-1)
    end if    
    i = index(line,';')
    wonames(nwo) = line(1:i-1)
!   adjust name...
    j = index(wonames(nwo),'_n ')
    if ( j /= 0 ) wonames(nwo) = wonames(nwo)(:j-1)
    do j=1,len_trim(wonames(nwo))
        if ( wonames(nwo)(j:j) == '_' .or. wonames(nwo)(j:j) == '-' ) wonames(nwo)(j:j) = ' '
    end do
!   special cases
    if ( wonames(nwo) == 'marken' ) then
        wonames(nwo) = 'marken nieuw'
    end if
    if ( wonames(nwo) == 'winterswijk' ) then
        wonames(nwo) = 'winterswijk sibinkweg'
    end if
    if ( wonames(nwo) == 'katwijk' ) then
        wonames(nwo) = 'katwijk aan den rijn'
    end if
    if ( wonames(nwo) == 'de bilt universiteitsweg' ) then
        wonames(nwo) = 'de bilt'
    end if
    if ( wonames(nwo) == 'veenhuizen' ) then
        wonames(nwo) = 'veenhuizen d'
    end if
    if ( wonames(nwo) == 'waalhaven' .or. wonames(nwo) == 'rotterdam waalhaven' ) then
        wonames(nwo) = 'r''dam waalhaven'
    end if
    if ( wonames(nwo) == 'hoek van holland molenpad' ) then
        wonames(nwo) = 'hoek van holland'
    end if
    if ( wonames(nwo) == 'nij beets' ) then
        wonames(nwo) = 'nijbeets'
    end if
    if ( wonames(nwo) == 'obdam' ) then
        wonames(nwo) = 'obdam nieuw'
    end if
    if ( wonames(nwo) == 'hoorn' ) then
        wonames(nwo) = 'hoorn nh'
        print *,'Hoorn is ambiguous, assumed Hoorn (NH)'
    end if
    if ( wonames(nwo) == 'lemmer buma' ) then
        wonames(nwo) = 'lemmer gemaal buma'
    end if
    if ( wonames(nwo) == 'hengelo gld' ) then
        wonames(nwo) = 'hengelo' ! not very good in list_rr.txt
    end if
    if ( wonames(nwo) == 'schoonloo' ) then
        wonames(nwo) = 'schoonlo'
    end if
    if ( wonames(nwo) == 'westdorpe aws' ) then
        wonames(nwo) = 'westdorpe'
    end if
    if ( wonames(nwo) == 'ijsselsteyn' ) then
        wonames(nwo) = 'ijsselsteyn l'
    end if
    if ( wonames(nwo) == 'ouddorp polder' ) then
        wonames(nwo) = 'ouddorp'
    end if
    if ( wonames(nwo) == 'steenbergen' ) then
        wonames(nwo) = 'steenbergen nb'
    end if
    if ( wonames(nwo) == 'anna jacobapolder' ) then
        wonames(nwo) = 'anna jacoba polder'
    end if
    if ( wonames(nwo) == 'lijnden' ) then
        wonames(nwo) = 'lijnden nh'
    end if
    if ( wonames(nwo) == 'stein' ) then
        wonames(nwo) = 'stein l'
    end if
    if ( wonames(nwo) == 'dwingeloo' ) then
        wonames(nwo) = 'dwingelo'
    end if
    if ( wonames(nwo) == 'heibloem' ) then
        wonames(nwo) = 'heibloem l'
    end if
    if ( wonames(nwo) == 'epen' ) then
        wonames(nwo) = 'epen nieuw  l'
    end if
    if ( wonames(nwo) == 'nijkerk gld' ) then
        wonames(nwo) = 'nijkerk'
    end if
    if ( wonames(nwo) == 'nieuwendijk' ) then
        wonames(nwo) = 'nieuwendijk nb'
    end if
    if ( wonames(nwo) == 'capelle' ) then
        wonames(nwo) = 'capelle nb'
    end if
    if ( wonames(nwo) == 'putten' ) then
        wonames(nwo) = 'putten gld'
    end if
    if ( wonames(nwo) == 'eindhoven' ) then
        wonames(nwo) = 'eindhoven vb'
    end if
    if ( wonames(nwo) == 'zweeloo' ) then
        wonames(nwo) = 'zweelo'
    end if
    if ( wonames(nwo) == 'kootwijk' ) then
        wonames(nwo) = 'kootwijk radio'
    end if
    if ( wonames(nwo) == 'kornwederzand' ) then
        wonames(nwo) = 'kornwerderzand'
    end if
    if ( wonames(nwo) == 'vlissingen' ) then
        wonames(nwo) = 'ritthem'
    end if
    read(line(i+1:i+8),'(i8)') wodates(nwo)
    goto 310
400 continue
    close(1)
    print *,'read ',nwo,' mutations from file ',trim(file)
    open(1,file='meer_vervangingen.txt',status='old')
    read(1,'(a)') line
500 continue
    read(1,'(a)',end=600) line
    i = index(line,' 201')
    if ( i /= 0 ) then
        nwo = nwo + 1
        read(line,'(i3)') woids(nwo)
        wonames(nwo) = line(6:i)
        call tolower(wonames(nwo))
        read(line(i+1:i+8),'(i8)') wodates(nwo)
        !!!print *,woids(nwo),wonames(nwo),wodates(nwo)
    end if
    goto 500
600 continue
    close(1)
    print *,'got to ',nwo,' mutations including meer_vervangingen.txt'
!
!   do adjustment
!
    do iwo=1,nwo
        ! search by name in my list
        do id=1,nids
            if ( names(id) == wonames(iwo) ) then
                exit
            end if
        end do
        if ( id > nids ) then
            write(0,*) 'error: could not find ',trim(wonames(iwo)),' in my list'
            cycle
        end if
        if ( .not.adjusted(id) ) then ! only do the correction once'
            adjusted(id) = .true.
            print *,'adjusting station ',ids(id),' ',names(id)
            write(file,'(a,i3.3,a)') 'rr',ids(id),'.dat'
            call mysystem('mv '//trim(file)//' '//trim(file)//'.unadjusted; sleep 1',iret)
            call readseries(trim(file)//'.unadjusted',data,npermax,yrbeg,yrend,nperyear, &
                var,units,lstandardunits,lwrite)
            yr = wodates(iwo)/10000
            mo = mod(wodates(iwo)/100,100)
            dy = mod(wodates(iwo),100)
            call invgetdymo(dy,mo,jj,nperyear)
            do k=1,10*366
                if ( k < nleak ) then
                    fac = 0.94 + 0.06*real(nleak-k)/nleak
                else
                    fac = 0.94
                end if
                j = jj+k
                call normon(j,yr,ii,nperyear)
                if ( ids(id) == 550 ) then
                    ! special case De Bilt: a good one was installed on 5 sep 2014
                    call getdymo(dy,mo,j,nperyear)
                    if ( 10000*ii + 100*mo + dy >= 20140905 ) then
                        if ( .not.ldebilt ) then
                            ldebilt = .true.
                            print *,'setting fac to 1 for De Bilt for dates starting',10000*ii+100*mo+dy
                        end if
                        fac = 1
                    end if
                end if
                if ( ii <= yrend ) then
                    if ( data(j,ii) < 1e33 ) then
                        data(j,ii) = fac*data(j,ii)
                    end if
                end if
            end do
            open(1,file=trim(file),status='new')
            call copyheader(trim(file)//'.unadjusted',1)
            write(1,'(2a,i8,a)') '# with a correction factor compensating leakage decreasing ', &
                'linearly from one on date ',wodates(iwo),' to 0.94 over 1.5 years'
            if ( ids(id) == 550 ) then
                write(1,'(a)') '# and no correction again from 20140905'
            end if
            call printdatfile(1,data,npermax,nperyear,yrbeg,yrend)
            close(1)
        end if
    end do
!
!   end game
!
    do id=1,nids
        if ( .not.adjusted(id) ) then
            print *,'no adjustment of station ',ids(id),' ',trim(names(id))
        end if
    end do
!
!   finito
!
end program fix_manual_gauges