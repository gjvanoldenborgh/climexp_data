        program makesoi
*
*       make a standard .dat file out of the two NCEP SOI file soi and soi.his
*
        implicit none
        integer yrbeg,yrend
        parameter(yrbeg=1882,yrend=2021)
        integer i,ii,j
        real data(12,yrbeg:yrend)
        character*128 line
*
        print '(a)','# SOI (Southern Oscillation Index) from NCEP'
        print '(a)','# Tahiti - Darwin SLP standardized'
        do i=yrbeg,yrend
            do j=1,12
                data(j,i) = -999.9
            enddo
        enddo
*
        print '(a)','# <a href="ftp://ftp.ncep.noaa.gov/pub/cpc/'//
     +        'wd52dg/data/indices/soi.his">historical data</a>'
        open(1,file='soi.his',status='old')
        do i=1,3
            read(1,'(a)') line
        enddo
        do i=yrbeg,1950
            read(1,'(i4,x,12f6.1)') ii,(data(j,i),j=1,12)
            if ( ii.ne.i ) goto 901
        enddo
        close(1)
*       
        print '(a)','# <a href="ftp://ftp.ncep.noaa.gov/pub/cpc/'//
     +        'wd52dg/data/indices/soi">recent data</a>'
        open(1,file='soi',status='old')
        do i=1,10000
            read(1,'(a)') line
            if ( index(line,'STANDARDIZED').ne.0 ) goto 100
        enddo
  100   continue
        read(1,'(a)') line
        if ( line(1:1).ne.'1' ) goto 100
        i = 1951
        read(line,'(i4,12f6.1)') ii,(data(j,i),j=1,12)
        if ( ii.ne.i ) goto 901
        do i=1952,yrend
            read(1,'(i4,12f6.1)',end=800) ii,(data(j,i),j=1,12)
            if ( ii.ne.i ) goto 901
        enddo
        write(*,*) 'time to extend yrend!'
  800   continue
        ii = i-1
        close(1)
*       
*       
        print '(a)','#'
        do i=yrbeg,ii
            do j=1,12
                if ( data(j,i).gt.-999 ) goto 810
            enddo
            goto 820
  810       continue
            print '(i4,12f8.1)',i,(data(j,i),j=1,12)
  820       continue
        enddo
*
        stop
*
  901   write(0,*) 'error: expected year ',i,' but found ',ii
        call abort
        end
