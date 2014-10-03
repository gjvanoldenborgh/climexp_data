        program patchprecip
*
*       patches the NCDC precip datafile and support.f, adding the KNMI KD data
*       for 1991-now.
*
        implicit none
        integer nknmi
        parameter(nknmi=5)
        integer i,nout,yr,mo,istation,ii,knmistation(nknmi,2),
     +        iprec(12),istat
        real prec(12)
        character line*74,file*8
        data knmistation /27437,27438,27439,27443,27445,
     +                      235,  260,  280,  310,  380/
*                         Helder,Bilt,Eelde,Vliss,Maast.
*
        open(1,file='../NCDCData/v2.precip.beta.data',status='old')
        open(2,file='../NCDCData/v2.precip.beta.data.new',status='new')
        nout = 0
*
  100   continue
        read(1,'(a)',err=900,end=800) line
        read(line,'(i7,i2,i5)') istation,ii,yr
        do istat=1,nknmi
            if ( istation.eq.knmistation(istat,1) ) goto 110
        enddo
*
*       not a KNMI station
        goto 700
*
*       KNMI station
  110   continue
*       copy records up to 1990
        if ( yr.le.1990 ) goto 700
*       insert KNMI records after this
        print *,'Inserting KNMI data for station ',knmistation(istat,2)
        write(file,'(a,i3.3,a)') 'p',knmistation(istat,2),'.dat'
        open(3,file=file,status='old')
        do i=1,5
            read(3,'(a)')
        enddo
  200   continue
        read(3,*,end=300,err=901) yr,prec
        if ( yr.gt.1990 ) then
            do i=1,12
                iprec(i) = nint(10*prec(i))
            enddo
            nout = nout + 1
            write(2,'(i7,i2,i5,12i5)') istation,ii,yr,iprec
        endif
        goto 200
  300   continue
        close(3)
*       skip remaining records in GHCN database
  400   continue
        read(1,'(a)',err=900,end=800) line
        read(line,'(i7)') istation
        if ( istation.eq.knmistation(istat,1) ) goto 400
*
*       put TWENTHE (27440) before HOOFDDORP (27441)
        if ( istation.eq.27441 ) then
            print *,'Inserting KNMI data for station ',290
            istation = 27440
            open(3,file='p290.dat',status='old')
            do i=1,5
                read(3,'(a)')
            enddo
  500       continue
            read(3,*,end=600,err=901) yr,prec
            do i=1,12
                iprec(i) = nint(10*prec(i))
            enddo
            nout = nout + 1
            write(2,'(i7,i2,i5,12i5)') istation,ii,yr,iprec
            goto 500
  600       continue
            close(3)
        endif
*
*       write line to output
  700   continue
        nout = nout + 1
        write(2,'(a)') line
        goto 100
  800   continue
*       
*       patch support.f
        print *,'wrote ',nout,' records, update nrecprcp in support.f'
        stop
*
*       errors
*
  900   print *,'error reading input'
        print *,line
  901   print *,'error reading from ',file
        end
