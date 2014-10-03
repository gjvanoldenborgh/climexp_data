        program dai2dat
!
!       convert the nao-trouet2009.txt file into a Climate Explorer datfile
!
        implicit none
        integer yr,i
        real pdo
        character line*80

        open(1,file='pdo-macdonald2005.txt',status='old')
        read(1,'(a)') line
        do while ( index(line(1:10),'Year').eq.0 )
            read(1,'(a)') line
        end do
        print '(a)','# Pacific Decadal Oscillation Reconstruction '//
     +       'for the Past Millennium'
        print '(a)','# MacDonald and Case 2005. GRL 32, L08703 '//
     +        'doi:10.1029/2005GL022478'
        print '(a)','# <a href="ftp://ftp.ncdc.noaa.gov/pub/data/'//
     +       'paleo/treering/reconstructions/pdo-macdonald2005.txt">'
     +       //'documentation</a>'
        print '(a)','# PDO [1] PDO Reconstruction'
        do
            read(1,'(a)',end=800) line
            if ( line.ne.' ' ) then
                !!!print *,'reading from ',trim(line)
                read(line,*) yr,pdo
                print '(i4,f11.6)',yr,pdo
            end if
        end do
 800    continue
        close(1)
        end
