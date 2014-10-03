        program toms_daily2dat
*
*       convert the ASCII TOMS monthly datafiles to a GrADS datafile
*
        implicit none
        integer nx,ny,nx1
        parameter (nx=288,ny=180,nx1=360)
#include "recfac.h"
        integer yr,mo,dy,i,j,irec,iret,dy1,mo1,yr1,ii,nnul,nund
        integer iozon(nx,ny),iomi(nx1),dpm(12,2)
        real ozon2(nx,ny,2),xlat,w,s
        character line*80
        character file*255
        character sat*2,st*2,months*36,var*7,vr*5
        integer get_endian,leap
        logical valid
        data dpm /31,28,31,30,31,30,31,31,30,31,30,31,
     +       31,29,31,30,31,30,31,31,30,31,30,31/
        data months /'JanFebMarAprMayJunJulAugSepOctNovDec'/

        call getarg(1,var)
        if ( var.eq.'ozone' ) then
            vr = 'ozone'
        elseif ( var.eq.'aerosol' ) then
            vr = 'aersl'
        else
            write(0,*) 'usage: toms_daily2dat ozone|aerosol'
            call abort
        endif
*       
*       open output file
*       
        open(2,file='toms_'//trim(var)//'daily.grd',form='unformatted',
     +       access='direct',recl=nx*ny*recfa4)
        irec = 0
*
*       loop over years, months
*
        do yr=1979,2008
            do mo=1,12
                do dy=1,dpm(mo,leap(yr))
                    do ii=1,2
                        if ( ii.eq.1 ) then
                            if ( yr.le.1993 ) then
                                sat = 'N7'
                            else
                                sat = 'EP'
                            endif
                        else
                            if ( yr.le.1994 ) then
                                sat = 'M3'
                            else
                                sat = 'OM'
                            endif
                        endif
                        st = sat
                        call tolower(st)
*                       
*                       open file
*                   
                        write(file,'(4a,i4,5a,i4,2i2.2,a)')
     +                       sat,'_TOMS/data/',trim(var),'/Y',yr,
     +                       '/L3_',vr,'_',st,'?_',yr,mo,dy,'.txt.gz'
                        call mysystem('(gunzip -c '//trim(file)//
     +                       ' > tmpfile) > /dev/null 2>&1',iret)
                        if ( iret.ne.0 ) then
                            ozon2(:,:,ii) = 3e33
                        else
                            open(1,file='tmpfile')
                            read(1,'(a)') line
                            print '(a)',line
                            read(line(15:16),*) dy1
                            read(line(19:22),*) yr1
                            mo1 = 1 + index(months,line(11:13))/3
                            if ( dy1.ne.dy .or.
     +                           mo1.ne.mo .or.
     +                           yr1.ne.yr ) then
                                write(0,*) 'error in dates'
                                write(0,*) yr,mo,dy
                                write(0,*) yr1,mo1,dy1
                                call abort
                            endif
                            read(1,'(a)') line
                            read(1,'(a)') line
*
*                           read data
*
                            do j=1,ny
                                if ( sat.eq.'OM' ) then
                                    read(1,'(1x,25i3)',err=901) 
     +                                   (iomi(i),i=1,350)
                                    read(1,'(1x,10i3,a8,f7.1)',err=902)
     +                                   (iomi(i),i=351,nx1),line,xlat
!                                   interpolate to 1.5x1 grid :-(
                                    do i=1,nx/4
                                        if ( valid(iomi(5*i-4),var).and.
     +                                       valid(iomi(5*i-3),var) )
     +                                       then
                                            iozon(4*i-3,j) = nint(
     +                                           (4*iomi(5*i-4) +
     +                                           iomi(5*i-3))/5.)
                                        else
                                            iozon(4*i-3,j) = iomi(5*i-4)
                                        endif
                                        if ( valid(iomi(5*i-3),var).and.
     +                                       valid(iomi(5*i-2),var) )
     +                                       then
                                            iozon(4*i-2,j) = nint(
     +                                           (3*iomi(5*i-3) +
     +                                           2*iomi(5*i-2))/5.)
                                        else
                                            iozon(4*i-2,j) = iomi(5*i-3)
                                        endif
                                        if ( valid(iomi(5*i-2),var).and.
     +                                       valid(iomi(5*i-1),var) )
     +                                       then
                                            iozon(4*i-1,j) = nint(
     +                                           (3*iomi(5*i-1) +
     +                                           2*iomi(5*i-2))/5.)
                                        else
                                            iozon(4*i-1,j) = iomi(5*i-1)
                                        endif
                                        if ( valid(iomi(5*i-1),var).and.
     +                                       valid(iomi(5*i),var) ) then
                                            iozon(4*i,j) = nint(
     +                                           (4*iomi(5*i) +
     +                                           iomi(5*i-1))/5.)
                                        else
                                            iozon(4*i,j) = iomi(5*i)
                                        endif
                                    enddo
                                else
                                    read(1,'(1x,25i3)',err=901) 
     +                                   (iozon(i,j),i=1,275)
                                    read(1,'(1x,13i3,a8,f7.1)',err=902)
     +                                   (iozon(i,j),i=276,nx),line,xlat
                                endif
                                if ( xlat.ne.-90.5+j ) then
                                    print *,'toms2dat: wrong latitude: '
     +                                   ,xlat,-90.5+j
                                endif
                            enddo
!                           check for weirdness
                            nnul = 0
                            nund = 0
                            do i=1,nx
                                do j=1,ny
                                    if ( iozon(i,j).eq.0 )
     +                                   nnul = nnul + 1
                                    if ( .not.valid(iozon(i,j),var) )
     +                                   nund = nund + 1
                                end do
                            end do
                            if ( var.eq.'aerosol' .and. nnul.eq.0 ) then
                                print *,'error: nnul,nund = ',nnul,nund
     +                               ,nx*ny
                                ozon2(:,:,ii) = 3e33
                            else    
                                do i=1,nx
                                    do j=1,ny
                                        if ( valid(iozon(i,j),var) )
     +                                       then
                                            if ( var.eq.'ozone' ) then
                                                ozon2(i,j,ii) =
     +                                               iozon(i,j)
                                            elseif ( var.eq.'aerosol' )
     +                                               then
                                                ozon2(i,j,ii) = 
     +                                               iozon(i,j)/10.
                                            endif
                                        else
                                            ozon2(i,j,ii) = 3e33
                                        endif
                                    enddo
                                enddo
                            end if
                            close(1,status='delete')
                        endif   ! valid yr,mo,dy
                    enddo
*
*                   merge data
*
                    do i=1,nx
                        do j=1,ny
                            if ( ozon2(i,j,2).lt.1e33 ) then
                                if ( ozon2(i,j,1).lt.1e33 ) then
                                    ozon2(i,j,1) = (ozon2(i,j,1) +
     +                                   ozon2(i,j,2))/2
                                else
                                    ozon2(i,j,1) = ozon2(i,j,2)
                                endif
                            endif
                        enddo
                    enddo
*
*                   write data
*
                    irec = irec + 1
                    write(2,rec=irec) ((ozon2(i,j,1),i=1,nx),j=1,ny)
                enddo           ! dy
            enddo               ! mo
        enddo                   ! yr
        open(1,file='toms_'//trim(var)//'daily.ctl')
        write(1,'(a)') 'DSET ^toms_'//trim(var)//'daily.grd'
        write(1,'(2a)') 'TITLE NIMBUS-7/METEOR-3/EP/OMI TOMS ',trim(var)
        if ( get_endian().eq.-1 ) then
            write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
        elseif ( get_endian().eq.+1 ) then
            write(1,'(a)') 'OPTIONS BIG_ENDIAN'
        endif
        write(1,'(a)') 'UNDEF 3e33'
        write(1,'(a,i3,a,2f8.3)') 'XDEF ',nx,' LINEAR ',-179.375,1.25
        write(1,'(a,i3,a,2f8.3)') 'YDEF ',ny,' LINEAR ',-89.5,1.
        write(1,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(1,'(a,i6,a)') 'TDEF ',irec,' LINEAR 01JAN1979 1DY'
        write(1,'(a)') 'VARS 1'
        if ( var.eq.'ozone' ) then
            write(1,'(a)')
     +           'ozone 0 99 column ozone concentration [Dobson]'
        else
            write(1,'(a)') 'aerosol 0 99 aerosol index [1]'
        endif
        write(1,'(a)') 'ENDVARS'
        close(1)
        goto 999
*
*       error messages
*       
  901   print *,'toms2dat: error reading first chunk of data at ',yr,mo
     +       ,dy,j,i
        stop
  902   print *,'toms2dat: error reading second chunk of data at ',yr,mo
     +       ,dy,j,i
        print '(a,13i3)','iozon(276:nx) = ',(iozon(i,j),i=276,nx)
        print '(2a)','line = ',line(1:8)
        print '(a,f8.2)','xlat = ',xlat
 999    continue
        end

        logical function valid(ix,var)
        implicit none
        integer ix
        character var*(*)
        if ( var.eq.'ozone' ) then
            if ( ix.gt.0 .and. ix.lt.999 ) then
                valid = .true.
            else
                valid = .false.
            endif
        elseif ( var.eq.'aerosol' ) then
            if ( ix.ge.0 .and. ix.lt.999 ) then
                valid = .true.
            else
                valid = .false.
            endif
        else
            write(0,*) 'valid: unknown variable ',trim(var)
            call abort
        endif
        end
