        program average
*
*       average GrADS files month-by-month or (other periods)
*
        implicit none
#include "recfac.h"
        integer nmax,npermax
        parameter(nmax=19*10*42,npermax=366)
        integer i,j,k,l,ll,m,n(nmax,npermax),nn,nx,ny,nz,yr1,yr2
     +        ,nperyear,is,ns
        real*4 temp(nmax),s(nmax,0:npermax),t(npermax),ss,minfac
        character string*255
        integer iargc
        external iargc,getarg
*
        if ( iargc().lt.6 ) then
            print *,'usage: averagedat file.dat nx ny nz yr1 yr2'//
     +            ' nperyear [minfac]'
            print *,'       (yr1,2 are offsets in file)'
            stop
        endif
        call getarg(2,string)
        read(string,*) nx
        call getarg(3,string)
        read(string,*) ny
        call getarg(4,string)
        read(string,*) nz
        call getarg(5,string)
        read(string,*) yr1
        call getarg(6,string)
        read(string,*) yr2
        call getarg(7,string)
        read(string,*) nperyear
        nn = nx*ny*nz
        if ( nn.gt.nmax ) then
            print *,'error: increase nmax to ',nn
            stop
        endif
        minfac = 0.8
        if ( iargc().ge.8 ) then
            call getarg(8,string)
            read(string,*) minfac
        endif
        call getarg(1,string)
        i = index(string,'.dat')
        if ( i.eq.0 ) i = index(string,' ')
        i = i-1
        open(2,file=string(:i)//'.dat',status='old',access='direct',
     +        recl=nn*recfa4)
        open(1,file=string(:i)//'clim.dat',status='new',access='direct',
     +        recl=nn*recfa4)
        open(3,file=string(:i)//'_ano.dat',status='new',access='direct',
     +        recl=nn*recfa4)
*
*       init
*
        do m=1,nperyear
            do j=1,nn
                s(j,m) = 0
            enddo
        enddo
        do m=1,nperyear
            do j=1,nn
                n(j,m) = 0
            enddo
        enddo
*
*       scan through file, collect sums
*
        do i=yr1,yr2
            do m=1,nperyear
                read(2,rec=nperyear*(i-1)+m) (temp(j),j=1,nn)
                do j=1,nn
                    if ( temp(j).lt.1e33 ) then
                        s(j,m) = s(j,m) + temp(j)
                        n(j,m) = n(j,m) + 1
                    endif
                enddo
            enddo
        enddo
*
*       compute monthly averages
*
        do m=1,nperyear
            do j=1,nn
                if ( n(j,m).ge.minfac*(yr2-yr1+1) ) then
                    s(j,m) = s(j,m)/n(j,m)
                else
                    s(j,m) = 3e33
                endif
            enddo
        enddo
*
*       compute yearly average
*
        do j=1,nn
            s(j,0) = 0
            do m=1,nperyear
                if ( s(j,m).lt.1e33 .and. s(j,0).lt.1e33 ) then
                    s(j,0) = s(j,0) + s(j,m)
                else
                    s(j,0) = 3e33
                endif
            enddo
            if ( s(j,0).lt.1e33 ) s(j,0) = s(j,0)/nperyear
        enddo
*
*       smooth monthly averages twice with a time scale of about one
*       month
*       
        ns = nint(nperyear/36.)
        if ( ns.gt.1 ) then
            do k=1,2
                do j=1,nn
                    do m=1,nperyear
                        t(m) = 0
                        is = 0
                        do ll=m-ns,m+ns
                            l = ll
                            if ( l.lt.1 ) l = l + nperyear
                            if ( l.gt.nperyear ) l = l - nperyear
                            if ( s(j,m).lt.1e33 ) then
                                t(m) = t(m) + s(j,l)
                                is = is + 1
                            endif
                        enddo
                        if ( is.gt.1 ) then
                            t(m) = t(m)/is
                        else
                            t(m) = 3e33
                        endif
                    enddo
                    do m=1,nperyear
                        s(j,m) = t(m)
                    enddo
                enddo
            enddo
        endif
*
*       write climatology
*
        do m=0,nperyear
            write(1,rec=m+1) (s(j,m),j=1,nn)
        enddo
*
*       compute anomalies
*
        do i=yr1,yr2
            do m=1,nperyear
                read(2,rec=nperyear*(i-1)+m) (temp(j),j=1,nn)
                do j=1,nn
                    if ( temp(j).lt.1e33 .and. s(j,m).lt.1e33 ) then
                        temp(j) = temp(j) - s(j,m)
                    else
                        temp(j) = 3e33
                    endif
                enddo
                write(3,rec=nperyear*(i-1)+m) (temp(j),j=1,nn)
            enddo
        enddo
        end
