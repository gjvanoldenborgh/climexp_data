        program txt2dat
!       convert the GISS txt files to my format dat files
        implicit none
        integer yrbeg,yrend
        parameter (yrbeg=1880,yrend=2020)
        integer i,j,vals(20),yr
        real mdata(12,yrbeg:yrend),sdata(4,yrbeg:yrend)
     +       ,adata(yrbeg:yrend)
        character line*300,reg*3,region*30,type*30,rg*2,tp*2
        logical lwrite
        integer iargc
!
        lwrite = .false.
        if ( iargc().ne.2 ) then
            print *,'usage: txt2dat region type'
            call abort
        end if
        call getarg(1,reg)
        call getarg(2,type)
        if ( reg.eq.'GLB') then
            rg = 'gl'
            region = 'global'
        else if ( reg.eq.'NH') then
            rg = 'nh'
            region = 'northern hemisphere'
        else if ( reg.eq.'SH') then
            rg = 'sh'
            region = 'southern hemisphere'
        else
            write(0,*) 'error: expected region GLB, NH or SH not '
     +           ,trim(region)
            call abort
        end if
        if ( type.eq.'Ts' ) then
            tp = 'ts'
        else if ( type.eq.'Ts+dSST' ) then
            tp = 'al'
        else
            write(0,*) 'error: expected type Ts or Ts+dSST, not '
     +           ,trim(type)
            call abort
        end if

        open(1,file=trim(reg)//'.'//trim(type)//'.txt',status='old')
        open(2,file='giss_'//tp//'_'//rg//'_m.dat')
        open(3,file='giss_'//tp//'_'//rg//'_s.dat')
        open(4,file='giss_'//tp//'_'//rg//'_a.dat')
        do i=2,4
            if ( tp.eq.'Ts' ) then
                write(i,'(a)') '# GISS Surface Temperature Analysis, '
     +               //trim(region)//' mean anomalies'
            else
                write(i,'(a)') '# GISS Land-Ocean Temperature Index, '
     +               //trim(region)//' mean anomalies'
            end if
            write(i,'(a)') '# Source: '
     +           //'<a href="http://data.giss.nasa.gov/gistemp/">'
     +           //'NASA/GISS</a>'
            write(i,'(a)')'# Ta [K] '//trim(region)//' temperature'
        end do

        mdata = 3e33
        sdata = 3e33
        adata = 3e33
 100    continue
        read(1,'(a)',end=800,err=900) line
        if ( line(1:1).ne.'1' .and. line(1:1).ne.'2' ) goto 100
 110    continue
!!!        print *,trim(line)
        i = index(line,'*****')
        if ( i.ne.0 ) then
            line(i:i+4) = ' 999 '
            goto 110
        end if
        i = index(line,'**** ')
        if ( i.ne.0 ) then
            line(i:i+4) = ' 999 '
            goto 110
        end if
        i = index(line,' ****')
        if ( i.ne.0 ) then
            line(i:i+4) = ' 999 '
            goto 110
        end if
        i = index(line,'****')
        if ( i.ne.0 ) then
            line(i+5:) = line(i+4:)
            line(i:i+4) = ' 999 '
            goto 110
        end if
        i = index(line,' *** ')
        if ( i.ne.0 ) then
            line(i:i+4) = ' 999 '
            goto 110
        end if
        i = index(line,' ** ')
        if ( i.ne.0 ) then
            line(i+5:) = line(i+4:)
            line(i:i+4) = ' 999 '
            goto 110
        end if
        i = index(line,' * ')
        if ( i.ne.0 ) then
            line(i+5:) = line(i+3:)
            line(i:i+4) = ' 999 '
            goto 110
        end if
        read(line,*,err=900) vals
        yr = vals(1)
        if ( lwrite ) then
            print *,trim(line)
            print *,vals
        endif
        if ( vals(20).ne.yr ) then
            write(0,*) 'error: vals(20) != yr: ',vals(20),yr
            call abort
        endif
        do j=1,19
            if ( vals(j).eq.999 ) vals(j) = -99990
        end do
        do j=1,12
            mdata(j,yr) = vals(j+1)/100.
        end do
        do j=1,4
            sdata(j,yr) = vals(j+15)/100.
        end do
        adata(yr) = vals(14)/100.
        goto 100

 800    continue
        call printdatfile(2,mdata,12,12,yrbeg,yrend)
        call printdatfile(3,sdata,4,4,yrbeg,yrend)
        call printdatfile(4,adata,1,1,yrbeg,yrend)
 
        goto 999
 900    write(0,*) 'error reading data, last line was'
        write(0,*) trim(line)

 999    continue
        end
