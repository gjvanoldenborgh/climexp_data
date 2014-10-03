        program makeindex
*
*       make an index on the RivDis database.
*       As obtained, this consists of a directory per country with
*       subdirectories per station, with two files site.txt and data.txt
*       (meta)data.  I therefore have the exact opposite problem as with 
*       the GHCN database: not retrieving is the problem, but searching.
*       I therefore make an index on this database with this program.
*       (Should be doing this in perl).
*
        implicit none
        integer i,j,yr,firstyr,lastyr,nyr,station,ielev,area
        real lat,lon,data(12)
        character file*255,country*20,cstation*20,line*80,river*20
        integer llen
        external llen
*
*       loop over all stations
*
        call system('find data -name site.txt -print > stationlist')
        open(1,file='stationlist',status='old')
  100   continue
        read(1,'(a)',end=900) file
        open(2,file=file,status='old')
        lat = -9999
        lon = -9999
        station = -9999
        river = '????????????????????????????????????'
  200   continue
        read(2,'(a)',end=300) line
        i = index(line,':')
        if ( line(:i).eq.'Latitude:' ) then
            read(line(i+2:),*) lat
        elseif ( line(:i).eq.'Longitude:' ) then
            read(line(i+2:),*) lon
        elseif ( line(:i).eq.'Elevation:' ) then
	    if ( line(i+2:i+5).eq.'N/A' ) then
		ielev = -9999
	    else
            	read(line(i+2:),*) ielev
	    endif
        elseif ( line(:i).eq.'Upstream Area:' ) then
            read(line(i+2:),*) area
        elseif ( line(:i).eq.'Point ID:' ) then
            read(line(i+2:),*) station
        elseif ( line(:i).eq.'Country:' ) then
            country = line(i+2:)
        elseif ( line(:i).eq.'Station:' ) then
            cstation = line(i+2:)
        elseif ( line(:i).eq.'River:' ) then
            river = line(i+2:)
        endif
        goto 200
  300   continue
        firstyr = 9999
        lastyr = -9999
        nyr = 0
        i = index(file,'site.txt')
        file(i:) = 'data.txt'
        open(2,file=file,status='old')
        read(2,'(a)') line
  400   continue
        read(2,*,end=500) i,yr,data
        if ( i.ne.station ) goto 901
        do j=1,12
            if ( data(j).ne.-9999 ) goto 410
        enddo
        goto 400
  410   continue
        nyr = nyr + 1
        firstyr = min(yr,firstyr)
        lastyr = max(yr,lastyr)
        goto 400
  500   continue
*
 1000   format(i5.5,2f8.2,i6,i8,3i5,x,a,x,a,x,a)
        print 1000,station,lat,lon,ielev,area,firstyr,lastyr,nyr,country
     +        ,cstation,river
        goto 100                ! next station
  900   continue
*
*       error messages
*
        goto 999
  901   write(0,*) 'error: wrong station ID: ',station,i,' in ',file
*
  999   continue
        end
