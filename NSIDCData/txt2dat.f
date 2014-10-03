        program txt2dat
!
!       convert the NSIDC txt files to my format
!       add the hole difference to the area numbers to get rid of the
!       discontinuity.
!
        implicit none
        integer yrbeg,yrend
        parameter(yrbeg=1978,yrend=2020)
        integer yr,mo,i,ins
        real a,e,extent(12,yrbeg:yrend),area(12,yrbeg:yrend),val
     +       ,hole_conc(12,yrbeg:yrend)
        character file*20,string*80,mon*3,NS(2)
        data NS /'N','S'/

        do ins=1,2
            open(2,file=NS(ins)//'_ice_extent.dat')
            write(2,'(3a)') '# ',NS(ins),'H ice extent from '//
     +           '<a href="http://nsidc.org/data/g02135.html">'//
     +           'NSIDC Sea Ice Index</a>'
            write(2,'(a)') '# ice_extent [million km^2] area covered '//
     +           ' with at least 15% ice'
            open(3,file=NS(ins)//'_ice_area.dat')
            write(3,'(3a)') '# ',NS(ins),'H ice area from '//
     +           '<a href="http://nsidc.org/data/g02135.html">'//
     +           'NSIDC Sea Ice Index</a>'
            hole_conc = 1
            if ( NS(ins).eq.'N' ) then
                write(3,'(a)') '# ice_area [million km^2] integrated '//
     +               ' sea ice concentration, polar hole interpolated'
                open(17,file='hole_conc.txt')
                read(17,'(a)') string
                do i=1,100000
                    read(17,*,end=101) yr,mo,val
                    hole_conc(mo,yr) = val
                end do
 101            continue
                close(17)
            else
                write(3,'(a)') '# ice_area [million km^2] integrated '//
     +               ' sea ice concentration'
            end if
            area = 3e33
            extent = 3e33
            do mo=1,12
                write(file,'(2a,i2.2,a)') NS(ins),'_',mo,'_area.txt'
                open(1,file=trim(file),status='old')
                read(1,'(a)') string
 100            continue
                read(1,'(a)',end=200) string
                if ( string.eq.' ' ) goto 200
                read(string,'(i4,i3)') yr,i
                if ( i.ne.mo ) then
                    write(0,*) 'error: i!=mo: ',i,mo
                    call abort
                end if
                if ( string(27:27).ne.NS(ins) ) then
                    write(0,*) 'error: NS!=NS: ',string(27:27),NS(ins)
                    call abort
                end if
                read(string(28:),*) e,a

                if ( a.gt.0 ) then
                    if ( NS(ins).eq.'N' ) then
                        if ( yr.lt.1986 .or. yr.eq.1987.and.mo.lt.7 )
     +                       then
                            a = a + 1.19
                        else
                            a = a + 0.31*hole_conc(mo,yr)
                        end if
                    end if
                else
                    a = -999.9
                end if

                extent(mo,yr) = e
                area(mo,yr) = a

                goto 100
 200            continue
                print *,'string = ',trim(string)
                print *,'finished with ',trim(file)
                close(1)
            end do
            call printdatfile(2,extent,12,12,yrbeg,yrend)
            close(2)
            call printdatfile(3,area,12,12,yrbeg,yrend)
            close(3)
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
