      program addyears
      implicit none
      integer i,j,ic,ifeet,ielevs,nyr,yr1,yr2,yr,yrold
      real rlat,rlon,vals(12)
      character stations*11,state*25,ss*2,name*40,line*256,station*11
      logical open
      integer llen
      external llen
*
      open(1,file='metadata.climexp',status='old')
      open(2,file='nrcssweclimexp.dat',status='old')
      open(3,file='metadata.climexp.withyear',status='unknown')
      read(1,'(a)')
 100  continue
      stations = ' '
      read(1,1001,end=800) stations,ic,state,ss,
     +       rlat,rlon,ifeet,ielevs,name
 1001 format(3x,a11,3x,i2,6x,a25,a2,f16.4,f13.4,i10,i11,3x,a40)
      if ( .false. ) then
          print *,stations
          print *,ic
          print *,state
          print *,ss
          print *,rlat,rlon
          print *,ifeet,ielevs
          print *,name
      endif
      rewind(2)
      open = .false.
      yr1 = +9999
      yr2 = -9999
      nyr = 0
      yrold = -9999
 200  continue
      read(2,'(a)',end=700) line
      i=index(line,' ')
      station = line(:i)
      if ( station.ne.stations ) goto 200
      if ( .not.open ) then
          open = .true.
          print *,'opening data/'//stations(1:llen(station))//'.dat'
          open(4,file='data/'//stations(1:llen(station))//'.dat',
     +         status='unknown')
          write(4,'(a)') '# Snow water equivalent from NCRS-USDA'
          write(4,'(2a)') '# station code ',stations
          write(4,'(3a)') '# ',name,state
          write(4,'(a,f10.4,a,f10.4,a)') '# Coordinates ',rlat,'N, '
     +         ,rlon,'E'
          write(4,'(a)') '# snow water equivalent [m]'
      endif
      read(line(i:),*) yr,vals
      if ( yr.le.yrold ) then
          write(0,*) 'error: duplicate reord: ',line(1:llen(line)),yr
     +         ,yrold
          write(*,*) 'error: duplicate reord: ',line(1:llen(line)),yr
     +         ,yrold
      endif
      yrold = yr
      yr1 = min(yr1,yr)
      yr2 = max(yr2,yr)
      nyr = nyr + 1
      do j=1,12
          if ( vals(j).eq.-9999 ) then
              vals(j) = -999.9
          elseif ( vals(j).ge.0 ) then
              vals(j) = vals(j)*0.001
          else
              write(0,*) 'weird value: ',vals(j)
              call abort
          endif
      enddo
      write(4,'(i4,12f9.3)') yr,vals
      goto 200
 700  continue
      close(4)
      write(3,1002) '   ',stations,'   ',ic,'      ',state,ss,
     +       rlat,rlon,ifeet,ielevs,'   ',name,nyr,yr1,yr2
      write(*,1002) '   ',stations,'   ',ic,'      ',state,ss,
     +       rlat,rlon,ifeet,ielevs,'   ',name,nyr,yr1,yr2
 1002 format(a3,a11,a3,i2,a6,a25,a2,f17.4,f13.4,i10,i11,a3,a40,3i5)
      call flush(3)
      goto 100
 800  continue
      end

        integer function llen(a)
        character*(*) a
        do 10 i=len(a),1,-1
            if ( a(i:i).ne.'?' .and. a(i:i).ne.' ' .and. 
     +           a(i:i).ne.char(0) ) goto 20
   10   continue
   20   continue
        llen = max(i,1)
        end
        
