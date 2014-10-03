        program ascii2grads
!
!       convert the UNH ascii land use files to grads
!       runs only on a 64-bit computer!
!
        implicit none
#include "recfac.h"
        integer nxmax,nymax,yrbeg,yrend
        parameter(nxmax=720,nymax=360,yrbeg=1500,yrend=2100)
        integer i,j,yr,irec,nx,ny
        real field(nxmax,nymax)
        character type*5,file*100,line*255,lvar*80,rcp*5

        call getarg(1,type)
        call getarg(2,rcp)
        if ( rcp.eq.' ' ) then
            write(0,*) 'usage: ascii2grads type rcpNN'
            call abort
        end if

        open(2,file=rcp//'_'//type//'_05.grd',access='direct',
     +       recl=recfa4*nxmax*nymax)
        irec = 0

        do yr=yrbeg,yrend
            if ( yr.le.2005 ) then
                write(file,'(3a,i4.4,a)')
     +               'updated_states_hist/',type,'.',yr,'.txt'
            else
                write(file,'(3a,i4.4,a)')
     +               'updated_states_'//rcp//'/',type,'.',yr,'.txt'
            end if
            print *,trim(file)
            open(1,file=trim(file),status='old')
            ! read header
            do i=1,6
                read(1,'(a)') line
                if ( line(1:5).eq.'ncols' ) then
                    read(line(15:),*) nx
                    if ( nx.ne.nxmax ) then
                        write(0,*) 'error: ncols != ',nxmax,nx
                        call abort
                    end if
                else if ( line(1:5).eq.'nrows' ) then
                    read(line(15:),*) ny
                    if ( ny.ne.nymax ) then
                        write(0,*) 'error: nrows != ',nymax,ny
                        call abort
                    end if
                end if
            end do
            do j=360,1,-1
                read(1,'(720f9.6)') (field(i,j),i=1,720)
            end do
            close(1)
            irec = irec + 1
            write(2,rec=irec) field
        end do
        close(2)
!
!       write ctl file
!
        open(2,file=rcp//'_'//type//'_05.ctl')
        write(2,'(3a)') 'DSET ^',rcp//'_'//type,'_05.grd'
        write(2,'(a)') 'TITLE UNH Land-Use History A v.1 '//rcp
        write(2,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(2,'(a)') 'UNDEF -9999'
        write(2,'(a,i3,a)') 'XDEF ',nxmax,' LINEAR -179.75 0.5'
        write(2,'(a,i3,a)') 'YDEF ',nymax,' LINEAR -89.75 0.5'
        write(2,'(a)') 'ZDEF 1 LINEAR 0 1'
        write(2,'(a,i3,a,i4.4,a)') 'TDEF ',irec,' LINEAR 1JAN',yrbeg,
     +       ' 1YR'
        write(2,'(a)') 'VARS 1'
        if ( type.eq.'gcrop' ) then
            lvar = 'fraction of each gridcell in cropland'
        else if ( type.eq.'gothr' ) then
            lvar = 'fraction of each gridcell in primary land'
        else if ( type.eq.'gpast' ) then
            lvar = 'fraction of each gridcell in pasture'
        else if ( type.eq.'gsecd' ) then
            lvar = 'fraction of each gridcell in secondary land'
        else if ( type.eq.'gurbn' ) then
            lvar = 'fraction of each gridcell in urban land'
        else
            lvar = ' '
        end if
        write(2,'(4a)') type,' 0 99 ',trim(lvar),' [1]'
        write(2,'(a)') 'ENDVARS'
        close(2)
        end
