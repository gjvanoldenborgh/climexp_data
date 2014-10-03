        program dai2dat
!
!       convert the nao-trouet2009.txt file into a Climate Explorer datfile
!
        implicit none
        integer yr,i
        real enso
        character line*80

        open(1,file='enso-li2011.txt',status='old')
        read(1,'(a)') line
        do while ( index(line(1:8),'Year').eq.0 )
            read(1,'(a)') line
        end do
        print '(a)','# 1,100 Year El Ni&ntilde;o/Southern Oscillation '
     +       //'(ENSO) Index Reconstruction'
        print '(a)','# Li et al 2011. NCC 1, 114-118 '//
     +        'doi:10.1038/nclimate1086'
        print '(a)','# <a href="ftp://ftp.ncdc.noaa.gov/pub/data/'//
     +       'paleo/treering/reconstructions/enso-li2011.txt">'
     +       //'documentation</a>'
        print '(a)','# ENSO [1] ENSO Reconstruction'
        do
            read(1,'(a)',end=800) line
            if ( line.ne.' ' ) then
                !!!print *,'reading from ',trim(line)
                read(line,*) yr,enso
                print '(i4,f11.6)',yr,enso
            end if
        end do
 800    continue
        close(1)
        end
