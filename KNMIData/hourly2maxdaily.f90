program hourly2max

!   read the KNMI datasebase files in and spews out files with daily data per station
!   max hourly precip
!   Tdew 4 hours earlier

    implicit none
    integer,parameter :: maxstations=100
    integer :: ifile,istation,station,datum,olddatum,yr,mo,dy,hr,i,j, &
        iname,stations(maxstations),nstations,years(2,maxstations)
    integer :: t,td,rh,tds(24),oldtds(24),rhs(24),maxpr,maxtp,maxtd,ii(8)
    real :: lon,lat,hgt
    character :: file*255,line*80,ofile*20,name*40
    logical :: lwrite

    lwrite = .false. 
    nstations = 0
    do ifile=1,iargc()
        olddatum = -1
        oldtds = 9999
        call get_command_argument(ifile,file)
        open(1,file=trim(file),status='old')
    100 continue
        read(1,'(a)',end=800) line
        if ( line(1:6) == '# STN,' ) then
            if ( line /= '# STN,YYYYMMDD,   HH,    T,   TD,   RH' ) then
                write(0,*) 'maybe wrong variables in file ',trim(file),'?'
                write(0,*) 'expected # STN,YYYYMMDD,   HH,    T,   TD,   RH'
                write(0,*) 'obtained ',trim(line)
                call exit(-1)
            end if
        end if
        if ( line(1:1) == '#' ) go to 100
        i = index(line,',', .true. )
        if ( line(i+1:) == ' ' ) go to 100
        read(line,*,err=901,end=901) station,datum,hr,t,td,rh
        if ( rh == -1 ) rh = 0 ! round down 0<rh<0.05
        yr = datum/10000
        do istation = 1,nstations
            if ( station == stations(istation) ) then
                exit
            end if
        end do
        if ( istation > nstations ) then
            nstations = nstations + 1
            stations(nstations) = station
            years(1,nstations) = yr
            years(2,nstations) = yr
            write(ofile,'(a,i3.3,a)') 'rx',station,'.dat'
            open(10+3*istation,file=trim(ofile))
            write(10+3*istation,'(a,i3)') '# daily max of hourly '// &
                'precipitation at station ',station
            write(10+3*istation,'(a)') '# pr [mm/hr] max hourly '// &
                'precipitation'
            write(ofile,'(a,i3.3,a)') 'tp',station,'.dat'
            open(11+3*istation,file=trim(ofile))
            write(11+3*istation,'(a,i3)') '# dew point '// &
                'temperature 4hr before max of hourly '// &
                'precipitation at station ',station
            write(11+3*istation,'(a)') '# Tdew [Celsius] dew '// &
                'point temperature'
            write(ofile,'(a,i3.3,a)') 'td',station,'.dat'
            open(12+3*istation,file=trim(ofile))
            write(12+3*istation,'(a,i3)') '# max dew point '// &
                'temperature at station ',station
            write(12+3*istation,'(a)') '# Tdew [Celsius] max '// &
                'dew point temperature'
            do i=10+3*istation,12+3*istation
                write(i,'(a)') '# institution :: KNMI'
                write(i,'(a)') '# source :: http://projects.knmi.nl/klimatologie/uurgegevens'
                call date_and_time(values=ii)
                write(i,'(a,i4,a,i2.2,a,i2.2,a,i2,a,i2.2,a,i2.2)') &
                    '# history :: generated ',ii(1),'-',ii(2),'-',ii(3),' ',ii(5),':',ii(6),':',ii(7)
            end do
        else
            years(1,istation) = min(yr,years(1,istation))
            years(2,istation) = max(yr,years(1,istation))
        end if

        if ( datum /= olddatum ) then
            if ( olddatum /= -1 ) then
                maxpr = -9999
                maxtd = -9999
                do i=1,24
                    if ( tds(i) > maxtd .and. tds(i) < 9999 ) then
                        maxtd = tds(i)
                    end if
                    if ( rhs(i) > maxpr .and. rhs(i) < 9999 ) then
                        maxpr = rhs(i)
                        if ( i > 4 ) then
                            maxtp = tds(i-4)
                        else
                            maxtp = oldtds(i+20)
                        end if
                    end if
                end do
                if ( maxpr >= 0 .and. maxpr < 9999 ) then
                    write(10+3*istation,'(i8,f7.1)') &
                    olddatum,maxpr/10.
                end if
                if ( maxtp >= 0 .and. maxtp < 9999 ) then
                    write(11+3*istation,'(i8,f7.1)') &
                    olddatum,maxtp/10.
                end if
                if ( maxtd >= 0 .and. maxtd < 9999 ) then
                    write(12+3*istation,'(i8,f7.1)') &
                    olddatum,maxtd/10.
                end if
            end if
            olddatum = datum
            oldtds = tds
            tds = 9999
            rhs = 9999
        end if
        tds(hr) = td
        rhs(hr) = rh

        goto 100
    800 continue
        close(1)
!       next file
    end do

    call get_command_argument(1,file)
    open(1,file=trim(file))
    open(2,file='list_rx.txt')
    open(3,file='list_tp.txt')
    open(4,file='list_td.txt')
    do i=2,4
        write(i,'(a,i4,a)') 'located ',nstations,' stations in 50.0N:54.0N, 3.0E:8.0E'
        write(i,'(a)') '=============================================='
    end do
    do istation=1,nstations
        rewind(1)
    801 continue
        read(1,'(a)',end=902) line
        if ( line(1:6) == '# STN ' ) then
            iname = index(line,'NAME')
        else if ( line(6:7) == ': ' ) then
            read(line(3:5),'(i3)',err=903) j
            if ( j == stations(istation) ) then
                if ( j == 215 ) then
                    lat = -999.9
                    lon = -999.9
                    hgt = -999.9
                    name = 'Voorschoten'
                else
                    read(line(8:),*) lon,lat,hgt
                    name = line(iname:)
                end if
                do i=2,4
                    write(i,'(2a)') name,'(Netherlands)'
                    write(i,'(a,f9.3,a,f9.3,a,f9.2,a)') &
                        'coordinates:',lat,'N,',lon,'E,',hgt,'m'
                    write(i,'(a,i3.3,2a)') 'station code: ', &
                        j,' ',trim(name)
                    write(i,'(a,i4,a,i4,a,i4)') 'Found ', &
                    years(2,istation)-years(1,istation)+1, &
                        ' years with data in ', &
                    years(1,istation),'-',years(2,istation)
                    write(i,'(a)') '=============================================='
                end do
                goto 802
            end if
        end if
        goto 801
    802 continue
    end do

    goto 999
901 write(0,*) 'error reading station,datum,hr,t,td,rh from line'
    write(0,*) trim(line)
    call exit(-1)
902 write(0,*) 'error reading metadata from line'
    write(0,*) trim(line)
    call exit(-1)
903 write(0,*) 'error reading station ID from line'
    write(0,*) trim(line)
    call exit(-1)

999 continue
    END PROGRAM
