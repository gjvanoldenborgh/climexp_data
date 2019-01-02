program txt2dat

!   convert the IITM txt files into my .dat files; generate a
!   file india.html with the meta-information

    implicit none
    integer :: nyears,yr,i,j,n,iregion,isub,idata(12),lat,lon
    real :: data(12)
    character name*5,file*9,details*100,text*100,string*80,longname*120

    open(10,file='getindiaprcp')
    write(10,'(a)') '#!/bin/sh'
    write(10,'(a)') 'case $1 in'

    open(1,file='pregion.txt',status='old',err=10)
    close(1,status='delete')
 10 continue
    open(1,file='pregion.txt',status='new')
    write(1,'(a)') 'Precipitation regions in 6N:39N, 66E:99E'
    write(1,'(a)') '=============================================='

    open(2,file='iitm-regionrf.txt',status='old')
    iregion = 0
100 continue
    iregion = iregion + 1
    read(2,'(i3,a)',end=190) nyears,details
    do while ( details(1:1) == ' ' )
        text = details(2:)
        details = text
    end do
    i = index(details,'(')
    longname = details(:i-1)
    if ( longname == 'NORTHWEST INDIA RAINFALL' ) then
        name = 'NWIND'
        lat = 26
        lon = 75
    elseif ( longname == 'WEST CENTRAL INDIA RAINFALL' ) then
        name = 'WCIND'
        lat = 19
        lon = 78
    elseif ( longname == 'CENTRAL NORTHEAST INDIA RAINFALL' ) then
        name = 'CNEIN'
        lat = 24
        lon = 85
    elseif ( longname == 'NORTHEAST INDIA RAINFALL' ) then
        name = 'NEIND'
        lat = 25
        lon = 93
    elseif ( longname == 'PENINSULAR INDIA RAINFALL' ) then
        name = 'PENIN'
        lat = 12
        lon = 78
    elseif ( longname == 'ALL-INDIA  RAINFALL' ) then
        name = 'ALLIN'
        lat = 20
        lon = 80
    else
        write(0,*) 'error: do not know where ',trim(longname),' is'
        call exit(-1)
    endif
    ! skip 5 lines
    do i=1,5
        read(2,'(a)')
    end do
    do i=1,nyears
        read(2,*) yr,idata
        if ( i == 1 ) then
            open(3,file=name//'.dat')
            write(3,'(2a)') '# ',trim(details)
            write(3,'(3a)') '# Data obtained from the Indian ', &
                'Institute of Tropical Meteorology', &
                ' (<a href="http://www.tropmet.res.in/">IITM</a>)'
            write(3,'(3a)') '# See their <a href="ftp://www.tropmet' &
                ,'.res.in/pub/data/rain/iitm-imr-readme.txt">', &
                'license file</a> for conditions for use'
            write(3,'(3a)') '# precip [mm/mo] ',trim(longname)
            n = index(details,'(')
            do j=n-1,1,-1
                if ( details(j:j) /= ' ' ) goto 110
            enddo
            110 n = j
            text = details(:n)
            do j=1,n
                if ( text(j:j) == ' ' ) text(j:j) = '_'
            enddo
            write(1,'(a)') details(:n)
            write(1,'(a,i3,a,i3,a)') 'coordinates: ',lat,'N, ',lon,'E'
            write(1,'(a,i3,2a)') 'Station code: ',100+iregion, &
                ' ',text(1:n)
            write(1,'(a,i3,2a)') 'Found ',nyears,' years of data ', &
                details(index(details,'('):)
            write(1,'(a)') &
            '=============================================='
120         continue
            write(10,'(i3,3a)') 100+iregion,') name="',name,'";;'
        endif
        write(3,'(i4,12f8.1)') yr,(idata(j)/10.,j=1,12)
    enddo
    close(3)
    ! skip 8 lines
    do i=1,8
        read(2,'(a)')
    end do
    goto 100
190 continue
    close(1)
    close(2)

    open(1,file='psubdiv.txt',status='old',err=201)
    close(1,status='delete')
201 continue
    open(1,file='psubdiv.txt',status='new')
    write(1,'(a)') 'Precipitation regions in 6N:39N, 66E:99E'
    write(1,'(a)') '=============================================='
            
    open(2,file='iitm-subdivrf.txt',status='old')
    iregion = 0
200 continue
    iregion = iregion + 1
    read(2,'(2i3,x,a)',end=290) nyears,isub,details
    i = index(details,'SUBDIVISION')
    longname = details(:i-1)
!   read off from the png maps combined with the Times atlas...
    if ( longname == 'ASSAM & MEGHALAYA' ) then
        name = 'ASMEG'
        lat = 27
        lon = 91
    elseif ( longname == 'NAGA.MANI.MIZO.&TRIP' ) then
        name = 'NMAMT'
        lat = 26
        lon = 93
    elseif ( longname == 'JHARKHAND' ) then
        name = 'JHKND'
        lat = 23
        lon = 85
    elseif ( longname == 'BIHAR' ) then
        name = 'BIHAR'
        lat = 26
        lon = 86
    elseif ( longname == 'VIDARBHA' ) then
        name = 'VDABH'
        lat = 21
        lon = 88
    elseif ( longname == 'CHATTISGARH' ) then
        name = 'CHHAT'
        lat = 24
        lon = 81
    elseif ( longname == 'NASSM' ) then
        lat = 27
        lon = 94
    elseif ( longname == 'SASSM' ) then
        lat = 25
        lon = 93
    elseif ( longname == 'SUB-HIMA. W. B' ) then
        name = 'SHWBL'
        lat = 26
        lon = 89
    elseif ( longname == 'GANGETIC W. B' ) then
        name = 'GNWBL'
        lat = 23
        lon = 88
    elseif ( longname == 'ORISSA' ) then
        name = 'ORISS'
        lat = 21
        lon = 85
    elseif ( longname == 'BHPLT' ) then
        lat = 23
        lon = 85
    elseif ( longname == 'BHPLN' ) then
        lat = 26
        lon = 86
    elseif ( longname == 'EAST UTTAR PR' ) then
        name = 'EUPRA'
        lat = 26
        lon = 82
    elseif ( longname == 'WEST U.P. PLA' ) then
        name = 'WUPPL'
        lat = 28
        lon = 79
    elseif ( longname == 'HARYANA' ) then
        name = 'HARYA'
        lat = 29
        lon = 76
    elseif ( longname == 'PUNJAB' ) then
        name = 'PUNJB'
        lat = 31
        lon = 76
    elseif ( longname == 'WEST RAJASTHAN' ) then
        name = 'WRJST'
        lat = 27
        lon = 72
    elseif ( longname == 'EAST RAJASTHAN' ) then
        name = 'ERJST'
        lat = 26
        lon = 76
    elseif ( longname == 'WEST MADHYA P' ) then
        name = 'WMPRA'
        lat = 23
        lon = 78
    elseif ( longname == 'EAST MADHYA P' ) then
        name = 'EMPRA'
        lat = 22
        lon = 82
    elseif ( longname == 'GUJARAT' ) then
        name = 'GUJRT'
        lat = 24
        lon = 73
    elseif ( longname == 'SAURASHTRA & KUTCH' ) then
        name = 'SAUKU'
        lat = 23
        lon = 71
    elseif ( longname == 'KONKAN AND GOA' ) then
        name = 'KNGOA'
        lat = 19
        lon = 73
    elseif ( longname == 'MADHYA MAHARASHTRA' ) then
        name = 'MADMH'
        lat = 19
        lon = 75
    elseif ( longname == 'MARATHWADA' ) then
        name = 'MARAT'
        lat = 19
        lon = 77
    elseif ( longname == 'VIDARBHA' ) then
        name = 'VDRBH'
        lat = 21
        lon = 79
    elseif ( longname == 'COASTAL ANDHRA PRADESH' ) then
        name = 'COAPR'
        lat = 17
        lon = 81
    elseif ( longname == 'TELANGANA' ) then
        name = 'TELNG'
        lat = 18
        lon = 79
    elseif ( longname == 'RAYALASEEMA' ) then
        name = 'RLSMA'
        lat = 14
        lon = 79
    elseif ( longname == 'TAMIL NADU' ) then
        name = 'TLNAD'
        lat = 11
        lon = 79
    elseif ( longname == 'COASTAL KARNATAKA' ) then
        name = 'COKNT'
        lat = 14
        lon = 75
    elseif ( longname == 'NORTH INT. KARNATAKA' ) then
        name = 'NIKNT'
        lat = 16
        lon = 76
    elseif ( longname == 'SOUTH INT. KARNATAKA' ) then
        name = 'SIKNT'
        lat = 13
        lon = 77
    elseif ( longname == 'KERALA' ) then
        name = 'KERLA'
        lat = 11
        lon = 76
    else
        write(0,*) 'error: unknown name ',trim(longname)
        write(0,*) trim(details)
        call exit(-1)
    endif
    ! skip 5 lines
    do i=1,5
        read(2,'(a)')
    end do
    do i=1,nyears
        read(2,*) yr,idata
        if ( i == 1 ) then
            open(3,file=name//'.dat')
            write(3,'(a,i2,2a)') '# Subdivision #',isub,'.',details
            write(3,'(3a)') '# Data obtained from the Indian ', &
                'Institute of Tropical Meteorology', &
                ' (<a href="http://www.tropmet.res.in/">IITM</a>)'
            write(3,'(3a)') '# See their <a href="ftp://www.tropmet' &
                ,'.res.in/pub/data/rain/iitm-imr-readme.txt">', &
                'license file</a> for conditions for use'
            write(3,'(3a)') '# precip [mm/mo] ',trim(longname),' RAINFALL'
            n = index(details,'SUBDIVISION')
            do j=n-1,1,-1
                if ( details(j:j) /= ' ' ) goto 210
            enddo
        210 n = j
            text = details(:n)
            do j=1,n
                if ( text(j:j) == ' ' ) text(j:j) = '_'
            enddo
            write(1,'(a)') details(:n)
            write(1,'(a,i3,a,i3,a)') 'coordinates: ',lat, &
            'N, ',lon,'E'
            write(1,'(a,i3,2a)') 'Station code: ',isub, &
            ' ',text(1:n)
            write(1,'(a,i3,2a)') 'Found ',nyears,' years of data ', &
            details(index(details,'SUBDIVISION')+12:)
            write(1,'(a)') '=============================================='
        220 continue
            write(10,'(i3,3a)') isub,') name="',name,'";;'
        endif
        write(3,'(i4,12f8.1)') yr,(idata(j)/10.,j=1,12)
    enddo
    close(3)
    ! skip 8 lines
    do i=1,8
        read(2,'(a)')
    end do
    goto 200
290 continue
    close(1)
    close(2)
            
    write(10,'(a)') '*) file=unknownindex;;'
    write(10,'(a)') 'esac'
    write(10,'(a)') 'cat IITMData/$name.dat'
    close(10)

    open(10,file='getindiatmin')
    write(10,'(a)') '#!/bin/sh'
    write(10,'(a)') 'case $1 in'

    open(1,file='nregion.txt',status='old',err=30)
    close(1,status='delete')
 30 continue
    open(1,file='nregion.txt',status='new')
    write(1,'(a)') 'Tmin regions in 6N:39N, 66E:99E'
    write(1,'(a)') '=============================================='

    open(2,file='NEW-TNREGION.TXT',status='old')
    iregion = 0
300 continue
    iregion = iregion + 1
    read(2,'(i3,6x,a,2x,a)',end=390) nyears,name,details
    do i=1,nyears
        read(2,'(a5,i4,x,12f6.1)') name,yr,data
        if ( i == 1 ) then
            open(3,file='tn'//name//'.dat')
            if ( details(1:1) == ' ' ) then
                text = details(2:)
                details = text
            endif
            write(3,'(2a)') '# ',trim(details)
            write(3,'(3a)') '# Data obtained from the Indian ', &
            'Institute of Tropical Meteorology', &
            ' (<a href="http://www.tropmet.res.in/">IITM</a>)'
            write(3,'(3a)') '# See their <a href="ftp://www.tropmet' &
            ,'.res.in/iitm-imr-readme.txt">license file</a> ', &
            'for conditions for use'
            write(3,'(3a)') '# See their <a href="ftp://www.tropmet' &
            ,'.res.in/pub/data/txtn/README.pdf">', &
            'license file</a> for conditions for use'
            write(3,'(3a)') '# Tmin [Celsius] ',name &
            ,' minimum temperature'
            n = index(details,'(')
            if ( n == 0 ) n = 1 + len_trim(details)
            do j=n-1,1,-1
                if ( details(j:j) /= ' ' ) goto 310
            enddo
            310 n = j
            text = details(:n)
            do j=1,n
                if ( text(j:j) == ' ' ) text(j:j) = '_'
            enddo
            if ( name == 'NWIND' ) then
                lat = 26
                lon = 75
            elseif ( name == 'WHIND' ) then
                lat = 34
                lon = 76
            elseif ( name == 'NCIND' ) then
                lat = 24
                lon = 81
            elseif ( name == 'NEIND' ) then
                lat = 26
                lon = 93
            elseif ( name == 'IPIND' ) then
                lat = 18
                lon = 78
            elseif ( name == 'ECIND' ) then
                lat = 15
                lon = 74
            elseif ( name == 'WCIND' ) then
                lat = 15
                lon = 80
            elseif ( name == 'ALLIN' ) then
                lat = 20
                lon = 80
            else
                write(0,*) 'error: unknown region: ',name
                call exit(-1)
            endif
            write(1,'(a)') details(:n)
            write(1,'(a,i3,a,i3,a)') 'coordinates: ',lat, &
            'N, ',lon,'E'
            write(1,'(a,i3,2a)') 'Station code: ',100+iregion, &
            ' ',text(1:n)
            write(1,'(a,i3,2a)') 'Found ',nyears,' years of data '
            write(1,'(a)') &
            '=============================================='
            320 continue
            write(10,'(i3,3a)') 100+iregion,') name="tn',name,'";;'
        endif
        write(3,'(i4,12f8.1)') yr,data
    enddo
    close(3)
    goto 300
    390 continue
    close(1)
    close(2)

    write(10,'(a)') '*) file=unknownindex;;'
    write(10,'(a)') 'esac'
    write(10,'(a)') 'cat IITMData/$name.dat'
    close(10)

    open(10,file='getindiatmax')
    write(10,'(a)') '#!/bin/sh'
    write(10,'(a)') 'case $1 in'

    open(1,file='xregion.txt',status='old',err=40)
    close(1,status='delete')
 40 continue
    open(1,file='xregion.txt',status='new')
    write(1,'(a)') 'Tmax regions in 6N:39N, 66E:99E'
    write(1,'(a)') '=============================================='

    open(2,file='NEW-TXREGION.TXT',status='old')
    iregion = 0
400 continue
    iregion = iregion + 1
    read(2,'(i3,6x,a,x,a)',end=490) nyears,name,details
    do i=1,nyears
        read(2,'(a5,i4,x,12f6.1)') name,yr,data
        if ( i == 1 ) then
            open(3,file='tx'//name//'.dat')
            if ( details(1:1) == ' ' ) then
                text = details(2:)
                details = text
            endif
            write(3,'(2a)') '# ',trim(details)
            write(3,'(3a)') '# Data obtained from the Indian ', &
            'Institute of Tropical Meteorology', &
            ' (<a href="http://www.tropmet.res.in/">IITM</a>)'
            write(3,'(3a)') '# See their <a href="ftp://www.tropmet' &
            ,'.res.in/pub/data/txtn/README.pdf">', &
            'license file</a> for conditions for use'
            write(3,'(3a)') '# Tmax [Celsius] ',name &
            ,' maximum temperature'
            n = index(details,'(')
            if ( n == 0 ) n = 1 + len_trim(details)
            do j=n-1,1,-1
                if ( details(j:j) /= ' ' ) goto 410
            enddo
            410 n = j
            text = details(:n)
            do j=1,n
                if ( text(j:j) == ' ' ) text(j:j) = '_'
            enddo
            if ( name == 'NWIND' ) then
                lat = 26
                lon = 75
            elseif ( name == 'WHIND' ) then
                lat = 34
                lon = 76
            elseif ( name == 'NCIND' ) then
                lat = 24
                lon = 81
            elseif ( name == 'NEIND' ) then
                lat = 26
                lon = 93
            elseif ( name == 'IPIND' ) then
                lat = 18
                lon = 78
            elseif ( name == 'ECIND' ) then
                lat = 15
                lon = 80
            elseif ( name == 'WCIND' ) then
                lat = 15
                lon = 74
            elseif ( name == 'ALLIN' ) then
                lat = 20
                lon = 80
            else
                write(0,*) 'error: unknown region ',name
                call exit(-1)
            endif
            write(1,'(a)') details(:n)
            write(1,'(a,i3,a,i3,a)') 'coordinates: ',lat, &
            'N, ',lon,'E'
            write(1,'(a,i3,2a)') 'Station code: ',100+iregion, &
            ' ',text(1:n)
            write(1,'(a,i3,2a)') 'Found ',nyears,' years of data '
            write(1,'(a)') &
            '=============================================='
420         continue
            write(10,'(i3,3a)') 100+iregion,') name="tx',name,'";;'
        endif
        write(3,'(i4,12f8.1)') yr,data
    enddo
    close(3)
    goto 400
490 continue
    close(1)
    close(2)

    write(10,'(a)') '*) file=unknownindex;;'
    write(10,'(a)') 'esac'
    write(10,'(a)') 'cat IITMData/$name.dat'
    close(10)

end program txt2dat
