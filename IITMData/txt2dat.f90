program txt2dat

!   convert the IITM txt files into my .dat files; generate a
!   file india.html with the meta-information

    implicit none
    integer :: nyears,yr,i,j,n,iregion,isub,idata(12),lat,lon
    real :: data(12)
    character name*5,file*9,details*100,text*100,string*80

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
    read(2,'(a)',end=190) string
    iregion = 0
100 continue
    iregion = iregion + 1
    read(2,'(i3,a)',end=190) nyears,details
    do while ( details(1:1) == ' ' )
        text = details(2:)
        details = text
    end do
    do i=1,nyears
        read(2,'(a5,i4,x,12i5)') name,yr,idata
        if ( i == 1 ) then
            open(3,file=name//'.dat')
            write(3,'(2a)') '# ',trim(details)
            write(3,'(3a)') '# Data obtained from the Indian ', &
            'Institute of Tropical Meteorology', &
            ' (<a href="http://www.tropmet.res.in/">IITM</a>)'
            write(3,'(3a)') '# See their <a href="ftp://www.tropmet' &
            ,'.res.in/pub/data/rain/iitm-imr-readme.txt">', &
            'license file</a> for conditions for use'
            write(3,'(3a)') '# precip [mm/mo] ',name &
            ,' precipitation'
            n = index(details,'(')
            do j=n-1,1,-1
                if ( details(j:j) /= ' ' ) goto 110
            enddo
            110 n = j
            text = details(:n)
            do j=1,n
                if ( text(j:j) == ' ' ) text(j:j) = '_'
            enddo
            if ( name == 'NWIND' ) then
                lat = 26
                lon = 75
            elseif ( name == 'WCIND' ) then
                lat = 19
                lon = 78
            elseif ( name == 'CNEIN' ) then
                lat = 24
                lon = 85
            elseif ( name == 'NEIND' ) then
                lat = 25
                lon = 93
            elseif ( name == 'PENIN' ) then
                lat = 12
                lon = 78
            elseif ( name == 'ALLIN' ) then
                lat = 20
                lon = 80
            elseif ( name == 'CORIN' ) then
                lat = 23
                lon = 76
            elseif ( name == 'HOMIN' ) then
                lat = 24
                lon = 76
            else
                write(0,*) 'error: do not know where ',name &
                ,' is'
                call abort
                goto 120
            endif
            write(1,'(a)') details(:n)
            write(1,'(a,i3,a,i3,a)') 'coordinates: ',lat, &
            'N, ',lon,'E'
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
    read(2,'(a)',end=190) string
    iregion = 0
200 continue
    iregion = iregion + 1
    read(2,'(2i3,x,a)',end=290) nyears,isub,details
    do i=1,nyears
        read(2,'(a5,i4,x,12i5)') name,yr,idata
        if ( i == 1 ) then
            open(3,file=name//'.dat')
            write(3,'(a,i2,2a)') '# Subdivision #',isub,'.',details
            write(3,'(3a)') '# Data obtained from the Indian ', &
            'Institute of Tropical Meteorology', &
            ' (<a href="http://www.tropmet.res.in/">IITM</a>)'
            write(3,'(3a)') '# See their <a href="ftp://www.tropmet' &
            ,'.res.in/pub/data/rain/iitm-imr-readme.txt">', &
            'license file</a> for conditions for use'
            write(3,'(3a)') '# precip [mm/mo] ',name &
            ,' precipitation'
            n = index(details,'SUBDIVISION')
            do j=n-1,1,-1
                if ( details(j:j) /= ' ' ) goto 210
            enddo
            210 n = j
            text = details(:n)
            do j=1,n
                if ( text(j:j) == ' ' ) text(j:j) = '_'
            enddo
        !       read off from the png maps combined with the Times atlas...
            if ( name == 'ASMEG' ) then
                lat = 27
                lon = 91
            elseif ( name == 'NMAMT' ) then
                lat = 26
                lon = 93
            elseif ( name == 'JHKND' ) then
                lat = 23
                lon = 85
            elseif ( name == 'BIHAR' ) then
                lat = 26
                lon = 86
            elseif ( name == 'VDABH' ) then
                lat = 21
                lon = 88
            elseif ( name == 'CHHAT' ) then
                lat = 24
                lon = 81
            elseif ( name == 'NASSM' ) then
                lat = 27
                lon = 94
            elseif ( name == 'SASSM' ) then
                lat = 25
                lon = 93
            elseif ( name == 'SHWBL' ) then
                lat = 26
                lon = 89
            elseif ( name == 'GNWBL' ) then
                lat = 23
                lon = 88
            elseif ( name == 'ORISS' ) then
                lat = 21
                lon = 85
            elseif ( name == 'BHPLT' ) then
                lat = 23
                lon = 85
            elseif ( name == 'BHPLN' ) then
                lat = 26
                lon = 86
            elseif ( name == 'EUPRA' ) then
                lat = 26
                lon = 82
            elseif ( name == 'WUPPL' ) then
                lat = 28
                lon = 79
            elseif ( name == 'HARYA' ) then
                lat = 29
                lon = 76
            elseif ( name == 'PUNJB' ) then
                lat = 31
                lon = 76
            elseif ( name == 'WRJST' ) then
                lat = 27
                lon = 72
            elseif ( name == 'ERJST' ) then
                lat = 26
                lon = 76
            elseif ( name == 'WMPRA' ) then
                lat = 23
                lon = 78
            elseif ( name == 'EMPRA' ) then
                lat = 22
                lon = 82
            elseif ( name == 'GUJRT' ) then
                lat = 24
                lon = 73
            elseif ( name == 'SAUKU' ) then
                lat = 23
                lon = 71
            elseif ( name == 'KNGOA' ) then
                lat = 19
                lon = 73
            elseif ( name == 'MADMH' ) then
                lat = 19
                lon = 75
            elseif ( name == 'MARAT' ) then
                lat = 19
                lon = 77
            elseif ( name == 'VDRBH' ) then
                lat = 21
                lon = 79
            elseif ( name == 'COAPR' ) then
                lat = 17
                lon = 81
            elseif ( name == 'TELNG' ) then
                lat = 18
                lon = 79
            elseif ( name == 'RLSMA' ) then
                lat = 14
                lon = 79
            elseif ( name == 'TLNAD' ) then
                lat = 11
                lon = 79
            elseif ( name == 'COKNT' ) then
                lat = 14
                lon = 75
            elseif ( name == 'NIKNT' ) then
                lat = 16
                lon = 76
            elseif ( name == 'SIKNT' ) then
                lat = 13
                lon = 77
            elseif ( name == 'KERLA' ) then
                lat = 11
                lon = 76
            else
                write(0,*) 'error: unknown name, isub ',name,isub
                call abort
            endif
            write(1,'(a)') details(:n)
            write(1,'(a,i3,a,i3,a)') 'coordinates: ',lat, &
            'N, ',lon,'E'
            write(1,'(a,i3,2a)') 'Station code: ',isub, &
            ' ',text(1:n)
            write(1,'(a,i3,2a)') 'Found ',nyears,' years of data ', &
            details(index(details,'SUBDIVISION')+12:)
            write(1,'(a)') &
            '=============================================='
            220 continue
            write(10,'(i3,3a)') isub,') name="',name,'";;'
        endif
        write(3,'(i4,12f8.1)') yr,(idata(j)/10.,j=1,12)
    enddo
    close(3)
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
                call abort
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
                call abort
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
