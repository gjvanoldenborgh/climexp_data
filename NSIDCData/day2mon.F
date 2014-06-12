        program day2mon
!
!       compute the monthly mean of daily NRT ice concentration fields
!
        implicit none
#include "recfac.h"
        integer yrbeg,yrend
        parameter(yrbeg=1978,yrend=2020)
        integer yr,mo,dy,isn,i,k,n,nsn(-1:1),yr1,mo1,dy1,dpm(12,2),
     +       idata(max(316*332,304*448))
        logical lexist,lwrite
        character cdata(max(316*332,304*448),31)
        character csn(-1:1),file*255,header*300
        integer,external :: leap

        data dpm /31,28,31,30,31,30,31,31,30,31,30,31,
     +            31,29,31,30,31,30,31,31,30,31,30,31/
        data csn /'s','?','n'/
        nsn(-1) = 316*332
        nsn(+1) = 304*448
        lwrite = .false.
!
        do isn=-1,+1,2
            yr1 = -1
            mo1 = -1
            do yr=yrbeg,yrend
                do mo=1,12

!                   search for monthly file
!
                    if ( lwrite ) print *,'searching for monthly file '
     +                   ,yr,mo
                    do k=1,50
                        write(file,'(a,i4,i2.2,a,i2.2,a,a,a)')
     +                       'nt_',yr,mo,'_n',k,'_v01_',csn(isn),'.bin'
                        if ( lwrite ) print *,'trying ',trim(file)
                        inquire(file=file,exist=lexist)
                        if ( lexist ) exit
                        write(file,'(a,i4,i2.2,a,i2.2,a,a,a)')
     +                       'nt_',yr,mo,'_f',k,'_v01_',csn(isn),'.bin'
                        if ( lwrite ) print *,'trying ',trim(file)
                        inquire(file=file,exist=lexist)
                        if ( lexist ) exit
                        write(file,'(a,i4,i2.2,a,i2.2,a,a,a)')
     +                       'nt_',yr,mo,'_f',k,'_pre_',csn(isn),'.bin'
                        if ( lwrite ) print *,'trying ',trim(file)
                        inquire(file=file,exist=lexist)
                        if ( lexist ) exit
                    end do
                    if ( lexist .and. yr1.lt.0 ) then
                        yr1 = yr
                        mo1 = mo
                    end if
                    if ( lexist .or. yr1.lt.0 ) then
                        if ( lexist .and. lwrite ) print *
     +                       ,'found monthly file ',yr,mo
                        cycle
                    endif
!
!                   no monthly file, search for daily files
!
                    dy1 = 0
                    do dy=1,dpm(mo,leap(yr))
                        if ( lwrite ) print *
     +                       ,'searching for daily file ',yr,mo,dy
                        do k=1,50
                            write(file,'(a,i4,2i2.2,a,i2.2,a,a,a)')
     +                           'nt_',yr,mo,dy,'_f',k,'_nrt_',csn(isn)
     +                           ,'.bin'
                            inquire(file=file,exist=lexist)
                            if ( lexist ) exit
                        end do  ! k
                        if ( lexist ) then
                            if ( lwrite ) print *,'found daily file'
                            open(10+dy,file=file,access='direct',
     +                           recl=recfa4/4)
                            dy1 = dy
                        else
                            if ( lwrite ) print *,'no daily file'
                            exit
                        endif
                    end do      ! dy
                    if ( dy1.eq.dpm(mo,leap(yr)) ) then
                        print *,'averaging ',yr,mo
                        do i=1,300
                            read(11,rec=i) header(i:i)
                        end do
                        do dy=1,dpm(mo,leap(yr))
                            do i=1,nsn(isn)
                                read(10+dy,rec=300+i) cdata(i,dy)
                            end do
                            close(10+dy)
                        end do
                        do i=1,nsn(isn)
                            n = 0
                            idata(i) = 0
                            do dy=1,dpm(mo,leap(yr))
                                if ( ichar(cdata(i,dy)).le.250 ) then
                                    n = n + 1
                                    idata(i) = idata(i)
     +                                   + ichar(cdata(i,dy))
                                end if
                            end do ! dy
                            if ( n.gt.dpm(mo,leap(yr))/2 ) then
                                idata(i) = nint(real(idata(i))/n)
                            else
                                idata(i) = 255
                            endif
                        end do  ! i
                        write(file,'(a,i4,i2.2,a,i2.2,a,a,a)')
     +                       'nt_',yr,mo,'_f',k,'_nrt_',csn(isn)
     +                       ,'.bin'
                        open(1,file=file,access='direct',recl=recfa4/4)
                        do i=1,300
                            write(1,rec=i) header(i:i)
                        end do
                        do i=1,nsn(isn)
                            write(1,rec=300+i) char(idata(i))
                        end do
                        close(1)
                    else
                        write(0,*) 'cannot handle partial month',yr,mo
     +                       ,dy1,' yet'
                        goto 800
                    end if
                end do          ! mo
            end do              ! yr
 800        continue
        end do                  ! isn
        end

	integer function leap(yr)
	implicit none
	integer yr
	if ( mod(yr,4).ne.0 ) then
	    leap = 1
	elseif ( mod(yr,100).ne.0 ) then
	    leap = 2
	elseif ( mod(yr,400).ne.0 ) then
	    leap = 1
	else	
	    leap = 2
	endif
	end


