      program cable2dat
*
*     convert the Florida current estimates from 
*     http://www.aoml.noaa.gov/phod/floridacurrent/data_access.html
*      to a climexp file
*
      implicit none
      integer yrbeg,yrend
      parameter(yrbeg=1982,yrend=2020)
      integer yyyy,yr,mo,dy
      real current
      character*80 line,file

      print '(a)','# Florida Current Transport estimates [Sv]'
      print '(a)','# from calibrated cable voltages'
      print '(a)','# <a href="http://www.aoml.noaa.gov/phod/'//
     $     'floridacurrent/" target="_new">web site</a>'
      print '(a)','#'
      print '(a)','#'
      do yr=yrbeg,yrend
         if ( yr.lt.2000 ) then
            write(file,'(a,i4,a)') 'FC_cable_transport_',yr,'.asc'
         else
            write(file,'(a,i4,a)') 'FC_cable_transport_',yr,'.dat'
         endif
         write(0,'(2a)') 'opening file ',trim(file)
         open(1,file=file,status='old',err=800)
 100     continue
         read(1,'(a)',err=900,end=800) line
         if (line(1:1).eq.'%' ) goto 100
         if ( index(line,'NaN').ne.0 ) goto 100
         print '(a)',trim(line)
         goto 100
 800     continue
      enddo
      goto 999
 900  write(0,*) 'error reading data file ',trim(file)
      call abort
 999  continue
      end
