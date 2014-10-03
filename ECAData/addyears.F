        program addyears
*
*       add years with data to the inventory file
*
        implicit none
        integer nmax
        parameter (nmax=1000000)
        integer staid,i,n,years(6,nmax),yr1(2:3),yr2(2:3),nyr(2:3)
     +       ,iblend
        character file*50,line*100,string*100

        call getarg(1,string)
        write(file,'(3a)') 'ECA_blend_station_',string(1:2)
     +       ,'.txt'
        open(1,file=trim(file),status='old')
        open(2,file=trim(file)//'.withyears')
        write(file,'(3a)') 'ECA_nonblend_station_',string(1:2)
     +       ,'.txt'
        open(12,file=trim(file)//'.withyears')
        open(3,file='years_'//string(1:2)//'.txt',status='old')
        years = -9999
 1      continue
        read(3,*,err=2,end=2) staid,(yr1(iblend),yr2(iblend),nyr(iblend)
     +       ,iblend=2,3)
        if ( staid.lt.1 .or. staid.gt.nmax ) then
            write(0,*) 'addyears: error: staid = ',staid
            goto 2
        end if
        years(1,staid) = yr1(3)
        years(2,staid) = yr2(3)
        years(3,staid) = nyr(3)
        years(4,staid) = yr1(2)
        years(5,staid) = yr2(2)
        years(6,staid) = nyr(2)
        goto 1
 2      continue
        close(3)
 10     continue
        read(1,'(a)') line
        write(2,'(a)') trim(line)
        write(12,'(a)') trim(line)
        if ( line(1:5).ne.'STAID' ) goto 10
        read(1,'(a)') line
        write(2,'(a)') trim(line)
        write(12,'(a)') trim(line)
 20     continue
        read(1,'(i5,a)',end=800) staid,line
        write(2,'(i5,a,3i5)') staid,line(1:71),(years(i,staid),i=1,3)
        write(12,'(i5,a,3i5)') staid,line(1:71),(years(i,staid),i=4,6)
        goto 20
 800    continue
        close(1)
        close(2)
        close(12)
        end
