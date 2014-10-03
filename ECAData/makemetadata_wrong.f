        program makemetadata
*
*       get ECA stations near a given coordinate, or with a given name,
*       or the data
*
        implicit none
        integer nn
        parameter(nn=2000)
        double precision pi
        parameter (pi = 3.1415926535897932384626433832795d0)
        integer i,j,k,jj,kk,n,ldir,istation,nmin(0:48),yr,nok,nlist
     +        ,ilat(3),ilon(3),idates(2),iecdold,yr1,yr2
        integer iwmo(nn),iecd(nn),firstyr(nn),lastyr(nn),nyr(nn),ind(nn)
     +       ,list(nn),tmin,tmax,temp,prcp,mo,dy,ielev
        real rlat(nn),rlon(nn),slat,slon,slat1,slon1,dist(nn),dlon
     +        ,rmin,elevmin,elevmax,rlonmin,rlonmax,rlatmin
     +        ,rlatmax,val,elev(nn)
        logical blend
        character name(nn)*40,country(nn)*40,pmlon*1,pmlat*1,gsn(nn)*3
     +       ,el*3,elem*40,element*2,elin*2,wmo*6
        character string*200,line*500,sname*25
        character datfile*25
        integer iargc,llen,system,rindex
        external iargc,getarg,llen,system,rindex
! 01- 05 LOCID  : Location identifier (see file location.txt for more info.)
! 07- 12 SOUID  : Source identifier
! 14- 53 SOUNAME: Source name
! 55- 56 CN     : Country code (ISO3116 country codes)
! 58- 66 LAT    : Latitude in degrees:minutes:seconds (+: North, -: South)
! 68- 76 LON    : Longitude in degrees:minutes:seconds (+: East, -: West)
! 78- 81 HGTH   : Height in meters
! 83- 86 ELEI   : Element detail identifier (see website at Daily Data, Data dictionary)
! 88- 95 START  : Start date YYYYMMDD
! 97-104 STOP   : Stop date YYYYMMDD
!106-110 PARID  : Participant identifier
!112-162 PARNAME: Participant name
        if ( iargc().ne.1 ) then
            print *,'usage: makemetadata element'
            stop
        endif
        call getarg(1,element)
        write(line,'(4a)') 'ECA_blend_source_',element
     +           ,'.txt'
        open(unit=1,file=line,status='old')
        write(line,'(4a)') 'ECA_source_',element
     +           ,'.txt'
        open(unit=2,file=line)

*       skip headers
 10     continue
        read(1,'(a)') line
        write(2,'(a)') line(1:llen(line))
        if ( line(1:5).ne.'LOCID' ) goto 10
        read(1,'(a)') string
        if ( string.ne.' ' ) then
            print *,'ecadata: error: header has changed!'
            print *,string
        endif
        write(2,'(a)') ' '
*
        i = 1
  100   continue
        read(1,'(a)',end=200) line
        read(line(83:87),'(i5)') jj
        if ( i.gt.1 ) then
            if ( jj.eq.iecd(i-1) ) goto 100
        endif
        read(line,1000) country(i),name(i),iecd(i),wmo,
     +       gsn(i),pmlat,ilat,pmlon,ilon,ielev,el,elem,idates
 1000   format(a40,x,a40,x,i5,x,a6,x,a3,x,
     +        a1,i2,x,i2,x,i2,x,
     +        a1,i2,x,i2,x,i2,x,
     +        i4,x,a3,x,a40,x,i8,x,i8)
        write(datfile,'(2a,i3.3,a)') 'data/',element,iecd(i),'.dat.gz'
        j = system('gunzip -c '//datfile//' > /tmp/aap')
        open(3,file='/tmp/aap',status='old')
        do j=1,5
            read(3,'(a)',end=100) string
        enddo
        read(3,*,end=100) yr1
 110    continue
        read(3,*,end=120) yr2
        goto 110
 120    continue
        close(3,status='delete')
        idates(1) = 10000*yr1 + 0101
        idates(2) = 10000*yr2 + 1231
        write(2,1001) country(i),name(i),iecd(i),wmo,
     +       gsn(i),pmlat,ilat,pmlon,ilon,ielev,el,elem,idates
 1001   format(a40,',',a40,',',i5,',',a6,',',a3,',',
     +        a1,i2,',',i2,',',i2,',',
     +        a1,i2,',',i2,',',i2,',',
     +        i4,',',a3,',',a40,',',i8,',',i8)
        goto 100
 200    continue
        close(2)
        close(1)
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
        
