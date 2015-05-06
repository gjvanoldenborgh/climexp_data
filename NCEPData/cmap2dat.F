        program txt2bin
c       program     :     example.f  
c       objective   :     to read the monthly CMAP data for 1998    
c       and convert to GrADS .dat files
c 
        implicit none
#include "recfac.h"
        integer i,j,ii,jj,kyr,kmn,yr,mn,nrec,iret,iu
        real*4 rain1(144,72),rain2(144,72),error1(144,72),error2(144,72)
     +        ,rlat,rlon
        character file*255,file1*255,var*10,lvar*40,command*1023
        logical lexist
c
c     1.  to open the data file 
c       
        open(12,file='cmap.dat',access='direct',recl=144*72*recfa4)
        open(22,file='cmaperr.dat',access='direct',recl=144*72*recfa4)
        open(13,file='cmapm.dat',access='direct',recl=144*72*recfa4)
        open(23,file='cmapmerr.dat',access='direct',recl=144*72*recfa4)
        nrec = 0
        call getarg(1,file1)
        do yr=1979,2020
            write(file,'(a,i2.2,a)') file1(1:15),mod(yr,100)
     +            ,'.txt'
            !!!print *,'looking for ',trim(file)
            inquire(file=trim(file),exist=lexist)
            if ( .not.lexist ) then
                command = 'gunzip -c '//trim(file)//'.gz > '//trim(file)
                print *,trim(command)
                call mysystem(trim(command),iret)
                if ( iret.ne.0 ) goto 900
                inquire(file=trim(file),exist=lexist)
                if ( .not.lexist ) goto 900
            endif
            open(unit=1,file=trim(file),status='old')
c
c     2.  to read the data 
c 
            do mn=1,12    
                do jj=1,72 
                    do ii=1,144 
 2901                   format  (2i4,2f8.2,4f8.2) 
                        read  (1,2901,end=800)  kyr,kmn,rlat,rlon, 
     #                        rain1(ii,jj),error1(ii,jj), 
     #                        rain2(ii,jj),error2(ii,jj) 
                        if ( mod(yr,100).ne.mod(kyr,100) .or. mn.ne.kmn
     +                        ) then
                            print *,'error: year,month not consistent: '
     +                            ,yr,kyr,mn,kmn
                            stop
                        endif
                        if ( abs(rlat+88.75-2.5*(jj-1)).gt.0.01 ) then
                            print *,'error: latitude not correct: ',rlat
     +                            ,-88.75+2.5*(jj-1)
                            stop
                        endif
                        if ( abs(rlon-1.25-2.5*(ii-1)).gt.0.01 ) then
                            print *,'error: longitude not correct: '
     +                            ,rlon,1.25+2.5*(ii-1)
                            stop
                        endif
                    enddo
                enddo
                nrec = nrec + 1
*               go for the model-independent one
                write(12,rec=nrec) rain2
                write(22,rec=nrec) error2
                write(13,rec=nrec) rain1
                write(23,rec=nrec) error1
            enddo
 800        continue
            close(1)
c
        enddo
 900    continue
        print *,'wrote ',nrec,' records'
        close(12)
        close(13)
        close(22)
        close(23)
        open(12,file='cmap.ctl')
        open(22,file='cmaperr.ctl')
        open(13,file='cmapm.ctl')
        open(23,file='cmapmerr.ctl')
        do i=1,2
            do j=2,3
                iu=10*i+j
                if ( iu.eq.12 ) then
                    write(iu,'(a)') 'DSET ^cmap.dat'
                    var = 'prec'
                    lvar = 'precipitation [mm/dy]'
                elseif ( iu.eq.22 ) then
                    write(22,'(a)') 'DSET ^cmaperr.dat'
                    var = 'rel_err'
                    lvar = 'relative error on precipitation'
                elseif ( iu.eq.13 ) then
                    write(13,'(a)') 'DSET ^cmapm.dat'
                    var = 'prec'
                    lvar = 'precipitation (incl model) [mm/dy]'
                elseif ( iu.eq.23 ) then
                    write(23,'(a)') 'DSET ^cmapmerr.dat'
                    var = 'rel_err'
                    lvar =
     +                   'relative error on precipitation (incl model)'
                else
                    write(0,*) 'error: ',iu
                    call abort
                endif
                write(iu,'(a)')
     +               'TITLE CPC Merged Analysis of Precipitation'
                write(iu,'(a)') 'UNDEF -999'
                write(iu,'(a)') 'OPTIONS LITTLE_ENDIAN'
                write(iu,'(a)') 'XDEF 144 LINEAR   1.25 2.5'
                write(iu,'(a)') 'YDEF  72 LINEAR -88.75 2.5'
                write(iu,'(a)') 'ZDEF 1 LINEAR 0 1'
                write(iu,'(a,i3,a)') 'TDEF ',nrec
     +               ,' LINEAR 15JAN1979 1MO'
                write(iu,'(a)') 'VARS 1'
                write(iu,'(3a)') var,' 1 99 ',lvar
                write(iu,'(a)') 'ENDVARS'
            enddo
        enddo
        end
