        program patchtemp
*
*       patches the NCDC temp datafile and support.f, adding the KNMI KD data
*
        implicit none
        integer nknmi
        parameter(nknmi=6)
        integer i,nout,yr,mo,istation,ii,knmistation(nknmi),
     +        itemp(12),istat
        real temp(12)
        logical done
        character line*76,file*8
        data knmistation /  235,  260,  280,  290,  310,  380/
*                         Helder,Bilt,Eelde,Twent,Vliss,Maast.
*
        open(1,file='../NCDCData/v2.mean_adj_nodup',status='old')
        open(2,file='../NCDCData/v2.mean_adj_nodup.new',status='new')
        nout = 0
        done = .FALSE.
*
  100   continue
        read(1,'(a)',err=900,end=800) line
        read(line,'(i9)') istation
        if ( done .or. istation.lt.633060000+10*knmistation(1) ) goto
     +        700
*
*       insert KNMI station
*
        do istat=1,6
            print*,'Inserting KNMI data for station ',knmistation(istat)
            write(file,'(a,i3.3,a)') 't',knmistation(istat),'.dat'
            open(3,file=file,status='old')
            do i=1,5
                read(3,'(a)')
            enddo
  500       continue
            read(3,*,end=600,err=901) yr,temp
            do i=1,12
                itemp(i) = nint(10*temp(i))
            enddo
            nout = nout + 1
            write(2,'(i8,i3.3,i1,i4,12i5)') 63306000+knmistation(istat)
     +            ,0,0,yr,itemp
            goto 500
  600       continue
            close(3)
        enddo
        done = .TRUE.
*
*       write line to output, skipping the original data
  700   continue
        do istat=1,6
            if ( istation.eq.633060000+10*knmistation(istat) ) goto 100
        enddo
        nout = nout + 1
        write(2,'(a)') line
        goto 100
  800   continue
*       
*       patch support.f
        print *,'wrote ',nout,' records, update nrectemp in support.f'
        stop
*
*       errors
*
  900   print *,'error reading input'
        print *,line
  901   print *,'error reading from ',file
        end
