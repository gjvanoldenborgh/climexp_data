        program getdepth
*
*       extract the depth of an isotherm from the NCEP reanalysis data
*
        implicit none
#include "recfac.h"
        integer nz, nlat, nlon, firstyear, lastyear
        parameter(nz=27, nlat=81, nlon=112, firstyear=1980
     +        ,lastyear=1999)
*
        integer yr,mn,i,j,k,n,yr1,yr2,nt
        real temp,mtemp(nlon,nlat,nz),ztemp(12,nlat,nlon)
        character string*80, extensie*8
        integer iargc
        external iargc,getarg
#include "grids.h"
*       
        nt = 12
        if ( iargc().lt.1 ) then
            write(0,*) 'usage: getdepth temp'
            stop
        endif
	yr1 = firstyear
	yr2 = lastyear
        call getarg(1,string)
        read(string,*) temp
        print *,'searching for ',temp,'-degree isotherm'
*
        open(1,file='otemp.dat',status='old',form='unformatted',
     +        access='direct',recl=recfa4*nlon*nlat*nz)
        open(2,file='ncep_z'//string(1:index(string,' ')-1)//'.dat',
     +        form='unformatted',access='direct',recl=recfa4*nlon*nlat
     +        *nt)
        do yr=yr1,yr2
            do mn=1,nt
                read(1,rec=nt*(yr-firstyear)+mn) mtemp
                do j=1,nlat
                    do i=1,nlon
                        ztemp(mn,j,i) = 3e33
                    enddo
                enddo
                do j=1,nlat
                    do i=1,nlon
                        do k=1,nz-1
                            if (  mtemp(i,j,k).lt.32000 .and.
     +                            mtemp(i,j,k+1).lt.1e33 ) then
                                if (  (mtemp(i,j,k)-temp)*
     +                                (mtemp(i,j,k+1)-temp).le.0 ) then
                                    ztemp(mn,j,i) = (
     +                                    (mtemp(i,j,k)-temp)*deps(k+1)+
     +                                    (temp-mtemp(i,j,k+1))*deps(k))
     +                                    /(mtemp(i,j,k)-mtemp(i,j,k+1))
***                                    print *,i,j,k,mtemp(i,j,k),
***     +                                    ztemp(mn,j,i)
***                                else
***                                    print *,i,j,k,mtemp(i,j,k)
                                endif ! crosses ztemp
                            endif ! valid points?
                        enddo   ! longitude
                    enddo       ! latitude
                enddo           ! depth
            enddo               ! month
            print *,'year = ',yr
            write(2,rec=(yr-firstyear)+1) (((ztemp(mn,j,i),i=1,nlon)
     +            ,j=1,nlat),mn=1,nt)
        enddo                   ! year
        close(1)
        close(2)
        end
