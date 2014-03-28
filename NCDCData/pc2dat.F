        program pc2dat
*
*       convert Matthias PCs to Climate Explorer dat format
*
        implicit none
#include "param.inc"
        integer mo,yr,i,j,lname,yr1,mo1,neof,yr2
        real data(1:12,yrbeg:yrend,12)
        character name*256,file*128,line*128,months*36
        data months /'JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC'/

        call getarg(1,name)
        lname = index(name,' ') - 1
        write(file,'(2a)') name(1:lname),'_pc.ctl'
        open(1,name=file,status='old')
  100   continue
        read(1,'(a)',end=200) line
        if ( line(1:4).eq.'TDEF' ) then
            mo1 = index(months,line(23:25))/3 + 1
            read(line(26:29),'(i4)') yr1
            if ( line(40:43).ne.'1mo' ) then
                write(0,*)
     +                'error: cannot handle interval other than 1mo yet'
                call abort
            endif
        elseif ( line(1:4).eq.'ZDEF' ) then
            read(line(5:),*) neof
            if ( neof.gt.12 ) then
                write(0,*)
     +                'error: cannot handle neof>12 yet'
                call abort
            endif                
        endif
        goto 100
  200   continue
        close(1)

        do i=1,neof
            do yr=yrbeg,yrend
                do mo=1,12
                    data(mo,yr,i) = -999.9
                enddo
            enddo
        enddo
        write(file,'(2a)') name(1:lname),'_pc.txt'
        open(1,file=file,status='old')
        yr = yr1
        mo = mo1
  300   continue
        read(1,*,end=400) j,(data(mo,yr,i),i=1,neof)
        mo = mo + 1
        if ( mo.gt.12 ) then
            mo = mo - 12
            yr = yr + 1
        endif
        goto 300
  400   continue
        yr2 = yr
        if ( mo.eq.1 ) yr2 = yr2 - 1
        close(1)
        
        do i=1,neof
            write(file,'(a,i2.2,a)') name(1:lname),i,'.dat'
            open(1,file=file)
            write(1,'(2a)') '# generated from ',name(1:lname)
            write(1,'(a,i2)') '# PC number ',i
            write(1,'(a)') '#'
            write(1,'(a)') '#'
            write(1,'(a)') '#'
            do yr=yr1,yr2
                write(1,'(i4,12f16.8)') yr,(data(mo,yr,i),mo=1,12)
            enddo
            close(1)
        enddo

        end
