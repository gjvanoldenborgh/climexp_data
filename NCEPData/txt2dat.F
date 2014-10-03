        program txt2bin
c     program     :     example.f  
c     objective   :     to read the monthly CMAP data for 1998    
c       and convert to GrADS .dat files
c 
        implicit none
#include "recfac.h"
        integer i,j,ii,jj,kyr,kmn,yr,mn,nrec
        real*4 rain1(144,72),rain2(144,72),error1(144,72),error2(144,72)
     +        ,rlat,rlon
        character file*21
c
c     1.  to open the data file 
c       
        open(12,file='cmap.dat',status='new',access='direct',
     +		recl=144*72*recfa4)
        open(22,file='cmaperr.dat',status='new',access='direct',
     +		recl=144*72*recfa4)
        open(13,file='cmapm.dat',status='new',access='direct',
     +		recl=144*72*recfa4)
        open(23,file='cmapmerr.dat',status='new',access='direct',
     +		recl=144*72*recfa4)
        nrec = 0
        do yr=1979,2001
            write(file,'(a,i2.2,a)') 'cmap_mon_v0107_',mod(yr,100)
     +            ,'.txt'
            call system('gunzip -c '//file//'.gz > '//file)
            open(unit=1,file=file,status='old')
c
c     2.  to read the data 
c 
            do mn=1,12    
                do jj=1,72 
                    do ii=1,144 
 2901                   format  (2i4,2f8.2,4f8.2) 
                        read  (1,2901)  kyr,kmn,rlat,rlon, 
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
*       go for the model-independent one
                write(12,rec=nrec) rain2
                write(22,rec=nrec) error2
                write(13,rec=nrec) rain1
                write(23,rec=nrec) error1
            enddo
            close(1,status='delete')
c
        enddo
        print *,'wrote ',nrec,' records'
        end
