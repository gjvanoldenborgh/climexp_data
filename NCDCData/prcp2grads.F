        program prcp2grads
*
*       convert the NCDC gridded seasonal precipitation anomaly file
*       to grads format
*
        implicit none
#include "recfac.h"
        integer i,j,k,iyear,imon,n,ldataset,ii
        real data(72,37)
        character dataset*5
        integer iargc
!!!        external iargc,getarg
*       
        if ( iargc().ne.1 ) then
            print *,'usage: prcp2grads seas|month'
            call abort
        endif
        call getarg(1,dataset)
        if ( dataset.eq.'seas ' ) then
            ldataset = 4
            ii = 5
        elseif ( dataset.eq.'month' ) then
            ldataset = 5
            ii = 12
        else
            print *,'unknown dataset ',dataset
            call abort
        endif
        open(1,file='prcp.'//dataset(1:ldataset)//'.anom',status='old')
        open(2,file='prcp_'//dataset(1:ldataset)//'_anom.dat',
     +        status='new',form='unformatted',access='direct',
     +        recl=72*37*recfa4)
        n = 0
  100   continue
        do i=1,ii
            read(1,9,end=800) iyear,imon,((data(j,k), j=1,72),k=1,37)
            do k=1,37
                do j=1,72
                    if ( data(j,k).lt.-9000 ) then
                        if ( abs(data(j,k)+9999.99).gt..001 ) then
                            print *,'weird value for precip: ',data(j,k)
     +                            ,' made invalid'
                        endif
                        data(j,k)= 3e33
                    endif
                enddo
            enddo
    9       format (i4,i2/(12f8.2))
            if ( ii.ne.5 .or. i.lt.5 ) then
                print *,'year,mon = ',iyear,imon
                n = n+1
                write(2,rec=n) ((data(j,k), j=1,72),k=1,37)
            endif
        enddo
        goto 100
  800   continue
        print *,'converted ',n,' records'
        end
