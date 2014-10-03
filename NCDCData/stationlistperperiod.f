        program stationlistperperiod
!
!       make a list of all stations with a reasanoble number of years
!       of data per decade

!
        implicit none
        integer iwmo,iwmoold,isub,yr,nn(160:201,10000),ids(10000),nid,id
        character file*50

        open(1,file='v2.mean')
        nn = 0
        nid = 0
        iwmoold = -999
 100    continue
        read(1,'(i8,i4,i4)',end=800) iwmo,isub,yr
!!!        print *,iwmo,yr
        if ( iwmo.ne.iwmoold ) then
            iwmoold = iwmo
            nid = nid + 1
            ids(nid) = iwmo
        end if
        if ( yr.lt.1600 .or. yr.gt.2010 ) goto 100
        nn(yr/10,nid) = nn(yr/10,nid) + 1
        goto 100
800     continue
        close(1)
        do yr=160,210
            write(file,'(a,i4,a)') 'stationlist_',10*yr,'.txt'
            open(1,file=file)
            write(1,'(a,i4,a,i4,a)') '# -180 180 -90 90 '//
     +           'list of GHCN stations with 8 '//
     +           'years or more of data in ',10*yr,'-',10*yr+9
            do id = 1,nid
                if ( nn(yr,id).ge.8 ) then
                    write(1,'(i8)') ids(id)
                end if
            end do
        end do
        end program


