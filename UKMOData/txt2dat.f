        program txt2dat
*
*       convert the Hadley Centre monthly temperature anomalies file
*       into time series the Climate Explorer can handle
*
        implicit none
        integer yr,i,j,iu,k,n
        real val(13),s
        character mofile*40,yrfile*40,name*40,line*128,region*80,
     +       region1*80
        logical wrong

        open(1,file='HadCRUG.txt',status='old')
        open(10,file='monthly.html')
        open(11,file='yearly.html')
 100    continue
        read(1,'(a)') line
        if ( line(1:9).ne.'LASTMONTH' ) goto 100
*
        read(1,'(a)',end=800) line
 200    continue
        read(1,'(a)',end=800) line
        do i=1,len(line)
            if ( line(i:i).ne.' ') goto 201
        enddo
 201    continue
        if ( i.ge.len(line) ) then
            write(0,*) 'error: empty line'
            call abort
        endif
        region = line(i:)
        j = index(region,'(')-1
        if ( j.le.0 ) j = index(region,'N OF') - 1
        if ( j.le.0 ) j = index(region,'S OF') - 1
        if ( j.le.0 ) j = index(region,'5') - 1
        if ( j.le.0 ) j = len_trim(region) + 1
        name = line(i:i+j-2)
        do k=1,len_trim(name)
            if ( name(k:k).eq.' ' .or. name(k:k).eq.'/' )
     +           name(k:k) = '_'
        enddo
        mofile = trim(name)//'.dat'
        yrfile = trim(name)//'_yr.dat'
        call tolower(name)
        call tolower(region)
        region1 = region
        do k=1,len_trim(region1)
            if ( region1(k:k).eq.' ' ) region1(k:k) = '_'
        enddo
        call tolower(mofile)
        call tolower(yrfile)
        write(10,'(10a)') '<a href="getindices.cgi?UKMOData/',trim(name)
     +       ,'+T_',trim(region1),'+i+$EMAIL+12">',trim(region)
     +       ,'</a>, '
        write(11,'(10a)') '<a href="getindices.cgi?UKMOData/',trim(name)
     +       ,'_yr+T_',trim(region1),'+i+$EMAIL+1">',trim(region)
     +       ,'</a>, '
        open(2,file=mofile)
        open(3,file=yrfile)
        do iu=2,3
            write(iu,'(10a)') '# HadCRUT2(v) Regional Averages'
            write(iu,'(10a)') '# from <a href="http://www.met-office'//
     +           '.gov.uk/research/hadleycentre/obsdata/'//
     +           'globaltemperature.html">Hadley Centre</a>'
            write(iu,'(10a)') '# ',trim(line(i:))
            write(iu,'(a)') '# Ta [Celsius]'
            write(iu,'(a)') '#'
        enddo
 300    continue
        read(1,'(a)',end=800) line
        if ( line.eq.' ' ) then
            close(2)
            close(3)
            goto 200
        endif
        read(line,'(i5,13f7.2)') yr,val
        wrong = .false.
        do i=1,12
*           Big Errors in file
            if ( val(i).lt.-50 ) then
                wrong = .true.
                val(i) = -999.9
            endif
        enddo
        if ( wrong ) then
*           recompute the annual average
            s = 0
            n = 0
            do i=1,12
                if ( val(i).gt.-99 ) then
                    n = n + 1
                    s = s + val(i)
                endif
            enddo
            if ( n.gt.3 ) then
                print *,'adjusting annual average from ',val(13),yr
                val(13) = s/n
                print *,'                           to ',val(13)
            else
                val(13) = -999.9
            endif
        endif
        write(2,'(i4,13f8.2)') yr,val
        write(3,'(i4,13f8.2)') yr,val(13)
        goto 300
 800    continue
        end

*  #[ tolower:
        subroutine tolower(string)
        implicit none
        character*(*) string
        integer i
        do i=1,len(string)
            if ( ichar(string(i:i)).ge.ichar('A') .and. 
     +           ichar(string(i:i)).le.ichar('Z') ) then
                string(i:i) = char(ichar(string(i:i)) - ichar('A') +
     +              ichar('a'))
            endif
        enddo
*  #] tolower:
        end
