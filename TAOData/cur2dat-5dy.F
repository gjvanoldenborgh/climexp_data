        program cur2dat
*
*       convert TAO current meter data into a GrADS file,
*       based on the PMEL cm_read.f
*       
c       This program reads TAO anonymous FTP ascii format current meter
c       mooring files, for example 110w.velocity . It creates real time 
c       series arrays which are evenly spaced in time. 
c
c       Current meter mooring files may have several sections of
c	data, each with its own set of header records.  Each section may
c	have data several variables at one depth (eg. u and v currents
c	at 100 meters depth) or one variable at several depths (eg. 
c	temperature at 10, 30, 50, 100... meters depth). Velocity files
c	typically have a section for wind data and then a section for
c	the depth of each current meter.  Temperature files will have
c	more than one section if the number of temperature sensor depths
c	exceeds 12. 
c
c	IMPORTANT NOTE!  This program overwrites output data arrays
c	and decoded header info each time a new set of headers are 
c	encountered.  The user must save (ie., write to an output
c	file or save in a different array) these data before processing
c	a new set of headers!  Suggested place to do so is indicated
c	below.
c       Programmed by Paul Freitag, NOAA/PMEL/OCRD, January 1996
c
        implicit none
#include "recfac.h"
        integer nt,maxt,maxv
        parameter(nt=1600, maxv=12, maxt=10000)
        integer nlon, nlat, nz, firstyear, lastyear
        parameter(nlon=19, nlat=10, nz=42, firstyear=1980
     +        ,lastyear=2000)
c
        integer i,j,k,ilon,ihead,ii,i1,i2,idep,ivar,itime,id,iv,it,yr,mn
     +        ,dy,iuv,nrec,iwrite,maxnt
        integer idate(5),ldate(5)
        real x(maxt,maxv),ydep(maxv),tdel,t(nz)
        real*4 duv(nz,31,12,firstyear:lastyear,2)
        real*4 uv(nt,nz,1,nlon,2)
        real*4 mx(nz,12,firstyear:lastyear)
        character*80 infile, header,varnam*50,tunit*8
        character*40 formin,formout
        character*1 ew
        character*80 string
        logical lexist, lintdep, lintlatlon
*       
        integer llen,isleap,iargc
        external llen,isleap,iargc
*       
#include "grid.h"
c
c .......................................................................
c       
        iwrite = 0
*       process arguments
        if ( iargc().gt.0 ) then
            lintdep = .FALSE.
            lintlatlon = .FALSE.
            do i=1,iargc()
                call getarg(i,string)
                if ( string(1:3).eq.'dep' ) then
                    lintdep = .TRUE.
                elseif ( string(1:5).eq.'nodep' ) then
                    lintdep = .FALSE.
                elseif ( string(1:6).eq.'latlon' ) then
                    lintlatlon = .TRUE.
                elseif ( string(1:8).eq.'nolatlon' ) then
                    lintlatlon = .FALSE.
                else
                    print *,'tao2dat: unrecognized argument'
     +                    ,string(1:index(string,' ')-1)
                    stop
                endif
            enddo               ! loop over args
        else                    ! no args, defaults
            lintdep = .TRUE.
            lintlatlon = .TRUE.
        endif
*       
*       loop over longitudes (all on the equator)
*
        do ilon=1,nlon
            i=lons(ilon)
            if ( i.eq.235 ) i = 236
            if ( i.gt.180 ) then
                ew = 'w'
                i = 360-i
            else
                ew = 'e'
            endif
            if ( i.ge.100 ) then
                write(infile,'(i3,a,a)') i,ew,'.velocity'
            else
                write(infile,'(i2,a,a)') i,ew,'.velocity'
            endif
            inquire(file=infile,exist=lexist)
            if ( .not.lexist ) then
                print *,'file ',infile(1:index(infile,' ')-1)
     +                ,' does not exist'
                do k=1,nz
                    do i=1,nt
                        uv(i,k,1,ilon,1) = 3e33
                        uv(i,k,1,ilon,2) = 3e33
                    enddo
                enddo
                goto 801
            endif
            print *,'Opening file ',infile(:llen(infile))
            open(1,file=infile,status='old',form='formatted')
*            
*       put daily array to undefined
*
            do iuv=1,2
                do k = 1,nz
                    do yr=firstyear,lastyear
                        do mn=1,12
                            do dy=1,31
                                duv(k,dy,mn,yr,iuv) = 3e33
                            enddo
                        enddo
                    enddo
                enddo
            enddo
c 
c       Read headers
c
  100       write(6,101)
  101       format(//' Header Records')
            do ihead=1,4
                read(1,110,end=800) header
  110           format(a)
                write(6,110) header
c       header1
                if( ihead.eq.1 ) then
                    varnam=' '
                    ii=index(header,'Time interval =')
                    if ( ii.eq.0 ) goto 800
                    read (header(ii+15:),111,err=900) tdel,tunit,itime
  111               format(f6.1,a,2x,i5)
                    i1 = index(header,'Depth')
                    i2 = index(header,'Height')
                    if(i1+i2.eq.0) then
                        idep=0
                        ivar=1
                        varnam(1:15)=header(19:)
                    else
                        idep=1
                        if(i1.gt.0)read(header(28:32),*,err=900) ydep(1)
                        if(i2.gt.0)read(header(29:32),*,err=900) ydep(1)
                    endif
c       header2
                elseif(ihead.eq.2) then
                    if(idep.eq.0) then
                        read(header,*,err=900) idep
                        ii=index(header,':')
                        read(header(ii+1:),*,err=900) (ydep(i),i=1,idep)
                    else
                        read(header,*,err=900) ivar
                        ii=index(header,':')
                        read(header(ii+1:),110,err=900) varnam
                    endif
                elseif(ihead.eq.3) then
                    read(header,121,err=900) idate,ldate
  121               format(14x,2i2,1x,3i3,32x,2i2,1x,3i3)
                elseif(ihead.eq.4) then
                    formin=header(11:50) 
                    ii=index(formin,',i5)')
                    if(ii.eq.0) go to 900
                    formin(ii:)=')'
                endif
            enddo
c
c       show the decoded header info
c       
            write(6,201) itime,tdel,tunit,idate,ldate
  201       format(/1x,i5,' time steps of ',f5.1,a/
     1            1x,'From ',2i2,1x,3i2,', to ',2i2,1x,3i2)
            write(6,202) idep,(ydep(id),id=1,idep)
  202       format(/1x,i2,' depths: ',12f6.1)
            write(6,203) ivar,varnam
  203       format(/1x,i2,' variables: ',a)
c       
c       Read the data.
c       
            if (idep.gt.ivar) then
                read(1,formin) ((x(it,id),id=1,idep),it=1,itime)
            else
                read(1,formin) ((x(it,iv),iv=1,ivar),it=1,itime)
            endif
c       
c       write out the first and last 5 time steps
c       
            if ( .false. ) then
                write(formout,301) max0(idep,ivar)
  301           format('(1x,',i2,'f7.2)')
                write(6,302)
  302           format(/1x,'First 5 time steps')
                if(idep.gt.ivar) then
                    write(6,formout) ((x(it,id),id=1,idep),it=1,5)
                    write(6,303)
  303               format(/1x,'Last 5 time steps')
                    write(6,formout) ((x(it,id),id=1,idep),it=itime-4
     +                    ,itime)
                else
                    write(6,formout) ((x(it,iv),iv=1,ivar),it=1,5)
                    write(6,303)
                    write(6,formout) ((x(it,iv),iv=1,ivar),it=itime-4
     +                    ,itime)
                endif
            endif
*       
*       put in big array
*       
            if ( ivar.ne.2 ) then
                print *,'expecting 2 variables (u,v), found ',ivar
                call abort
            endif
            do id=1,idep
*       skip wind
                if ( ydep(id).lt.0 ) goto 499
                do k=1,nz
                    if ( deps(k).eq.nint(ydep(id)) ) then
                        goto 401
                    endif
                enddo
                print *,'error: could not locate depth ',id,ydep(id)
     +                ,' in ',deps
                call abort
  401           continue
                yr = idate(5)
                if ( yr.lt.100 ) then
                    if ( yr.gt.50 ) then
                        yr = yr + 1900
                    else
                        yr = yr + 2000
                    endif
                endif
                mn = idate(4)
                dy = idate(3) - 1
 9402           format(a,i3,'E,',i3,'m from ',i4,2i2.2,' to ',i4,2i2.2)
                print 9402,'Found data at ',lons(ilon),deps(k),yr,mn,dy
     +                +1,1900+ldate(5),ldate(4),ldate(3)
                do it=1,itime
                    dy = dy + 1
                    call canontime(yr,mn,dy)
                    do iuv=1,2
                        if ( x(it,1).gt.-999 ) then
                            duv(k,dy,mn,yr,iuv) = x(it,iuv)
                        else
                            duv(k,dy,mn,yr,iuv) = 3e33
                        endif
                    enddo
                enddo
                if ( mod(yr,100).ne.ldate(5) .or. mn.ne.ldate(4) .or. 
     +                dy.ne.ldate(3) ) then
                    print *,'error: final date deos not agree: ',yr,mn
     +                    ,dy,ldate
                    call abort
                endif
  499           continue
            enddo
*       next header
            goto 100
  800       close(1)
*       
*       process this vertical profile (one file)
*       
            do iuv=1,2
                call day2month(duv(1,1,1,firstyear,iuv),
     +                mx(1,1,firstyear),nz,firstyear
     +                ,lastyear,0)
                call day2five(duv(1,1,1,firstyear,iuv),
     +                uv(1,1,1,ilon,iuv),nt,maxnt,nz,firstyear
     +                ,lastyear,iwrite)
                if ( iwrite.ge.0 ) print *,'maxnt = ',maxnt
                if ( lintdep ) then
                    do i=1,maxnt
                        do k=1,nz
                            t(k) = uv(i,k,1,ilon,iuv)
                        enddo
                        call depint(t,deps,nz,0)
                        do k=1,nz
                            uv(i,k,1,ilon,iuv) = t(k)
                        enddo
                    enddo       ! 5-day intervals
                endif
            enddo               ! u,v
*       
*       next longitude
*
  801       continue
        enddo                   ! ilon
        if ( lintlatlon ) then
            do iuv=1,2
                call latlonint(uv(1,1,1,1,iuv),nz*nt,1,nlon,0,lons
     +                ,iwrite,-200.,+200.)
            enddo
        endif
c
c       Write out the temperature array to a grads file
c       
*       open output file
        if ( iwrite.ge.0 ) print *,'Opening output file tao_cur.dat'
        open(2,file='tao_cur-5dy.dat',form='unformatted',
     +        access='direct',recl=recfa4*2*nlon*nz)
        nrec = 0
        do i=1,73*(lastyear-firstyear+1)
            write(2,rec=i) (((uv(i,k,1,ilon,iuv),ilon=1,nlon),k=1,nz)
     +            ,iuv=1,2)
        enddo
        stop
c       
  900   write(6,901)
  901   format(' Header format error')
        end
        
        integer function isleap(yr)
        implicit none
        integer yr
        if ( mod(yr,4).eq.0 .and. 
     +        ( mod(yr,100).ne.0 .or. mod(yr,400).eq.0 ) ) then
            isleap = 2
        else
            isleap = 1
        endif
        end
        
        subroutine canontime(yr,mn,dy)
        implicit none
        integer yr,mn,dy
        integer dpm(12,2)
        logical dirty
        integer isleap
        external isleep
        data dpm
     +        /31,28,31,30,31,30,31,31,30,31,30,31
     +        ,31,29,31,30,31,30,31,31,30,31,30,31/
*       
  100   continue
        dirty = .FALSE.
        if ( mn.gt.12 ) then
            mn = mn - 12
            yr = yr + 1
            dirty = .TRUE.
        endif
        if ( mn.lt.0 ) then
            mn = mn + 12
            yr = yr - 1
            dirty = .TRUE.
        endif
        if ( dirty ) goto 100
        if ( dy.gt.dpm(mn,isleap(yr)) ) then
            dy = dy - dpm(mn,isleap(yr))
            mn = mn + 1
            dirty = .TRUE.
        endif
        if ( dy.lt.0 ) then
            mn = mn - 1
            dy = dy + dpm(mn,isleap(yr))
            dirty = .TRUE.
        endif
        if ( dirty ) goto 100
        end
