        program stationsperyear
!
!       estimate the number of sttaions per year in the CRU dataset
!       by tracking them in the GHCN dataset
!
        implicit none
        integer yrbeg,yrend
        parameter (yrbeg=1700,yrend=2020)
        integer nstations(yrbeg:yrend),id,idsub,yr1,yr2,lon,lat,lev
        character name*40

        open(1,file='crustnsused.txt',status='old')
 100    continue
        read(1,'(i7,i5,i6,i6,a)') id,lat,lon,lev,name
        idsub = mod(id,10)
        id = id/10
        
