        program regen2dat
*
*       convert the KD format 8-8 precip files to my format files for the
*       daily dutch data
*
        implicit none
        integer yrbeg,yrend,npermax,nstations
        parameter(yrbeg=1906,yrend=2020,npermax=366,nstations=15+3)
        integer i,stn,yyyymmdd,yr,mo,dy,stations(nstations),istation
     +       ,station,decade,k,d,u,iret,ii(3),j,n
        real data(31,12,yrbeg:yrend,nstations),x
        character file*50,file1*50,vars(18)*2,units(18)*10,line*256
     +       ,outfile*50,stationnames(nstations)*20,dum*1
        integer system
        external system
        data stations /009,011,025,139,144,222,328,438,550,666,737,745
     +       ,770,828,961,3*0/
        data stationnames /'Den Helder','West Terschelling','De Kooy'
     +       ,'Groningen','Ter Apel','Hoorn (NH)','Heerde',
     +       'Hoofddorp','De Bilt','Winterswijk','Kerkwerve',
     +       'Axel','Westdorpe','Oudenbosch','Roermond',
     +       'Den Helder/De Kooy','Axel/Westdorpe','average13'/
*
        data = 3e33
        do istation=1,nstations
            station = stations(istation)
            if ( station.ne.0 ) then
                write(outfile,'(a,i3.3,a)') 'rd',station,'.dat'
            elseif ( istation.eq.15+1 ) then
                outfile='rd009025.dat'
            elseif ( istation.eq.15+2 ) then
                outfile='rd745770.dat'
            elseif ( istation.eq.15+3 ) then
                outfile='precip13stations.dat'
            endif
            open(10,file=outfile)
            write(10,'(3a)')
     +           '# DEZE GEGEVENS MOGEN VRIJ WORDEN'
     +           ,' GEBRUIKT MITS DE VOLGENDE BRONVERMELDING '
     +           ,'WORDT GEGEVEN:'
            write(10,'(2a)') '# KONINKLIJK NEDERLANDS ',
     +           'METEOROLOGISCH INSTITUUT (KNMI)'
            write(10,'(3a)') '# THESE DATA CAN BE USED FREELY '
     +           ,'PROVIDED THAT THE FOLLOWING SOURCE IS '
     +           ,'ACKNOWLEDGED'
            write(10,'(2a)') '# ROYAL NETHERLANDS ',
     +           'METEOROLOGICAL INSTITUTE'
            call date_and_time(values=ii)
            write(10,'(9a,i4,a,i2.2,a,i2.2)')
     +           '# ','precip',' [','mm/day','] at ',
     +           trim(stationnames(istation)),
     +           ' from <a href="http://www.knmi.nl/klimatologie',
     +           '/daggegevens/nsl-download.cgi?language=eng">KNMI ',
     +           'climatological service</a>, last updated ',
     +           ii(1),'-',ii(2),'-',ii(3)
            if ( istation.le.15 ) then
                write(file,'(a,i3.3,a,a,a)') 'datafiles.job/daggegrd_',
     +               station,'_????.zip'
                write(file1,'(a,i3.3,a,a,a)') 'datafiles.job/daggegrd_'
     +               ,station,'.dat'
                call mysystem('gunzip -c '//trim(file)//' > '/
     +               /trim(file1),iret)
                if ( iret.ne.0 ) then
                    write(0,*) 'gunzipping '//trim(file)/
     +                   /' went wrong, abort'
                    call abort
                endif
                open(1,file=file1,status='old',err=800)
                print *,file
!               skip header
 100            continue
                read(1,'(a)',end=800) line
                if ( line(1:4).ne.'STN,' ) goto 100
!               read data
 200            continue
                read(1,'(a)',end=700) line
                if ( index(line,',').eq.0 ) goto 200                
                i=1
                call readfield(line,i,stn)
                if ( stn.ne.station ) then
                    write(0,*) 'error: station not correct: ',stn
     +                   ,station
                    call abort
                endif
                call readfield(line,i,yyyymmdd)
                yr = yyyymmdd/10000
                mo = mod(yyyymmdd/100,100)
                dy = mod(yyyymmdd,100)
                call readfield(line,i,j)
                if ( j.ge.0 ) then
                    data(dy,mo,yr,istation) = j/10.
                    write(10,'(i5,2i3,f8.1)') yr,mo,dy,j/10.
                endif
                goto 200
 700            continue
                close(1)
            elseif ( istation.eq.15+1 ) then
                do yr=yrbeg,yrend
                    do mo=1,12
                        do dy=1,31
                            if ( data(dy,mo,yr,1).lt.1e33 ) then
                                write(10,'(i5,2i3,f8.1)') yr,mo,dy,
     +                               data(dy,mo,yr,1)
                            elseif ( data(dy,mo,yr,3).lt.1e33 ) then
                                write(10,'(i5,2i3,f8.1)') yr,mo,dy,
     +                               data(dy,mo,yr,3)
                            endif
                        enddo
                    enddo
                enddo
            elseif ( istation.eq.15+2 ) then
                do yr=yrbeg,yrend
                    do mo=1,12
                        do dy=1,31
                            if ( data(dy,mo,yr,12).lt.1e33 ) then
                                write(10,'(i5,2i3,f8.1)') yr,mo,dy,
     +                               data(dy,mo,yr,12)
                            elseif ( data(dy,mo,yr,13).lt.1e33 ) then
                                write(10,'(i5,2i3,f8.1)') yr,mo,dy,
     +                               data(dy,mo,yr,13)
                            endif
                        enddo
                    enddo
                enddo
            elseif ( istation.eq.15+3 ) then
                do yr=yrbeg,yrend
                    do mo=1,12
                        do dy=1,31
                            n = 0
                            x = 0
                            do j=1,15
                                if ( data(dy,mo,yr,j).lt.1e33 ) then
                                    n = n + 1
                                    x = x + data(dy,mo,yr,j)
                                endif
                            enddo
                            if ( n.eq.13 ) then
                                write(10,'(i5,2i3,f10.3)') yr,mo,dy,x/13
                            elseif ( n.gt.13 ) then
                                write(0,*) '????'
                            endif
                        enddo
                    enddo
                enddo
            endif
            close(10)
            file=outfile
            i = index(file,'.dat')
            file(i:) = '.gz'
            call mysystem('gzip -c '//trim(outfile)//' > '//trim(file)
     +           ,iret)
        enddo
        
 800    continue
        end

        subroutine readfield(line,i1,k)
*        
*       reads k from line, assuming it consists of comma-delimited
*       fields.  Blanks are translated to -999
*       
        integer i1,k
        character*(*) line
        integer i2
*       
        i2 = i1 + index(line(i1:),',')
        if ( i2.eq.i1 ) i2 = i1 + 6
        if ( i2-2.lt.i1 ) then
            write(0,*) 'cannot read values from ',line
            write(0,*) 'i1,i2 = ',i1,i2
            call abort
        endif
        if ( line(i1:i2-2).eq.' ' ) then
            k = -999
        else
            if ( .false. ) then
                print *,'line = ',trim(line)
                print *,'i1,i2 = ',i1,i2
                print *,'line(i1:i2-1) = ',line(i1:i2-1)
            endif
            read(line(i1:i2-2),*) k
        endif
        i1 = i2
        end
