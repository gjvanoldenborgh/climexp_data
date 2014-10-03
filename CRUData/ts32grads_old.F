        program new2grads
*
*       convert the TS 3 files to GrADS
*       of course they changed the format from TS 2.1 (ts2grads.F)
*
        implicit none
#include "recfac.h"
        integer yrbeg,yrend
        parameter(yrbeg=1901,yrend=2020)
        integer i,j,i0,i1,j1,i2,j2,m,n,mo,yr
     +       ,yr1,yr2,avex,avey,nx,ny,ivars(2,1),iouttype
        real field(720,360,12,yrbeg:yrend),fac,xx(720),yy(360),zz(1)
     +       ,wx(720),wy(360),lat,lon,valclim(12),val(12,yrbeg:yrend)
        logical clim,climold,lwrite
        character file*255,datfile*255,line*80,type*3,lvar*60,title*80
     +       ,id*2,format*50
        integer iargc
        external iargc
*
        lwrite = .false.
        if ( iargc().ne.2 ) then
            print *,'usage: ts2grads 1|2 infile'
            stop
        endif
        call getarg(1,file)
        read(file,*) iouttype
        if ( iouttype.lt.1 .or. iouttype.gt.2 ) then
            print *,'expecting 1 or 2'
            call abort
        endif
        call getarg(2,file)
        open(1,file=file,status='old')
        i = len_trim(file)
        type = file(i-2:)
*       parse some info in the header
 1      continue
        read(1,'(a)') line
        if ( line(1:1).ne.'.' ) goto 1
        i = index(line,'=')
        lvar = line(i+2:)
        i = index(lvar,'(')
        lvar(i:i) = '['
        j = index(lvar,')')
        lvar(j:j) = ']'
        if ( lvar(i:j).eq.'[mm]' ) then
            lvar(i:) = '[mm/month]'
        elseif ( lvar(i:j).eq.'[degrees Celsius]' ) then
            lvar(i:) = '[Celsius]'
        endif
        print *,'type,lvar = ',type,',',trim(lvar)
        title = 'CRU analysis TS 3'

 2      continue
        read(1,'(a)') line
        read(1,'(a)') line
        read(1,'(a)') line
        i = index(line,'Multi=')
        if ( i.eq.0 ) then
            write(0,*) 'error: expecting Multi'
            call abort
        end if
        i = i + 6
        read(line(i:i+9),'(f10.4)') fac
        print *,'fac = ',fac

        read(1,'(a)') line
        i = index(line,'Format=')
        if ( i.eq.0 ) then
            write(0,*) 'error: expecting Format'
            call abort
        end if
        i = i + 8
        j = i + index(line(i:),'''') - 2
        format = line(i:j)
        print *,'format = ',format

        do i=1,15
            read(1,'(a)') line
        end do
        if ( line.ne.' ' ) then
            write(0,*) 'error: expecting blank line, not ',trim(line)
            call abort
        end if
        yr1=1901
        yr2=2005
*
*       init
*
        print *,'setting field to undef'
        field = 3e33
*
*       main loop
*
        n = 0
 100    continue
        n = n + 1
        read(1,*,end=800) m,j,i,j1,i1,lat,lon,i2,j2
        if ( m.ne.n ) then
            write(0,*) 'error: m != n',m,n
            call abort
        end if
        if ( j.ne.j1 .or. j.ne.j2 ) then
            write(0,*) 'error: expecting j = j1 = j2, but got ',j,j1,j2
            call abort
        end if
        if ( i.ne.i1 .or. i.ne.i2 ) then
            write(0,*) 'error: expecting i = i1 = i2, but got ',i,i1,i2
            call abort
        end if
        if ( lat.ne.-89.75+0.5*(j-1) ) then
            write(0,*) 'expecting lat = ',-89.75+0.5*(j-1),lat
            call abort
        end if
        if ( lon.ne.-179.75+0.5*(i-1) ) then
            write(0,*) 'expecting lon = ',-179.75+0.5*(i-1),lon
            call abort
        end if
***        print *,'grid point ',i,j
        do yr=yr1,yr2
            read(1,format) i0,i1,(val(mo,yr),mo=1,12)
            if ( i0.ne.yr .or. i1.ne.yr ) then
                write(0,*) 'error: expecting ',yr,' found ',i0,i1
                call abort
            end if
        enddo
        do yr=yr1,yr2
            do mo=1,12
                if ( val(mo,yr).ne.-999 ) then
                    if ( lwrite) print *,'reading year,mo ',yr,mo
                    field(i,j,mo,yr) = fac*val(mo,yr)
                endif
            enddo
        enddo
***        print '(14i4)',i,j
        goto 100
 800    continue
        close(1)
*
*       write 0.5 degree data (in two halves, otherwise it does not fit)
*
        if ( iouttype.eq.1 ) then
            print *,'writing eastern hemisphere'
            call writedata(1,field,yrbeg,yrend,yr1,yr2,type,lvar,title)
            print *,'writing western hemisphere'
            call writedata(2,field,yrbeg,yrend,yr1,yr2,type,lvar,title)
        endif
*
*       interpolate to 1, 2.5 degree fields
*
        if ( iouttype.eq.1 ) then
            avex = 2
            avey = 2
            id = '10'
            print *,'writing 1 degree version'
        else
            avex = 5
            avey = 5
            id = '25'
            print *,'writing 2.5 degree version'
        endif
        do i=1,720
            xx(i) = -180 - 0.5/2 + 0.5*i
        enddo
        nx = 720
        do i=1,360
            yy(i) = -90 - 0.5/2 + 0.5*i
        enddo
        ny = 360
        call enscutoutwindow(1,720,1,360,xx,nx,.true.,.false.,avex,yy,ny
     +       ,avey,wx,wy,field,720,360,0,0,12,yrbeg,yrend,yr1,yr2,
     +       .false.)
        file = 'cru3_'//type//'_'//id//'.ctl'
        datfile = 'cru3_'//type//'_'//id//'.grd'
        ivars(1,1) = 1
        ivars(2,1) = 99
        call writectl(file,datfile,nx,xx,ny,yy,1,zz,12*(yr2-yr1+1),12
     +       ,yr1,1,3e33,title,1,type,ivars,lvar,' ')
        open(1,file=datfile,access='direct',recl=recfa4*nx*ny*12)
        do yr=yr1,yr2
            write(1,rec=yr-yr1+1)
     +           (((field(i,j,mo,yr),i=1,nx),j=1,ny),mo=1,12)
        enddo
        close(1)
*
        end

        subroutine writedata(ii,field,yrbeg,yrend,yr1,yr2,type,lvar
     +       ,title)
        implicit none
#include "recfac.h"
        integer ii,yrbeg,yrend,yr1,yr2
        real field(720,360,12,yrbeg:yrend)
        character type*3,lvar*(*),title*(*)
        integer i,j,mo,yr,irec
        character file*255
*
        if ( ii.eq.1 ) then
            file = 'cru3_'//type//'_eh.dat'
            open(1,file=file,access='direct',recl=recfa4*440*360)
        else
            file = 'cru3_'//type//'_wh.dat'
            open(1,file=file,access='direct',recl=recfa4*280*360)
        endif
        irec = 0
        do yr=yr1,yr2
            do mo=1,12
                irec = irec + 1
                if ( ii.eq.1 ) then
                    write(1,rec=irec) ((field(i,j,mo,yr),i=301,720),
     +                   (field(i,j,mo,yr),i=1,20),j=1,360)
                else
                    write(1,rec=irec) ((field(i,j,mo,yr),i=21,300),
     +                   j=1,360)
                endif
            enddo
        enddo
        close(1)
        if ( ii.eq.1 ) then
            open(1,file='cru3_'//type//'_eh.ctl')
        else
            open(1,file='cru3_'//type//'_wh.ctl')
        endif
        write(1,'(3a)') 'DSET ^',trim(file)
        write(1,'(3a)') 'TITLE ',trim(title)
        write(1,'(a)') 'UNDEF 3e33'
        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
        if ( ii.eq.1 ) then
            write(1,'(a)') 'XDEF 440 LINEAR -29.75 0.5'
        else
            write(1,'(a)') 'XDEF 280 LINEAR -169.75 0.5'
        endif
        write(1,'(a)') 'YDEF 360 LINEAR -89.75 0.5'
        write(1,'(a)') 'ZDEF   1 LINEAR 0 1'
        write(1,'(a,i5,a,i4,a)') 'TDEF ',12*(yr2-yr1+1),' LINEAR 15JAN'
     +       ,yr1,' 1MO'
        write(1,'(a)') 'VARS 1'
        write(1,'(3a)') type,' 0 1 ',trim(lvar)
        write(1,'(a)') 'ENDVARS'
        end
