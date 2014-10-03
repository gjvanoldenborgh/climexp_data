        program current2dat
!
!       convert the file curremt.txt to .dat format,
!       appending it to the old one
!
        implicit none
        integer yrbeg,yrend
        parameter(yrbeg=1947,yrend=2020)
        integer mo,yr,dy,i,j,ut,n,dat,datold
        real data(31,12,yrbeg:yrend),mdata(12,yrbeg:yrend),x,jul,car,s
        character line*255
        logical lwrite
        lwrite = .false.
!
!       old data
!
        mdata = 3e33
        open(1,file='maver.txt')
 100    continue
        read(1,'(a)',end=190) line
        if ( line(1:2).eq.' 1' ) then
            read(line,*) yr,mo,x
            if ( x.gt.0.1 ) mdata(mo,yr) = x
            if ( lwrite ) print *,yr,mo,mdata(mo,yr)
        endif
        goto 100
 190    continue
        close(1)
!
!       more recent data
!
        open(1,file='current.txt')
        s = 0
        n = 0
        datold = -1
        data = 3e33
 200    continue
        read(1,'(a)',end=290) line
        if ( line(1:3).ne.'024' ) goto 200
        read(line,*,end=200) jul,car,yr,mo,dy,ut,x
        if ( yr.le.1996 ) goto 200
        dat = dy + 100*(mo + 100*yr)
        if ( datold.eq.-1 ) datold = dat
        if ( dat.ne.datold ) then
            datold = dat
            data(dy,mo,yr) = s/n
            s = 0
            n = 0
        endif
        s = s + x
        n = n + 1
        goto 200
 290    continue
        close(1)
        do yr=1997,yrend
            do mo=1,12
                s = 0
                n = 0
                do dy=1,31
                    if ( data(dy,mo,yr).lt.1e33 ) then
                        n = n + 1
                        s = s + data(dy,mo,yr)
                    endif
                enddo
                if ( n.gt.5 ) then
                    mdata(mo,yr) = s/n
                    if ( lwrite ) print *,yr,mo,mdata(mo,yr)
                endif
            enddo
        enddo
!
!       most recent data
!
        open(1,file='fluxtablerolling.text')
        s = 0
        n = 0
        datold = -1
        data = 3e33
 300    continue
        read(1,'(a)',end=390) line
        if ( line(1:2).ne.'20' ) goto 300
        read(line,*) dat,ut,jul,car,x
        if ( datold.eq.-1 ) datold = dat
        if ( dat.ne.datold ) then
            datold = dat
            yr = dat/10000
            mo = mod(dat,10000)/100
            dy = mod(dat,100)
            if ( lwrite ) write(0,*) dat,dy,mo,yr
            data(dy,mo,yr) = s/n
            s = 0
            n = 0
        endif
        s = s + x
        n = n + 1
        goto 300
 390    continue
        close(1)
        do yr=2005,yrend
            do mo=1,12
                s = 0
                n = 0
                do dy=1,31
                    if ( data(dy,mo,yr).lt.1e33 ) then
                        n = n + 1
                        s = s + data(dy,mo,yr)
                    endif
                enddo
                if ( n.gt.5 ) then
                    mdata(mo,yr) = s/n
                    if ( lwrite ) print *,yr,mo,mdata(mo,yr)
                endif
            enddo
        enddo
!
!       print out
!
        open(1,file='solarradioflux.dat')
        write(1,'(a)') '# observed 10.7cm solar radio flux'
        write(1,'(a)') '# 10.7cm_solar_flux [10-22 m-2 Hz-1]'
        write(1,'(a)') '# from <a href="http://www.drao-ofr.'//
     +       'hia-iha.nrc-cnrc.gc.ca/icarus/www/sol%5Fhome.html">'//
     +       'Solar Radio Monitoring Programme</a>'
        call printdatfile(1,mdata,12,12,yrbeg,yrend)
        close(1)
        end
