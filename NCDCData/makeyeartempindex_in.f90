program makeyeartempindex

!   update the index file ghcnm/ghcnm.t???.v3.qc?.inv with the number of years
!   of data in from ghcnm/ghcnm.t???.v3.qc?.dat

!   Geert Jan van Oldenborgh, KNMI, 1999-2000, 2014

    implicit none
    integer :: ic,iwmo,imod,ielevg,ipop,iloc,itowndis,nyr(0:48),ivar,iext
    real :: rlat,rlon,elevs
    character name*30,pop*1,topo*2,stveg*2,stloc*2,airstn*1,grveg*16,var*4,ext*3,popcss

    do ivar=1,3
        if ( ivar == 1 ) then
            var='tavg'
        else if ( ivar == 2 ) then
            var='tmax'
        else if ( ivar == 3 ) then
            var='tmin'
        else
            write(0,*) 'makeyeartempindex: error: ivar = ',ivar
            call exit(-1)
        end if
        do iext=1,2
            if ( iext == 1 ) then
                ext='qcu'
            else if ( iext == 2 ) then
                ext='qca'
            else
                write(0,*) 'makeyeartempindex: error: iext = ',iext
                call exit(-1)
            end if
                                
            print '(a)','Opening files'
            open(1,file='ghcnm/ghcnm.'//var//'.v3.'//ext//'.inv',status='old')
            open(2,file='ghcnm/ghcnm.'//var//'.v3.'//ext//'.dat',status='old', &
                form='formatted',access='direct',recl=116)
            open(3,file='ghcnm/ghcnm.'//var//'.v3.'//ext//'.inv.withmonth')
        
        100 continue
            read(1,1000,end=200) ic,iwmo,imod,rlat,rlon,elevs,name,ielevg,pop,ipop,topo &
                ,stveg,stloc,iloc,airstn,itowndis,grveg,popcss
       1000 format(i3.3,i5.5,i3.3,1x,f8.4,1x,f9.4,1x,f6.1,1x,a30, &
                             1x,i4,a1,i5,3(a2),i2,a1,i2,a16,a1)
            if ( var == 'tavg' .and. ext == 'qca' ) then
                call getdata3('temp',2,100000*ic+iwmo,imod,0,nyr, &
                    NREC_MEAN_ADJ,NSTAT_MEAN_ADJ,0,3000,'VERSION_MEAN_ADJ')
            else if ( var == 'tmin' .and. ext == 'qca' ) then
                call getdata3('tmin',2,100000*ic+iwmo,imod,0,nyr, &
                    NREC_MIN_ADJ,NSTAT_MIN_ADJ,0,3000,'VERSION_MIN_ADJ')
            else if ( var == 'tmax' .and. ext == 'qca' ) then
                call getdata3('tmax',2,100000*ic+iwmo,imod,0,nyr, &
                    NREC_MAX_ADJ,NSTAT_MAX_ADJ,0,3000,'VERSION_MAX_ADJ')
            else if ( var == 'tavg' .and. ext == 'qcu' ) then
                call getdata3('tempall',2,100000*ic+iwmo,imod,0,nyr, &
                    NREC_MEAN_ALL,NSTAT_MEAN_ALL,0,3000,'VERSION_MEAN_ALL')
            else if ( var == 'tmin' .and. ext == 'qcu' ) then
                call getdata3('tminall',2,100000*ic+iwmo,imod,0,nyr, &
                    NREC_MIN_ALL,NSTAT_MIN_ALL,0,3000,'VERSION_MIN_ALL')
            else if ( var == 'tmax' .and. ext == 'qcu' ) then
                call getdata3('tmaxall',2,100000*ic+iwmo,imod,0,nyr, &
                    NREC_MAX_ALL,NSTAT_MAX_ALL,0,3000,'VERSION_MAX_ALL')
            else
                write(0,*) 'makeyeartempindex: error: var = ',var,' and ext = ',ext
                call exit(-1)
            end if
            write(3,1001) ic,iwmo,imod,rlat,rlon,elevs,name,ielevg,pop,ipop,topo &
                ,stveg,stloc,iloc,airstn,itowndis,grveg,popcss,nyr
       1001 format(i3.3,i5.5,i3.3,' ',f8.4,' ',f9.4,' ',f6.1,' ',a30,' ',i4,a1,i5, &
                3(a2),i2,a1,i2,a16,a1,49i4)
            goto 100
        200 continue
            close(1)
            close(2)
            close(3)
        end do
    end do
end program makeyeartempindex
