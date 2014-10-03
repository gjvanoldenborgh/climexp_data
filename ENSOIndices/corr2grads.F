        program corr2grads
!
!       read output of a series of correlation jobs and convert into a
!       GrDAS file for later plotting
!
        implicit none
#include "recfac.h"
        integer mo,m,i,j,lead
        real data(12,12)
        character file*255,datfile*255,months(12)*3
        logical lwrite
        data months
     +       /'jan','feb','mar','apr','may','jun','jul','aug','sep'
     +       ,'oct','nov','dec'/

        lwrite = .false.
        data = -999.9
        call getarg(1,file)
        i = index(file,'%%%')
        if ( i.eq.0 ) then
            write(0,*) 'corr2grads: error: expected filename with "%%%"'
     +           ,' found ',trim(file)
            call abort
        end if
        do mo=1,12
            file(i:i+2) = months(mo)
            open(1,file=trim(file),status='old')
            do j=1,12
                lead = j - mo
                if ( lead.lt.0 ) lead = lead + 12
                read(1,*,end=100) data(mo,lead+1)
                if ( lwrite ) 
     +               print *,'data(',mo,lead,') = ',data(mo,lead+1)
            end do
 100        continue
            close(1)
        end do

        call getarg(2,file)
        i = index(file,'.ctl')
        if ( i.eq.0 ) then
            write(0,*) 'corr2grads: error: expected .ctl in ',trim(file)
            call abort
        end if
        datfile=file(1:i-1)//'.grd'

        open(1,file=trim(file))
        write(1,'(2a)') 'DSET ^',trim(datfile)
        write(1,'(a)') 'TITLE start/lead correlation diagram'
        write(1,'(a)') 'UNDEF -999.9'
        write(1,'(a)') 'XDEF 1 LINEAR 0 1'
        write(1,'(a)') 'YDEF 1 LINEAR 0 1'
        write(1,'(a)') 'ZDEF 12 LINEAR 0 1'
        write(1,'(a)') 'TDEF 12 LINEAR 15JAN0001 1MO'
        write(1,'(a)') 'VARS 1'
        write(1,'(a)') 'corr 12 99 correlation coefficient'
        write(1,'(a)') 'ENDVARS'
        close(1)
        open(1,file=trim(datfile),access='direct',recl=12*recfa4)
        do mo=1,12
            write(1,rec=mo) (data(mo,lead+1),lead=0,11)
        end do
        close(1)

        end
