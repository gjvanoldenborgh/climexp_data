        program annual2monthly
*
*       convert Martin Todd's annual files into monthly ones
*
        implicit none
#include "recfac.h"
        integer nxmax,nymax
        parameter(nxmax=13,nymax=5)
        integer i,j,yr,mo,nx,ny,nt,irec
        real data(nxmax,nymax)
        character string*80,newstring*81
        integer iargc
        external iargc,getargs

        if ( iargc().ne.4 ) then
            print *,'usage: annual2monthly nx ny nt file.dat'
            stop
        endif
        call getarg(1,string)
        read(string,*) nx
        call getarg(2,string)
        read(string,*) ny
        call getarg(3,string)
        read(string,*) nt
        call getarg(4,string)
        open(1,file=string,status='old',form='unformatted',
     +        access='direct',recl=recfa4*nx*ny)
        i = index(string,'annual')
        write(newstring,'(3a)') string(1:i-1),'monthly',string(i+6:)
        open(2,file=newstring,form='unformatted',
     +        access='direct',recl=recfa4*nx*ny*12)
        
        irec = 0
        do yr=1,nt
            irec = irec + 1
            read(1,rec=irec) ((data(i,j),i=1,nx),j=1,ny)
            write(2,rec=irec) ((data(i,j),i=1,nx),j=1,ny),
     +            (3e33,i=1,nx*ny*11)
        enddo
        end
