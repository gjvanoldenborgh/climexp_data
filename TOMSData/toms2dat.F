        program toms2dat
*
*       convert the ASCII TOMS monthly datafiles to a GrADS datafile
*       averaging in the process.
*
        implicit none
#include "recfac.h"
        integer yr,mo,i,j,irec
        integer iozon(288,180)
        real ozon2(144,90),xlat,w,s
        character*80 line
        character*10 file
        integer system
        external system
*       
*       open output file
*       
        open(2,file='toms.dat',form='unformatted',access='direct',recl
     +        =144*90*recfa4)
        irec = 0
*
*       loop over years, months
*
        do yr=78,93
            do mo=1,12
                if (  yr.eq.78 .and. mo.lt.11 .or.
     +                yr.eq.93 .and. mo.gt. 4 ) then
*                   no data
                    do j=1,90
                        do i=1,144
                            ozon2(i,j) = 3e33
                        enddo
                    enddo
                else
*       
*                   open file
*
                    write(file,'(a,2i2.2,a)') 'gm',yr,mo,'.n7t'
                    if ( system('gunzip -c '//file//'.gz > tmpfile').ne
     +                    .0 ) then
                        print *,'toms2dat: error unzippng ',file
                    endif
                    open(1,file='tmpfile')
                    read(1,'(a)') line
                    print '(a)',line
                    read(1,'(a)') line
                    read(1,'(a)') line
*       
*                   read data
*
                    do j=1,180
                        read(1,'(1x,25i3)',err=901) (iozon(i,j),i=1,275)
                        read(1,'(1x,13i3,a8,f8.2)',err=902) (iozon(i,j)
     +                        ,i=276,288),line,xlat
                        if ( xlat.ne.-90.5+j ) then
                            print *,'toms2dat: wrong latitude: ',xlat,
     +                            -90.5+j
                        endif
                    enddo
*       
*                   average to 2.5x2 grid
*       
                    do j=1,90
                        do i=1,144
                            w = 0
                            s = 0
                            call addtoms(w,s,iozon,144+2*i-1,2*j-1,1.)
                            call addtoms(w,s,iozon,144+2*i  ,2*j-1,1.)
                            call addtoms(w,s,iozon,144+2*i-1,2*j  ,1.)
                            call addtoms(w,s,iozon,144+2*i  ,2*j  ,1.)
                            if ( w.gt.2.1 ) then
                                ozon2(i,j) = s/w
                            else
                                ozon2(i,j) = 3e33
                            endif
                        enddo
                    enddo
                endif           ! valid yr,mo
*                
*               write data
*       
                irec = irec + 1
                write(2,rec=irec) ozon2
                close(1,status='delete')
            enddo               ! mo
        enddo                   ! yr
        stop
*       
*       error messages
*       
  901   print *,'toms2dat: error reading first chunk of data at ',yr,mo
     +        ,j,i
        stop
  902   print *,'toms2dat: error reading second chunk of data at ',yr,mo
     +        ,j,i
        print '(a,13i3)','iozon(276:288) = ',(iozon(i,j),i=276,288)
        print '(2a)','line = ',line(1:8)
        print '(a,f8.2)','xlat = ',xlat
        end

        subroutine addtoms(w,s,ifield,ii,jj,fac)
        implicit none
        integer ii,jj,ifield(288,180)
        real w,s,fac
        integer iii
*
        if ( jj.ge.1 .and. jj.le.180 ) then
            if ( ii.ge.288 ) then
                iii = ii - 288
            elseif ( ii.lt.0 ) then
                iii = ii + 288
            else
                iii = ii
            endif
            if ( ifield(iii,jj).gt.0 .and. ifield(iii,jj).lt.999 )
     +            then
                w = w + fac
                s = s + fac*ifield(iii,jj)
            endif
        endif
        end
