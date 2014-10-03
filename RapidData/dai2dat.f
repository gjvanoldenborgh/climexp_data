        program dai2dat
!
!       convert the dai.txt file into a Climate Explorer datfile
!
        implicit none
        integer yr,i
        real cnt,pct,dai,cl25,cl975
        character line*80

        open(1,file='dai.txt',status='old')
        read(1,'(a)') line
        do while ( index(line,'YEAR').eq.0 )
            i = index(line,'<')
            if ( i.ne.0 ) then
                line = line(:i-1)//'&lt;'//line(i+1:)
            end if
            if ( line.ne.' ' ) then
                print '(2a)','# ',trim(line)
            end if
            read(1,'(a)') line
        end do
        print '(a)','# <a href="ftp://ftp.ncdc.noaa.gov/pub/data'//
     +       '/paleo/drought/pdsi2004/readme-pdsi-na2004.txt">'//
     +       'documentation</a>'
        print '(a)','# DAI [%] area with PDSI&lt;-1'
        do
            read(1,'(a)',end=800) line
            if ( line.ne.' ' ) then
                read(line,*) yr,cnt,pct,dai,cl25,cl975
                print '(i4,f9.3)',yr,dai
            end if
        end do
 800    continue
        close(1)
        end
