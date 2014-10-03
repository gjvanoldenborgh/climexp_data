*  #[ getgetargs:
*       support function common to getprpcp and gettemp
*       Geert Jan van Oldenborgh, KNMI, 1999-2000
*
        subroutine getgetargs(sname,slat,slon,slat1,slon1,n,nn,istation
     +        ,ifac,nmin,rmin,elevmin,elevmax,list,nl,nlist)
        implicit none
        character sname*(*)
        real slat,slon,slat1,slon1,rmin,elevmin,elevmax
        integer n,nn,istation,ifac,nmin(0:48),nl,list(nl),nlist
*       
        integer i,j,mon,lsum,m
        double precision fstation
        character string*80
        integer iargc
        character months(12)*3
        data months /'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug'
     +        ,'Sep','Oct','Nov','Dec'/
*
        sname = ' '
        slat1 = 3e33
        slon1 = 3e33
        rmin = 0
        elevmin = -3e33
        elevmax = +3e33
        nlist = 0
        do j=0,48
            nmin(j) = 0
        enddo
        mon = -1
        lsum = 1
*
        call getarg(1,string)
        if ( iargc().eq.1 ) then
            if ( ichar(string(1:1)).ge.ichar('0') .and. 
     +            ichar(string(1:1)).le.ichar('9') ) then
                call readstation(string,istation,ifac)
                n = 1
            else
                sname = string
                istation = -1
                do i=1,len_trim(sname)
                    if ( sname(i:i).eq.'+' ) sname(i:i) = ' '
                enddo
                print *,'Looking for stations with substring '
     +                ,trim(sname)
                n = 0
            endif
        elseif ( string(1:4).eq.'list' ) then
            call getarg(2,string)
            print '(2a)','Reading stationlist from file ',trim(string)
            open(1,file=string,status='old')
   10       continue
            read(1,'(a)',end=20,err=20) string
            if ( string.eq.' ' ) goto 10
            if ( index(string(1:2),'#').ne.0 ) then
                read(string(3:),*,err=18) slon,slon1,slat,slat1
                print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,a)'
     +                    ,'Searching for stations in ',slat,'N:',
     +                      slat1,'N, ',slon,'E:',slon1,'E'
   18           continue
            else
                nlist = nlist + 1
                if ( nlist.gt.nl ) then
                    print *,'error: too many stations',nl
                    call abort
                endif
                call readstation(string,list(nlist),ifac)
            endif
            goto 10
   20       continue                
            n = 2
            istation = -1
            if ( nlist.eq.0 ) then
                print *,'could not locate any stations'
                stop
            endif
        else
            istation = 0
            n = 10
            call getarg(1,string)
            i = index(string,':')
            if ( i.ne.0 ) then
                read(string(1:i-1),*,err=900) slat
                read(string(i+1:),*,err=900) slat1
                if ( slat1.lt. -90 .or. slat1.gt.90 ) goto 900
                istation = -1
                n = 0
            else
                read(string,*,err=900) slat
            endif
            if ( slat.lt. -90 .or. slat.gt.90 ) goto 900
            call getarg(2,string)
            i = index(string,':')
            if ( i.ne.0 ) then
                read(string(:i-1),*,err=901) slon
                if ( slon.gt.180 ) slon = slon-360
                if ( slon.lt.-180 .or. slon.gt.180 ) goto 901
                read(string(i+1:),*,err=901) slon1
                if ( slon1.gt.180 ) slon1 = slon1-360
                if ( slon1.lt.-180 .or. slon1.gt.180 ) goto 901
                if ( abs(slon-slon1).lt.1e-3 ) then
                    slon = -180
                    slon1 = 180
                endif
            else
                read(string,*,err=901) slon
                if ( slon.gt.180 ) slon = slon-360
                if ( slon.lt.-180 .or. slon.gt.180 ) goto 901
            endif
            if ( slat1.lt.1e33 .neqv. slon1.lt.1e33 ) goto 905
            if ( iargc().ge.3 ) then
                call getarg(3,string)
                if (  index(string,'min').eq.0 .and.
     +                index(string,'elev').eq.0 .and.
     +                index(string,'dist').eq.0 ) then
                    read(string,*,err=903) n
                    if ( n.gt.nn ) then
                        print *,'recompile with nn larger'
                        call abort
                    endif
                    i = 4
                else
                    i = 3
                endif
  100           continue
                if ( iargc().ge.i+1 ) then
                    call getarg(i,string)
                    if ( index(string,'elevmin').ne.0 ) then
                        call getarg(i+1,string)
                        read(string,*,err=907) elevmin
                    elseif ( index(string,'elevmax').ne.0 ) then
                        call getarg(i+1,string)
                        read(string,*,err=908) elevmax
                    elseif ( index(string,'min').ne.0 ) then
                        call getarg(i+1,string)
                        read(string,*,err=904) nmin(0)
                    elseif ( index(string,'mon').ne.0 ) then
                        call getarg(i+1,string)
                        read(string,*,err=904) mon
                        if ( mon.lt.0 .or. mon.gt.12 ) then
                            write(0,*) 'error: mon = ',12
                            write(*,*) 'error: mon = ',12
                            call abort
                        endif
                        if ( mon.eq.0 ) then
                            do m=1,12
                                nmin(m) = nmin(0)
                            enddo
                        else
                            nmin(mon) = nmin(0)
                        endif
                        nmin(0) = 0
                    elseif ( index(string,'sum').ne.0 ) then
                        call getarg(i+1,string)
                        read(string,*,err=904) lsum
                        if ( mon.eq.-1 ) then
                            write(0,*) 'please specify mon and sum'
                            write(*,*) 'please specify mon and sum'
                            call abort
                        endif
                        if ( lsum.gt.4 .or. lsum.lt.1 ) then
                            write(0,*) 'error: 0 <= sum <= 4: ',lsum
                            write(*,*) 'error: 0 <= sum <= 4: ',lsum
                            call abort
                        endif
                        if ( lsum.gt.1 ) then
                            if ( mon.eq.0 ) then
                                do m=1,12
                                    nmin(m+12*(lsum-1)) = nmin(m)
                                    nmin(m) = 0
                                enddo
                            else
                                nmin(mon+12*(lsum-1)) = nmin(mon)
                                nmin(mon) = 0
                            endif
                        endif
                    elseif ( index(string,'dist').ne.0 ) then
                        call getarg(i+1,string)
                        read(string,*,err=906) rmin
                    else
                        print *,'error: unrecognized argument: ',string
                        call abort
                    endif
                    i = i+2
                    goto 100
                endif
            endif
            if ( n.gt.1 ) print '(a,i4,a)','Looking up ',n,' stations'
            if ( n.gt.1 .or. slat1.lt.1e33 ) then
                if ( slat1.gt.1e33 ) then
                    print '(a,f6.2,a,f7.2,a)'
     +                    ,'Searching for stations near ',slat,'N, '
     +                    ,slon,'E'
                else
                    print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,a)'
     +                    ,'Searching for stations in ',slat,'N:',slat1,
     +                    'N, ',slon,'E:',slon1,'E'
                endif
                if ( elevmin.gt.-1e33 ) then
                    print '(a,f8.2,a)'
     +                    ,'Searching for stations higher than ',elevmin
     +                    ,'m'
                endif
                if ( elevmax.lt.+1e33 ) then
                    print '(a,f8.2,a)'
     +                    ,'Searching for stations lower than ',elevmax
     +                    ,'m'
                endif
                if ( mon.eq.-1 ) then
                    if ( nmin(0).gt.0 ) print '(a,i4,a)',
     +                    'Requiring at least ',nmin(0),
     +                    ' years with data'
                elseif ( mon.eq.0 ) then
                    if ( lsum.eq.1 ) then
                        print '(a,i4,a)','Requiring at least ',
     +                        nmin(1),' years with data in all months'
                    else
                        print '(a,i4,a,i1,a)','Requiring at least ',
     +                        nmin(1+(lsum-1)*12),
     +                        ' years with data in all ',lsum
     +                        ,'-month seasons'
                    endif
                elseif ( mon.gt.0 ) then
                    if ( lsum.eq.1 ) then
                        print '(a,i4,2a)','Requiring at least ',
     +                        nmin(mon),' years with data in '
     +                        ,months(mon)
                    else
                        print '(a,i4,4a)','Requiring at least ',
     +                        nmin(mon+(lsum-1)*12),
     +                        ' years with data in ',months(mon),'-',
     +                        months(1+mod(mon+lsum-2,12))
                    endif
                endif
                if ( rmin.gt.0 ) then
                    print '(a,f8.2,a)','Requiring at least ',rmin
     +                    ,' degrees of separation'
                endif
            endif
        endif
        goto 999
  900   print *,'please give latitude in degrees N, not ',string
        call abort
  901   print *,'please give longitude in degrees E, not ',string
        call abort
  903   print *,'please give number of stations to find, not ',string
        call abort
  904   print *,'please give minimum number of years, not ',string
        call abort
  905   print *,'please give range on both longitude and latitude'
        call abort
  906   print *,'please give minimum distance between stations, ',string
        call abort
  907   print *,'please give minimum elevation of station, ',string
        call abort
  908   print *,'please give maximum elevation of station, ',string
        call abort
  999   continue
        end
*  #] getgetargs:
*  #[ getdata:
        subroutine getdata(type,iu,ii,n,nyr)
*
*       print precip data - use binary search to find the records in
*       the (sorted) direct access file v2.precip.beta.data open on unit
*       iu
*
        implicit none
        character*(*) type
        integer iu,ii,n,nyr(0:48)
        integer j,k,kk,l,ilo,ihi,imi,i0,yr,yrm1,yr1,yr2,prcp(24),md
        integer nrecprcp,nstatprcp
        parameter (nrecprcp=1149121,nstatprcp=38169)
        integer nrectemp,nstattemp
        parameter (nrectemp=315395,nstattemp=800999140)
        integer nrectmin,nstattmin
        parameter (nrectmin=228280,nstattmin=650345241)
        integer nrectmax,nstattmax
        parameter (nrectmax=227031,nstattmax=650345241)
        integer nrecsea,nstatsea
        parameter (nrecsea=65776,nstatsea=799896642)
        integer nrecsta,nstatsta
        parameter (nrecsta=73542,nstatsta=799896621)
        integer nrecslv,nstatslv
        parameter (nrecslv=   45963,nstatslv=999103)
        logical lwrite
        parameter (lwrite=.FALSE.)
*
        if ( lwrite ) print *,'looking for station ',ii
        do j=0,48
            nyr(j) = 0
        enddo
        ilo = 1
        md = 0
        yrm1 = -9999
        do j=1,24
            prcp(j) = -9999
        enddo
        if ( type.eq.'prcp' ) then
            ihi = nrecprcp
            if ( ii.gt.nstatprcp ) then
                print '(a)','Cannot locate any data.'
***                print *,'Sorry, the file only goes to station '
***     +                ,nstatprcp
                goto 800
            endif
        elseif ( type.eq.'temp' ) then
            ihi = nrectemp
            if ( ii.gt.nstattemp ) then
                print '(a)','Cannot locate any data.'
***                print *,'Sorry, the file only goes to station '
***     +                ,nstattemp
                goto 800
            endif
        elseif ( type.eq.'tmin' ) then
            ihi = nrectmin
            if ( ii.gt.nstattmin ) then
                print '(a)','Cannot locate any data.'
***                print *,'Sorry, the file only goes to station '
***     +                ,nstattmin
                goto 800
            endif
        elseif ( type.eq.'tmax' ) then
            ihi = nrectmax
            if ( ii.gt.nstattmax ) then
                print '(a)','Cannot locate any data.'
***                print *,'Sorry, the file only goes to station '
***     +                ,nstattmax
                goto 800
            endif
        elseif ( type.eq.'sea' ) then
            ihi = nrecsea
            if ( ii.gt.nstatsea ) then
                print '(a)','Cannot locate any data.'
***                print *,'Sorry, the file only goes to station '
***     +                ,nstatsea
                goto 800
            endif
        elseif ( type.eq.'sta' ) then
            ihi = nrecsta
                print '(a)','Cannot locate any data.'
            if ( ii.gt.nstatsta ) then
***                print *,'Sorry, the file only goes to station '
***     +                ,nstatsta
                goto 800
            endif
        elseif ( type.eq.'slv' ) then
            ihi = nrecslv
            if ( ii.gt.nstatslv ) then
                print '(a)','Cannot locate any data.'
***                print *,'Sorry, the file only goes to station '
***     +                ,nstatslv
                goto 800
            endif
        else
            print *,'getdata: unknown database ',type
            call abort
        endif
  300   continue
        imi = (ilo+ihi)/2
        if ( lwrite ) print *,'reading record ',imi
        if ( type.eq.'prcp' .or. type.eq.'slv' ) then
            read(iu,1001,rec=imi) i0
 1001       format(i7)
        elseif ( type(1:1).eq.'t' ) then
            read(iu,1011,rec=imi) i0,md
 1011       format(i8,i3)
            i0 = 10*i0+md
        elseif ( type(1:1).eq.'s' ) then
            read(iu,1021,rec=imi) i0,md
 1021       format(i8,i2)
            i0 = 10*i0+md
        endif
        if ( lwrite ) print *,'Comparing with station ',i0,imi,'(',ilo
     +        ,ihi,')'
        if ( ii.gt.i0 ) then
            ilo = imi
        elseif ( ii.lt.i0 ) then
            ihi = imi
        else
*           found a match - scan it
            if ( lwrite ) print *,'found match ',imi
            if ( n.eq.1 ) then
                if ( type.eq.'prcp' ) then
                    print '(a)'
     +                    ,'# prcp from v2.precip.beta.data [mm/month]'
                elseif ( type.eq.'temp' ) then
                    print '(2a)','# temp from v2.mean_adj_nodup ',
     +                    '[Celsius]'
                elseif ( type.eq.'tmin' ) then
                    print '(2a)','# tmin from v2.min_adj_nodup ',
     +                    '[Celsius]'
                elseif ( type.eq.'tmax' ) then
                    print '(2a)','# tmax from v2.max_adj_nodup ',
     +                    '[Celsius]'
                elseif ( type.eq.'sea' ) then
                    print '(2a)','# sealevelpressure from ',
     +                    'press.sea.data [mb]'
                elseif ( type.eq.'sta' ) then
                    print '(2a)','# stationpressure from ',
     +                    'press.sta.data [mb]'
                elseif ( type.eq.'slv' ) then
                    print '(2a)','# ssh [cm] sealevel from PSMSL'
                else
                    print *,'unknown type ',type
                    stop
                endif
            endif
            yr1 = +100000
            yr2 = -100000
  310       continue
            imi = imi - 1
            if ( type.eq.'prcp' .or. type.eq.'slv' ) then
                if ( imi.gt.0 ) then
                    read(iu,1001,rec=imi) i0
                else
                    i0 = -1
                endif
                if ( lwrite) print *,'read record ',imi,i0
            elseif ( type(1:1).eq.'t' ) then
                if ( imi.gt.0 ) then
                    read(iu,1011,rec=imi) i0,md
                    i0 = 10*i0+md
                else
                    i0 = -1
                endif
                if ( lwrite) print *,'read record ',imi,i0
            elseif ( type(1:1).eq.'s' ) then
                if ( imi.gt.0 ) then
                    read(iu,1021,rec=imi) i0,md
                    i0 = 10*i0+md
                else
                    i0 = -1
                endif
                if ( lwrite) print *,'read record ',imi,i0
            else
                write(0,*) 'getdata: internal error: ',type
                call abort
            endif
            if ( i0.ne.ii ) goto 320
            goto 310
            if ( lwrite ) print *,'found first'
  320       continue
            imi = imi + 1
            do j=1,12
                prcp(j) = prcp(j+12)
            enddo
            if ( type.eq.'prcp' ) then
                if ( imi.le.nrecprcp ) then
                    read(iu,1002,rec=imi) i0,j,yr,(prcp(j),j=13,24)
                    if ( lwrite ) print *,'read complete record ',
     +                    imi,i0
 1002               format(i7,i2,i5,12i5)
                else
                    i0 = -1
                endif
            elseif ( type.eq.'slv' ) then
                if ( imi.le.nrecslv ) then
                    read(iu,1042,rec=imi) i0,yr,(prcp(j),j=13,24)
                    if ( lwrite ) print *,'read complete record ',
     +                    imi,i0
 1042               format(14i6)
                else
                    i0 = -1
                endif
            elseif ( type(1:1).eq.'t' ) then
                if (  type.eq.'temp' .and. imi.le.nrectemp .or.
     +                type.eq.'tmin' .and. imi.le.nrectmin .or.
     +                type.eq.'tmax' .and. imi.le.nrectmax ) then
                    read(iu,1012,rec=imi) i0,md,j,yr,(prcp(j),j=13,24)
                    i0 = 10*i0+md
 1012               format(i8,i3,i1,i4,12i5)
                else
                    i0 = -1
                endif
            elseif ( type(1:1).eq.'s' ) then
                if (  type.eq.'sea' .and. imi.le.nrecsea .or.
     +                type.eq.'sta' .and. imi.le.nrecsta ) then
                    read(iu,1022,rec=imi) i0,md,yr,(prcp(j),j=13,24)
                    i0 = 10*i0+md
 1022               format(i8,i2,i4,12i5)
                else
                    i0 = -1
                endif
            else
                write(0,*) 'getdata: internal error: ',type
                call abort
            endif
            if ( i0.ne.ii ) then
                if ( lwrite ) print *,'found last'
                if ( n.gt.1 ) print '(a,i4,a,i4,a,i4)','Found ',nyr(0),
     +                ' years with data in ',yr1,'-',yr2
                goto 800
            endif
*
*           count number of valid months, 2,3,4-month seasons
*
            if ( yrm1.ne.yr-1 ) then
                do j=1,12
                    prcp(j) = -9999
                enddo
            endif
            yrm1 = yr
            do j=1,12
                do k=0,3
                    kk = j-k
                    if ( kk.le.0 ) kk = kk+12
                    kk = kk + k*12
                    do l=0,k
                        if ( prcp(j-l).eq.-9999 .or. prcp(j-l).eq.-8888
     +                        ) goto 325
                    enddo
                    nyr(kk) = nyr(kk) + 1
  325               continue
                enddo
            enddo
*       
*           and the old measure - any year with valid months
*
            do j=13,24
                if ( prcp(j).ne.-9999 .and. prcp(j).ne.-8888 ) then
                    nyr(0) = nyr(0) + 1
                    yr1 = min(yr1,yr)
                    yr2 = max(yr2,yr)
                    goto 330
                endif
            enddo
  330       continue
            if ( n.eq.1 ) then
                print '(i5,12f7.1)',yr,(prcp(j)/10.,j=13,24)
            endif
            goto 320
        endif
        if ( ihi-ilo.gt.2 ) then
            goto 300
        else
            if ( lwrite ) print *,'stop'
            if ( n.gt.0 ) print *,'getdata: cannot locate any data'
        endif
  800   continue
*
        end
*  #] getdata:
*  #[ tidyname:
        subroutine tidyname(name,country)
*
*       Get rid of country
*       Replace spaces by underscores
*
        implicit none
        character*(*) name,country
        integer i,j
        character*5 c5
*
        c5 = country
        if ( len_trim(c5).gt.3 ) then
            i = index(name(3:),trim(c5)) ! dont kill SINGAPORE...
            if ( i.gt.0 ) name(i+2:) = ' '
        endif
*       a few spacial cases
        i = index(name,'   ')
        if ( i.gt.0 ) name(i:) = ' '
        i = index(name,' USA')
        if ( i.gt.0 ) name(i:) = ' '
        i = index(name,' YEMEN')
        if ( i.gt.0 ) name(i:) = ' '
        i = index(name,' W.GERMANY')
        if ( i.gt.0 ) name(i:) = ' '
*
        do j=1,len_trim(name)
            if ( name(j:j).eq.' ' ) name(j:j) = '_'
        enddo
*
        end
*  #] tidyname:
*  #[ toupper:
        subroutine toupper(string)
        implicit none
        character string*(*)
        integer i
        do i=1,len(string)
            if (  ichar(string(i:i)).ge.ichar('a') .and. 
     +            ichar(string(i:i)).le.ichar('z') ) then
                string(i:i) = char(ichar(string(i:i)) 
     +                - ichar('a') + ichar('A'))
            endif
        enddo
        if ( string.eq.' ' ) then
            string = 'UNKNOWN'
        endif
        end
*  #] toupper:
*  #[ tolower:
        subroutine tolower(string)
        implicit none
        character string*(*)
        integer i
        do i=1,len(string)
            if (  ichar(string(i:i)).ge.ichar('A') .and. 
     +            ichar(string(i:i)).le.ichar('Z') ) then
                string(i:i) = char(ichar(string(i:i)) 
     +                - ichar('A') + ichar('a'))
            endif
        enddo
        end
*  #] tolower:
*  #[ sortdist:
        subroutine sortdist(i,n,dist,rlon,rlat,ind,rmin)
        implicit none
        integer i,n,ind(i)
        real dist(i),rlat(i),rlon(i),rmin
        integer j,k,nok,jj,kk
        real dlon,d,pi
	parameter (pi  = 3.1415926535897932384626433832795d0)
*       
*       make and sort index array - Numerical recipes routine
        call indexx(i,dist,ind)
        if ( rmin.gt.0 ) then
*       discard stations that are too close together
            nok = 0
            do j=1,i
                jj = ind(j)
                if ( dist(jj).lt.1e33 ) then
                    nok = nok + 1
                    if ( nok.gt.n ) return
                    do k=j+1,i
                        kk = ind(k)
                        if ( dist(kk).lt.1e33 ) then
                            dlon = min(abs(rlon(jj)-rlon(kk)),
     +                            abs(rlon(jj)-rlon(kk)-360),
     +                            abs(rlon(jj)-rlon(kk)+360))
                            d = (rlat(jj)-rlat(kk))**2 + 
     +                            (dlon*cos((rlat(jj)+rlat(kk))/2/180*pi
     +                            ))**2
                            if ( d.lt.rmin**2 ) then
                                dist(kk) = 3e33
                            endif
                        endif
                    enddo
                endif
            enddo
        else
            nok = n
        endif
        n = nok
        end
*  #] sortdist:
*  #[ indexx:
C  (C) Copr. 1986-92 Numerical Recipes Software +.-).
      SUBROUTINE indexx(n,arr,indx)
      INTEGER n,indx(n),M,NSTACK
      REAL arr(n)
      PARAMETER (M=7,NSTACK=50)
      INTEGER i,indxt,ir,itemp,j,jstack,k,l,istack(NSTACK)
      REAL a
      do 11 j=1,n
        indx(j)=j
11    continue
      jstack=0
      l=1
      ir=n
1     if(ir-l.lt.M)then
        do 13 j=l+1,ir
          indxt=indx(j)
          a=arr(indxt)
          do 12 i=j-1,1,-1
            if(arr(indx(i)).le.a)goto 2
            indx(i+1)=indx(i)
12        continue
          i=0
2         indx(i+1)=indxt
13      continue
        if(jstack.eq.0)return
        ir=istack(jstack)
        l=istack(jstack-1)
        jstack=jstack-2
      else
        k=(l+ir)/2
        itemp=indx(k)
        indx(k)=indx(l+1)
        indx(l+1)=itemp
        if(arr(indx(l+1)).gt.arr(indx(ir)))then
          itemp=indx(l+1)
          indx(l+1)=indx(ir)
          indx(ir)=itemp
        endif
        if(arr(indx(l)).gt.arr(indx(ir)))then
          itemp=indx(l)
          indx(l)=indx(ir)
          indx(ir)=itemp
        endif
        if(arr(indx(l+1)).gt.arr(indx(l)))then
          itemp=indx(l+1)
          indx(l+1)=indx(l)
          indx(l)=itemp
        endif
        i=l+1
        j=ir
        indxt=indx(l)
        a=arr(indxt)
3       continue
          i=i+1
        if(arr(indx(i)).lt.a)goto 3
4       continue
          j=j-1
        if(arr(indx(j)).gt.a)goto 4
        if(j.lt.i)goto 5
        itemp=indx(i)
        indx(i)=indx(j)
        indx(j)=itemp
        goto 3
5       indx(l)=indx(j)
        indx(j)=indxt
        jstack=jstack+2
        if(jstack.gt.NSTACK)then
            write(0,*) 'indexx: error: NSTACK too small'
            call abort
        end if
        if(ir-i+1.ge.j-l)then
          istack(jstack)=ir
          istack(jstack-1)=i
          ir=j-1
        else
          istack(jstack)=j-1
          istack(jstack-1)=l
          l=i
        endif
      endif
      goto 1
      END
*  #] indexx:
*  #[ readstation:
      subroutine readstation(string,istation,ifac)
      implicit none
      character*(*) string
      integer istation,ifac
      integer i,j
      real fstation
      j=1
   10 continue
      if ( string(j:j).eq.' ' ) then
          j = j + 1
          goto 10
      endif
      if ( ifac.eq.1 ) then
          read(string(j:),*) istation
      else
          read(string(j:),*,err=904) fstation
          istation = nint(ifac*fstation)
          i = j + 3                
          if ( string(i:i).eq.'.' ) i = j + 4
              j = ichar(string(i:i))
              if ( i.ge.ichar('a') .and. j.le.ichar('z') ) then
              istation = istation + j - ichar('a')
          elseif ( i.ge.ichar('A') .and. j.le.ichar('Z') ) then
              istation = istation + j - ichar('A')
          endif
      endif
      return
 904  print *,'error reading station code'
      call abort
      end
*  #] readstation:
*  #[ updatebox:
        subroutine updatebox(i,rlonmin,rlonmax,rlatmin,rlatmax,rlon,rlat
     +        )
        implicit none
        integer i
        real rlonmin,rlonmax,rlatmin,rlatmax,rlon,rlat
        if ( i.eq.1 ) then
            rlonmin = rlon
            rlonmax = rlon
            rlatmin = rlat
            rlatmax = rlat
        else
            rlatmin = min(rlatmin,rlat)
            rlatmax = max(rlatmax,rlat)
            if ( abs(rlon-rlonmin).lt.
     +            abs(rlon-rlonmin-360) ) then
                rlonmin = min(rlonmin,rlon)
            else
                rlonmin = min(rlonmin,rlon-360)
            endif
            if ( abs(rlon-rlonmax).lt.
     +            abs(rlon-rlonmax+360) ) then
                rlonmax = max(rlonmax,rlon)
            else
                rlonmax = max(rlonmax,rlon+360)
            endif
        endif
        end
*  #] updatebox: 
*  #[ printbox: 
        subroutine printbox(rlonmin,rlonmax,rlatmin,rlatmax)
        implicit none
        real rlonmin,rlonmax,rlatmin,rlatmax
        real r
        if ( rlonmax-rlonmin.gt.360 ) then
            rlonmax = rlonmax - 360
        endif
*       add 10%
        r = rlatmax-rlatmin
        rlatmin = max(-90.,rlatmin-r/10)
        rlatmax = min(+90.,rlatmax+r/10)
        r = rlonmax-rlonmin
        rlonmin = rlonmin-r/10
        rlonmax = rlonmax+r/10
        print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,a)','Located stations in '
     +        ,rlatmin,'N:',rlatmax,'N, ',rlonmin,'E:',rlonmax,'E'
        end
*  #] printbox: 
