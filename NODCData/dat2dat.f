        program dat2dat
        implicit none
        integer yrbeg,yrend
        parameter (yrbeg=1950,yrend=2020)
        integer i,j,yr,mo,ibasin,jbasin,iseason
        real yrf,vals(6),data(12,yrbeg:yrend,12)
        character file*30,basins(4),string*80,depth*5,var*2,altvar*4
        logical lwrite
        data basins /'a','i','p','w'/

        lwrite = .false.
        data = 3e33
        call getarg(1,depth)
        call getarg(2,var)

        do ibasin=1,4           ! Atlantic, Indian, Pacific, World
!
            if ( var.eq.'HC' ) then
                altvar = 'h22'
                jbasin = 5
            else if ( var.eq.'MT' ) then
                altvar = 'T-dC'
                jbasin = 6
            end if
!           input
            file='pent_'//trim(altvar)//'-i0-'//trim(depth)//'m.dat'
            file(jbasin+5:jbasin+5) = basins(ibasin)
            print *,'opening ',trim(file)
            open(0+ibasin,file=trim(file),status='old')
            file=trim(altvar)//'-i0-'//trim(depth)//'m1-3.dat'
            file(jbasin:jbasin) = basins(ibasin)
            print *,'opening ',trim(file)
            open(10+ibasin,file=trim(file),status='old')
            file=trim(altvar)//'-i0-'//trim(depth)//'m4-6.dat'
            file(jbasin:jbasin) = basins(ibasin)
            print *,'opening ',trim(file)
            open(20+ibasin,file=trim(file),status='old')
            file=trim(altvar)//'-i0-'//trim(depth)//'m7-9.dat'
            file(jbasin:jbasin) = basins(ibasin)
            print *,'opening ',trim(file)
            open(30+ibasin,file=trim(file),status='old')
            file=trim(altvar)//'-i0-'//trim(depth)//'m10-12.dat'
            file(jbasin:jbasin) = basins(ibasin)
            print *,'opening ',trim(file)
            open(40+ibasin,file=trim(file),status='old')
!
!           skip headers
            do iseason=0,4
                read(10*iseason+ibasin,'(a)') string
            end do

            !!!if ( depth.eq.'2000' ) then
!               first read the annual (actually, pentad) values
                do while ( .true. )
                    read(0*iseason+ibasin,*,end=100) yrf,vals
                    if ( lwrite ) print *,'read ',basins(ibasin),yrf 
                    yr = int(yrf)
                    do mo=1,12
                        do i=1,3
                            data(mo,yr,3*(ibasin-1)+i) = vals(2*i-1)
                        end do
                    end do
                end do
  100       continue
            !!!end if
!           next overwrite with 3-monthly values if these exist
            do while ( .true. )
                do iseason=1,4
                    read(10*iseason+ibasin,*,end=800) yrf,vals
                    if ( lwrite ) print *,'read ',basins(ibasin),yrf 
                    yr = int(yrf)
                    do mo=3*iseason-2,3*iseason
                        do i=1,3
                            data(mo,yr,3*(ibasin-1)+i) = vals(2*i-1)
                        end do
                    end do
                end do
            end do
 800        continue
            do iseason=0,4
                close(10*iseason+ibasin)
            end do
        end do
!
!       write output
        if ( var.eq.'HC' ) then
            altvar = 'heat'
        else if ( var.eq.'MT' ) then
            altvar = 'temp'
        end if

        do i=1,12
            if ( i.eq.1 ) then
                file=altvar//trim(depth)//'_Atlantic.dat'
            else if ( i.eq.2 ) then
                file=altvar//trim(depth)//'_North_Atlantic.dat'
            else if ( i.eq.3 ) then
                file=altvar//trim(depth)//'_South_Atlantic.dat'
            else if ( i.eq.4 ) then
                file=altvar//trim(depth)//'_Indian.dat'
            else if ( i.eq.5 ) then
                file=altvar//trim(depth)//'_North_Indian.dat'
            else if ( i.eq.6 ) then
                file=altvar//trim(depth)//'_South_Indian.dat'
            else if ( i.eq.7 ) then
                file=altvar//trim(depth)//'_Pacific.dat'
            else if ( i.eq.8 ) then
                file=altvar//trim(depth)//'_North_Pacific.dat'
            else if ( i.eq.9 ) then
                file=altvar//trim(depth)//'_South_Pacific.dat'
            else if ( i.eq.10 ) then
                file=altvar//trim(depth)//'_global.dat'
            else if ( i.eq.11 ) then
                file=altvar//trim(depth)//'_nh.dat'
            else if ( i.eq.12 ) then
                file=altvar//trim(depth)//'_sh.dat'
            else
                write(0,*) 'error jkhfry33412'
                call abort
            end if
            open(1,file=trim(file))
            j = index(file,'.dat')
            if ( var.eq.'HC' ) then
                write(1,'(a)') '# <a href="http://www.nodc.noaa.gov/'//
     +               'OC5/3M%5fHEAT%5fCONTENT/basin%5fdata.html">NODC'//
     +               '</a> upper ocean heat content of the '//
     +               file(9:j-1)
                write(1,'(a)') '# HC [10^22 J] heat content 0-'//
     +               trim(depth)//'m'
            else
                write(1,'(a)') '# <a href="http://www.nodc.noaa.gov/'//
     +               'OC5/3M_HEAT_CONTENT/basin_avt_data.html">NODC'//
     +               '</a> upper ocean mean temperature anomaly of the '
     +               //file(9:j-1)
                write(1,'(a)') '# MT [K] mean temperature anomaly 0-'//
     +               trim(depth)//'m'
            end if
            call printdatfile(1,data(1,yrbeg,i),12,12,yrbeg,yrend)
            close(1)
        end do
        end

        subroutine printdatfile(unit,data,npermax,nperyear,yrbeg,yrend)
        implicit none
        integer unit,npermax,nperyear,yrbeg,yrend
        real data(npermax,yrbeg:yrend)
        integer year,i,dy,mo,dpm(12,3),ical
        data dpm /
     +       30,30,30,30,30,30,30,30,30,30,30,30,
     +       31,28,31,30,31,30,31,31,30,31,30,31,
     +       31,29,31,30,31,30,31,31,30,31,30,31/
        double precision val(360),offset
*
        if ( nperyear.lt.360 ) then
            ical = 0
        elseif ( nperyear.eq.360 ) then
            ical = 1
        elseif ( nperyear.eq.365 ) then
            ical = 2
        elseif ( nperyear.eq.366 ) then
            ical = 3
        else
            ical = 4
        endif
        call flush(unit)
        do year=yrbeg,yrend
            if ( ical.eq.0 ) then
                do i=1,nperyear
                    if ( data(i,year).lt.1e33 ) goto 200
                enddo
*               no valid points
                goto 210
*               there are valid points - print out
 200            continue
                do i=1,nperyear
                    if ( data(i,year).lt.1e33 ) then
                        val(i) = data(i,year)
                    else
                        val(i) = -999.9d0
                    endif
                enddo
                write(unit,'(i5,2000g15.7)') year,(val(i),i=1,nperyear)
 210            continue
            elseif ( ical.le.3 ) then
                i = 0
                do mo=1,12
                    do dy=1,dpm(mo,ical)
                        i = i + 1
                        if ( data(i,year).lt.1e33 ) then
                            write(unit,'(i4,2i3,g15.7)') year,mo,dy
     +                           ,data(i,year)
                        endif
                    enddo
                enddo
            else
                if ( nperyear.le.366 ) then
                    offset = 0.5d0 ! most likely averages
                else
                    offset = 1.0d0  ! most likely point measurements
                end if
                do i=1,nperyear
                    if ( data(i,year).lt.1e33 ) then
                        write(unit,'(2g15.7)') year+(i-offset)/nperyear
     +                       ,data(i,year)
                    endif
                enddo
            endif
        enddo
        return
        end
