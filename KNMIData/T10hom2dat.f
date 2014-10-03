        program T10hom2dat
!
!       convert Aad's spreadsheet to my old ASCII format
!
        implicit none
        integer nstation
        parameter (nstation=10)
        integer yr,mo,istation,yrs(nstation)
        real data(12,1906:2008,nstation)
        character names(10,2)*20,dummy(13),file*100

        open(1,file='T_10_hom_reeksen.csv',status='old')
        names = ' '
        read(1,*) (names(istation,1),dummy,istation=1,nstation)
        read(1,*) (names(istation,2),dummy,istation=1,nstation-1)
        do istation=1,nstation
            if (names(istation,2)(1:1).eq.'_' ) then
                names(istation,2) =  names(istation,2)(2:)
            end if
        end do
        data = 3e33
        do yr=1906,2008
            read(1,*) (dummy(istation),yrs(istation),
     +           (data(mo,yr,istation),mo=1,12),istation=1,nstation)
!            print '(2a,i4,12f7.1)',(names(istation,1),names(istation,2),
!     +           yrs(istation),(data(mo,yr,istation),mo=1,12),
!     +           istation=1,nstation)
            do istation=1,nstation
                if ( yrs(istation).ne.yr ) then
                    write(0,*) 'error: years wrong: ',yr,yrs(istation)
     +                   ,istation
                    call abort
                end if
                do mo=1,12
                    if ( data(mo,yr,istation).eq.-999.9 ) then
                        data(mo,yr,istation) = 3e33
                    end if
                end do
            end do
        end do
        close(1)
        do istation=1,nstation
            if ( names(istation,2).ne.' ') then
                write(file,'(8a)') 'temp_',trim(names(istation,1)),'_',
     +               trim(names(istation,2)),'_hom.dat.org'
                open(1,file=file)
                write(1,'(8a)') '# Homogenised temperature at ',
     +               trim(names(istation,1)),'/',trim(names(istation,2))
            else
                write(file,'(8a)') 'temp_',trim(names(istation,1)),
     +               '_hom.dat.org'
                open(1,file=file)
                write(1,'(8a)') '# Homogenised temperature at ',
     +               trim(names(istation,1))
            end if
            write(1,'(8a)') '# for details see <a href="http://www.knmi'
     +           ,'.nl/publications/fulltexts/CNT.pdf">KNMI WR 2009-03',
     +           '</a>'
            write(1,'(a)') '# T [C] homogenised temperature'
            write(1,'(2a)') '# These data can be used freely ',
     +           'as long as the source KNMI is acknowledged'
            call printdatfile(1,data(1,1906,istation),12,12,1906,2008)
            close(1)
        end do
        end
