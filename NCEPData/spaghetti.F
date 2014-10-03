        program spaghetti
*
*       make spaghettiplots of NINO3 and NINO3 temperature
*
        implicit none
#include "param.inc"
        integer np
        real sx,sy
        parameter (np=5,sx=400.,sy=250.)
        integer yr,mo,i,j,k,nperyear,nyr(12,-np:np),years(6),
     +        colours(3,6)
        real nino3(npermax,yrbeg:yrend),clim(12,-np:np)
        logical penup
        character command*7,months(12)*1
        data months /'J','F','M','A','M','J','J','A','S','O','N','D'/
        data years /1970,1973,1975,1988,1999,2007/
        data colours /1,0,0, 0,1,0, 0,0,1, 1,1,0, 1,0,1, 0,1,1/

        call makeabsent(nino3,npermax,yrbeg,yrend)
        call readdat(nino3,npermax,nperyear,yrbeg,yrend,'nino5.dat')
        do mo=1,12
            do k=-np,-1
                clim(mo,k) = +3e33
            enddo
            clim(mo,0) = 0
            do k=1,np
                clim(mo,k) = -3e33
            enddo
        enddo
        do yr=1856,yrend
            do mo=1,12
                if ( nino3(mo,yr).lt.1e33 ) then
                    nyr(mo,0) = nyr(mo,0) + 1
                    clim(mo,0 ) = clim(mo,0) + nino3(mo,yr)
                    do k=1,np
                        if ( nino3(mo,yr).gt.clim(mo,k) ) then
                            if ( k.gt.1 ) then
                                clim(mo,k-1) = clim(mo,k)
                                nyr(mo,k-1) = nyr(mo,k)
                            endif
                            clim(mo,k) = nino3(mo,yr)
                            nyr(mo,k) = yr
                        endif
                    enddo
                    do k=1,np
                        if ( nino3(mo,yr).lt.clim(mo,-k) ) then
                            if ( k.gt.1 ) then
                                clim(mo,-k+1) = clim(mo,-k)
                                nyr(mo,-k+1) = nyr(mo,-k)
                            endif
                            clim(mo,-k) = nino3(mo,yr)
                            nyr(mo,-k) = yr
                        endif
                    enddo
                endif
            enddo
        enddo

        open(1,file='spaghetti.eps')
        write(1,'(a)') '%!PS-Adobe-1.0 EPSF-1.2'
        write(1,'(a,2i4)') '%%BoundingBox: 75 75 ',
     +        nint(sx)+110,nint(sy)+130
        write(1,'(a)') '%%Pages: 1'
        write(1,'(a)') '%%PaperSize: A4'
        write(1,'(a)') '%%PageOrientation: Landscape'
        write(1,'(a)') '%%Documentfonts: Helvetica'
        write(1,'(a)') '%%Page: 1 1'
        write(1,'(a)') '100 100 translate'
        write(1,'(a)') '1 setlinewidth'
        write(1,'(a)') '0 0 moveto'
        write(1,'(2i4,a)') nint(sx),0,' lineto'
        write(1,'(2i4,a)') nint(sx),nint(sy),' lineto'
        write(1,'(2i4,a)') 0,nint(sy),' lineto'
        write(1,'(a)') 'closepath stroke newpath'
        write(1,'(a)') '(Helvetica) findfont 10 scalefont setfont'
        do mo=1,24
            write(1,'(2f8.2,a)') (mo-1)*sx/23, 0.,' moveto'
            write(1,'(2f8.2,a)') (mo-1)*sx/23,-5.,' lineto'
            write(1,'(2f8.2,a)') (mo-1)*sx/23,sy,' moveto'
            write(1,'(2f8.2,a)') (mo-1)*sx/23,sy+5.,' lineto'
            write(1,'(2f8.2,a)') (mo-1)*sx/23-4,-20.,' moveto'
            write(1,'(4a)') '(',months(1+(mod(mo-1,12))),') show'
        enddo
        do i=-3,5
            write(1,'(2f8.2,a)')   0.,(i+3)*sy/8,' moveto'
            write(1,'(2f8.2,a)')  -5.,(i+3)*sy/8,' lineto'
            write(1,'(2f8.2,a)')   sx,(i+3)*sy/8,' moveto'
            write(1,'(2f8.2,a)') sx+5,(i+3)*sy/8,' lineto'
            write(1,'(2f8.2,a)') -20.,(i+3)*sy/8-3,' moveto'
            write(1,'(a,i2,a)') '(',i,') show'
        enddo
        write(1,'(2f8.2,a)') 0.,sy+10,' moveto'
        write(1,'(a)') '(Helvetica) findfont 15 scalefont setfont'
        write(1,'(a)') '(NINO3.4 anomalies) show'

        do i=1856,yrend-1
            write(1,'(a)') '0.8 setgray'
            do k=1,6
                if ( yr.eq.years(k) ) then
                    write(1,'(3i2,a)') (colours(j,k),j=1,3)
     +                    ,' setrgbcolor'
                    write(1,'(2i4,a)') 50*k-40,nint(sy-15),' moveto'
                    write(1,'(a)')
     +                    '(Helvetica) findfont 10 scalefont setfont'
                    write(1,'(a,i4,a)') '(',yr,') show'
                endif
            enddo
            penup = .true.
            do j=1,24
                if ( j.le.12 ) then
                    yr=i
                    mo=j
                else
                    yr=i+1
                    mo=j-12
                endif
                if ( nino3(mo,yr).lt.1e33 ) then
                    if ( penup ) then
                        command = ' moveto'
                    else
                        command = ' lineto'
                    endif
                    write(1,'(2f8.2,a)') (j-1)*sx/23,(nino3(mo,yr)+3)
     +                    /8*sy,command
                    penup = .false.
                else
                    if ( .not.penup ) write(1,'(a)') 'stroke newpath'
                    penup = .true.
                endif
            enddo
            if ( .not.penup ) write(1,'(a)') 'stroke newpath'
        enddo
        write(1,'(a)') 'showpage'
        write(1,'(a)') '%%EOF'
        close(1)

        do mo=1,12
            clim(mo,0) = clim(mo,0)/nyr(mo,0)
            nyr(mo,0) = 0
            print '(a,5f6.2,x,f6.2,x,5f6.2)',months(mo),
     +            (clim(mo,k),k=-np,np)
            print '(a,5i6,x,i6,x,5i6)',' ',(nyr(mo,k),k=-np,np)
        enddo
        end
