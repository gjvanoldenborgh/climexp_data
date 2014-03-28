        program makeyeartempindex
*
*       update the index file v2.precip.beta.inv with the number of years
*       of data in from with v2.precip.beta.data
*
*       Geert Jan van Oldenborgh, KNMI, 1999-2000
*
        implicit none
        integer ic,iwmo,imod,ielevs,ielevg,ipop,iloc,itowndis,nyr(0:48)
     +        ,nyrmin(0:48),nyrmax(0:48),nyrall(0:48)
     +        ,nyrminall(0:48),nyrmaxall(0:48)
        real rlat,rlon
        character name*30,pop*1,topo*2,stveg*2,stloc*2,airstn*1,
     +        grveg*16
*
        print '(a)','Opening files'
        open(1,file='v2.temperature.inv',status='old')
        open(20,file='v2.mean_adj_nodup',status='old',form='formatted',
     +        access='direct',recl=77)
        open(21,file='v2.min_adj',status='old',form='formatted',
     +        access='direct',recl=77)
        open(22,file='v2.max_adj',status='old',form='formatted',
     +        access='direct',recl=77)
        open(30,file='v2.mean_nodup',status='old',form='formatted',
     +        access='direct',recl=77)
        open(31,file='v2.min',status='old',form='formatted',
     +        access='direct',recl=77)
        open(32,file='v2.max',status='old',form='formatted',
     +        access='direct',recl=77)
        open(3,file='v2.temperature_adj.inv.withmonth',status='new')
        open(4,file='v2.temperature.inv.withmonth',status='new')
*
  100   continue
        read(1,1000,end=200) ic,iwmo,imod,name,rlat
     +        ,rlon,ielevs,ielevg,pop,ipop,topo
     +        ,stveg,stloc,iloc,airstn,itowndis,grveg
 1000   format(i3.3,i5.5,i3.3,1x,a30,1x,f6.2,1x,f7.2,1x,i4,
     +        1x,i4,a1,i5,3(a2),i2,a1,i2,a16)
        call getdata('temp',20,100000*ic+iwmo,imod,0,nyr,
     +        NREC_MEAN_ADJ,NSTAT_MEAN_ADJ,0,3000)
        call getdata('tmin',21,100000*ic+iwmo,imod,0,nyrmin,
     +        NREC_MIN_ADJ,NSTAT_MIN_ADJ,0,3000)
        call getdata('tmax',22,100000*ic+iwmo,imod,0,nyrmax,
     +        NREC_MAX_ADJ,NSTAT_MAX_ADJ,0,3000)
        call getdata('tempall',30,100000*ic+iwmo,imod,0,nyrall,
     +        NREC_MEAN_ALL,NSTAT_MEAN_ALL,0,3000)
        call getdata('tminall',31,100000*ic+iwmo,imod,0,nyrminall,
     +        NREC_MIN_ALL,NSTAT_MIN_ALL,0,3000)
        call getdata('tmaxall',32,100000*ic+iwmo,imod,0,nyrmaxall,
     +        NREC_MAX_ALL,NSTAT_MAX_ALL,0,3000)
        write(3,1001) ic,iwmo,imod,name,rlat
     +        ,rlon,ielevs,ielevg,pop,ipop,topo
     +        ,stveg,stloc,iloc,airstn,itowndis,grveg,nyr,nyrmin,nyrmax
        write(4,1001) ic,iwmo,imod,name,rlat
     +        ,rlon,ielevs,ielevg,pop,ipop,topo
     +        ,stveg,stloc,iloc,airstn,itowndis,grveg,nyrall,nyrminall
     +        ,nyrmaxall
 1001   format(i3.3,i5.5,i3.3,' ',a30,' ',f6.2,' ',f7.2,' ',i4,
     +        ' ',i4,a1,i5,3(a2),i2,a1,i2,a16,147i4)
        goto 100
  200   continue
        close(1)
        close(2)
        close(3)
        end
