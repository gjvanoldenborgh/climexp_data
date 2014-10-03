        program getdepth
*
*       extract the depth of an isotherm from the TAO data tao.dat
*
        implicit none
#include "recfac.h"
        integer nz, nlat, nlon, firstyear
        parameter(nz = 42, nlat=10, nlon=19, firstyear=1980)
*
        integer yr,mn,i,j,k,n,yr1,yr2,nt,lastyear,ii(8)
        real temp,mtemp(nlon,nlat,nz),ztemp(366,nlat,nlon)
        logical lintlatlon
        character string*80, extensie*8
        integer iargc
        external iargc,getarg
#include "grids.h"
*       
        lintlatlon = .TRUE.
        nt = 12
        call date_and_time(values=ii)
        lastyear = ii(1)
        if ( iargc().lt.1 ) then
            write(0,*) 'usage: getdepth temp [clim|5dy|dy]'
            stop
        endif
        if ( iargc().eq.2 ) then
            call getarg(2,string)
            if ( string.eq.'clim' ) then
                extensie = 'clim.dat'
                yr1 = firstyear
                yr2 = firstyear
            elseif ( string.eq.'5dy' .or. string.eq.'-5dy' ) then
                extensie = '-5dy.dat'
                yr1 = firstyear
                yr2 = lastyear
                nt = 73
            elseif ( string.eq.'dy' .or. string.eq.'-dy' ) then
                extensie = '-dy.dat'
                yr1 = firstyear
                yr2 = lastyear
                nt = 366
            else
                print *,'cannot handle ',string(1:index(string,' ')-1),
     +                ' yet'
                stop
            endif
        else
            extensie = '.dat'
            yr1 = firstyear
            yr2 = lastyear
        endif
        call getarg(1,string)
        read(string,*) temp
        print *,'searching for ',temp,'-degree isotherm'
*
        open(1,file='tao'//extensie,status='old',form='unformatted',
     +        access='direct',recl=recfa4*nlon*nlat*nz)
        open(2,file='tao_z'//string(1:index(string,' ')-1)//extensie,
     +        form='unformatted',access='direct',recl=recfa4*nlon*nlat
     +        *nt)
        do yr=yr1,yr2
            do mn=1,nt
                do j=1,nlat
                    do i=1,nlon
                        ztemp(mn,j,i) = 3e33
                    enddo
                enddo
                read(1,rec=nt*(yr-firstyear)+mn,end=800,err=800) mtemp
                do k=1,nz-1
                    do j=1,nlat
                        do i=1,nlon
                            if (  mtemp(i,j,k).lt.1e33 .and.
     +                            mtemp(i,j,k+1).lt.1e33 ) then
                                if (  (mtemp(i,j,k)-temp)*
     +                                (mtemp(i,j,k+1)-temp).le.0 ) then
                                    ztemp(mn,j,i) = (
     +                                    (mtemp(i,j,k)-temp)*deps(k+1)+
     +                                    (temp-mtemp(i,j,k+1))*deps(k))
     +                                    /(mtemp(i,j,k)-mtemp(i,j,k+1))
                                    if ( .FALSE. ) then
                                        print *,'interpolated from ',
     +                                       mtemp(i,j,k),deps(k)
                                        print *,'              and ',
     +                                       mtemp(i,j,k+1),deps(k+1)
                                        print *,'               to ',
     +                                       temp,ztemp(mn,j,i)
                                    endif
                                endif ! crosses ztemp
                            endif ! valid points?
                        enddo   ! longitude
                    enddo       ! latitude
                enddo           ! depth
 800            continue
            enddo               ! month
*
*           interpolate in latlon to fill up holes.
            print *,'year = ',yr
            do mn=1,nt
                n = 0
                do i=1,nlon
                    do j=1,nlat
                        if ( ztemp(mn,j,i).lt.1e33 ) then
                            n = n + 1
                        endif
                    enddo
                enddo
                print *,'Month ',mn,': found ',n
     +                ,' valid points in ztemp'
            enddo
            if ( lintlatlon ) then
                call latlonint(ztemp,73,nt,nlat,nlon,lats,lons,2,0.,300.
     +               )
                do mn=1,nt
                    n = 0
                    do i=1,nlon
                        do j=1,nlat
                            if ( ztemp(mn,j,i).lt.1e33 ) then
                                n = n + 1
                            endif
                        enddo
                    enddo
                    print *,'Month ',mn,': found ',n
     +                    ,' valid points in ztemp'
                enddo
            endif
            write(2,rec=(yr-firstyear)+1) (((ztemp(mn,j,i),i=1,nlon)
     +            ,j=1,nlat),mn=1,nt)
        enddo                   ! year
        close(1)
        close(2)
        end
