        program dat2dat
*
*       convert the KD format files to my format files for the
*       daily dutch data
*
        implicit none
        integer yrbeg,yrend,npermax,nstations
        parameter(yrbeg=1901,yrend=2020,npermax=366,nstations=10)
        integer i,stn,yyyymmdd,yr,mo,dy,stations(nstations),istation
     +       ,station,decade,ivar,icol,k,d,u,iret,ii(8)
        real s
        character file*19,vars(18)*2,units(18)*10,line*256
     +       ,stationnames(nstations)*20,dum*1
        integer system
        external system
        data stations /235,240,260,270,280,290,310,344,370,380/
        data vars /'dd','fg','fh','fx','tg','tn','tx','sq','sp','dr'
     +        ,'rh','pg','vv','ng','dx','dy','ux','uy'/
        data units /'degrees','m/s','m/s','m/s','Celsius','Celsius',
     +       'Celsius','hr/day','1/day','hr/day','mm/day','mb','m','ng',
     +       '1','1','m/s','m/s'/
        data stationnames /'Den Helder','Schiphol','De Bilt',
     +       'Leeuwarden','Eelde','Twenthe','Vlissingen','Rotterdam',
     +       'Eindhoven','Maastricht'/
*
        do istation=1,nstations
            station = stations(istation)
            do ivar=1,18
                write(file,'(a,i3,a)') vars(ivar),station,'.dat'
                open(10+ivar,file=file)
                write(10+ivar,'(3a)')
     +               '# DEZE GEGEVENS MOGEN VRIJ WORDEN'
     +               ,' GEBRUIKT MITS DE VOLGENDE BRONVERMELDING '
     +               ,'WORDT GEGEVEN:'
                write(10+ivar,'(2a)') '# KONINKLIJK NEDERLANDS ',
     +                'METEOROLOGISCH INSTITUUT (KNMI)'
                write(10+ivar,'(3a)') '# THESE DATA CAN BE USED FREELY '
     +               ,'PROVIDED THAT THE FOLLOWING SOURCE IS '
     +               ,'ACKNOWLEDGED'
                write(10+ivar,'(2a)') '# ROYAL NETHERLANDS ',
     +                'METEOROLOGICAL INSTITUTE'
                call date_and_time(values=ii)
                write(10+ivar,'(9a,i4,a,i2.2,a,i2.2)')
     +               '# ',vars(ivar),' [',trim(units(ivar)),'] at ',
     +               trim(stationnames(istation)),
     +               ' from <a href="http://www.knmi.nl/klimatologie',
     +               '/daggegevens/download.cgi?language=eng">KNMI ',
     +               'climatological service</a>, last updated ',
     +               ii(1),'-',ii(2),'-',ii(3)
            enddo
            do decade=1901,2001,10
                write(file,'(a,i3,a,i4,a)') 'etmgeg_',station,'_',decade
     +                ,'.dat'
                open(1,file=file,status='old',err=800)
                print *,file
  100           continue
                read(1,'(a)',end=800,err=900) line
                icol = 1
                call readfield(line,icol,i)
                if ( i.ne.station ) then
                    print *,'error: expected ',station,' but found ',i
                    call abort
                endif
                call readfield(line,icol,yyyymmdd)
                yr = yyyymmdd/10000
                mo = mod(yyyymmdd,10000)/100
                dy = mod(yyyymmdd,100)
                do ivar=1,18
                    if ( ivar.le.14 ) then
                        call readfield(line,icol,k)
***                        print *,yr,mo,dy,vars(ivar),k
                        if ( vars(ivar).eq.'dd' ) then
                            if ( k.eq.0 ) then
                                k = -999
                                d = 0
                            elseif ( k.eq.360 ) then
                                k = 0
                            else
                                d = k
                            endif
                        endif
                        if ( vars(ivar).eq.'fg' ) u = k
                        if ( vars(ivar).eq.'sq' .and. k.eq.-1 ) k = 0
                        if ( vars(ivar).eq.'rh' .and. k.eq.-1 ) k = 0
                        if ( vars(ivar).eq.'vv' ) then
                            if ( k.eq.-999 ) then
                                k = k
                            elseif ( k.lt.0 ) then
                                print *,'error: unknown code for VVN: '
     +                                ,k
                                call abort
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
                                print *,'error: unknown code for VVN: '
     +                                ,k
                                call abort
                            endif
                        endif
                    endif
                    if ( vars(ivar).eq.'dx' ) then
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
                    elseif ( vars(ivar).eq.'ux' ) then
                        if ( d.ge.0 .and. u.gt.0 ) then
                            k = -nint(10*u*sin(d*atan(real(1))/45))
                        elseif ( u.eq.0 .or. d.eq.0 ) then
                            k = 0
                        endif
                    elseif ( vars(ivar).eq.'uy' ) then
                        if ( d.gt.0 .and. u.gt.0 ) then
                            k = +nint(10*u*cos(d*atan(real(1))/45))
                        elseif ( u.eq.0 .or. d.eq.0 ) then
                            k = 0
                        else
                            k = -999
                        endif
                    endif
                    if ( k.ne.-999) then
                        if ( vars(ivar).eq.'sp' .or. 
     +                        vars(ivar).eq.'dx' .or.
     +                        vars(ivar).eq.'dy' .or.
     +                        vars(ivar).eq.'ux' .or.
     +                        vars(ivar).eq.'uy' ) then
                            write(10+ivar,'(i5,2i3,f8.2)')
     +                            yr,mo,dy,k/100.
                        elseif ( vars(ivar).eq.'dd' .or. 
     +                            vars(ivar).eq.'vv' .or.
     +                            vars(ivar).eq.'ng' ) then
                            write(10+ivar,'(i5,2i3,i8)') yr,mo,dy,k
                        else
                            write(10+ivar,'(i5,2i3,f8.1)')yr,mo,dy,k/10.
                        endif
                    endif
                enddo           ! ivar
*
                goto 100        ! read next line
 800            continue        ! end of file
                close(1)
            enddo               ! decade
*
*           for tn, we can do one day better, as this program runs after
*           8AM local time (at 9:30 last time I looked).  By this time
*           todays' minimum temperature is known.  There must be a
*           better place to get it...
*
            open(1,file='tabel_opgetreden_extremen.html',status='old'
     +           ,err=850)
            print *,'opened tabel'
 811        continue
            read(1,'(a)',end=850) line
            if ( index(line,'Nacht').eq.0 ) then
                goto 811
            endif
            print *,'found Nacht'
            i = index(line,'tot') + 4
            read(line(i:),'(i2,a1,i2)') dy,dum,mo
            if ( dy.ne.ii(3) .or. mo.ne.ii(2) ) then
                write(0,'(a,i2.2,a,i2.2,a,i2.2,a,i2.2)') 'expecting '
     +               ,ii(3),'/',ii(2),' but found ',dy,'/',mo
                goto 850
            endif
            print *,'date OK'
 812        continue
            read(1,'(a)',end=850) line
            if ( index(line,trim(stationnames(istation))).ne.0 ) then
                print *,'found station ',trim(stationnames(istation))
                read(1,'(a)',end=850) line
                i = index(line,'right>') + 6
                k = index(line,'&nbsp;') - 1
                read(line(i:k),*,end=820) s
                print *,'found Tn ',s
                do ivar=1,18
                    if ( vars(ivar).eq.'tn' ) then
                        write(10+ivar,'(i5,2i3,f8.1)') ii(1),ii(2),ii(3)
     +                       ,s
                        goto 850
                    endif
                enddo
 820            continue
            endif
            goto 812
 850        continue
*
*           and ready
*
            do ivar=1,18
                close(10+ivar)
            enddo
            do ivar=1,18
                write(file,'(a,i3)') vars(ivar),station
                iret = system('gzip -c '//file(1:5)//'.dat > '//file(1:5
     +                )//'.gz')
                if ( iret.ne.0 ) then
                    write(0,*) 'error in gzip system call of ',file(1:5)
                    call abort
                endif
            enddo
        enddo
*       
        goto 999
  900   print *,'error reading ',file
        call abort
  999   continue
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
            read(line(i1:i2-2),*) k
        endif
        i1 = i2
        end
