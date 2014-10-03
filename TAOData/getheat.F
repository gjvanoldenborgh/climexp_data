        program getheat
*
*       extract the heat content from the TAO data tao.dat
*
        implicit none
#include "recfac.h"
        integer nz, nlat, nlon, firstyear, lastyear
        parameter(nz = 42, nlat=10, nlon=19, firstyear=1980
     +        ,lastyear=2003)
*
        integer yr,mn,i,j,k,kmax,yr1,yr2
        real zmax,mtemp(nz,12,nlat,nlon),heat(12,nlat,nlon)
        character string*80,extensie*8
        integer iargc
        external iargc,getarg
#include "grids.h"
*
        if ( iargc().le.0 ) then
            write(0,*) 'usage: getheat zmax [clim]'
            stop
        endif
        call getarg(1,string)
        read(string,*) zmax
        if ( iargc().eq.2 ) then
            extensie = 'clim.dat'
            yr1 = firstyear
            yr2 = firstyear
        else
            extensie = '.dat'
            yr1 = firstyear
            yr2 = lastyear
        endif
        do k=1,nz-1
            if ( (deps(k)+deps(k+1))/2.gt.zmax ) goto 100
        enddo
  100   continue
        kmax = k
        print *,'integrating temperature from the surface to ',(deps(k)
     +        +deps(k+1))/2,'m'
*
        open(1,file='tao'//extensie,status='old',form='unformatted',
     +        access='direct',recl=recfa4*nlon*nlat*nz)
        open(2,file='tao_heat'//string(1:index(string,' ')-1)//extensie,
     +        form='unformatted',access='direct',recl=recfa4*nlon*nlat)
        do yr=yr1,yr2
            do mn=1,12
                read(1,rec=12*(yr-firstyear)+mn) (((mtemp(k,mn,j,i),
     +                i=1,nlon),j=1,nlat),k=1,nz)
*
*               interpolate depth once more
                do j=1,nlat
                    do i=1,nlon
                        call depint(mtemp(1,mn,j,i),deps,nz,1)
                    enddo
                enddo
                do j=1,nlat
                    do i=1,nlon
                        heat(mn,j,i) = 0
                    enddo
                enddo
                do k=1,kmax-1
                    do j=1,nlat
                        do i=1,nlon
                            if (  mtemp(k,mn,j,i).lt.1e33 .and. 
     +                            heat(mn,j,i).le.1e33 ) then
                                if ( k.eq.1 ) then
                                    heat(mn,j,i) = mtemp(k,mn,j,i)
     +                                    *(deps(1)+deps(2))/2
                                else
                                    heat(mn,j,i) = heat(mn,j,i) +
     +                                    mtemp(k,mn,j,i)*(deps(k+1)
     +                                    -deps(k-1))/2
                                endif
                            else
                                heat(mn,j,i) = 3e33
                            endif ! valid points?
                        enddo   ! longitude
                    enddo       ! latitude
                enddo           ! depth
            enddo               ! month
*       
*           interpolate in latlon to fill up holes.
            call latlonint(heat,12,12,1,1,nlat,nlon,lats,lons,2,0.,24
     +           *zmax)
*
*           write to file
            do mn=1,12
                write(2,rec=12*(yr-firstyear)+mn) ((heat(mn,j,i),i=1
     +                ,nlon),j=1,nlat)
            enddo               ! month
        enddo                   ! year
        close(1)
        close(2)
        end
