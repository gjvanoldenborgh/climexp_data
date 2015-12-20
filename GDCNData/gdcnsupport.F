*  #[ getgetargs:
*       support function common to getprpcp and gettemp
*       Geert Jan van Oldenborgh, KNMI, 1999-2000
*
        subroutine gdcngetargs(sname,slat,slon,slat1,slon1,n,nn,station
     +        ,ifac,nmin,rmin,elevmin,elevmax,qcflag,list,nl,nlist)
        implicit none
        integer n,nn,ifac,nmin(0:48),nl,nlist,narg
        character sname*(*),station*11,list(nl)*11,qcflag*1,minnum*20
        real slat,slon,slat1,slon1,rmin,elevmin,elevmax
*
        integer i,j,mon,lsum,m
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
        qcflag = 'O'
*
        narg = 9999
        call getarg(1,string)
        minnum=""
        if ( iargc().ge.3 ) call getarg(2,minnum)
        if ( iargc().eq.1 .or. minnum(1:3).eq.'min' .or.
     +       minnum(1:4).eq.'elev' ) then
!           is it a station ID?  I demand 11 letters, no spaces
!           and at least 1 digit
            if ( iargc().eq.1 .and. len_trim(string).eq.11 .and.
     +           index(string(1:11),' ').eq.0 .and. (
     +           index(string,'0').ne.0 .or. index(string,'1').ne.0 .or.
     +           index(string,'2').ne.0 .or. index(string,'3').ne.0 .or.
     +           index(string,'4').ne.0 .or. index(string,'5').ne.0 .or.
     +           index(string,'6').ne.0 .or. index(string,'7').ne.0 .or.
     +           index(string,'8').ne.0 .or. index(string,'9').ne.0 ) )
     +           then
                station = string
                n = 1
            else
                sname = string
                station = '-1'
                do i=1,len_trim(sname)
                    if ( sname(i:i).eq.'+' ) sname(i:i) = ' '
                    if ( sname(i:i).eq.'_' ) sname(i:i) = ' '
                enddo
                print *,'Looking for stations with substring '
     +                ,trim(sname)
                n = 0
                if ( iargc().gt.1 ) then
                    narg = 2
                end if
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
                list(nlist) = string
            endif
            goto 10
   20       continue                
            n = 2
            station = '-1'
            if ( nlist.eq.0 ) then
                print *,'could not locate any stations'
                stop
            endif
        else
            station = '-2'
            n = 10
            call getarg(1,string)
            i = index(string,':')
            if ( i.eq.0 ) i = 1 + len_trim(string)
            read(string(:i-1),*,err=900) slat
            if ( slat.lt. -90 .or. slat.gt.90 ) goto 900
            if ( i.ne.1+len_trim(string) ) then
                read(string(i+1:),*,err=900) slat1
                n = 0
            else
                station = '-1'
            endif
            call getarg(2,string)
            i = index(string,':')
            if ( i.eq.0 ) i = 1 + len_trim(string)
            read(string(:i-1),*,err=901) slon
            if ( slon.gt.180 ) slon = slon-360
            if ( slon.lt.-180 .or. slon.gt.180 ) goto 901
            if ( i.ne.1+len_trim(string) ) then
                read(string(i+1:),*,err=901) slon1
                if ( slon1.gt.180 ) slon1 = slon1-360
                if ( slon1.lt.-180 .or. slon1.gt.180 ) goto 901
                if ( abs(slon-slon1).lt.1e-3 ) then
                    slon = -180
                    slon1 = 180
                endif
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
                        call exit(-1)
                    endif
                    narg = 4
                else
                    narg = 3
                endif
            end if
        end if
        i = narg
 100    continue
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
                    call exit(-1)
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
                    call exit(-1)
                endif
                if ( lsum.gt.4 .or. lsum.lt.1 ) then
                    write(0,*) 'error: 0 <= sum <= 4: ',lsum
                    write(*,*) 'error: 0 <= sum <= 4: ',lsum
                    call exit(-1)
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
            elseif ( index(string,'qc').ne.0 ) then
                call getarg(i+1,qcflag)
            else
                print *,'error: unrecognized argument: ',string
                call exit(-1)
            endif
            i = i+2
            goto 100
        endif
!
        if ( n.gt.1 ) print '(a,i4,a)','Looking up ',n,' stations'
        if ( n.gt.1 .or. slat1.lt.1e33 ) then
            if ( slat1.gt.1e33 ) then
                print '(a,f6.2,a,f7.2,2a)'
     +               ,'Searching for stations near ',slat,'N, '
     +               ,slon,'E'
            else
                print '(a,f6.2,a,f6.2,a,f7.2,a,f7.2,2a)'
     +               ,'Searching for stations in ',slat,'N:',slat1,
     +               'N, ',slon,'E:',slon1,
     +               'E'
            endif
            if ( elevmin.gt.-1e33 ) then
                print '(a,f8.2,a)'
     +               ,'Searching for stations higher than ',elevmin
     +               ,'m'
            endif
            if ( elevmax.lt.+1e33 ) then
                print '(a,f8.2,a)'
     +               ,'Searching for stations lower than ',elevmax
     +               ,'m'
            endif
            if ( mon.eq.-1 ) then
                if ( nmin(0).gt.0 ) print '(a,i4,a)',
     +               'Requiring at least ',nmin(0),
     +               ' years with data'
            elseif ( mon.eq.0 ) then
                if ( lsum.eq.1 ) then
                    print '(a,i4,a)','Requiring at least ',
     +                   nmin(1),' years with data in all months'
                else
                    print '(a,i4,a,i1,a)','Requiring at least ',
     +                   nmin(1+(lsum-1)*12),
     +                   ' years with data in all ',lsum
     +                   ,'-month seasons'
                endif
            elseif ( mon.gt.0 ) then
                if ( lsum.eq.1 ) then
                    print '(a,i4,2a)','Requiring at least ',
     +                   nmin(mon),' years with data in '
     +                   ,months(mon)
                else
                    print '(a,i4,4a)','Requiring at least ',
     +                   nmin(mon+(lsum-1)*12),
     +                   ' years with data in ',months(mon),'-',
     +                   months(1+mod(mon+lsum-2,12))
                endif
            endif
            if ( rmin.gt.0 ) then
                print '(a,f8.2,a)','Requiring at least ',rmin
     +               ,' degrees of separation'
            endif
        endif

        goto 999
  900   print *,'please give latitude in degrees N, not ',string
        call exit(-1)
  901   print *,'please give longitude in degrees E, not ',string
        call exit(-1)
  903   print *,'please give number of stations to find, not ',string
        call exit(-1)
  904   print *,'please give inimum number of years, not ',string
        call exit(-1)
  905   print *,'please give range on both longitude and latitude'
        call exit(-1)
  906   print *,'please give minimum distance between stations, ',string
        call exit(-1)
  907   print *,'please give minimum elevation of station, ',string
        call exit(-1)
  908   print *,'please give maximum elevation of station, ',string
        call exit(-1)
  999   continue
        end
*  #] getgetargs:
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
*  #[ llen:
        integer function llen(a)
        character*(*) a
        do 10 i=len(a),1,-1
            if(a(i:i).ne.'?' .and. a(i:i).ne.' ')goto 20
   10   continue
        llen=len(a)
   20   continue
        llen = i
        end
*  #] llen:
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
            write(0,*) 'NSTACK too small in indexx'
            call exit(-1)
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
        subroutine mysystem(string,retval)
        implicit none
        integer retval
        character*(*) string
#ifdef __linux
*       pgf90, but possibly more
        integer system
        retval = system(string)
#else
*       curiously, g95 does not define __linux...
        call system(string,retval)
#endif
        end
