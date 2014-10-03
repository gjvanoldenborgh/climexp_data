        program nodup
        integer yrbeg,yrend
        parameter (yrbeg=1500,yrend=2020)
        integer i,ic,iw,is,id,yr,icold,iwold,isold,nin,nout
        logical pastdata(yrbeg:yrend)
        character filein*255,fileout*255,line*76,lines(yrbeg:yrend)*76
        
        call getarg(1,filein)
        open(1,file=filein,status='old')
        call getarg(2,fileout)
        open(2,file=fileout,status='new')

        icold = -1
        iwold = -1
        isold = -1
        nin = 0
        nout = 0
        pastdata = .false.
  100   continue
        read(1,'(a)',end=800,err=900) line
        nin = nin + 1
        read(line,'(i3,i5,i3,i1,i4)') ic,iw,is,id,yr
        if ( ic.ne.icold .or. iw.ne.iwold .or. is.ne.isold ) then
            icold = ic
            iwold = iw
            isold = is
            do i=yrbeg,yrend
                if ( pastdata(i) ) then
                    write(2,'(a)') lines(i)
                    pastdata(i) = .FALSE.
                end if
            end do
        endif
        if ( yr.lt.yrbeg .or. yr.gt.yrend ) then
            write(0,*) 'error: yr<yrbeg or yr>yrend: ',yr,yrbeg,yrend
            call abort
        endif
        if ( .not.pastdata(yr) ) then
            pastdata(yr) = .TRUE.
            lines(yr) = line
            nout = nout + 1
        endif
        goto 100
  800   continue
        close(1)
        close(2)
        print *,'read ',nin,' records, wrote ',nout,' records'
        stop
  900   write(0,*) 'error reading line ',line
        call abort
        end
