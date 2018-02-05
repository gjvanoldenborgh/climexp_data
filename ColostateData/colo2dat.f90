        program colo2dat
*
*       convert the gnuplot-like AO index files from 
*       http://www.atmos.colostate.edu/ao/Data/ao_index.html
*       to my .dat format
*
        implicit none
        integer year,month,yrbeg,yrend
        parameter(yrbeg=1700,yrend=2020)
        real ao(12,yrbeg:yrend),yrmo
*       
        open(1,file='AO_TREN_NCEP_Jan1899Current.ascii',status='old')
        call makeabsent(ao,12,yrbeg,yrend)
        do year=1899,yrend
            do month=1,12
                read(1,*,end=200) ao(month,year)
            enddo
        enddo
        print *,'Increase yrend!'
        call abort
  200   continue
        close(1)
        open(1,file='ao_slp.dat')
        write(1,'(a)')
     +        'http://www.atmos.colostate.edu/ao/Data/ao_index.html'
        write(1,'(a)') 'MONTHLY INDEX BASED ON SLP DATA.'
        write(1,'(a)')
     +        'January-March monthly-mean from Jan1899 to current'
        write(1,'(a)') 'Index values 1899-Dec1957 are based on '//
     +        'data described in Trenberth and Paolino (1980).'
        write(1,'(a)') 'Index values Jan1958 to current are from '//
     +        'the NCEP/NCARReanalysis'
        call printdatfile(1,ao,12,12,yrbeg,yrend)
        close(1)
*       
        open(1,file='AO_SATindex_JFM_Jan1851March1997.ascii',status
     +        ='old')
        call makeabsent(ao,12,yrbeg,yrend)
        do year=1851,yrend
            do month=1,3
                read(1,*,end=400) yrmo,ao(month,year)
                if ( abs(yrmo-year-(month-1)/3.).gt.0.01 ) then
                    print *,'error in yrmo: ',yrmo,year,month
                    call abort
                endif
            enddo
        enddo
        print *,'Increase yrend!'
        call abort
  400   continue
        close(1)
        open(1,file='ao_sat.dat')
        write(1,'(a)')
     +        'http://www.atmos.colostate.edu/ao/Data/ao_index.html'
        write(1,'(a)') 'MONTHLY INDEX BASED ON SAT DATA.'
        write(1,'(a)')
     +        'January-March monthly-mean from Jan1851 to March1997'
        write(1,'(a)') 'Thompson and Wallace 1998, Thompson et al. 1999'
        write(1,'(a)') 'SAT data provided by P. D. Jones (Jones 1994)'
        call printdatfile(1,ao,12,12,yrbeg,yrend)
        close(1)
*
        end
