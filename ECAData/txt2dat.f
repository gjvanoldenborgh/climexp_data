        program txt2dat
*
*       convert the ECA database formart to my standard format
*
        implicit none
        integer yrbeg,yrend
        parameter (yrbeg=1700,yrend=2020)
        integer i,j,n,yr,mo,dy,qq,id,datum,val,
     +       yr1(2:3),yr2(2:3),nyr(2:3),lastyr(2:3),iblend,sourceid
        character infile*128,outfile*13,line*200,element*2
        integer iargc

        if ( iargc().ne.1 ) then
            print *,'usage: txt2dat infile'
            print *,'creates a file number.dat, prints number to stdout'
            stop
        endif
        call getarg(1,infile)
        open(1,file=infile,status='old')
        i = index(infile,'_')
        j = index(infile,'.')
*       changed 27-oct-2004 to TX_LOCIDnnnnnn.txt ...
*       changed jul-2009 to    RR_STAIDnnnnnn.txt ...
        read(infile(i+6:j-1),*) n
        element = infile(i-2:i-1)
        call tolower(element)
        do iblend=2,3
            if ( iblend.eq.2 ) then
                write(outfile,'(a,i6.6,a)') element,n,'.dat'
            else
                write(outfile,'(2a,i6.6,a)') 'b',element,n,'.dat'
            endif
            !!!write(0,*) 'opening ',trim(outfile)
            open(iblend,file=outfile)
            write(iblend,'(2a)') '# ',infile(1:index(infile,' ')-1)
            write(iblend,'(2a)')
     +           '# These data can be used freely provided that'
     +           ,' the following source is acknowledged:'
            write(iblend,'(2a)') 
     +           '# Klein Tank, A.M.G. and Coauthors, 2002. ',
     +           'Daily dataset of 20th-century surface air temperature'
            write(iblend,'(2a)') 
     +           '# and precipitation series for the European Climate',
     +           ' Assessment.  Int. J. of Climatol., 22, 1441-1453'
            write(iblend,'(2a)') '# Data and metadata available at ',
     +           '<a href="http://www.ecad.eu">http://www.ecad.eu</a>'
        enddo
 100    continue
        read(1,'(a)') line
        i = index(line,'sta-ID')
        if ( i.ne.0 ) then
            j = i + index(line(i:),')') - 1
            read(line(i+7:j-1),*) id
            if ( id.ne.n ) then
                write(0,*)
     +               'warning: sta-ID does not match file name'
                write(0,*) 'sta-ID       = ',id
                write(0,*) 'ID from file = ',n
                n = id
            end if
        end if
        if ( index(line,'SOUID,').eq.0 ) goto 100
        yr1=9999
        yr2=-9999
        nyr = 0
        lastyr = -9999
 200    continue
        read(1,'(i6,1x,i6,1x,i8,1x,i5,1x,i5)',end=800) id,sourceid,datum
     +       ,val,qq
        yr = datum/10000
        do iblend=2,3
            if ( iblend.eq.2 .and. (qq.ne.0 .or.sourceid.ge.900000) )
     +           goto 190
            if ( qq.gt.1 .or. val.eq.-999 .or. val.eq.-9999 ) goto 200
            yr1(iblend) = min(yr1(iblend),yr)
            yr2(iblend) = max(yr2(iblend),yr)
            if ( yr.ne.lastyr(iblend) ) then
                lastyr(iblend) = yr
                nyr(iblend) = nyr(iblend) + 1
            end if
            if ( element.eq.'sd' ) then
                if ( val.ne.999 .and. val.ne.998 ) then
                    write(iblend,'(i4,2i3,f7.2)') datum/10000,mod(datum
     +                   /100,100),mod(datum,100),val/100.
                endif
            elseif ( element.eq.'cc' ) then
                if ( val.lt.0 .or. val.gt.8 ) then
                    write(0,*) 'error: val = ',val,' octas!'
                endif
                write(iblend,'(i4,2i3,f6.3)') datum/10000,mod(datum/100
     +               ,100),mod(datum,100),val/8.
            else
                write(iblend,'(i4,2i3,f8.1)') datum/10000,mod(datum/100
     +               ,100),mod(datum,100),val/10.
            endif
 190        continue
        enddo
        goto 200
 800    continue
        print '(i6.6,6i5)',n,(yr1(iblend),yr2(iblend),nyr(iblend),
     +       iblend=2,3)
        end

            