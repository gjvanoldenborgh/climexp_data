      program addyears
!
!     add number of years, first year and last year of data to 
!     GDCN_V1_0.inv
!
      implicit none
      integer i,j,idates(18),ires,yr,mo,val(31),yrold(6),nrec &
     &     ,failed(26)
      character station*11,station1*11,elevflag,datasource,name*30,id1*8 &
     &     ,id2*8,element*4,filename*21,flag1(31)*1,flag2(31)*1, &
     &     flag3(31)*1,wmo*5,dummy1*1,dummy2*1,errstation*11,line*300, &
     &     country*2,state*2,source(2)*3,cfailed(26)*60
      real rlat,rlon,relev
      logical lwrite,lonlygts,lvalid
      integer system
      external system
      lwrite = .false.
      call getenv('LWRITE',line)
      call tolower(line)
      if ( line(1:1) == 't' ) lwrite = .true.
      errstation=' '
      failed = 0
      cfailed = 'UNKNOWN'
      cfailed(1+ichar('A')-ichar('A')) = 'failed accumulation total check'
      cfailed(1+ichar('C')-ichar('A')) = 'failed intraday consistency check'
      cfailed(1+ichar('D')-ichar('A')) = 'failed duplicate check'
      cfailed(1+ichar('F')-ichar('A')) = 'failed value-measurement flagged consistency check'
      cfailed(1+ichar('G')-ichar('A')) = 'failed gap check'
      cfailed(1+ichar('I')-ichar('A')) = 'failed internal consistency check'
      cfailed(1+ichar('K')-ichar('A')) = 'failed streak/frequent-value check'
      cfailed(1+ichar('M')-ichar('A')) = 'failed megaconsistency check'
      cfailed(1+ichar('N')-ichar('A')) = 'failed naught check'
      cfailed(1+ichar('O')-ichar('A')) = 'failed climatological outlier check'
      cfailed(1+ichar('R')-ichar('A')) = 'failed lagged range check'
      cfailed(1+ichar('S')-ichar('A')) = 'failed spatial consistency check'
      cfailed(1+ichar('T')-ichar('A')) = 'failed temporal consistency check'
      cfailed(1+ichar('W')-ichar('A')) = 'temperature too warm for snow'
      cfailed(1+ichar('X')-ichar('A')) = 'failed bounds check'
!     no longer used, but still in my .withyears file
!     because I am too lazy to adapt the other programs
      elevflag = ' '
      dummy1 = ' '
      datasource = ' '
      dummy2 = ' '
      id1 = ' '
      id2 = ' '
!
      open(unit=1,file='ghcnd-stations.txt',status='old')
      open(unit=2,file='ghcnd2.inv.withyears',status='unknown')
!
      nrec = 0
 100  continue
      nrec = nrec + 1
      read(1,1000,end=900) station,rlat,rlon,relev,state,name,source,wmo
 1000 format(a11,f9.4,f10.4,f7.1,1x,a2,1x,a30,1x,a3,1x,a3,1x,a5)
      country = station(1:2)
      if ( lwrite ) print *,station
      filename = 'ghcnd/'//station//'.dly'
      call mysystem('gunzip -c '//filename//'.gz > /tmp/gdcn',ires)
      open(3,file='/tmp/gdcn',status='old')
      do i=1,6
          idates(3*i-2) = 0
          idates(3*i-1) = +9999
          idates(3*i)   = -9999
          yrold(i) = -9999
      enddo
 200  continue
      read(3,1001,end=800) station1,yr,mo,element, &
     &     (val(i),flag1(i),flag2(i),flag3(i),i=1,31)
 1001 format(a11,i4,i2,a4,31(i5,3a1))
      if ( lwrite ) print *,element,yr,mo
      if ( station.ne.station1 ) then
          write(0,*) 'error: station ',station,' != ',station1,yr,mo
          call abort
      endif
      lvalid = .false.
      lonlygts = .true.
      do i=1,31
          if ( val(i).ne.-9999 ) then
              if ( flag2(i).eq.' ' ) then
                  lvalid = .true.
                  if ( flag3(i).ne.'S' ) then
                      lonlygts = .false.
                      goto 210
                  endif
              else
                  j = 1 + ichar(flag2(i)) - ichar('A')
                  if ( j.lt.1 .or. j.gt.26 ) then
                      write(0,*) 'error: unexpected QC flag ',flag2(i)
                      call abort
                  endif
                  failed(j) = failed(j) + 1
                  if ( lwrite ) print *,trim(cfailed(j))
              endif
          endif
      enddo
      if ( .not.lvalid ) goto 200
!     at least some valid data
 210  continue
      if ( element.eq.'TMIN' ) then
          i = 1
      elseif ( element.eq.'TMAX' ) then
          i = 2
      elseif ( element.eq.'PRCP' ) then
          i = 3
      elseif ( element.eq.'SNOW' ) then
          i = 5
      elseif ( element.eq.'SNWD' ) then
          i = 6
      elseif ( element.eq.'TOBS' ) then
          goto 200
      else
          !!!write(0,*) 'error: unknown element ',element,' in ',station
          goto 200
      endif
      idates(3*i-1) = min(yr,idates(3*i-1))
      idates(3*i)   = max(yr,idates(3*i))
      if ( element.eq.'PRCP' .and. .not.lonlygts ) then
          idates(11) = min(yr,idates(11))
          idates(12) = max(yr,idates(12))
      endif
!     this assumes the years are ordered
      if ( yrold(i).eq.-9999 ) then
          idates(3*i-2) = 1
          yrold(i) = yr
      endif
      if ( element.eq.'PRCP' .and. .not.lonlygts .and. yrold(4).eq.-9999) then
          idates(10) = 1
          yrold(4) = yr
      endif
      if ( yr.gt.yrold(i) ) then
          yrold(i) = yr
          idates(3*i-2) = idates(3*i-2) + 1
      endif
      if ( element.eq.'PRCP' .and. .not.lonlygts .and. yr.gt.yrold(4) ) then
              yrold(4) = yr
              idates(10) = idates(10) + 1
      endif
      if ( yr.lt.yrold(i) ) then
          if ( station.ne.errstation ) then
              print *,'error: backward data in ',station,' ',name
              errstation = station
          endif
      endif
!!!      if ( lwrite ) print *,idates(3*i-2),idates(3*i-1),idates(3*i)
      goto 200
 800  continue
      if ( lwrite ) print *,'EOF, next station'
      close(3,status='delete')
!     any data?
!      if ( idates(1).eq.0 .and. idates(4).eq.0 .and. idates(7).eq.0 )
!     +     then
!          goto 100
!      endif
      if ( lwrite ) print *,(idates(i),i=1,18)
!     add state to name, country is added by gdcndata
      i = len_trim(name)
      if ( i.lt.len(name)-4 .and. state.ne.' ' ) then
          name(i+1:) = ', '//state
      endif
 1002 format(a11,f7.2,f8.2,i5,4a1,a30,a5,2a8,18i5)
      write(2,1002) station,rlat,rlon,nint(relev),elevflag,dummy1 &
     &     ,datasource,dummy2,name,wmo,id1,id2,(idates(i),i=1,18)
      print '(a,18i5)',station,(idates(i),i=1,18)
      goto 100
 900  continue
      print *,'number of failed QC chacks'
      do i=1,26
          if ( failed(i).ne.0 ) then
              print '(i12,2a)',failed(i),' ',trim(cfailed(i))
          endif
      enddo
      print *,'processed ',nrec,' stations'        
      end
