        program deos2grads
*
*       convert Ejo's 1x1 files to GrADS 2x2 format.
*
        implicit none
#include "recfac.h"
        integer i,j,yr,mo,irec
        real field1(1:360,-70:70),lat,lon,ssh,w
        character file*28,line*80,month(12)*3
        integer system
        external system
        data month 
     +        /'JAN','FEB','MAR','APR','MAY','JUN'
     +        ,'JUL','AUG','SEP','OCT','NOV','DEC'/
*       
*       open output file
*       
        open(2,file='ssh.dat',access='direct',recl=360*141*recfa4,
     +        form='unformatted')
        irec = 0
*       
*       loop over years
*
        do yr=1992,2020
            do mo=1,12
                if ( yr.eq.1992.and.mo.lt.10 ) then
                    do j=-70,70
                        do i=1,360
                            field1(i,j) = 3e33
                        enddo
                    enddo
                    goto 800
                endif
*
*               uncompress and open file
*
                if ( mo.lt.10 ) then
                    write(file,'(a,i4,a,i1,a)') 'tpe1e2_ssh2mss_',yr,'_'
     +                    ,mo,'.dat.Z'
                else
                    write(file,'(a,i4,a,i2,a)') 'tpe1e2_ssh2mss_',yr,'_'
     +                    ,mo,'.dat.Z'
                endif
                if ( system('gunzip -c '//file//' > tmpfile').ne.0 )
     +                then
                    print *,'deos2grads: error uncompressing file ',file
                    stop
                endif
                open(1,file='tmpfile',status='old',err=900)
*
*               read header
*
                read(1,'(a)',err=901) line
                print '(a)',line(1:20)
                if ( line(10:12).ne.month(mo) ) print *
     +                ,'deos2grads: error: months do not agree: ',mo
     +                ,line(10:12)
                read(line(14:),'(i4)') i
                if ( i.ne.yr ) print *
     +                ,'deos2grads: error: years do not agree: ',yr
     +                ,line(14:)
                do i=1,4
                    read(1,'(a)',end=901,err=901) line
***                    print *,line
                enddo
*       
*               read data
*       
                do j=-70,70
                    do i=1,360
                        field1(i,j) = 3e33
                    enddo
                enddo
  100           continue
                read(1,*,err=902,end=200) lon,lat,ssh
                i = nint(lon)
                j = nint(lat)
                if ( i.gt.0 .and. i.le.360 .and. j.ge.-70 .and. j.le.70
     +                ) then
                    field1(i,j) = ssh/100
                else
                    print *,'deos2grads: error: invalid coordinates ',i
     +                    ,j
                endif
                goto 100
  200           continue
*
*               write field
*       
  800           continue
                irec = irec + 1
                write(2,rec=irec) field1
                close(1,status='delete')
            enddo               ! month
        enddo                   ! year        
        stop
*       
*       error messages
*        
  900   print *,'error opening tmpfile'
        stop
  901   print *,'error reading header'
        stop
  902   print *,'error reading data'
        end
