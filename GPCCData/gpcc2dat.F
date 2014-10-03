      program gpcc2dat
*
*     convert the VASClimO climatology to grads format.
*
      implicit none
      integer yrbeg,yrend,nxmax,nymax,imax
      parameter(yrbeg=1951,yrend=2000,nxmax=720,nymax=360,imax=65617)
      integer i,j,k,yr,mo,ival(12),nx,ny,ires,indx(imax,2),n
      real data(nxmax,nymax,12),val(12),x,y
      character file*80,gridfile*80,outfile*80,ctlfile*80

      do ires=3,1,-1
         if ( ires.eq.1 ) then
            nx=720
            ny=360
            file='grd05_yyyy.csv'
            gridfile='gr05_coordinates.txt'
            outfile = 'gpcc_05.dat'
            ctlfile = 'gpcc_05.ctl'
         elseif ( ires.eq.2 ) then
            nx=360
            ny=180
            file='grd10_yyyy.csv'
            gridfile='gr10_coordinates.txt'
            outfile = 'gpcc_10.dat'
            ctlfile = 'gpcc_10.ctl'
         elseif ( ires.eq.3 ) then
            nx=144
            ny= 72
            file='grd25_yyyy.csv'
            gridfile='gr25_coordinates.txt'
            outfile = 'gpcc_25.dat'
            ctlfile = 'gpcc_25.ctl'
         endif
         open(2,file=outfile,access='direct',recl=4*12*nx*ny)
*
*     read grid point index file
*
         open(1,file=gridfile,status='old')
 10      read(1,*,end=20) k,x,y
         if ( k.gt.imax ) then
            write(0,*) 'too many points'
            write(0,*) 'increase imax'
            call abort
         endif
         i = int(1+nx*(x+180)/360)
         j = int(1+ny*(y+ 90)/180)
         if ( i.lt.1 .or. i.gt.nx ) then
            write(0,*) 'error in i ',i,x
            call abort
         endif
         if ( j.lt.1 .or. j.gt.ny ) then
            write(0,*) 'error in j ',j,y
            call abort
         endif
         indx(k,1) = i
         indx(k,2) = j
         goto 10
 20      continue
         close(1)
*
*     read and write data
*
         do yr=yrbeg,yrend
            do mo=1,12
               do j=1,ny
                  do i=1,nx
                     data(i,j,mo) = 3e33
                  enddo
               enddo
            enddo
            write(file(7:10),'(i4)') yr
            open(1,file=file,status='old')
 110        continue
            if ( ires.eq.3 ) then
               read(1,*,end=120) i,val
               if ( i.lt.1 .or. i.gt.imax ) then
                  write(0,*) 'error ',i
                  call abort
               endif
               if ( indx(i,1).lt.1 .or. indx(i,1).gt.nx ) then
                  write(0,*) 'error in indx(i,1) ',i,indx(i,1)
                  call abort
               endif
               if ( indx(i,2).lt.1 .or. indx(i,2).gt.ny ) then
                  write(0,*) 'error in indx(i,2) ',i,indx(i,2)
                  call abort
               endif
               do mo=1,12
                  data(indx(i,1),indx(i,2),mo) = val(mo)
               enddo
            else
               read(1,*,end=120) i,ival
               if ( i.gt.imax ) then
                  write(0,*) 'error ',i
                  call abort
               endif
               do mo=1,12
                  data(indx(i,1),indx(i,2),mo) = ival(mo)
               enddo
            endif
            goto 110
 120        continue            
            close(1)
            write(2,rec=yr-yrbeg+1) (((data(i,j,mo),i=1,nx),j=1,ny),
     $           mo=1,12)
         enddo                  ! yr
         close(2)
         open(2,file=ctlfile)
         write(2,'(2a)') 'DSET ^',outfile(1:index(outfile,' ')-1)
         write(2,'(a)')
     $        'TITLE GPCC VASClimO-50yr precipitation climatology'
         write(2,'(a)') 'OPTIONS LITTLE_ENDIAN'
         write(2,'(a)') 'UNDEF 3e33'
         write(2,'(a,i3,a,2f6.2)') 'XDEF ',nx,' LINEAR ',-180+180./nx
     $        ,360./nx
         write(2,'(a,i3,a,2f6.2)') 'YDEF ',ny,' LINEAR ',-90+90./ny,
     $        180./ny
         write(2,'(a)') 'ZDEF 1 LINEAR 0 1'
         write(2,'(a,i4,a,i4,a)') 'TDEF ',12*(yrend-yrbeg+1)
     $        ,' LINEAR 15JAN',yrbeg,' 1MO'
         write(2,'(a)') 'VARS 1'
         write(2,'(a)') 'prcp 0 99 precipitation [mm/month]'
         write(2,'(a)') 'ENDVARS'
         close(2)
      enddo
      end
