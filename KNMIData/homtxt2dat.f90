program homtxt2dat
    implicit none
    character :: line*255
    integer :: init

    init = 0
    do
        read(*,'(a)',end=800) line
        if ( len_trim(line) <= 1 ) cycle
        if ( index(line,'=') /= 0 ) cycle
        if ( index(line,'STN') /= 0 ) cycle
        if ( line(1:3) /= '260' ) then
            print '(2a)','# ',trim(line)
            cycle
        endif
        if ( init == 0) then
            init = 1
            print '(a)','# Tair [C] homogenised temperature at De Bilt'
            print '(a)','# latitude :: 52.100N'
            print '(a)','# longitude :: 5.183E'
            print '(a)','# altitude :: 2.0m'
            print '(a)','# author :: theo.brandsma@knmi.nl'
            print '(a)','# institution :: KNMI'
            print '(a)','# description :: https://climexp.knmi.nl/KNMIData/Tg_De_Bilt_homogenized.html'
        endif
        print '(4a)',line(5:8),' ',line(9:10),trim(line(13:))
        end do
800	continue
end program homtxt2dat
