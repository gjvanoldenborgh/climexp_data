        program convert
*
*       convert http://ingrid.ldgo.columbia.edu/SOURCES/.KEELING/.MAUNA_LOA.cdf/co2/gridtable.tsv
*       (reachable from http://ingrid.ldgo.columbia.edu/descriptions/.keeling.html)
*       into a standard dat file
*
        implicit none
        integer yr,mn,yrold
        real xmn,s,ss(12)
*
        write(*,'(a)') 
        write(*,'(a)') 
        write(*,'(a)')
        write(*,'(a)')
        write(*,'(a)')
        read(*,'(a)')
        read(*,'(a)')
        yrold = 0
        do mn=1,12
            ss(mn) = -999.9
        enddo
*
  100   continue
        read(*,*,end=800) xmn,s
        yr = 1960 + int(xmn/12)
        if ( xmn.lt.0 ) yr = yr-1
        if ( yr.ne.yrold ) then
            if ( yrold.ne.0 ) then
                write(*,'(i5,12f8.2)') yrold,ss
                do mn=1,12
                    ss(mn) = -999.9
                enddo
            endif
            yrold = yr
        endif
        mn = 1+mod(int(xmn),12)
        if ( mn.le.0 ) mn = mn + 12
        ss(mn) = s
        goto 100
  800   continue
        do mn=1,12
            if ( ss(mn).gt.0 ) goto 810
        enddo
        stop
  810   write(*,'(i5,12f8.2)') yr,ss
        stop
        end
