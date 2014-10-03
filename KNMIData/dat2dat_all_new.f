        program dat2dat
*
*       convert the KD format files to my format files for the
*       daily dutch data
!       17-may-2013: put last night's Tn back in from dat2dat
*
        implicit none
        integer yrbeg,yrend,npermax,nvars,nvarmax
        parameter(yrbeg=1901,yrend=2020,npermax=366,nvars=26,nvarmax=50)
        integer i,j,i1,stn,yyyymmdd,yr,mo,dy,stationid,istation
     +       ,station,decade,ivar,icol,k,kk,d,u,iret,iarray(8),ideg,imin
     +       ,nyears(nvars),yr1(nvars),yr2(nvars),yrsold(nvars),ier
     +       ,ii(nvarmax),iwrong(100,nvars),jvar,mvars,offset
        real s,lat,lon,elev
        character infile*19,outfile*19,vars(nvars)*2,units(nvars)*10,
     +       line*256,stationname*40,altname*40,dum*1,metadatafile*80,
     +       lvars(nvars)*256,station_name*40,invars(nvars)*5,var*5
        logical lwrite
        data vars /'dd','fg','fh','fn','fx','tg','tn','tx','t1','sq',
     +             'sp','qq','dr','rh','pg','px','pn','vn','vx','ng',
     +             'ug','ux','un','ev','dx','dy'/
        data invars /'DDVEC','FG','FHX','FHN','FXX','TG','TN','TX',
     +       'T10N','SQ','SP','Q','DR','RH','PG','PX','PN','VVN',
     +       'VVX','NG','UG','UX','UN','EV24','dx','dy'/
        data units /'degrees','m/s','m/s','m/s','m/s',
     +       'Celsius','Celsius','Celsius','Celsius',
     +       'hr/day','1/day','W/m2','hr/day','mm/day',
     +       'mb','mb','mb','m','m','octa',
     +       '1','1','1','mm/day','1','1'/
*
        lwrite = .false.
        yrsold = -1
        ii = -1
        iwrong = -1
        offset = 0
        open(1,file='etmgeg_260.txt')
        do i=1,100
            read(1,'(a)') line
            if ( index(line,'YYYYMMDD').ne.0 ) exit
        enddo
        if ( lwrite ) print *,'Start parsing variable names'
        do jvar=1,nvarmax
            read(1,'(a)') line
            if ( line(2:20).eq.' ' ) exit
            if ( index(line,'STN,').ne.0 ) exit
            i = index(line,'=')
            if ( i.eq.0 ) exit
            var = line(3:i)
            if ( lwrite ) print *,'Variable ',var
            if ( var.eq.'HH' .or. line(1:1).eq.' ' ) then
                if ( lwrite ) print *,'skipping line: ',trim(line)
                offset = -1
                cycle           ! bug in file?
            end if
            do ivar=1,nvars
                if ( invars(ivar).eq.var ) exit
            end do
            if ( ivar.gt.nvars ) then
                if ( lwrite ) print *,'cannot find ',var,' in list'
                cycle
            end if
            ii(jvar+offset) = ivar
            i = index(line,'/ ') + 2
            line = line(i:)
            i = 1
            j = index(line,' in ')
            if ( j.eq.0 ) j = index(line,' (')
            if ( j.eq.0 ) j = len_trim(line) + 1
            lvars(ivar) = line(i:j-1)
            if ( vars(ivar).eq.'dd' ) then
                lvars(ivar) = trim(lvars(ivar))//
     +               ' (360=North, 180=South, 270=West, 90=East)'
            else if ( vars(ivar)(1:1).eq.'f' ) then
                lvars(ivar) = trim(lvars(ivar))//
     +               ' (watch out: inhomogeneous series '//
     +               'due to measuring height changes, see <a href='//
     +               '"http://www.knmi.nl/samenw/hydra">Hydra</a>)'
            else if ( vars(ivar).eq.'sp' ) then
                lvars(ivar) = 'fraction'//lvars(ivar)(11:)
            else if ( vars(ivar).eq.'vn' ) then
                lvars(ivar) = trim(lvars(ivar))//
     +               ' (the upper bound of the interval)'
            else if ( vars(ivar).eq.'vx' ) then
                lvars(ivar) = trim(lvars(ivar))//
     +               ' (the lower bound of the interval)'
            else if ( vars(ivar).eq.'ev' ) then
                lvars(ivar) = trim(lvars(ivar))//' (Makkink)'
            end if
            if ( lwrite ) print *,jvar+offset,var,': found lvars(',ivar,
     +           ') = ',trim(lvars(ivar))
        end do
        mvars = jvar - 1 + offset
        if ( lwrite ) print *,'End parsing variable names, found ',mvars
     +       ,' variables'
        lvars(nvars-1) = 'x-component of wind direction'
        lvars(nvars)   = 'y-component of wind direction'
        close(1)
        do ivar=1,nvars
            open(10+ivar,file='list_'//vars(ivar)//'.txt')
            write(10+ivar,'(a)')
     +           ,'located stations in 50.0N:54.0N, 3.0E:8.0E'
            write(10+ivar,'(a)')
     +           ,'=============================================='
        end do
        if ( lwrite ) print *,'opening stationslijst.html'
        open(1,file='stationslijst.html',status='old')
 10     continue
!
!       search for metadata file, station id and station name in list
!
        read(1,'(a)',end=800) line
        if ( index(line,'/metadata').eq.0 ) goto 10
        if ( lwrite ) print *,'found ',trim(line)
        i = index(line,'../metadata/') + 12
        if ( i.eq.1 ) then
            write(0,*) 'error: cannot find ../metadata" in ',trim(line)
            call abort
        end if
        j = i + index(line(i:),'"') - 2
        if ( j.eq.i-2 ) then
            write(0,*) 'error: cannot find " in ',trim(line(i:))
            call abort
        end if
        metadatafile =line(i:j)
        if ( lwrite ) print *,'opening ',line(i:j)
        open(2,file=line(i:j),status='old')
        i = j + 3
        j = i + 2
        if ( lwrite ) print *,'reading id from ',trim(line(i:j))
        read(line(i:j),*,err=901) stationid
!
        i = j + 2
        j = i + index(line(i:),'<') - 2
        if ( j.eq.i-2 ) then
            j = len_trim(line)
        end if
        stationname = line(i:j)
        print *,stationid,trim(stationname)
        station_name = stationname
        do i=1,len_trim(station_name)
            if ( station_name(i:i).eq.' ' )
     +           station_name(i:i) = '_'
        end do
!
!       get lat,lon
!
 110    continue
        read(2,'(a)') line
        if ( index(line,'N.B.').eq.0 ) goto 110
        i = index(line,'&deg;') + index(line,char(176)) - 2
        if ( lwrite ) print *,'reading degrees N from ',line(i:i+1)
        read(line(i:i+1),*) ideg
        if ( index(line,char(176)).eq.0 ) then
            i = i + 7
        else
            i = i + 3
        end if
        if ( lwrite ) print *,'reading minutes N from ',trim(line(i:i+2)
     +       )
        read(line(i:i+2),*) imin
        lat = ideg + imin/60.
        i = i + index(line(i:),'&deg;') + index(line(i:),char(176)) - 3
        if ( lwrite ) print *,'reading degrees E from ',line(i:i+1)
        read(line(i:i+1),*) ideg
        if ( index(line(i:),char(176)).eq.0 ) then
            i = i + 7
        else
            i = i + 3
        end if
        if ( lwrite ) print *,'reading minutes E from ',trim(line(i:i+2)
     +       )
        read(line(i:i+2),*) imin
        lon = ideg + imin/60.
!
!       get elev
!
 120    continue
        read(2,'(a)') line
        if ( index(line,'Terrein').eq.0 ) goto 120
        read(2,'(a)') line
        i = index(line,',')
        if ( i.ne.0 ) line(i:i) = '.'
        i = index(line,'+')
        if ( i.eq.0 ) i = index(line,'-')
        if ( i.eq.0 ) i = index(line,'>') + 1
        if ( i.eq.0 ) then
            write(0,*) 'error: cannot find + or - in ',trim(line)
            call abort
        end if
        if ( line(i:i+2).eq.'AWS' ) i = i + 4
        j = i + index(line(i:),' ') - 2
        if ( j.eq.-2 ) j = len_trim(line)
        if ( lwrite ) print *,'reading elev from ',line(i:j)
        read(line(i:j),*) elev
        if ( lwrite ) print *,'elev = ',elev
        close(2)
!
!       write data files headers
!
        write(infile,'(a,i3.3,a)') 'etmgeg_',stationid,'.txt'
        open(2,file=trim(infile),status='old')
!
!       skip header
!
 200    continue
        read(2,'(a)') line
        if ( index(line,'STN,YYYY').eq.0 ) goto 200
        read(2,'(a)') line
        do while ( line(1:1).eq.'#' .or. line(1:20).eq.' ' )
            read(2,'(a)') line
        end do
        do ivar=1,nvars
            write(outfile,'(a,i3.3,a)') vars(ivar),stationid,'.dat'
            j = 10+nvars+ivar
            open(j,file=trim(outfile))
            write(j,'(a)') '# THESE DATA CAN BE USED FREELY PROVIDED'//
     +           ' THAT THE FOLLOWING SOURCE IS ACKNOWLEDGED: '//
     +           'ROYAL NETHERLANDS METEOROLOGICAL INSTITUTE'
            write(j,'(8a)') '# ',vars(ivar),' [',trim(units(ivar)),'] ',
     +           trim(lvars(ivar))
            write(j,'(3a,f6.2,a,f6.2,a,f6.1,4a)') '# ',trim(stationname)
     +           ,' (',lat,'N, ',lon,'E, ',elev,
     +           'm, <a href="http://www.knmi.nl/',
     +           'klimatologie/metadata/',trim(metadatafile),
     +           '" target="_new">metadata</a>)'
            write(j,'(3a)') '# from <a href="http://www.knmi.nl/',
     +           'klimatologie/daggegevens/download.html">KNMI ',
     +           'climatological service</a>'
            call date_and_time(values=iarray)
            write(j,'(a)')
     +           '# These data have not been corrected for changes'
     +           //' in observing practices and the surroundings'
            write(j,'(a,i4,a,i2.2,a,i2.2)') '# last updated ',
     +           iarray(1),'-',iarray(2),'-',iarray(3)
            if ( vars(ivar).eq.'qq' ) write(j,'(2a)')
     +           '# Added a factor 1.022 to data before 1-1-1981 to ',
     +           'correct for the difference between IPS1956 and WRR'
        end do
!
!       convert and write data, get number of years with data
!
        nyears = 0
        yr1 = 9999
        yr2 = -9999
 300    read(2,'(a)',end=400) line
        i1 = 1
        call readfield(line,i1,i)
        if ( i.ne.stationid ) then
            write(0,*) 'error: stationid is wrong ',i,stationid
            write(0,*) 'last line read: ',trim(line)
            write(0,*) 'in file ',trim(infile)
            call abort
        end if
        call readfield(line,i1,yyyymmdd)
        yr = yyyymmdd/10000
        mo = mod(yyyymmdd,10000)/100
        dy = mod(yyyymmdd,100)
        do jvar=1,mvars+2
            if ( jvar.le.mvars ) then
                call readfield(line,i1,k)
                ivar = ii(jvar)
                if ( ivar.le.0 ) cycle
***             print *,yr,mo,dy,vars(ivar),k
            elseif ( jvar.eq.mvars + 1 ) then
                ivar = nvars - 1
            elseif ( jvar.eq.mvars + 2 ) then
                ivar = nvars
            end if

            if ( vars(ivar).eq.'dd' ) then
                if ( k.eq.0 ) then
                    k = -999
                    d = 0
                elseif ( k.eq.360 ) then
                    k = 0
                else
                    d = k
                endif
            else if ( vars(ivar).eq.'fg' ) then
                u = k
            else if ( vars(ivar).eq.'sq' .and. k.eq.-1 ) then
                k = 0
            else if ( vars(ivar).eq.'rh' .and. k.eq.-1 ) then
                k = 0
            else if ( vars(ivar).eq.'qq' ) then
                if ( k.ne.-999 .and.k.lt.0 ) write(0,*) 
     +               'weird value for Q ',stationid,yyyymmdd,k
                 if ( k.ne.-999 ) then
                     if ( yr.ge.1981 ) then
                         k = nint(100*100*k/real(24*6*6))
                     else       ! data from befofore 1 Jan 1981 are still in IPS 1956, convert to WRR
                                ! see Velds 1992 p.147
                                ! p.143 in http://www.knmi.nl/klimatologie/achtergrondinformatie/Zonnestraling_in_Nederland.pdf
                         k = nint(1.022*100*100*k/real(24*6*6))
                     end if
                 end if
            else if ( vars(ivar).eq.'vn' .or. vars(ivar).eq.'vx' ) then
                kk = k
                if ( vars(ivar).eq.'vx' .and. k.ne.-999 ) k = k - 1
                if ( k.eq.-999 ) then
                    k = k
                else if ( k.eq.-1 .and. vars(ivar).eq.'vx' ) then
                    k = 0
                elseif ( k.lt.0 ) then
                    k = -999
                    do j=1,100
                        if ( iwrong(j,ivar).eq.kk ) goto 310
                        if ( iwrong(j,ivar).eq.-1 ) exit
                    end do
                    iwrong(j,ivar) = kk
                    write(*,*) 'error: unknown code for ',vars(ivar),kk
                    write(*,*) trim(line)
                    write(*,*) 'in file ',trim(infile)
 310                continue
                elseif ( k.lt.50 ) then
                    k = 100*(k+1)
                elseif ( k.eq.50 ) then
                    k = 6000
                elseif ( k.lt.80 ) then
                    k = 1000*(k-49)
                elseif ( k.lt.89 ) then
                    k = 5000*(k-73)
                elseif ( k.eq.89 ) then
                    k = 100000
                elseif ( k.ne.-999 ) then
                    k = -999
                    do j=1,100
                        if ( iwrong(j,ivar).eq.kk ) goto 320
                        if ( iwrong(j,ivar).eq.-1 ) exit
                    end do
                    iwrong(j,ivar) = kk
                    write(*,*) 'error: unknown code for ',vars(ivar),kk
                    write(*,*) trim(line)
                    write(*,*) 'in file ',trim(infile)
 320                continue
                endif
            else if ( vars(ivar).eq.'dx' ) then
                if ( d.gt.0 .and. u.gt.0 .and. d.le.360 ) then
                    k = -nint(100*sin(d*atan(real(1))/45))
                elseif ( d.eq.0 .or. u.eq.0 ) then
                    k = 0
                elseif ( d.eq.990 ) then
                    k = 0
                else
                    k = -999
                endif
            elseif ( vars(ivar).eq.'dy' ) then
                if ( d.ge.0 .and. u.gt.0 .and. d.le.360 ) then
                    k = -nint(100*cos(d*atan(real(1))/45))
                elseif ( d.eq.0 .or. u.eq.0 ) then
                    k = 0
                elseif ( d.eq.990 ) then
                    k = 0
                else
                    k = -999
                endif
            endif
            if ( k.ne.-999) then
                yr1(ivar) = min(yr,yr1(ivar))
                yr2(ivar) = max(yr,yr2(ivar))
                if ( yrsold(ivar).ne.yr ) then
                    nyears(ivar) = nyears(ivar) + 1
                    yrsold(ivar) = yr
                end if
                j = 10+nvars+ivar
                if ( vars(ivar).eq.'sp' .or. 
     +               vars(ivar).eq.'dx' .or.
     +               vars(ivar).eq.'dy' .or.
     +               vars(ivar)(1:1).eq.'u' .or.
     +               vars(ivar).eq.'qq' ) then
                     if ( vars(ivar).eq.'dx' .or.
     +                    vars(ivar).eq.'dy' ) then
                        if ( k.lt.-100 ) then
                            write(*,*) 'error: ',vars(ivar),
     +                           '<-1: ',k/100.
                            k = -100
                        else if ( k.gt.100 ) then
                            write(*,*) 'error: ',vars(ivar),
     +                           '>+1: ',k/100.
                            k = +100
                        end if
                    elseif ( vars(ivar)(1:1).eq.'u' .or.
     +                       vars(ivar).eq.'sp' ) then
                        if ( k.lt.0 ) then
                            write(*,*) 'error: ',vars(ivar),
     +                           '<0: ',k/100.
                            k = 0
                        elseif ( k.gt.100 ) then
                            write(*,*) 'error: ',vars(ivar),
     +                           '>+1: ',k/100.
                            write(*,*) trim(line)
                            write(*,*) 'in file ',trim(infile)
                            k = 100
                        end if
                    end if
                    write(j,'(i5,2i3,f8.2)')
     +                   yr,mo,dy,k/100.
                elseif ( vars(ivar).eq.'dd' .or. 
     +                   vars(ivar)(1:1).eq.'v' .or.
     +                   vars(ivar).eq.'ng' ) then
                    write(j,'(i5,2i3,i8)') yr,mo,dy,k
                else
                    write(j,'(i5,2i3,f8.1)') yr,mo,dy,k/10.
                endif
            endif
        enddo                   ! ivar
        goto 300
 400    continue
*
*       for tn, we can do one day better, as this program runs after
*       8AM local time (at 9:30 last time I looked).  By this time
*       todays' minimum temperature is known.  There must be a
*       better place to get it...
*
        open(3,file='tabel_opgetreden_extremen.html',status='old',
     +       err=850)
        if ( lwrite ) print *,'opened tabel'
 811    continue
        read(3,'(a)',end=850) line
        if ( index(line,'Nacht').eq.0 ) then
            goto 811
        endif
        if ( lwrite ) print *,'found Nacht'
        i = index(line,'tot') + 4
        read(line(i:),'(i2,a1,i2)') dy,dum,mo
        if ( dy.ne.iarray(3) .or. mo.ne.iarray(2) ) then
            write(0,'(a,i2.2,a,i2.2,a,i2.2,a,i2.2)') 'expecting '
     +           ,iarray(3),'/',iarray(2),' but found ',dy,'/',mo
            goto 850
        endif
        if ( lwrite ) print *,'date OK'
 812    continue
        read(3,'(a)',end=850) line
        if ( stationname.eq.'De Kooy' ) then
        	altname = 'Den Helder'
        elseif ( stationname.eq.'Hoorn Terschelling' ) then
        	altname = 'Terschelling'
        elseif ( stationname.eq.'Gilze-Rijen' ) then
        	altname = 'Gilze Rijen'
        else
        	altname = stationname
        end if
        if ( index(line,trim(stationname)).ne.0 .or. 
     +       index(line,trim(altname)).ne.0 ) then
            if ( lwrite ) print *,'found station ',trim(stationname),
     +          ' ',trim(altname)
            read(3,'(a)',end=850) line
            i = index(line,'right>') + 6
            k = index(line,'&nbsp;') - 1
            read(line(i:k),*,end=820) s
            if ( lwrite ) print *,'found Tn ',s
            do ivar=1,nvars
                if ( vars(ivar).eq.'tn' ) then
                    j = 10+nvars+ivar
                    write(j,'(i5,2i3,f8.1)')
     +                   iarray(1),iarray(2),iarray(3),s
                    goto 850
                endif
            enddo
 820        continue
        endif
        goto 812
 850    continue
        close(3)
!
!       and ready
!
        do ivar=1,nvars
            j = 10+nvars+ivar
            close(j)
            write(line,'(2a,i3.3,2a,i3.2,a)') 'gzip -c ',vars(ivar)
     +           ,stationid,'.dat > ',vars(ivar),stationid,'.gz &'
            call mysystem(trim(line),ier)
        end do
!
!       output
!
        do ivar=1,nvars
            if ( nyears(ivar).gt.0 ) then
                write(10+ivar,'(2a)') stationname,' (Netherlands)'
                write(10+ivar,'(a,f8.2,a,f8.2,a,f8.1,4a)')
     +               'coordinates: ',lat,'N,',lon,'E, ',elev,
     +               'm, <a href="http://www.knmi.nl/klimatologie/',
     +               'metadata/',trim(metadatafile),
     +               '" target="_new">metadata</a>'
                write(10+ivar,'(a,i3,2a)') 'station code: ',stationid
     +               ,' ',trim(station_name)
                write(10+ivar,'(a,i3,a,i4,a,i4)') 'Found ',nyears(ivar)
     +               ,' years with data in ',yr1(ivar),'-',yr2(ivar)
                write(10+ivar,'(a)')
     +               '=============================================='
            end if
        end do
!
!       next station
!
        if ( lwrite ) print *,'next station'
        goto 10
 800    continue
        goto 999
 901    write(0,*) 'error reading station id from ',trim(line(:))
        call abort
 999    continue
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
        if ( i1.gt.len(line) ) then
            write(0,*) 'error: i1 outside line ',i1
            write(0,*) trim(line)
            call abort
        end if
        i2 = i1 + index(line(i1:),',')
        if ( i2.eq.i1 ) i2 = i1 + 6
        if ( i2-2.lt.i1 ) then
            write(0,*) 'cannot read values from ',line
            write(0,*) 'i1,i2 = ',i1,i2
            call abort
        endif
        if ( i2.gt.len(line) ) then
            write(0,*) 'error: i2 outside line ',i2
            write(0,*) trim(line)
            call abort
        end if            
!!!        print *,'reading field ',i1,i2-2
        if ( line(i1:i2-2).eq.' ' ) then
            k = -999
        else
            read(line(i1:i2-2),*,err=999) k
        endif
        i1 = i2
        return
 999    continue
        write(*,*) 'error reading field from ',line(i1:i2-1)
        write(*,*) 'line = ',trim(line)
        write(*,*) 'i1,i2 = ',i1,i2
        call abort
        end
