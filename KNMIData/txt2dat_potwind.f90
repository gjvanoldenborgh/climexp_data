program txt2dat

!   read stnadrd KNMI txt file with potential wind data and spew out a standard Climate Explorer file
!   with daily maximum potential wind

    implicit none
    integer,parameter :: yrbeg=1970,yrend=2020,hourperyear=24*366,npermax=366
    integer :: datum,yyyy,hh,dd,mm,qdd,up,qup,i,j,k,istation,nvals,olddatum,nyr,yr1,yr2, &
        vals(24),iarg,ioldstation
    real :: upx(31,12,yrbeg:yrend),xlat,xlon,factor
    character :: file*1023,auxfile*1023,line*120,station*40,oldstation*40, &
        description*400,license*400,url*120,version*50
    integer :: iargc
    
    if ( iargc() == 0 ) then
        write(0,*) 'usage: txt2dat infile1 infile2 ... >> listfile'
        write(0,*) '       generates upxNNN.dat'
        call exit(-1)
    end if
    oldstation = 'unknown'
    ioldstation = -999
    upx = 3e33
    do iarg=1,iargc()
        call getarg(iarg,file)
        write(0,*) 'txt2dat_potwind: opening file ',trim(file)
        open(1,file=trim(file),status='old')
        description = ' '
        license = ' '
        factor = 1
        do
            read(1,'(a)') line
            if ( line(1:1) /= ' ' ) exit
            if ( line == ' ' ) cycle
            i = index(line,'STATION')
            if ( i /= 0 ) then
                i = i+8
                k = i+1
                if ( line(k:k) /= ' ' ) k = k + 1
                if ( line(k:k) /= ' ' ) k = k + 1
                k = k - 1
                read(line(i:k),'(i3)') istation
                if ( ioldstation > 0 .and. istation /= ioldstation ) then
                    write(0,*) 'txt2dat_potwind: error: station IDs do not agree ',ioldstation,istation
                    call exit(-1)
                end if
                if ( istation /= ioldstation ) then
                    if ( ioldstation > 0 ) close(2)
                    write(file,'(a,i3.3,a)') 'upx',istation,'.dat'
                    open(2,file=trim(file))
                end if
                station = line(k+2:)
                ! get coordinates
                write(file,'(a,i3.3,a)') 'latlon_wind',istation,'.txt'
                open(3,file=trim(file),status='old')
                read(3,*) i
                if ( i /= istation ) then
                    write(0,*) 'txt2dat_potwind: interbal error: istation not correct ',istation,i,trim(file)
                    call exit(-1)
                end if
                read(3,*) xlat
                read(3,*) xlon
                close(3)
            end if
            i = index(line,'MEASURED AT') + index(line,'MEANS') + index(line,'ROUGHNESS')
            if ( i /= 0 ) then
                description = trim(description) // ' ' // trim(line) 
                if ( index(line,'MEASURED AT') /= 0 ) description = trim(description) // ';'
            end if
            if ( istation == 252 .or. istation == 253 .or. istation == 254 .or. &
                 istation == 258 .or. istation == 285 .or. istation == 312 .or. &
                 istation == 313 .or. istation == 316 .or. istation == 320 .or. &
                 istation == 321 .or. istation == 331 ) then
                ! sea stations
                i = index(line,'OPEN LAND')
                if ( i /= 0 ) then
                    description = description(:i-1)//'OPEN WATER'//trim(description(i+10:))
                    i = index(description,'0.03 METER')
                    if ( i == 0 ) then
                        write(0,*) 'txt2dat_potwind: error: expecting string "0.03 METER" in ', &
                            trim(description)
                        call exit(-1)
                    end if
                    description(i-1:) = '0.002 METER'
                    factor = 1.081 ! from email by Andrew Stepek
                end if
            end if
            i = index(line,'http:')
            if ( i /= 0 ) then
                url = line(i:)
            end if
            i = index(line,'FREELY') + index(line,'ROYAL')
            if ( i /= 0 ) then
                license = trim(license) // ' ' // trim(line)
            end if
            i = index(line,'VERSION')
            if ( i /= 0 ) then
                version = trim(line(i+8:))
            end if
        end do ! end of header lines

!       print header

        if ( istation /= ioldstation ) then
            ioldstation = istation
            call tolower(description)
            write(2,'(a)') '# Wind originally'//trim(description)
            write(2,'(3a,f7.2,a,f7.2,a)') '# ',trim(station),' ( ',xlat,'N, ',xlon,'E)'
            write(2,'(a,f7.2,a)') '# longitude :: ',xlon,' degrees_east'
            write(2,'(a,f7.2,a)') '# latitude :: ',xlat,' degrees_north'
            write(2,'(a,i3.3)') '# station_code :: ',istation
            write(2,'(2a)') '# station_name :: ',trim(station)
            write(2,'(a)') '# institution :: KNMI'
            ! URL from file no longer works.
            write(2,'(2a)') '# source_url_historical :: '// &
                'ttp://projects.knmi.nl/klimatologie/onderzoeksgegevens/potentiele_wind/up_upd/'
            write(2,'(2a)') '# source_url_current :: '// &
                'http://projects.knmi.nl/klimatologie/onderzoeksgegevens/potentiele_wind-sigma/'
            write(2,'(a)') '# license :: These data can be used freely provided'// &
            ' that the following source is acknowledged: '// &
            'Royal Netherlands Meteorological Institute (KNMI)'
            write(2,'(2a)') '# version :: ',trim(version)
            write(2,'(a)') '# upx [m/s] daily maximum of hourly potential wind speed'
            olddatum = -1
            vals = -1
            !!!write(0,*) 'txt2dat_potwind: resetting yr1,yr2'
            yr1 = 9999
            yr2 = -9999
        end if

!       data
    
        do
            read(line,*) datum,hh,dd,qdd,up,qup
             if ( datum /= olddatum .and. olddatum > 0 ) then
                call takemax(upx,yrbeg,yrend,olddatum,vals,factor)
                vals = -1
            end if
            olddatum = datum
            if ( up >= 0 .and. qup == 0 ) then
                yyyy = datum/10000
                yr1 = min(yr1,yyyy)
                yr2 = max(yr2,yyyy)
                if ( hh < 1 .or. hh > 24 ) then
                    write(0,*) 'txt2dat_potwind: error: hh = ',hh
                    call exit(-1)
                end if
                vals(hh) = up
            end if
            read(1,'(a)',err=800,end=800) line
        end do
    800 continue
        call takemax(upx,yrbeg,yrend,olddatum,vals,factor)
        vals = -1
        olddatum = -1
        close(1)
    end do ! iarg
    do yyyy=yrbeg,yrend
        do mm=1,12
            do dd=1,31
                if ( upx(dd,mm,yyyy) < 1e33 ) then
                    write(2,'(i4.4,2i2.2,f7.1)') yyyy,mm,dd,upx(dd,mm,yyyy)
                end if
            end do
        end do
    end do

!   list output

    nyr = yr2-yr1+1 ! approximately
    if ( nyr >= 8 ) then
        print '(a)','=============================================='
        print '(3a)',station,'(Netherlands)'
        print '(a,f7.2,a,f7.2,a)','coordinates: ',xlat,'N, ',xlon,'E'
        do i=1,len(station)
            if ( station(i:) == ' ' ) exit
            if ( station(i:i) == ' ' ) station(i:i) = '_'
        end do
        print '(a,i3.3,2a)','station code: ',istation,' ',trim(station)
        !!!write(0,*) 'txt2dat_potwind: writing yr1,yr2',yr1,yr2
        print '(a,i3,a,i4.4,a,i4.4)','Found ',nyr,' years with data in ',yr1,'-',yr2
    end if
    
end program txt2dat

subroutine takemax(upx,yrbeg,yrend,olddatum,vals,factor)
    implicit none
    integer :: yrbeg,yrend,olddatum,vals(24)
    real :: upx(31,12,yrbeg:yrend),factor
    integer :: n,yyyy,mm,dd,hh
    real :: upmax
    n = 0
    upmax = 0
    do hh=1,24
        if ( vals(hh) >= 0 ) then
            n = n+ 1
            upmax = max(upmax,vals(hh)/10.)
        end if
    end do
    if ( n < 20 ) then ! arbitrary
        upmax = 3e33
    end if
    if ( upmax < 1e33 ) then
        yyyy = olddatum/10000
        mm = mod(olddatum/100,100)
        dd = mod(olddatum,100)
        if ( upx(dd,mm,yyyy) < 1e33 ) then
            if ( abs(upx(dd,mm,yyyy)-upmax) > 0.1 ) then
                write(0,*) 'txt2dat_potwind: warning: different values for ', &
                    olddatum,upx(dd,mm,yyyy),upmax
            end if
        end if
        upx(dd,mm,yyyy) = upmax*factor
    end if
end subroutine takemax