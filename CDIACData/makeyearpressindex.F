        program makeyearpressindex
*
*       update the index files press.sea.statinv and press.sta.statinv 
*       with the number of years of data in press.sea.data and press.sta.data
*
*       Geert Jan van Oldenborgh, KNMI, 1999-2000-2001
*
        implicit none
        integer ii,ielev,nyr(0:48)
        real rlat,rlon
        character name*30,country*20
*
        print '(a)','Opening files'
        open(1,file='press.sea.statinv',status='old')
        open(2,file='press.sea.data',status='old'
     +        ,form='formatted',access='direct',recl=75)
        open(3,file='press.sea.statinv.withmonth',status='new')
*
  100   continue
        read(1,1000,end=800) ii,rlat,rlon,ielev,name,country
 1000   format(i7,1x,f6.2,1x,f7.2,1x,i4,1x,a30,1x,a20)
        call getdata('prcp',2,ii,0,nyr)
        print 1001,ii,rlat,rlon,ielev,name,country,nyr
        write(3,1001) ii,rlat,rlon,ielev,name,country,nyr
 1001   format(i7,' ',f6.2,' ',f7.2,' ',i4,' ',a30,' ',a20,49i4)
        goto 100
  800   continue
        close(1)
        close(2)
        close(3)
        end
