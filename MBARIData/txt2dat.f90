program txt2dat
!
! 	convert the txt file obtained from stripping the HTML from Mset.htm
!	into Climate Explorer standard .dat files
!
    implicit none
    integer :: yr,mo,ifile
    real :: data(6)
    character :: infile*256,file*256

    call getarg(1,infile)
    if ( infile.eq.' ' ) then
        write(0,*) 'usage: txt2dat file.txt'
        call exit(-1)
    end if
    open(10,file=trim(infile),status='old')

    do ifile=1,6
        write(file,'(a,i1,a)') 'M',ifile,'.dat'
        open(ifile,file=trim(file))
        write(ifile,'(a,i1,a)') '# index M',ifile,' from <a href="https://www.mbari.org/'// &
            'science/upper-ocean-systems/biological-oceanography/'// &
            'global-modes-of-sea-surface-temperature/">Mset</a>'
        write(ifile,'(a)') '# source_url :: https://www3.mbari.org/science/upper-ocean-systems/'// &
            'biological-oceanography/GlobalModes/Mset.htm'
        write(ifile,'(a)') '# organisation :: MBARI'
        write(ifile,'(a)') '# author :: Monique Messié and Francisco P. Chavez'
        write(ifile,'(a)') '# references :: Messié, M. and F.P. Chavez, 2011: Global modes of '// &
            'sea surface temperature variability in relation to regional climate indices. '// &
            'Journal of Climate, 24(16), 4313-4330. doi:10.1175/2011JCLI3941.1'
        write(ifile,'(a,i1,a)') '# M',ifile,' [1]'
    end do

    do
        read(10,*,end=800) yr,mo,data
        do ifile=1,6
            write(ifile,'(2i4,f8.4)') yr,mo,data(ifile)
        end do
    end do

800	continue
    do ifile=1,6
        close(ifile)
    end do

end program txt2dat