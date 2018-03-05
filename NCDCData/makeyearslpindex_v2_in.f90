program makeyearprecindex

!   update the index file v2.slp.*inv with the number of years
!   of data in from with v2.slp*

!   Geert Jan van Oldenborgh, KNMI, 1999-2003

    implicit none
    integer :: ic,iwmo,imod,ielevs,nyr(0:48)
    real :: rlat,rlon
    character :: name*30,country*20

    print '(a)','Opening files'
    open(1,file='v2.slp.inv',status='old')
    open(2,file='v2.slp',status='old',form='formatted',access='direct',recl=77)
    open(3,file='v2.slp.inv.withmonth',status='new')

100 continue
    read(1,1000,end=200) ic,iwmo,imod,name,rlat,rlon,ielevs
1000 format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4)
    call getdata('slp',2,100000*ic+iwmo,imod,0,nyr, &
    NREC_SLP,NSTAT_SLP,0,3000)
!**        print 1001,ic,iwmo,imod,name,rlat,rlon,ielevs,nyr
    write(3,1001) ic,iwmo,imod,name,rlat,rlon,ielevs,nyr
1001 format(i3.3,i5.5,i3.3,' ',a30,' ',f6.2,' ',f7.2,' ',i4,147i4)
    goto 100
200 continue
    close(1)
    close(2)
    close(3)
end program
