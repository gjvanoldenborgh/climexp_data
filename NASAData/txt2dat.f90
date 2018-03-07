program txt2dat
!   convert the GISS txt files to my format dat files
    implicit none
    integer,parameter :: yrbeg=1880,yrend=2020
    integer :: i,j,vals(20),yr,idatum(8)
    real :: mdata(12,yrbeg:yrend),sdata(4,yrbeg:yrend),adata(yrbeg:yrend)
    character :: line*300,history*100,reg*3,region*30,type*30,rg*2,tp*2,outfile*80
    logical :: lwrite
    integer :: iargc

    lwrite = .false. 
    if ( iargc() /= 2 ) then
        print *,'usage: txt2dat region type'
        call exit(-1)
    end if
    call getarg(1,reg)
    call getarg(2,type)
    if ( reg == 'GLB') then
        rg = 'gl'
        region = 'global'
    else if ( reg == 'NH') then
        rg = 'nh'
        region = 'northern hemisphere'
    else if ( reg == 'SH') then
        rg = 'sh'
        region = 'southern hemisphere'
    else
        write(0,*) 'error: expected region GLB, NH or SH not ' ,trim(region)
        call exit(-1)
    end if
    if ( type == 'Ts' ) then
        tp = 'ts'
    else if ( type == 'Ts+dSST' ) then
        tp = 'al'
    else
        write(0,*) 'error: expected type Ts or Ts+dSST, not ',trim(type)
        call exit(-1)
    end if

    line = '# source :: GISTEMP Team, 2018: GISS Surface Temperature Analysis '// &
            '(GISTEMP). NASA Goddard Institute for Space Studies. '// &
            'Dataset accessed'
    history = '# history :: retrieved and converted'
    call date_and_time(values=idatum)
    write(line(len_trim(line)+2:),'(i4,a,i2.2,a,i2.2)') idatum(1),'-',idatum(2),'-',idatum(3)
    write(line(len_trim(line)+2:),'(i2,a,i2.2,a,i2.2)') idatum(5),':',idatum(6),':',idatum(7)
    write(history(len_trim(history)+2:),'(i4,a,i2.2,a,i2.2)') idatum(1),'-',idatum(2),'-',idatum(3)
    write(history(len_trim(history)+2:),'(i2,a,i2.2,a,i2.2)') idatum(5),':',idatum(6),':',idatum(7)

    open(1,file=trim(reg)//'.'//trim(type)//'.txt',status='old')
    do i=2,4
        if ( i == 2 ) then
            outfile = 'giss_'//tp//'_'//rg//'_m.dat'
        else if ( i == 3 ) then
            outfile = 'giss_'//tp//'_'//rg//'_s.dat'
        else if ( i == 4 ) then
            outfile = 'giss_'//tp//'_'//rg//'_a.dat'
        else
            write(0,*) 'txt2dat: error: fgyjuiol;jln'
            call exit(-1)
        end if
        open(i,file=trim(outfile))
        if ( tp == 'Ts' ) then
            write(i,'(a)') '# GISS Surface Temperature Analysis, ' &
                //trim(region)//' mean '//trim(type)//' anomalies'
        else
            write(i,'(a)') '# GISS Land-Ocean Temperature Index, ' &
                //trim(region)//' mean '//trim(type)//' anomalies'
        end if
        write(i,'(a)') '# Source: <a href="http://data.giss.nasa.gov/gistemp/">NASA/GISS</a>'
        write(i,'(a)')'# Ta [K] GISTEMP '//trim(region)//' '//trim(type)//' temperature anomaly'
        write(i,'(a)') '# title :: GISTEMP '//trim(region)//' '//trim(type)//' temperature anomalies '// &
            'relative to 1951-1980'
        write(i,'(a)') '# institution :: NASA/GISS'
        write(i,'(a)') '# contact :: https://www.giss.nasa.gov/staff/rruedy.html'
        write(i,'(a)') '# references :: Hansen, J., R. Ruedy, M. Sato, and K. Lo, 2010: '// &
            'Global surface temperature change, Rev. Geophys., 48, RG4004, doi:10.1029/2010RG000345'
        write(i,'(a)') trim(line)
        write(i,'(a)') '# source :: http://data.giss.nasa.gov/gistemp/'
        write(i,'(a)') trim(history)
        write(i,'(a)') '# climexp_url :: https://climexp.knmi.nl/getindices.cgi?'//trim(outfile)
    end do

    mdata = 3e33
    sdata = 3e33
    adata = 3e33
100 continue
    read(1,'(a)',end=800,err=900) line
    if ( line(1:1) /= '1' .and. line(1:1) /= '2' ) goto 100
110 continue
!!!        print *,trim(line)
    i = index(line,'*****')
    if ( i /= 0 ) then
        line(i:i+4) = ' 999 '
        goto 110
    end if
    i = index(line,'**** ')
    if ( i /= 0 ) then
        line(i:i+4) = ' 999 '
        goto 110
    end if
    i = index(line,' ****')
    if ( i /= 0 ) then
        line(i:i+4) = ' 999 '
        goto 110
    end if
    i = index(line,'****')
    if ( i /= 0 ) then
        line(i+5:) = line(i+4:)
        line(i:i+4) = ' 999 '
        goto 110
    end if
    i = index(line,' *** ')
    if ( i /= 0 ) then
        line(i:i+4) = ' 999 '
        goto 110
    end if
    i = index(line,' ** ')
    if ( i /= 0 ) then
        line(i+5:) = line(i+4:)
        line(i:i+4) = ' 999 '
        goto 110
    end if
    i = index(line,' * ')
    if ( i /= 0 ) then
        line(i+5:) = line(i+3:)
        line(i:i+4) = ' 999 '
        goto 110
    end if
    read(line,*,err=900) vals
    yr = vals(1)
    if ( lwrite ) then
        print *,trim(line)
        print *,vals
    end if
    if ( vals(20) /= yr ) then
        write(0,*) 'error: vals(20) != yr: ',vals(20),yr
        call exit(-1)
    end if
    do j=1,19
        if ( vals(j) == 999 ) vals(j) = -99990
    end do
    do j=1,12
        mdata(j,yr) = vals(j+1)/100.
    end do
    do j=1,4
        sdata(j,yr) = vals(j+15)/100.
    end do
    adata(yr) = vals(14)/100.
    goto 100

800 continue
    call printdatfile(2,mdata,12,12,yrbeg,yrend)
    call printdatfile(3,sdata,4,4,yrbeg,yrend)
    call printdatfile(4,adata,1,1,yrbeg,yrend)
     
    goto 999
900 write(0,*) 'error reading data, last line was'
    write(0,*) trim(line)

999 continue
end program txt2dat
