        program polar2grads
!
!       convert the Rutgers polar stereographic coordinate files
!       to Grads latlon files
!
        implicit none
#include "recfac.h"
        integer yrbeg,yrend,latmin,nmax,nx,ny
        parameter (yrbeg=1966,yrend=2020,latmin=10,nmax=10,nx=89,ny=89)
        integer i,j,ix,iy,irec,nll(360,latmin:89),ii,jj,imin,jmin
        integer mo,yr,k,krec,n,yr1,mo1,row(ny)
        integer xyll(nmax,2,360,latmin:89)
        real conxy(nx,ny),conll(360,latmin:89),mask(360,latmin:89)
        real x,y,alat,alon,d,area,llxy(2,nx,ny),pi,dmin
        character file*255,ifile*255,csn(-1:1),cval,infile*255,
     +       months(12)*3,ew
        logical lexist,lwrite,undef(nx,ny)
        integer,external :: get_endian
        real,external :: dist
!
        data months /'JAN','FEB','MAR','APR','MAY','JUN','JUL',
     +       'AUG','SEP','OCT','NOV','DEC'/
        lwrite = .false.
        pi = 4*atan(1.)
!
!       set up grid conversion arrays
!
        yr1 = -1
        mo1 = -1
!
!       first determine which polar grid boxes sit 
!       inside a large (1x1) lat-lon box
!
        print *,'set up interpolation'
        open(1,file='rucl-gridboxes-center.txt',status='old')
        do ix=1,nx
            do iy=1,ny
                read(1,'(i2,i3,f10.3,f6.2,f7.2,x,a)') 
     +               i,j,area,alat,alon,ew
                if ( i.ne.ix .or. j.ne.iy ) then
                    write(0,*) 'error: i,j do not agree: ',i,j,ix,iy
                    call abort
                end if
                if ( ew.eq.'W' ) then
                    alon = 360-alon
                else if ( ew.ne.'E' ) then
                    write(0,*) 'error: unknown value for ew: ',ew
                    call abort
                end if
                if ( area.lt.0 ) then
                    undef(ix,iy) = .true.
                else
                    undef(ix,iy) = .false.
                end if
                llxy(1,ix,iy) = alon
                llxy(2,ix,iy) = alat
                if ( lwrite ) print*,ix,iy,' => ',alon,alat,undef(ix,iy)
                i = 1 + int(alon)
                if ( i.eq.361 ) i=360
                if ( i.lt.1 .or. i.gt.360 ) then
                    write(0,*) 'error in longitude',alon,i
                    call abort
                end if
                j = int(alat)
                if ( j.eq.90 ) j = 89
                if ( j.lt.latmin ) cycle
                nll(i,j) = nll(i,j) + 1
                if ( nll(i,j).gt.nmax ) then
                    write(0,*) 'error: increase nmax'
                    call abort
                end if
                xyll(nll(i,j),1,i,j) = ix
                xyll(nll(i,j),2,i,j) = iy
                if ( lwrite ) print *,i,j,ix,iy,nll(i,j)
            end do              ! iy
        end do                  ! ix
!
!       next fill out lat-lon boxes that were left out
!
        if ( .true. ) then
            do j=latmin,89
                do i=1,360
                    if ( nll(i,j).eq.0 ) then
                        alon = i - 0.5
                        alat = j + 0.5
                        dmin = 3e33
!                       no inverse map for this dataset (although it is
!                       probably the same), brute force search.
                        do ix=1,nx
                            do iy=1,ny
                                if ( abs(alat-llxy(2,ix,iy)).lt.10 .and.
     +                               min(abs(alon+360-llxy(1,ix,iy)),
     +                                   abs(alon-llxy(1,ix,iy)),
     +                                   abs(alon-360-llxy(1,ix,iy)))
     +                               .le.10 ) then
                                    d = dist(alon,alat,
     +                                   llxy(1,ix,iy),llxy(2,ix,iy))
                                    if ( d.lt.dmin ) then
                                        dmin = d
                                        imin = ix
                                        jmin = iy
                                    end if
                                end if
                            end do
                        end do
                        ix = imin
                        iy = jmin
                        nll(i,j) = 1
                        if ( ix.eq.0 .or. iy.eq.0 ) then
                            write(0,*) 'error: ix,iy = ',ix,iy
                            call abort
                        end if
                        xyll(1,1,i,j) = ix
                        xyll(1,2,i,j) = iy
                    end if
                end do          ! i
            end do              ! j
        end if
!
!       read land.sea mask
!       open snow_rucl  (generated with mask=1)
!       set x 1 360
!       define mean = ave(snow,t=1,t=530)
!       sdfopen ls_ghcn_cams_10.nc
!       define mask = const(maskout(mean,landsea.2(t=1)+100*mean-0.0001),1)
!       set gxout fwrite
!       set fwrite mask.grd
!       d mask
!       disable fwrite
!
        if ( latmin.ne.10 ) then
            write(0,*) 'error: mask.grd not for ghis latmin'
            call abort
        end if
        open(1,file='mask.grd',status='old',access='direct',
     +       recl=360*80*recfa4)
        read(1,rec=1) mask
        close(1)
        !!! mask = 1
!
!       read data
!
        file='snow_rucl.ctl'
        open(2,file=trim(file))
        file(index(file,'.ctl'):) = '.grd'
        open(1,file=trim(file),access='direct',form='unformatted',
     +       recl=recfa4*360*(90-latmin))
        open(3,file='rutgers-monthly-snow.mtx',status='old')
        irec = 0
        do yr=yrbeg,yrend
            print *,yr
            do mo=1,12
                if ( yr.eq.1966 .and. mo.lt.11 ) cycle
                if ( yr.eq.1968 .and. mo.eq.7 .or. 
     +               yr.eq.1969 .and. mo.ge.6 .and.mo.le.10 .or.
     +               yr.eq.1971 .and. mo.ge.7 .and. mo.le.9 ) then
                    conll = 3e33
                    irec = irec + 1
                    write(1,rec=irec) ((conll(i,j),i=1,360),
     +                   j=latmin,89)
                    cycle
                end if
                read(3,'(i4,i2)',end=800) yr1,mo1
                if ( yr.ne.yr1 .or. mo1.ne.mo ) then
                    write(0,*) 'error reading file ',yr1,mo1,yr,mo
                    call abort
                end if
                do ix=1,nx
                    read(3,'(89i3)') row
                    do iy=1,ny
                        if ( undef(ix,iy) ) then
                            if ( row(iy).ne.0 ) then
                                write(0,*) 'error: snow on sea ',yr,mo
     +                               ,ix,iy,row(iy)
                            end if
                            conxy(ix,iy) = 3e33
                        else
                            conxy(ix,iy) = row(iy)/100.
                        end if
                    end do
                end do
!
!               interpolate
!
                conll = 0
                do j=latmin,89
                    do i=1,360
                        if ( mask(i,j).lt.0 ) then
                            conll(i,j) = 3e33
                        else
                            n = 0
                            do k=1,nll(i,j)
                                ix = xyll(k,1,i,j)
                                iy = xyll(k,2,i,j)
                                if ( lwrite ) 
     +                               print *,'(5i4,f6.2)',i,j,ix,iy,k
     +                               ,conxy(ix,iy)
                                if ( conxy(ix,iy).lt.1e33 ) then
                                    n = n + 1
                                    conll(i,j) = conll(i,j)
     +                                   + conxy(ix,iy)
                                end if
                            end do ! k
                            if ( n.gt.0 .and. n.ge.nll(i,j)/2 ) then
                                conll(i,j) = conll(i,j)/n
                            else
                                conll(i,j) = 3e33
                            endif
                        end if
                    end do      ! i
                end do          ! j
                irec = irec + 1
                write(1,rec=irec) ((conll(i,j),i=1,360),
     +               j=latmin,89)
            end do              ! mo
        end do                  ! yr
 800    continue
        close(1)
        write(2,'(2a)') 'DSET ^',trim(file)
        write(2,'(a)')
     +       'TITLE Rutgers University global snow lab analysis'
        if ( get_endian().eq.-1 ) then
            write(2,'(a)') 'OPTIONS LITTLE_ENDIAN'
        elseif ( get_endian().eq.+1 ) then
            write(2,'(a)') 'OPTIONS BIG_ENDIAN'
        endif
        write(2,'(a)') 'UNDEF 3e33'
        write(2,'(a)') 'XDEF 360 LINEAR -89.5 1' ! no idea why this is not 0.5
        write(2,'(a,i2,a,f5.1,a)') 'YDEF ',90-latmin,
     +       ' LINEAR ',latmin+0.5,' 1'
        write(2,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(2,'(a,i4,a)') 'TDEF ',irec,' LINEAR 15NOV1966 1MO'
        write(2,'(a)') 'VARS 1'
        write(2,'(a)') 'snow 1 99 snow fraction [1]'
        write(2,'(a)') 'ENDVARS'
        end

        integer function get_endian()
*
*       try to figure out whether I/O is big-endian or little-endian
*
        implicit none
        integer endian,grib,birg,iu
        integer*4 i
        save endian
        data endian /0/
        data grib,birg /1196575042,1112101447/

        if ( endian.eq.0 ) then
            call rsunit(iu)
            open(iu,file='/tmp/get_endian',form='unformatted')
            write(iu) 'GRIB'
            rewind(iu)
            read(iu) i
            close(iu,status='delete')
            if ( i.eq.grib ) then
                endian = +1
            elseif ( i.eq.birg ) then
                endian = -1
            endif
        endif
        get_endian = endian
        end
*  #[ rsunit:
	subroutine rsunit(irsunit)
*
*       find a free unit number below 100
*
	implicit none
	integer irsunit
	logical lopen
	do irsunit=99,10,-1
	    inquire(irsunit,opened=lopen)
	    if ( .not.lopen ) goto 20
	enddo
	print '(a)','rsunit: error: no free units under 100!'
	call abort
   20	continue
*  #] rsunit:
	end

        real function dist(x1,y1,x2,y2)
!       compute great circle distance
!       http://en.wikipedia.org/wiki/Great-circle_distance
        implicit none
        real x1,y1,x2,y2
        real lon1,lat1,lon2,lat2,deg2rad
        deg2rad = atan(1.)/45.
        lon1 = x1*deg2rad
        lat1 = y1*deg2rad
        lon2 = x2*deg2rad
        lat2 = y2*deg2rad
        dist = atan2( sqrt( (cos(lat2)*sin((lon2-lon1)))
     +       **2+ (cos(lat1)*sin(lat2)- sin(lat1)
     +       *cos(lat2)*cos(lon2-lon1))**2 )
     +       , sin(lat1)*sin(lat2)
     +       + cos(lat1)*cos(lat2)*cos(lon2-lon1) )
        end
