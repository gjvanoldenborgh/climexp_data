        PROGRAM dat2grads
!
!       convert NODC's ASCII format to a griudded file, based on analyse.for
!
        implicit none
        integer recfa4
        parameter (recfa4=4)
        integer nx,ny,nz,yrbeg,yrend
        parameter (nx=360, ny=180, nz=33, yrbeg=1950,yrend=2020)
        integer i,j,k,yr,yy,irec
        real data(nx,ny),lat
        character file*70,hex(0:15),depth*5,var*2,altvar*4,line*200
        integer,external :: get_endian
 
        
        open(2,file='heat700_jma.grd',access='direct',
     +       recl=nx*ny*recfa4)
        irec = 0
        do yr=yrbeg,yrend,10
            write(file,'(a,i4,a,i4)') 'ohc_',yr,'_',yr+9
            print *,'opening ',trim(file)
            open(1,file=trim(file),status='old',err=101)
            goto 102
 101        continue
            write(file,'(a,i4,a)') 
     +           'ohc_',yr,'_last'
            print *,'opening ',trim(file)
            open(1,file=trim(file),status='old',err=800)
 102        continue
            do yy=0,9
                read(1,'(a)',end=800) line
                if ( line(1:1).ne.'#' ) then
                    write(0,*) 'error: expecting comment line'
                    print *,trim(line)
                    call abort
                end if
                do j=ny,1,-1
                    lat = (-90.5+j)*atan(1.)/45 ! in radians
                    read(1,*,err=900,end=900)(data(i,j),i=1,nx)
                    do i=1,nx
                        if ( data(i,j).eq.-9.9999 ) then
                            data(i,j) = 3e33
                        else
!                           convert from 10^19 J/gridbox to J/m2
                            data(i,j) = 10.**19*data(i,j)*
     +                           (90./10000000.)**2/cos(lat)/10.**9
                        end if
                    end do
                end do
                irec = irec + 1
                write(2,rec=irec) data
            end do              ! yr within decade
            close(1)
        end do                  ! decade
 800    continue
        close(2)
        open(2,file='heat700_jma.ctl')
        write(2,'(a)') 'DSET ^heat700_jma.grd'
        write(2,'(a)') 'TITLE JMA heat content 0-700m'
        if ( get_endian().eq.-1 ) then
            write(2,'(a)') 'OPTIONS LITTLE_ENDIAN'    
        else if ( get_endian().eq.+1 ) then
            write(2,'(a)') 'OPTIONS BIG_ENDIAN'
        end if
        write(2,'(a)') 'UNDEF 3e33'
        write(2,'(a)') 'XDEF 360 LINEAR 0.5 1'
        write(2,'(a)') 'YDEF 180 LINEAR -89.5 1'
        write(2,'(a)') 'ZDEF 1 LINEAR 350 1'
        write(2,'(a,i5,a,i4,a)') 'TDEF ',irec,' LINEAR 1JUN',yrbeg,
     +       ' 1YR'
        write(2,'(a)') 'VARS 1'
        write(2,'(a)') 'heat 0 99 heat content 0-700m [GJ/m2]'
        write(2,'(a)') 'ENDVARS'
        close(2)
        goto 999
 900    write(0,*) 'error reading NODC file ',trim(file)
        write(0,*) 'at j=',j
        if ( j.gt.1 ) then
            write(0,*) 'last data read ',(data(i,j),i=1,nx)
        end if
        call abort
 999    continue
        end
