program neerslag2dat
!
!   convert the KA datafiles to climate explorer conventions
!
    implicit none
    integer i,j,i1,i2,istation,datum,rr,sd,mmsd,deg,min,yr,yr1,yr2,yr1a,yr2a
    real lat,lon
    character infile*100,outfile*100,name*40,capsname*40,line*1000,history*1000
    logical lwrite
    
    lwrite = .false.
    outfile = ' '
    call getarg(1,infile)
    open(1,file=trim(infile),status='old')
    i1 = index(infile,'_')
    i2 = i1 + index(infile(i1+1:),'_')
    capsname = infile(i1+1:i2-1)
    if ( lwrite ) print *,'name = ',capsname
    i1 = i2
    i2 = i1 + index(infile(i1+1:),'.')
    if ( lwrite ) print *,'number = ',infile(i1+1:i2-1)
    read(infile(i1+1:i2-1),'(i3)') istation

    ! the best place I can find with the coordinates...
    open(10,file='lijst_nstn.html',status='old')
1   continue
    read(10,'(a)',end=8) line
    line = line(9:)
    if ( line(1:1) == ' ' ) line = line(2:)
    i = index(line,'<')
    name = line(:i-1)
    if ( lwrite ) print *,'name = ',trim(name)
    line = line(i+24:)
    i = index(line,'<')
    if ( lwrite ) print *,'station = ',line(:i-1)
    read(line(:i-1),*) i1
    if ( i1 /= istation ) goto 1
    line = line(i+24:)
    i = index(line,'&')
    if ( lwrite ) print *,'deg = ',line(:i-1)
    read(line(:i-1),*) deg
    line = line(i+5:)
    i = index(line,'''')
    if ( lwrite ) print *,'min = ',line(:i-1)
    read(line(:i-1),*) min
    lon = deg + min/60.
    line = line(30:)
    i = index(line,'&')
    if ( lwrite ) print *,'deg = ',line(:i-1)
    read(line(:i-1),*) deg
    line = line(i+5:)
    i = index(line,'''')
    if ( lwrite ) print *,'min = ',line(:i-1)
    read(line(:i-1),*) min
    lat = deg + min/60.
    
    goto 9
8   continue
    name = capsname
    lon = -999.9
    lat = -999.9

9   continue
    yr1 = 9999
    yr2 = -9999
    yr1a = 9999
    yr2a = -9999
100 continue
    read(1,'(a)') line
    if ( line(1:4) /= 'STN,' ) goto 100
200 continue
    rr = -9999
    read(1,'(a)',end=800) line
    !!!print *,'line(13:19) = ',line(13:19)
    if ( line(14:18) == '     ' ) goto 200
    !!!print *,'line(14:18) = ',line(14:18)
    if ( line(20:24) == '     ' ) then
        read(line,*) i1,datum,rr
        mmsd = -999
    else
        read(line,*) i1,datum,rr,sd
        if ( sd == 997 ) then
            mmsd = 3
        else if ( sd == 998 ) then
            mmsd = 9
        else if ( sd == 999 ) then
            mmsd = -999 ! no idea how to interpret "sneeuwhopen"
        else
            mmsd = 10*sd
        end if
    end if
    if ( i1 /= istation ) then
        write(0,*) 'neerslag2dat: error: station ID inconsistent: ',i1,istation
        call abort
    end if
    yr = datum/10000
    if ( outfile == ' ' ) then
        write(outfile,'(a,i3.3,a)') 'rr',istation,'.dat'
        open(2,file=trim(outfile))
        write(2,'(a,i3.3,3a,f9.2,a,f9.2,a)') '# ',istation,' ',trim(name), &
        &   ' (',lat,'N, ',lon,'E)'
        write(2,'(a)') '# precip [mm/dy] precipitation (8-8)'
        write(2,'(a)') '# time refers to the day it is observed, 8UTC'
    
        write(outfile,'(a,i3.3,a)') 'sd',istation,'.dat'
        open(3,file=trim(outfile))
        write(3,'(a,i3.3,3a,f9.2,a,f9.2,a)') '# ',istation,' ',trim(name), &
        &   ' (',lat,'N, ',lon,'E)'
        write(3,'(a)') '# sd [mm] snow depth'
        write(3,'(a)') '# time refers to the day it is observed, 8UTC'

        history = ' '
        call extend_history(history)
        do j=2,3
            write(j,'(a,f7.2,a)') '# longitude :: ',lon,' degrees_east'
            write(j,'(a,f7.2,a)') '# latitude :: ',lat,' degrees_north'
            write(j,'(a,i3.3)') '# station_code :: ',istation
            write(j,'(2a)') '# station_name :: ',trim(name)
            write(j,'(3a)') '# source_url :: http://www.knmi.nl/nederland-nu/klimatologie/monv/reeksen'
            write(j,'(a)') '# institute :: Royal Netherlands Meteorological Institute (KNMI)'
            write(j,'(a)') '# license :: These data can be used freely provided'// &
                ' that the following source is acknowledged: '// &
                'Royal Netherlands Meteorological Institute (KNMI)'
            write(j,'(2a)') '# history :: ',trim(history)        
        end do
        yr1 = yr
    end if
    yr2 = max(yr,yr2)
    write(2,'(i8,f9.1)') datum,rr/10.
    if ( mmsd >= 0 ) then
        yr1a = min0(yr,yr1a)
        yr2a = max(yr,yr2a)
        write(3,'(i8,i5)') datum,mmsd
    end if
    goto 200
800 continue
    close(1)
    close(2)
    if ( yr2 > yr1 ) then
        print '(2a)',name,'(Netherlands)'
        print '(a,f9.2,a,f9.2,a)','coordinates: ',lat,'N, ',lon,'E'
        print '(a,i3.3,2a)','station code: ',istation,' ',trim(name)
        print '(a,i4,a,i4,a,i4)','Found ',yr2-yr1+1,' years with data in ',yr1,'-',yr2
        print '(a)','=============================================='
        close(2)
    else
        close(2,status='delete')
    end if
    if ( yr2a > yr1a ) then
        write(0,'(2a)') name,'(Netherlands)'
        write(0,'(a,f9.2,a,f9.2,a)') 'coordinates: ',lat,'N, ',lon,'E'
        write(0,'(a,i3.3,2a)') 'station code: ',istation,' ',trim(name)
        write(0,'(a,i4,a,i4,a,i4)') 'Found ',yr2a-yr1a+1,' years with data in ',yr1a,'-',yr2a
        write(0,'(a)') '=============================================='
        close(3)
    else
        close(3,status='delete')
    end if
end program