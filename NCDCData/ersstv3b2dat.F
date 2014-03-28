        program ersstf
c     
c       To read the extended reconstructed SST.
c
        implicit none
#include "recfac.h"
        integer im,jm,yrbeg,yrend        
        parameter (im=180,jm=89,yrbeg=1854,yrend=2019)
c
c       i is longitude index (values 1 to im)
c       j is the latitude index (values 1 to jm)
c       
        integer yr,idec,iyr,mo,i,j,irec,status
        integer isst(im,jm)
c       
c       isst is the input SST array (values are degrees C times 100)
c       land value = -9999
        real ersst(12,im,jm)
c       
c       ersst is the reconstructed SST mean in degrees C
c       
        logical empty,exist
        character file*23,command*200
   81   format (90i6)
        open(3,file='ersstv3b.ctl',status='new')
        open(2,file='ersstv3b.grd',form='unformatted',access='direct',
     +        recl=im*jm*12*recfa4)
        irec = 0
c       
c       Read in the ERSST data for 1880 to 2010 (unit 11) 
c       
        do idec=yrbeg+5,yrend,10
            if ( idec.eq.1859 ) then
                i = 1854
            else
                i = idec - 9
            end if
            write(file,'(a,i4.4,a,i4.4,a)') 'ersst.',i,'.',
     +		idec,'.asc'
            print *,'opening ',file
            inquire(file=file,exist=exist)
            if ( .not.exist ) then
                command = 'gunzip -c '//trim(file)//'.gz > '//
     +               trim(file)
                call mysystem(command,status)
                if ( status.ne.0 ) then
                    write(0,*) 'error executing ',trim(command)
                    call abort
                endif
            endif
            open(1,file=file,status='old')
            do iyr=-9,0
                yr = idec + iyr
                if ( yr.lt.yrbeg ) cycle
                empty = .TRUE.
                do mo=1,12
                    do j=1,jm
                        do i=1,im
                            isst(i,j) = -9999
                        enddo
                    enddo
                    do i=1,im
                        read(1,81,end=100,err=100) (isst(i,j),j=1,jm)
                    enddo
  100               continue
                    do j=1,jm
                        do i=1,im
                            if ( isst(i,j).eq.-9999 ) then
                                ersst(mo,i,j) = 3e33
                            else
                                empty = .FALSE.
                                ersst(mo,i,j) = real(isst(i,j))/100.
                            endif
                        enddo
                    enddo
                enddo
                if ( empty ) then
                    goto 800
                endif
                irec = irec + 1
                print *,yr
                write(2,rec=irec) (((ersst(mo,i,j),i=1,im),j=1,jm),
     +                mo=1,12)
            enddo
            close(1)
        enddo
  800   continue
        print *,'wrote ',12*irec,' records'
        write(3,'(a)') 'DSET ^ersstv3b.grd'
        write(3,'(a)') 'TITLE NCDC Extended Reconstructed SST v3b'
        write(3,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(3,'(a)') 'UNDEF 3e33'
        write(3,'(a,i4,a)') 'XDEF ',im,' LINEAR 0 2'
        write(3,'(a,i4,a)') 'YDEF ',jm,' LINEAR -88 2'
        write(3,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(3,'(a,i4,a,i4.4,a)') 'TDEF ',12*irec,' LINEAR 15JAN'
     +        ,yrbeg,' 1MO'
        write(3,'(a)') 'VARS 1'
        write(3,'(a)') 'SST 1 99 Sea Surface temperature [C]'
        write(3,'(a)') 'ENDVARS'
        close(3)
        end
