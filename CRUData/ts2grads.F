        program new2grads
*
*       convert Mark News grim files to GrADS
*
        implicit none
#include "recfac.h"
        integer yrbeg,yrend
        parameter(yrbeg=1901,yrend=2020)
        integer i,j,mo,yr,ival(12,yrbeg:yrend),ivalclim(12),nn(12),
     +       yr1,yr2,avex,avey,nx,ny,ivars(2,1),iouttype
        real field(720,360,12,yrbeg:yrend),fac,xx(720),yy(360),zz(1)
     +       ,wx(720),wy(360)
        logical clim,climold,lwrite
        character file*255,datfile*255,line*80,type*3,lvar*60,title*80
     +       ,id*2
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
        read(1,'(a)') line
        read(1,'(a)') line
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
        read(1,'(a)') title
        read(1,'(a)') line
        read(1,'(a)') line
        i = index(line,'Years=') + 6
        read(line(i:i+3),'(i4)') yr1
        if ( yr1.ne.yrbeg ) then
            write(0,*) 'errior: yr1 != yrbeg: ',yr1,yrbeg
            call abort
        endif
        read(line(i+5:i+8),'(i4)') yr2
        if ( yr2.gt.yrend .or. yr2.lt.2000 ) then
            write(0,*) 'errior: yr2 > yrend: ',yr2,yrend
            call abort
        endif
        print *,'yr1,yr2 = ',yr1,yr2
        i = index(line,'Multi=') + 6
        read(line(i:i+9),'(f10.4)') fac
        print *,'fac = ',fac
*
*       init
*
        field = 3e33
*
*       main loop
*
 100    continue
        read(1,'(a)',end=800) line
        if ( line(1:9).ne.'Grid-ref=' ) then
            write(0,*) 'error: expecting ''Grid-ref='', found ',line
            call abort
        endif
        read(line(10:),*) i,j
        do mo=1,12
            ivalclim(mo) = -999
            nn(mo) = 0
        enddo
        do yr=yr1,yr2
            read(1,'(12i5)') (ival(mo,yr),mo=1,12)
        enddo
        do yr=yr1+1,yr2
            clim = .true.
            do mo=1,12
                if ( ival(mo,yr).ne.ival(mo,yr-1) ) clim = .false.
            enddo
            if ( clim ) then
                if ( lwrite) print *,'found climatology ',yr
                do mo=1,12
*                   if the climatology is zero for precip and clouds, 
*                   then leave it in to avoid undefs in the desert
                    if ( (type.eq.'pre' .or. type.eq.'cld') 
     +                   .and. ival(mo,yr).eq.0 ) then
                        ivalclim(mo) = -999
                    else
                        ivalclim(mo) = ival(mo,yr)
                    endif
                enddo
                goto 200
            endif
        enddo
 200    continue
        do yr=yr1,yr2
            do mo=1,12
                if ( ival(mo,yr).ne.ivalclim(mo) .and. 
     +               ival(mo,yr).ne.-999 ) then
                    if ( lwrite) print *,'reading year,mo ',yr,mo
                    nn(mo) = nn(mo) + 1
                    field(i,j,mo,yr) = fac*ival(mo,yr)
                endif
            enddo
        enddo
***        print '(14i4)',i,j,nn
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
        file = 'cru2_'//type//'_'//id//'.ctl'
        datfile = 'cru2_'//type//'_'//id//'.grd'
        ivars(1,1) = 1
        ivars(2,1) = 99
        call writectl(file,datfile,nx,xx,ny,yy,1,zz,12*(yr2-yr1),12,yr1
     +       ,1,3e33,title,1,type,ivars,lvar,' ')
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
            file = 'cru2_'//type//'_eh.dat'
            open(1,file=file,access='direct',recl=recfa4*440*360)
        else
            file = 'cru2_'//type//'_wh.dat'
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
            open(1,file='cru2_'//type//'_eh.ctl')
        else
            open(1,file='cru2_'//type//'_wh.ctl')
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
