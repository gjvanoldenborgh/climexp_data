        program addyears
*
*       add years with data to the inventory file
*
        implicit none
#include "recfac.h"
        integer nt
        parameter (nt=89484)
        integer i,iwmo,ielev,yrmin(0:4),yrmax(0:4),dy,mo,yr,jul0,itype
     +       ,irec
        real rlat,rlon,val
        character scountry*40,sname*40,types(0:4)*2,string*100
        integer llen,julday,system,firstnonspace
        external llen,julday,system,firstnonspace
        data types /'pp','tn','tg','tx','rr'/
*
        open(unit=1,file='ECA_locations_all.txt',status='old')
        open(unit=2,file='ECA_locations_all.withyears')
*       skip headers
        do i=1,21
            read(1,'(a)') string
        enddo
        if ( string.ne.' ' .and. string.ne.char(13) ) then
            print *,'ecadata: error: header has changed!'
            print *,string
        endif
  100   continue
        read(1,1000,err=920,end=200) iwmo,scountry,sname
     +       ,rlat,rlon,ielev
        if ( .false. ) then
            print *,iwmo
            print *,scountry
            print *,sname
            print *,rlat
            print *,rlon
            print *,ielev
            stop
        endif
 1000   format(i4,1x,a,1x,a,1x,f6.2,1x,f7.2,1x,i6)
        do itype=0,4
            string = '/tmp/addyears.bin'
            open(3,file='/tmp/addyears.tmp')
            write(3,'(a)') 'sdfopen http://ecadev.knmi.nl/dods/eca'
            write(3,'(a)') 'q file'
            write(3,'(a)') 'set gxout fwrite'
            write(3,'(a,i3)') 'set x ',iwmo
            do i=1,nt/10000
                write(3,'(a,i8,a,i8)') 'set t ',1+10000*(i-1),' ',
     +               10000*i
                write(3,'(3a,i2.2)') 'set fwrite ',string(1:llen(string)
     +               ),'.',i
                write(3,'(2a)') 'd ',types(itype)
                write(3,'(a)') 'disable fwrite'
            enddo
            write(3,'(a,i8,a,i8)') 'set t ',1+10000*(i-1),' ',nt
            write(3,'(3a,i2.2)') 'set fwrite ',string(1:llen(string))
     +           ,'.',i
            write(3,'(2a)') 'd ',types(itype)
            write(3,'(a)') 'disable fwrite'
            write(3,'(a)') 'quit'
            call flush(3)
            i = system('gradsdods -b -l < /tmp/addyears.tmp '//
     +           '> /tmp/addyears.log')
            if ( i.ne.0 ) then
                write(0,*) 'grads failed, error code =',i
            endif
***         close(3,status='delete')
            close(3)
            i = system('cat '//string(1:llen(string))//'.* > '//
     +           string(1:llen(string)))
            open(3,file=string(1:llen(string)),form='unformatted',
     +           access='direct',recl=recfa4,status='old',err=940)
            write(string,'(2a,i10.10,a)') 'data/',types(itype),
     +           iwmo,'.dat'
            open(4,file=string)
            write(4,'(4a)') '# ',sname(firstnonspace(sname):),',',
     +           scountry(firstnonspace(scountry):)
            write(4,'(2a)') '# ',types(itype)
            write(4,'(3a)') '# These data can be used freely ',
     +           'provided that the following source is ',
     +           'acknowledged:'
            write(4,'(5a)') '# Klein Tank, A.M.G. and Coauthors, ',
     +           '2002. Daily dataset of 20th-century surface ',
     +           'air temperature and precipitation series for ',
     +           'the European Climate Assessment, Int. J. of ',
     +           'Climatol., 22, 1441-1453'
            write(4,'(2a)') '# data are available from ',
     +           'http://ecadev.knmi.nl/'
            irec=0
            yrmin(itype) = +99999999
            yrmax(itype) = -9999999
            jul0 = julday(1,1,1775) ! hardcoded!
            do irec=1,nt
                read(3,rec=irec) val
                if ( val.eq.-9999 ) goto 801
                if ( itype.eq.0 .and.
     +               (val.lt.9000 .or. val.gt.10800) ) then
                    if ( val.gt.900 .and. val.lt.1080 ) then
                        write(*,*) 'Found pp ',val
     +                       ,', mulitplying with 10'
                        val = val*10
                    else
                        write(*,*) 'dubious value pp: ',val
                        goto 801
                    endif
                endif
                if ( itype.ge.1 .and. itype.le.3 .and.
     +               (val.lt.-900 .or. val.gt.600) ) then
                    write(*,*) 'dubious value ',types(itype),': ',val
                    goto 801
                endif
                if ( itype.eq.4 .and.
     +               (val.lt.0 .or. val.gt.3000) ) then
                    write(*,*) 'dubious value rr: ',val
                    goto 801
                endif
                call caldat(jul0+irec-1,mo,dy,yr)
                yrmin(itype) = min(yrmin(itype),dy+100*mo+10000*yr)
                yrmax(itype) = max(yrmax(itype),dy+100*mo+10000*yr)
                write(4,'(i4,2i3,f7.1)') yr,mo,dy,val/10
 801            continue
            enddo
            close(3,status='delete')
            close(4)
            i = system('gzip -f '//string//'&')
        enddo
        print *,sname,scountry
        write(2,1001) iwmo,scountry,sname,
     +       rlat,rlon,ielev,(yrmin(itype),yrmax(itype),itype=1,4),
     +       yrmin(0),yrmax(0)
        call flush(2)
 1001   format(i4,',',a40,',',a40,',',f6.2,',',f7.2,',',i6,',',
     +       10(i8,','))
        goto 100
 200    continue
        print *,'ready'
        stop
 920    print *,'error reading data from inventory'
        call abort
 930    print *,'error reading data from ',string,' at irec=',irec
        call abort
 940    print *,'error opening ',string
        call abort
        end

        integer function firstnonspace(string)
        implicit none
        character string*(*)
        do firstnonspace=1,len(string)
            if ( string(firstnonspace:firstnonspace).ne.' ' ) goto 100
        enddo
 100    continue
        end
