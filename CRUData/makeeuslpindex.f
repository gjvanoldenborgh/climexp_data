        program makeeuslpindex
*
*       Jones gave just the raw data, no metadata
*       let's get these from the GHCN dataset
*
        implicit none
        integer i,j,k,iwmo,yr1,yr2,height,irec,nyr,yr,yrold,ivals(12)
        real lat,lon
        character name*12,name1*18,country*18
        integer system
        external system

        open(1,file='eurpres51.tmp',status='old')
        open(2,file='eurpres51.data',access='direct',form='formatted',
     +        recl=77,status='old')
        open(3,file='eurpres51.coordinates',status='old')
        open(10,file='eurpres51.inv')
        i = 0
        irec = 0
	yr = -1
  100   continue
        i = i + 1
        read(1,'(i3,2i6,2x,a)',end=200) iwmo,yr1,yr2,name
        read(3,'(i3,2a,2f6.2,i4)',end=200) iwmo,name1,country,lat,lon
     +        ,height
        nyr = 0
  110   continue
        irec = irec + 1
	yrold = yr
        read(2,'(i8,i3,i1,i4,12i5)',rec=irec) i,j,k,yr,ivals
        if ( i.ne.iwmo ) then
            irec = irec - 1
            print *,iwmo,name,country,yr1,yrold,nyr
            write(10,'(i2,x,2a,2f6.2,i4,3i5)') 
     +		iwmo,name1,country,lat,lon,height,yr1,yrold,nyr
            goto 100
        endif
        do i=1,12
            if ( ivals(i).gt.0 ) goto 120
        enddo
        goto 110
  120   continue
        nyr = nyr + 1
        if ( nyr.eq.1 ) then
            if ( yr.ne.yr1 ) then
                write(0,*) 'warning: yr1 not first year ',name,yr1,yr
            endif
        endif
        goto 110
  200   continue
        end
