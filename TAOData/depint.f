        subroutine depint(vals,deps,nz,iwrite)
*
*       interpolate an array of measurements to (unequally spaced)
*       depths, linearly, whenever the vertical distance is not too great
*
        integer nz,iwrite
        integer deps(nz)
        real vals(nz)
        integer k,l,state,last,next,n
        real maxfrac,maxdep
        data maxfrac,maxdep /0.251,10.5/
*
*       check whether there is anything to do
        do k=1,nz
            if ( vals(k).lt.1e33 ) goto 10
        enddo
        return
   10   continue
*
*       debug output
        if ( iwrite.ge.2 ) then
            print '(a,100i6)',  'depths: ',(deps(k),k=1,nz)
            print '(a,100f6.2)','depint: ',(vals(k),k=1,nz)
        endif
*
*       interpolate
        state = 0
        n = 0
        do k=1,nz
            if ( vals(k).lt.1e33 ) then
*               valid point
                state = 1
                last = k
            elseif ( state.eq.0 ) then
*               no interpolation possible
                state = 0
            elseif ( state.eq.1 ) then
*               invalid point, search for interpolation interval
                do l=k+1,nz
                    if ( vals(l).lt.1e33 ) then
                        state = 2
                        next = l
                        goto 110
                    endif
                enddo
                state = 0
  110           continue
            endif
            if ( state.eq.2 ) then
*               interpolate if not too far-fetched
                if (  deps(k)-deps(last).le.maxfrac*deps(k) .or.
     +                deps(k)-deps(last).le.maxdep .or.
     +                deps(next)-deps(k).le.maxfrac*deps(k) .or.
     +                deps(next)-deps(k).le.maxdep .or.
     +                abs(vals(next)-vals(last)).lt.1. ) then
                    n = n + 1
                    vals(k) = ( (deps(next) - deps(k))*vals(last)
     +                    +     (deps(k) - deps(last))*vals(next) )
     +                    /real(deps(next) - deps(last))
                    if ( iwrite.ge.3 ) then
                        print *,'depint: interpolating '
                        print '(a,i3,i4,f8.2)',
     +                        'last ',last,deps(last),vals(last),
     +                        ' new ',k,deps(k),vals(k),
     +                        'next ',next,deps(next),vals(next)
                    endif
                endif
            endif
        enddo
        if ( iwrite.ge.2 ) then
            print '(a,100f6.2)','depint: ',(vals(k),k=1,nz)
        endif
        if ( iwrite.ge.1 ) then
            print '(a,i4,a)','depint: interpolated ',n,' points'
        endif
*
        end
