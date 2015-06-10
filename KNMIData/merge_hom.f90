program merge_hom
    !   merge the operational data to the homogenised series from Theo
    implicit none
    integer yrbeg,yrend,npermax
    parameter(yrbeg=1900,yrend=2020,npermax=366)
    integer i,j,k,dy,mo,yr,iret,nperyear,dpm(12)
    real vals(5),data(npermax,yrbeg:yrend)
    character var*2,station*3,svar*40,units*40,file*40,line*80
    logical lstandardunits,lwrite
    data dpm /31,29,31,30,31,30,31,31,30,31,30,31/
    
    lwrite = .false.
    call getarg(1,var)
    call getarg(2,file)
    station = '260'
    lstandardunits = .false.
    call readseries(var//station//'.dat',data,npermax,yrbeg,yrend,nperyear, &
    &   svar,units,lstandardunits,lwrite)
    
    open(1,file=trim(file),status='old')
    do
        read(1,'(a)',end=800) line
        do i=1,len(line)
            if ( line(i:i) == ',' ) line(i:i) = '.'
            if ( line(i:i) == ';' ) line(i:i) = ' '
        end do
        read(line,*) vals
        yr = nint(vals(1))
        mo = nint(vals(2))
        dy = nint(vals(3))
        if ( yr < yrbeg .or. yr > yrend ) then
            write(0,*) 'merge_hom: error: yr outside range ',yr,yrbeg,yrend
            call abort
        end if
        j = dy
        do k=1,mo-1
            j = j + dpm(k)
        end do
        data(j,yr) = vals(5)
    end do
800 continue
    close(1)
    open(1,file=var//station//'_hom.dat')
    call copyheader(var//station//'.dat',1)
    write(1,'(a)') '# Homogenised data from '//trim(file)
    call printdatfile(1,data,npermax,nperyear,yrbeg,yrend)
    close(1)
    call mysystem('gzip -c '//var//station//'_hom.dat > '//var//station//'.gz',iret)
end program