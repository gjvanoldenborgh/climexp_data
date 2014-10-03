        program dai2dat
!
!       convert the nao-trouet2009.txt file into a Climate Explorer datfile
!
        implicit none
        integer yr,i
        real nao
        character line*80

        open(1,file='nao-trouet2009.txt',status='old')
        read(1,'(a)') line
        do while ( index(line,'Year').eq.0 )
            read(1,'(a)') line
        end do
        print '(a)','# Multi-decadal Winter North Atlantic '//
     +       'Oscillation Reconstruction'
        print '(a)','# Trouet et al. 2009. Science 324, 78-80 '//
     +       'doi:10.1126/science.1166349'
        print '(a)','# <a href="http://www.ncdc.noaa.gov/paleo/pubs/'//
     +       'trouet2009/trouet2009.html">documentation</a>'
        print '(a)','# NAO [1] Winter NAO Reconstruction'
        do
            read(1,'(a)',end=800) line
            if ( line.ne.' ' ) then
                read(line,*) yr,nao
                print '(i4,f9.4)',yr,nao
            end if
        end do
 800    continue
        close(1)
        end
