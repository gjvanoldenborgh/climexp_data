        program countstations
!
!       make a list of how many stations there are per year in the GHCN
!       database.
!
        implicit none
        integer iwmo,isub,yr,none(1600:2010),ntot(1600:2010),iwmoold

        open(1,file='v2.mean')
        ntot = 0
        none = 0
        iwmoold = -999
 100    continue
        read(1,'(i8,i4,i4)',end=800) iwmo,isub,yr
!!!        print *,iwmo,yr
        if ( iwmo.ne.iwmoold ) then
            iwmoold = iwmo
            ntot = ntot + none
            none = 0
        end if
        if ( yr.lt.1600 .or. yr.gt.2010 ) goto 100
        none(yr) = 1
        goto 100
800     continue
        print '(a)','# number of stations in the GHCN v2.mean dataset'
        do yr=1600,2010
            print '(i4,i8)',yr,ntot(yr)
        end do
        end

