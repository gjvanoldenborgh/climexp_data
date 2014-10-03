        PROGRAM wod2grads
      
c***********************************************************
!       grids WOD data into a 4D datafile
!       based on wodASC.f
c***********************************************************
c   Parameters (constants):
c     
c     maxlevel  - maximum number of depth levels, also maximum
c                   number of all types of variables
c     maxcalc   - maximum number of measured and calculated
c                   depth dependent variables
c     nz        - number of standard depth levels
c     bmiss     - binary missing value marker
c     maxtcode  - maximum number of different taxa variable codes
c     maxtax    - maximum number of taxa sets
c
c******************************************************************
        implicit none
        integer nvarmax,nz,maxlevel,maxtcode,maxtax,nx,ny,yrbeg,yrend
     +       ,npermax
        real bmiss
        parameter (nvarmax=100)
        parameter (maxlevel=30000,bmiss=-999.99)
        parameter (maxtcode=25,maxtax=2000)
        parameter(nx=36,ny=36,nz=40)  ! for 10x5 grid boxes
        parameter(yrbeg=1850,yrend=2020,npermax=12)

c******************************************************************
c
c   Character Arrays:
c
c     cc        - NODC country code
c     chars     - WOD character data: 1. originators cruise code,
c                                     2. originators station code
c     filename  - file name
c
c*****************************************************************
      
      character*2  cc
      character*15 chars(2)
      character*80 file,datfile

c******************************************************************
c
c   Arrays:
c
c     isig()    - number of significant figures in (1) latitude, (2) longitude
c                  and (3) time
c     iprec()   - precision of (1) latitude, (2) longitude, (3) time
c
c     ip2()     - variable codes for variables in cast
c     ierror()  - whole profile error codes for each variable
c     
c     jsig2()   - number of significant figures in each second header variable
c     jprec2()  - precision of each second header variable
c     jtot2()   - number of figures in each second header variable
c     sechead() - second header variables
c
c     jsigb()   - number of significant figures in each biological variable
c     jprecb()  - precision of each biological variable
c     jtotb()   - number of figures in each biological variable
c     bio()     - biological data
c
c     depth()   - depth of each measurement
c     msig()    - number of significant figures in each measured variable at
c                  each level of measurement
c     mprec()   - precision of each measured variable at each
c                  level of measurement
c     mtot()    - number of figures in each measured variable at
c                  each level of measurement
c     temp()    - measured variable data at each level
c     iderror() - error flags for each variable at each depth level
c     isec()    - variable codes for second header data
c     ibio()    - variable codes for biological data
c     itaxnum() - different taxonomic and integrated variable
c                  codes found in data
c     vtax()    - value of taxonomic variables and integrated variables
c     jsigtax() - number of significant figures in taxon values and
c                  integrated variables
c     jprectax()- precision of taxon values and integrated variables
c     jtottax() - number of figures in taxon values and integrated
c                  variables
c     itaxerr() - error codes for taxon data
c     nbothtot()- total number of taxa and integrated variables 
c     ipi()     - primary investigators information
c                   1. primary investigators
c                   2. for which variable
c
c*******************************************************************

        integer isig(3), iprec(3), ip2(0:maxlevel), ierror(maxlevel)
        integer ipi(maxlevel,2)
        integer jsig2(maxlevel), jprec2(maxlevel)
        real sechead(maxlevel)
        integer jsigb(maxlevel), jprecb(maxlevel)
        real bio(maxlevel)
        real depth(maxlevel)
        integer jtot2(maxlevel),jtotb(maxlevel)
        integer msig(maxlevel,nvarmax), mprec(maxlevel,nvarmax)
        integer mtot(maxlevel,nvarmax)
        real temp(maxlevel,nvarmax)
        integer iderror(maxlevel,0:nvarmax)
        integer isec(maxlevel),ibio(maxlevel)
        integer itaxnum(maxtcode,maxtax)
        real vtax(0:maxtcode,maxtax)
        integer jsigtax(maxtcode,maxtax),jprectax(maxtcode,maxtax)
        integer jtottax(maxtcode,maxtax),itaxerr(maxtcode,maxtax)
        integer itaxorigerr(maxtcode,maxtax)
        real stdz(nz)

        common /thedata/ depth,temp
        common /flags/ ierror,iderror
        common /significant/ msig
        common /precision/ mprec
        common /totfigs/ mtot
        common /second/ jsig2,jprec2,jtot2,isec,sechead
        common /biology/ jsigb,jprecb,jtotb,ibio,bio
        common /taxon/ jsigtax,jprectax,jtottax,itaxerr,
     *       vtax,itaxnum,nbothtot,itaxorigerr
        
        integer idepthset,ifld,iVERSflag,ieof,iendcast
        integer ij,i,jj,n,nf,iyear,month,iday,ifield,ifound,iprm,nparm
     +       ,icruise,istdlev,levels,nbio,nbothtot,npi,nsecond,yr1,yr2
        integer ix,iy,iz,yr,mo
        integer,allocatable :: nn(:,:,:,:,:)
        real rlat,rlon,time
        real,allocatable :: data(:,:,:,:,:)
        logical lwrite

        data stdz/ 0., 10., 20., 30., 50., 75., 100., 125., 150.,
     *       200., 250., 300., 400., 500., 600., 700., 800., 900.,
     *       1000., 1100., 1200., 1300., 1400., 1500., 1750., 2000.,
     *       2500., 3000., 3500., 4000., 4500., 5000., 5500., 6000.,
     *       6500., 7000., 7500., 8000., 8500., 9000./
!
!       init
!
        lwrite = .false.
        print *,'init'
        idepthset=0
        if ( lwrite ) print *,'allocating ',nx,ny,nz,npermax
     +       ,yrbeg,yrend,' = ',4*nx*ny*nz*npermax*(1-yrbeg+yrend)
        allocate(nn(nx,ny,nz,npermax,yrbeg:yrend))
        allocate(data(nx,ny,nz,npermax,yrbeg:yrend))
        nn = 0
        data = 0
        yr1 = yrend
        yr2 = yrbeg

c**************************************************************
c
c     Get user input file name from which casts will be
c     taken.  Open this file.
c
c**************************************************************

        call getarg(2,file)
        if ( file.eq.' ' ) then
            write(0,*) 'usage: wod2grads infile temp|salt'
            call abort
        end if
        if ( file.eq.'temp' ) then
            ifld = 1
        else if ( file.eq.'salt' ) then
            ifld = 2
        else
            write(0,*) 'error: should be temp or salt, not ' ,trim(file)
        end if
        call getarg(1,file)
        nf = 1
        print *,'opening file ',trim(file)
        open(nf,file=trim(file),status='old')

c**************************************************************
c
c   SUBROUTINE "WODread":  READS IN A SINGLE PROFILE FROM THE ASCII 
c                          FILE AND STORES THE DATA INTO ARRAYS (PASSED
c                          OR SHARED BETWEEN WODread AND wodASC).
c   -------------------------------------------------------------------
c
c   Passed Variables:
c     
c     nf      - file identification number for input file
c     jj      - WOD cast number
c     cc      - NODC country code
c     icruise - NODC cruise number
c     iyear   - year of cast
c     month   - month of cast
c     iday    - day of cast
c     time    - time of cast
c     rlat    - latitude of cast
c     rlon    - longitude of cast
c     levels  - number of depth levels of data
c     istdlev - observed (0) or standard (1) levels
c     nparm   - number of variables recorded in cast 
c     ip2(i)  - variable codes of variables in cast
c     nsecond - number of second header variables
c     nbio    - number of biological variables
c     isig()  - number of significant figures in (1) latitude, (2) longitude
c                and (3) time
c     iprec() - precision of (1) latitude, (2) longitude, (3) time
c     ieof    - set to one if end of file has been encountered
c     bmiss   - missing value marker
c
c   Common/Shared Variables and Arrays (see COMMON area of program):
c
c     depth(x)   - depth in meters (x = depth level)
c     temp(x,y)  - variable data (x = depth level, y = variable ID = ip2(i))
c                ... see also nparm, ip2, istdlev, levels above ...
c     sechead(i) - second header data (i = second header ID = isec(j))
c     isec(j)    - second header ID (j = #sequence (1st, 2nd, 3rd))
c                ... see also nsecond above ...
c     bio(i)     - biology header data (i = biol-header ID = ibio(j))
c     ibio(j)    - biology header ID (j = #sequence (1st, 2nd, 3rd))
c                ... see also nbio above ...
c     nbothtot   - number of taxa set / integrated variables
c     vtax(i,j)  - taxonomic/integrated array, where j = (1..nbothtot)
c                   For each entry (j=1..nbothtot), there are vtax(0,j)
c                   sub-entries.  [Note:  The number of sub-entries is 
c                   variable for each main entry.]  vtax also holds the
c                   value of the sub-entries.
c    itaxnum(i,j)- taxonomic code or sub-code 
c     
c***************************************************************

        iVERSflag = 0
        ieof = 0

        iendcast=10000000

        print *,'reading data'
        do ij=1,iendcast     !- MAIN LOOP 

            chars(1)= '               '
            chars(2)= '               '
      
            if ( iVERSflag.eq.0 ) then

                call WODread200X(nf,jj,cc,icruise,iyear,month,iday,
     *               time,rlat,rlon,levels,istdlev,nparm,ip2,nsecond
     +               ,nbio,isig,iprec,bmiss,ieof,chars,ipi,npi,iVERSflag
     +               )

c               ONLY happens if format rejected (rewind and try as WOD98)
                if ( iVERSflag.gt.0 ) then
                    print*, 
     *                   'This data file in not in WOD-200X format.',
     *                   '  Trying WOD-1998 format. '
                    print*, ' '
                    rewind(nf)
                end if
            end if


            if ( IVERSflag.eq.1 ) then

c               Read in as WOD-1998 format
                call WODread1998(nf,jj,cc,icruise,iyear,month,iday,
     *               time,rlat,rlon,levels,istdlev,nparm,ip2,nsecond
     +               ,nbio,isig,iprec,bmiss,ieof,chars,ipi,npi)

            end if

            if ( ieof.gt.0 ) goto 800 !- Exit

C           The program searches the cast to determine if the desired
C           variable is contained in the cast. If not, the program
C           skips to the next cast.

            ifound = 0

            do iprm=1,nparm
                if ( ip2(iprm).eq.ifld ) then
                    ifound = 1 
                    ifield = ip2(iprm)
                end if
            end do

            if ( ifound.eq.0 ) cycle

c***************************************************************
c
c     STANDARD LEVELS OR OBSERVED LEVELS
c     ----------------------------------
c     
c     If this file is on standard levels, place the standard
c     depths in the depth array (otherwise, observed depth values 
c     were read in and stored above by WODread).
c
c***************************************************************

            if ( istdlev.eq.1 .and. idepthset.eq.0 ) then
                do i=1,nz
                    depth(i) = stdz(i)
                end do
                idepthset = 2
            end if
            if ( lwrite ) then
c               write data to file in column format
c               the first line is to separate the individual casts
c               the % sign at the beginning is a comment in matlab
c               and will not be read in when loading the data file
c               if the data are missing at a certain level in the cast
c               then the depth level is not written out.
                write(*,*) '% ', rlon, rlat, iyear, month, iday,ij
                do n=1,levels
                    if ( temp(n,ifield).lt.-90.0 ) then
                        cycle
                    else
                        write(*,'(2f12.4)') depth(n), temp(n,ifield)
                    end if
                end do
            end if              ! debug output
!
!           fill 4D array
!
            if ( iyear.lt.yrbeg ) then
                if ( lwrite ) print *,'disregarding data at yr = ',iyear
                cycle
            end if
            if ( iyear.gt.yrend ) then
                write(0,*) 'error: disregarding data in year ',iyear
                cycle
            end if
            yr1 = min(iyear,yr1)
            yr2 = max(iyear,yr2)
            if ( month.lt.1 .or. month.gt.12 ) then
                write(0,*) 'error: disregarding data with month ',month
                cycle
            end if
            ix = floor(rlon*nx/360)
            if ( ix.le.0 ) ix = ix + nx
            iy = floor(rlat*ny/180) + ny/2 + 1
!           make sure the poles go the right way
            if ( iy.eq.0 .and. rlat.eq.-90 ) iy = 1
            if ( iy.eq.ny+1 .and. rlat.eq.90 ) iy = ny
            if ( ix.lt.1 .or. ix.gt.nx .or.
     +           iy.lt.1 .or. iy.gt.ny ) then
                write(0,*) 'something went wrong in lon,lat: ',rlon,rlat
     +               ,ix,iy
                cycle
            end if
            if ( levels.gt.nz ) then
                write(0,*) 'error: expected levels <= nz ',levels,nz
                call abort
            end if
            do iz=1,levels
                if ( temp(iz,ifield).lt.-90.0 ) then
                    cycle
                else
                    if ( lwrite ) print *,'updating ',ix,iy,iz,mo,yr
                    nn(ix,iy,iz,month,iyear) = 
     +                   nn(ix,iy,iz,month,iyear) + 1
                    data(ix,iy,iz,month,iyear) = 
     +                   data(ix,iy,iz,month,iyear) + temp(iz,ifield)
                end if
            end do
            if ( mod(ij,1000).eq.0 ) then
                write(*,'(i10,2f8.2,i5,2i3.2)') 
     +               ij,rlon,rlat,iyear,month,iday
            end if
        end do                  !- End of MAIN LOOP
 800    continue                !- end of data
        close(nf)

        print *,'computing gridbox averages'
        do yr=yrbeg,yrend
            do mo=1,npermax
                do iz=1,nz
                    do iy=1,ny
                        do ix=1,nx
                            if ( nn(ix,iy,iz,mo,yr).gt.0 ) then
                                data(ix,iy,iz,mo,yr) = 
     +                               data(ix,iy,iz,mo,yr)
     +                               /nn(ix,iy,iz,mo,yr)
                            else
                                data(ix,iy,iz,mo,yr) = 3e33
                            end if
                        end do
                    end do
                end do
            end do
        end do

        print *,'writing output files'
        call getarg(2,file)
        open(1,file=trim(file)//'.grd',form='unformatted',
     +       access='direct',recl=4*nx*ny*nz*npermax)
        do yr=yr1,yr2
            write(1,rec=yr-yr1+1) ((((data(ix,iy,iz,mo,yr),
     +           ix=1,nx),iy=1,ny),iz=1,nz),mo=1,npermax)
        end do
        close(1)
        open(1,file=trim(file)//'.ctl')
        write(1,'(a)') 'DSET ^'//trim(file)//'.grd'
        write(1,'(a)') 'TITLE binned WODC data, no interpolation'
        write(1,'(a)') 'OPTIONS LITTLE_ENDIAN'
        write(1,'(a)') 'UNDEF 3e33'
        write(1,'(a,i4,a,2f7.2)') 'XDEF ',nx,' LINEAR ',180./nx,360./nx
        write(1,'(a,i4,a,2f7.2)') 'YDEF ',ny,' LINEAR ',-90+90./ny,
     +       180./ny
        write(1,'(a,i4,a,10f10.1)') 'ZDEF ',nz,' LEVELS ',
     +       (depth(iz),iz=1,10)
        do i=1,(nz-1)/10
            write(1,'(a,10f10.1)') '    ',
     +           (depth(iz),iz=10*i+1,min(10*i+10,nz))
        end do
        write(1,'(a,i6,a,i4,a)') 'TDEF ',(yr2-yr1+1)*npermax,
     +       ' LINEAR 15JAN',yr1,' 1MO'
        write(1,'(a)') 'VARS 1'
        if ( ifield.eq.1 ) then
            write(1,'(a,i4,a)') 'temp ',nz,' 99 temperature [Celsius]'
        else if ( ifield.eq.2 ) then
            write(1,'(a,i4,a)') 'salt ',nz,' 99 salinity [psu]'
        else
            write(0,*) 'eror: unknown variable ',ifield
            call abort
        end if
        write(1,'(a)') 'ENDVARS'
        close(1)

        end
*  #[ wodread200x:
C-----------------------------------------------------------------      

      SUBROUTINE WODREAD200X(nf,jj,cc,icruise,iyear,month,iday,
     *  time,rlat,rlon,levels,isoor,nvar,ip2,nsecond,nbio,
     *  isig,iprec,bmiss,ieof,chars,ipi,npi,iVERSflag)


c     This subroutine reads in the WOD ASCII format and loads it
c     into arrays which are common/shared with the calling program.
c*****************************************************************
c
c   Passed Variables:
c
c     nf       - file identification number for input file
c     jj       - WOD cast number
c     cc       - NODC country code
c     icruise  - NODC cruise number
c     iyear    - year of cast
c     month    - month of cast
c     iday     - day of cast
c     time     - time of cast
c     rlat     - latitude of cast
c     rlon     - longitude of cast
c     levels   - number of depth levels of data
c     isoor    - observed (0) or standard (1) levels
c     nvar     - number of variables recorded in cast
c     ip2      - variable codes of variables in cast
c     nsecond  - number of secondary header variables
c     nbio     - number of biological variables
c     isig     - number of significant figures in (1) latitude, (2) longitude,
c                 and (3) time
c     iprec    - precision of (1) latitude, (2) longitude, (3) time
c     itotfig  - number of digits in (1) latitude, (2) longitude, (3) time
c     bmiss    - missing value marker
c     ieof     - set to one if end of file has been encountered
c     chars    - character data: 1=originators cruise code,
c                                2=originators station code
c     npi      - number of PI codes
c     ipi      - Primary Investigator information
c                  1. primary investigator
c                  2. variable investigated
c
c     iVERSflag  -  set to "1" if data are in WOD-1998 format. 
c                (subroutine exits so 1998 subroutine can be run)
c
c   Common/Shared Variables and Arrays (see COMMON area of program):
c
c     depth(x)   - depth in meters (x = depth level)
c     temp(x,y)  - variable data (x = depth level, y = variable ID = ip2(i))
c                ... see also nvar, ip2, istdlev, levels above ...
c     sechead(i) - secondary header data (i = secondary header ID = isec(j))
c     isec(j)    - secondary header ID (j = #sequence (1st, 2nd, 3rd))
c                ... see also nsecond above ...
c     bio(i)     - biology header data (i = biol-header ID = ibio(j))
c     ibio(j)    - biology header ID (j = #sequence (1st, 2nd, 3rd))
c                ... see also nbio above ...
c     nbothtot   - number of taxa set / biomass variables
c     vtax(i,j)  - taxonomic/biomass array, where j = (1..nbothtot)
c                   For each entry (j=1..nbothtot), there are vtax(0,j)
c                   sub-entries.  [Note:  The number of sub-entries is
c                   variable for each main entry.]  vtax also holds the
c                   value of the sub-entries.
c    itaxnum(i,j)- taxonomic code or sub-code
c    parminf(i,j)- variable specific information
c    origflag(i,j)- originators data flags
c
c***************************************************************


c******************************************************************
c
c   Parameters (constants):
c
c     maxlevel - maximum number of depth levels, also maximum
c                 number of all types of variables
c     nvarmax  - maximum number of measured and calculated
c                 depth dependent variables
c     maxtcode - maximum number of different taxa variable codes
c     maxtax   - maximum number of taxa sets
c     maxpinf - number of distinct variable specific information
c               variables
c******************************************************************

      parameter (maxlevel=30000, nvarmax=100)
      parameter (maxtcode=25, maxtax=2000, maxpinf=25)

c******************************************************************
c
c   Character Variables:
c
c     cc       - NODC country code
c     xchar    - dummy character array for reading in each 80
c                 character record
c     aout     - format specifier (used for FORTRAN I/O)
c     ichar    - cast character array
c     
c******************************************************************

      character*2 cc
      character*4 aout
      character*15 chars(2)
      character*80 xchar
      character*1500000 ichar

      data aout /'(iX)'/

c******************************************************************
c
c    Arrays:
c
c     isig     - number of significant figures in (1) latitude, (2) longitude,
c                 and (3) time
c     iprec    - precision of (1) latitude, (2) longitude, (3) time
c     itotfig  - number of digits in (1) latitude, (2) longitude, (3) time
c     ip2      - variable codes for variables in cast
c     ierror   - whole profile error codes for each variable
c     jsig2    - number of significant figures in each secondary header variable
c     jprec2   - precision of each secondary header variable
c     jtot2    - number of digits in each secondary header variable
c     sechead  - secondary header variables
c     jsigb    - number of significant figures in each biological variable
c     jprecb   - precision of each biological variable
c     jtotb    - number of digits in each biological variable
c     bio      - biological data
c     idsig    - number of significant figures in each depth measurement
c     idprec   - precision of each depth measurement
c     idtot    - number of digits in each depth measurement
c     depth    - depth of each measurement
c     msig     - number of significant figures in each measured variable at
c                 each level of measurement
c     mprec    - precision of each measured variable at each
c                 level of measurement
c     mtot     - number of digits in each measured variable at
c                 each level of measurement
c     temp     - variable data at each level
c     iderror  - error flags for each variable at each depth level
c     iorigflag- originators flags for each variable and depth
c     isec     - variable codes for secondary header data
c     ibio     - variable codes for biological data
c     parminf  - variable specific information
c     jprecp   - precision for variable specific information
c     jsigp    - number of significant figures for variable specific
c                information
c     jtotp    - number of digits in for variable specific information
c     itaxnum  - different taxonomic and biomass variable
c                 codes found in data
c     vtax     - value of taxonomic variables and biomass variables
c     jsigtax  - number of significant figures in taxon values and
c                 biomass variables
c     jprectax - precision of taxon values and biomass variables
c     jtottax  - number of digits in taxon values and biomass
c                 variables
c     itaxerr  - taxon variable error code
c     itaxorigerr - taxon originators variable error code
c     nbothtot - total number of taxa and biomass variables
c     ipi      - Primary investigator informationc
c                 1. primary investigator
c                 2. variable investigated
c
c*******************************************************************

      integer isig(3), iprec(3), ip2(0:maxlevel), ierror(maxlevel)
      integer itotfig(3),ipi(maxlevel,2)
      integer jsig2(maxlevel), jprec2(maxlevel), sechead(maxlevel)
      integer jsigb(maxlevel), jprecb(maxlevel), bio(maxlevel)
      integer idsig(maxlevel),idprec(maxlevel), depth(maxlevel)
      integer jtot2(maxlevel),jtotb(maxlevel),idtot(maxlevel)
      integer msig(maxlevel,nvarmax), mprec(maxlevel,nvarmax)
      integer mtot(maxlevel,nvarmax)
      dimension temp(maxlevel,nvarmax),iderror(maxlevel,0:nvarmax)
      integer isec(maxlevel),ibio(maxlevel)
      dimension parminf(maxpinf,0:nvarmax),jsigp(maxpinf,0:nvarmax)
      integer jprecp(maxpinf,0:nvarmax),jtotp(maxpinf,0:nvarmax)
      integer iorigflag(maxlevel,0:nvarmax)
      integer itaxnum(maxtcode,maxtax),vtax(0:maxtcode,maxtax)
      integer jsigtax(maxtcode,maxtax),jprectax(maxtcode,maxtax)
      integer jtottax(maxtcode,maxtax),itaxerr(maxtcode,maxtax)
      integer itaxorigerr(maxtcode,maxtax)


c*******************************************************************
c     
c   Common Arrays and Variables:
c
c*******************************************************************
  

      common /thedata/ depth,temp
      common /flags/ ierror,iderror
      common /oflags/ iorigflag
      common /significant/ msig
      common /precision/ mprec
      common /totfigs/ mtot
      common /second/ jsig2,jprec2,jtot2,isec,sechead
      common /parminfo/ jsigp,jprecp,jtotp,parminf
      common /biology/ jsigb,jprecb,jtotb,ibio,bio
      common /taxon/ jsigtax,jprectax,jtottax,itaxerr,
     *     vtax,itaxnum,nbothtot,itaxorigerr

c******************************************************************
c     
c     Read in the first line of a cast into dummy character
c     variable xchar
c     
c
c     WOD-2005   First byte of each "cast record" is char "B".
c
c     WOD-2001   First byte of each "cast record" is char "A".
c
c     WOD-1998   First byte of each "cast recond" is a number.
c
c******************************************************************

      read(nf,'(a80)',end=500) xchar

      if ( xchar(1:1) .ne. 'B' .and. xchar(1:1) .ne. 'A' ) then

         iVERSflag = 1 !- not WOD-200X format, must be WOD-1998

         return

      else

         iVERSflag = 0 !- WOD-200X format

      endif

      

c******************************************************************
c
c     The first seven characters of a cast contain the
c     number of characters which make up the entire cast.  Read
c     this number into nchar
c     
c******************************************************************


      read(xchar(2:2),'(i1)') inc
      write(aout(3:3),'(i1)') inc
      read(xchar(3:inc+2),aout) nchar

c******************************************************************
c
c     Place the first line of the cast into the cast holder
c     character array (ichar)
c
c******************************************************************



      ichar(1:80) = xchar



c******************************************************************

c

c     Calculate the number of full (all 80 characters contain information)

c     lines in this cast.  Subtract one since the first line was

c     already read in.

c

c******************************************************************



      nlines = nchar/80



c*****************************************************************

c

c     Read each line into the dummy variable

c

c*****************************************************************



      do 49 n0 = 2,nlines



       read(nf,'(a80)') xchar



c*****************************************************************

c

c     Place the line into the whole cast array

c

c*****************************************************************



       n = 80*(n0-1)+1

       ichar(n:n+79)=xchar



49    continue



c*****************************************************************

c

c     If there is a last line with partial information, read in

c     this last line and place it into the whole cast array

c

c*****************************************************************



      if ( nlines*80 .lt. nchar .and. nlines .gt. 0) then



       read(nf,'(a80)') xchar



       n = 80*nlines+1

       ichar(n:nchar) = xchar



      endif

       

c*****************************************************************

c

c   Extract header information from the cast array

c

c     jj       - WOD cast number  

c     cc       - NODC country code  

c     icruise  - NODC cruise number

c     iyear    - year of cast

c     month    - month of cast

c     iday     - day of cast 

c

c*****************************************************************



      istartc=inc+3

      read(ichar(istartc:istartc),'(i1)') inc

      write(aout(3:3),'(i1)') inc

      read(ichar(istartc+1:istartc+inc),aout) jj

      istartc=istartc+inc+1



      cc = ichar(istartc:istartc+1)

      istartc=istartc+2



      read(ichar(istartc:istartc),'(i1)') inc

      write(aout(3:3),'(i1)') inc

      read(ichar(istartc+1:istartc+inc),aout) icruise

      istartc=istartc+inc+1



      read(ichar(istartc:istartc+3),'(i4)') iyear

      istartc=istartc+4

      read(ichar(istartc:istartc+1),'(i2)') month

      istartc=istartc+2

      read(ichar(istartc:istartc+1),'(i2)') iday

      istartc=istartc+2



c*****************************************************************

c

c   SUBROUTINE "charout":  READS IN A WOD ASCII FLOATING-POINT

c                          VALUE SEQUENCE (i.e. # sig-figs,

c                          # total figs, precision, value itself).

c                          * THIS WILL BE CALLED TO EXTRACT MOST 

c   Examples:              FLOATING POINT VALUES IN THE WOD ASCII.

c

c     VALUE  Precision    WOD ASCII

c     -----  ---------    ---------

c     5.35       2        332535

c     5.         0        1105

c     15.357     3        55315357

c    (missing)            -

c

c   ---------------------------------------------------------------

c

c  Read in time of cast (time) using CHAROUT subroutine:

c

c     istartc  - position in character array to begin to read

c                 in data

c     isig     - number of digits in data value

c     iprec    - precision of data value

c     ichar    - character array from which to read data

c     time     - data value

c     bmiss    - missing value marker

c

c*****************************************************************



      call charout(istartc,isig(3),iprec(3),itotfig(3),ichar,time,bmiss)



c*****************************************************************

c

c     Read in latitude (rlat) and longitude (rlon) using CHAROUT:

c     

c        Negative latitude is south.

c        Negative longitude is west.

c     

c*****************************************************************



      call charout(istartc,isig(1),iprec(1),itotfig(3),ichar,rlat,bmiss)

      call charout(istartc,isig(2),iprec(2),itotfig(3),ichar,rlon,bmiss)



c*****************************************************************

c     

c     Read in the number of depth levels (levels) using CHAROUT:

c

c*****************************************************************



      read(ichar(istartc:istartc),'(i1)') inc

      write(aout(3:3),'(i1)') inc

      read(ichar(istartc+1:istartc+inc),aout) levels

      istartc=istartc+inc+1



c*****************************************************************

c

c     Read in whether data is on observed levels (isoor=0) or

c     standard levels (isoor=1)

c

c*****************************************************************



      read(ichar(istartc:istartc),'(i1)') isoor

      istartc=istartc+1



c*****************************************************************

c

c     Read in number of variables in cast

c

c*****************************************************************



      read(ichar(istartc:istartc+1),'(i2)') nvar

      istartc=istartc+2



c*****************************************************************

c

c     Read in the variable codes (ip2()), the whole profile

c       error flags (ierror(ip2())), and variable specific

c       information (iorigflag(,ip2()))

c

c*****************************************************************



      do 30 n = 1,nvar



       read(ichar(istartc:istartc),'(i1)') inc

       write(aout(3:3),'(i1)') inc

       read(ichar(istartc+1:istartc+inc),aout) ip2(n)

       istartc=istartc+inc+1



       read(ichar(istartc:istartc),'(i1)') ierror(ip2(n))

       istartc=istartc+1



       read(ichar(istartc:istartc),'(i1)') inc

       write(aout(3:3),'(i1)') inc

       read(ichar(istartc+1:istartc+inc),aout) npinf

       istartc=istartc+inc+1



       do 305 n2=1,npinf



        read(ichar(istartc:istartc),'(i1)') inc

        write(aout(3:3),'(i1)') inc

        read(ichar(istartc+1:istartc+inc),aout) nn

        istartc=istartc+inc+1



        call charout(istartc,jsigp(nn,ip2(n)),jprecp(nn,ip2(n)),
     *  jtotp(nn,ip2(n)),ichar, parminf(nn,ip2(n)),bmiss) 



305    continue



30    continue



c****************************************************************

c

c     Read in number of bytes in character data

c

c****************************************************************



      read(ichar(istartc:istartc),'(i1)') inc

      istartc=istartc+1

      if ( inc .gt. 0 ) then

       write(aout(3:3),'(i1)') inc

       read(ichar(istartc+1:istartc+inc),aout) inchad

       istartc=istartc+inc



c****************************************************************

c

c    Read in number of character and primary investigator arrays

c

c****************************************************************



      npi=0

      chars(1)(1:4)='NONE'

      chars(2)(1:4)='NONE'

      read(ichar(istartc:istartc),'(i1)') ica

      istartc=istartc+1



c****************************************************************

c

c    Read in character and primary investigator data

c      1 - originators cruise code

c      2 - originators station code

c      3 - primary investigators information

c

c****************************************************************



      do 45 nn=1,ica



       read(ichar(istartc:istartc),'(i1)') icn

       istartc=istartc+1



       if ( icn .lt. 3 ) then

        read(ichar(istartc:istartc+1),'(i2)') ns

        istartc=istartc+2

        chars(icn)= '               '

        chars(icn)= ichar(istartc:istartc+ns-1)

        istartc= istartc+ns

       else

        read(ichar(istartc:istartc+1),'(i2)') npi

        istartc=istartc+2

        do 505 n=1,npi

         read(ichar(istartc:istartc),'(i1)') inc

         write(aout(3:3),'(i1)') inc

         read(ichar(istartc+1:istartc+inc),aout) ipi(n,2)

         istartc=istartc+inc+1



         read(ichar(istartc:istartc),'(i1)') inc

         write(aout(3:3),'(i1)') inc

         read(ichar(istartc+1:istartc+inc),aout) ipi(n,1)

         istartc=istartc+inc+1

505     continue

       endif



45    continue



      endif



c****************************************************************

c

c     Read in number of bytes in secondary header variables

c

c****************************************************************



      read(ichar(istartc:istartc),'(i1)') inc

      istartc=istartc+1

      if ( inc .gt. 0 ) then

       write(aout(3:3),'(i1)') inc

       read(ichar(istartc+1:istartc+inc),aout) insec

       istartc=istartc+inc



c****************************************************************

c

c     Read in number of secondary header variables (nsecond)

c

c****************************************************************



       read(ichar(istartc:istartc),'(i1)') inc

       write(aout(3:3),'(i1)') inc

       read(ichar(istartc+1:istartc+inc),aout) nsecond

       istartc=istartc+inc+1



c****************************************************************

c

c     Read in secondary header variables (sechead())

c

c****************************************************************



       do 35 n = 1,nsecond



        read(ichar(istartc:istartc),'(i1)') inc

        write(aout(3:3),'(i1)') inc

        read(ichar(istartc+1:istartc+inc),aout) nn

        istartc=istartc+inc+1



        call charout(istartc,jsig2(nn),jprec2(nn),jtot2(nn),ichar,
     *  sechead(nn),bmiss) 



        isec(n) = nn



35     continue



       endif



c****************************************************************

c

c     Read in number of bytes in biology variables 

c

c****************************************************************



      read(ichar(istartc:istartc),'(i1)') inc

      istartc=istartc+1



      if ( inc .gt. 0 ) then

       write(aout(3:3),'(i1)') inc

       read(ichar(istartc+1:istartc+inc),aout) inbio

       istartc=istartc+inc



c****************************************************************

c

c     Read in number of biological variables (nbio)

c

c****************************************************************



      read(ichar(istartc:istartc),'(i1)') inc

      write(aout(3:3),'(i1)') inc

      read(ichar(istartc+1:istartc+inc),aout) nbio

      istartc=istartc+inc+1



c****************************************************************

c

c     Read in biological variables (bio())

c

c****************************************************************



      do 40 n = 1,nbio



       read(ichar(istartc:istartc),'(i1)') inc

       write(aout(3:3),'(i1)') inc

       read(ichar(istartc+1:istartc+inc),aout) nn

       istartc=istartc+inc+1



       call charout(istartc,jsigb(nn),jprecb(nn),jtotb(nn),ichar,
     * bio(nn),bmiss)



       ibio(n) = nn



40    continue



c****************************************************************

c

c     Read in biomass and taxonomic variables

c

c****************************************************************



      read(ichar(istartc:istartc),'(i1)') inc

      write(aout(3:3),'(i1)') inc

      read(ichar(istartc+1:istartc+inc),aout) nbothtot

      istartc=istartc+inc+1



      do 41 n = 1,nbothtot



       itaxtot=0

       read(ichar(istartc:istartc),'(i1)') inc
       write(aout(3:3),'(i1)') inc
       read(ichar(istartc+1:istartc+inc),aout) nn

       istartc=istartc+inc+1



       vtax(0,n)=nn



       do 42 n2 =1,nn



        itaxtot=itaxtot+1



        read(ichar(istartc:istartc),'(i1)') inc

        write(aout(3:3),'(i1)') inc

        read(ichar(istartc+1:istartc+inc),aout) itaxnum(itaxtot,n)

        istartc=istartc+inc+1

        call charout(istartc,jsigtax(itaxtot,n),jprectax(itaxtot,n),
     *   jtottax(itaxtot,n),ichar,vtax(itaxtot,n),bmiss)



        read(ichar(istartc:istartc),'(i1)') itaxerr(itaxtot,n)

        istartc=istartc+1

        read(ichar(istartc:istartc),'(i1)') itaxorigerr(itaxtot,n)

        istartc=istartc+1



42     continue



41    continue

      endif



c****************************************************************

c

c     Read in measured and calculated depth dependent variables

c       along with their individual reading flags

c

c****************************************************************



      do 50 n = 1,levels



       if ( isoor.eq.0 ) then



        call charout(istartc,idsig(n),idprec(n),idtot(n),ichar,
     * depth(n),bmiss)
        read(ichar(istartc:istartc),'(i1)') iderror(n,0)
        istartc=istartc+1
        read(ichar(istartc:istartc),'(i1)') iorigflag(n,0)
        istartc=istartc+1

       endif

       do 55 i = 1,nvar

        call charout(istartc,msig(n,ip2(i)),mprec(n,ip2(i)),
     * mtot(n,ip2(i)),ichar,temp(n,ip2(i)),bmiss)


       if ( temp(n,ip2(i)) .gt. bmiss ) then

       read(ichar(istartc:istartc),'(i1)') iderror(n,ip2(i))
       istartc=istartc+1
       read(ichar(istartc:istartc),'(i1)') iorigflag(n,ip2(i))
       istartc=istartc+1

       else

        iderror(n,ip2(i))=0
        iorigflag(n,ip2(1))=0
        msig(n,ip2(i))=0
        mprec(n,ip2(i))=0
        mtot(n,ip2(i))=0
       endif

55     continue
50     continue
       return
500    ieof = 1
       return
       end
*  #] wodread200x:
*  #[ wodread1998:
      SUBROUTINE WODREAD1998(nf,jj,cc,icruise,iyear,month,iday,
     *     time,rlat,rlon,levels,isoor,nvar,ip2,nsecond,nbio,
     *     isig,iprec,bmiss,ieof,chars,ipi,npi)
    

c     This subroutine reads in the WOD ASCII format and loads it
c     into arrays which are common/shared with the calling program.

c*****************************************************************
c
c   Passed Variables:
c
c     nf       - file identification number for input file
c     jj       - WOD cast number
c     cc       - NODC country code
c     icruise  - NODC cruise number
c     iyear    - year of cast
c     month    - month of cast
c     iday     - day of cast
c     time     - time of cast
c     rlat     - latitude of cast
c     rlon     - longitude of cast
c     levels   - number of depth levels of data
c     isoor    - observed (0) or standard (1) levels
c     nvar     - number of variables recorded in cast
c     ip2      - variable codes of variables in cast
c     nsecond  - number of secondary header variables
c     nbio     - number of biological variables
c     isig     - number of significant figures in (1) latitude, (2) longitude,
c                 and (3) time
c     iprec    - precision of (1) latitude, (2) longitude, (3) time
c     itotfig  - number of digits in (1) latitude, (2) longitude, (3) time
c     bmiss    - missing value marker
c     ieof     - set to one if end of file has been encountered
c     chars    - character data: 1=originators cruise code,
c                                2=originators station code
c     npi      - number of PI codes
c     ipi      - Primary Investigator information
c                  1. primary investigator
c                  2. variable investigated
c
c   Common/Shared Variables and Arrays (see COMMON area of program):
c
c     depth(x)   - depth in meters (x = depth level)
c     temp(x,y)  - variable data (x = depth level, y = variable ID = ip2(i))
c                ... see also nvar, ip2, istdlev, levels above ...
c     sechead(i) - secondary header data (i = secondary header ID = isec(j))
c     isec(j)    - secondary header ID (j = #sequence (1st, 2nd, 3rd))
c                ... see also nsecond above ...
c     bio(i)     - biology header data (i = biol-header ID = ibio(j))
c     ibio(j)    - biology header ID (j = #sequence (1st, 2nd, 3rd))
c                ... see also nbio above ...
c     nbothtot   - number of taxa set / biomass variables
c     vtax(i,j)  - taxonomic/biomass array, where j = (1..nbothtot)
c                   For each entry (j=1..nbothtot), there are vtax(0,j)
c                   sub-entries.  [Note:  The number of sub-entries is
c                   variable for each main entry.]  vtax also holds the
c                   value of the sub-entries.
c    itaxnum(i,j)- taxonomic code or sub-code
c
c***************************************************************




c******************************************************************
c
c   Parameters (constants):
c
c     maxlevel - maximum number of depth levels, also maximum
c                 number of all types of variables
c     nvarmax  - maximum number of measured and calculated
c                 depth dependent variables
c     maxtcode - maximum number of different taxa variable codes
c     maxtax   - maximum number of taxa sets
c
c******************************************************************

      parameter (maxlevel=30000, nvarmax=100)
      parameter (maxtcode=25, maxtax=2000)

c******************************************************************
c
c   Character Variables:
c
c     cc       - NODC country code
c     xchar    - dummy character array for reading in each 80
c                 character record
c     aout     - format specifier (used for FORTRAN I/O)
c     ichar    - cast character array
c     
c******************************************************************


      character*2  cc
      character*4  aout
      character*15 chars(2)
      character*80 xchar
      character*300000 ichar
      data aout /'(iX)'/

c******************************************************************
c
c    Arrays:
c
c     isig     - number of significant figures in (1) latitude, (2) longitude,
c                 and (3) time
c     iprec    - precision of (1) latitude, (2) longitude, (3) time
c     itotfig  - number of digits in (1) latitude, (2) longitude, (3) time
c     ip2      - variable codes for variables in cast
c     ierror   - whole profile error codes for each variable
c     jsig2    - number of significant figures in each secondary header variable
c     jprec2   - precision of each secondary header variable
c     jtot2    - number of digits in each secondary header variable
c     sechead  - secondary header variables
c     jsigb    - number of significant figures in each biological variable
c     jprecb   - precision of each biological variable
c     jtotb    - number of digits in each biological variable
c     bio      - biological data
c     idsig    - number of significant figures in each depth measurement
c     idprec   - precision of each depth measurement
c     idtot    - number of digits in each depth measurement
c     depth    - depth of each measurement
c     msig     - number of significant figures in each measured variable at
c                 each level of measurement
c     mprec    - precision of each measured variable at each
c                 level of measurement
c     mtot     - number of digits in each measured variable at
c                 each level of measurement
c     temp     - variable data at each level
c     iderror  - error flags for each variable at each depth level
c     isec     - variable codes for secondary header data
c     ibio     - variable codes for biological data
c     itaxnum  - different taxonomic and biomass variable
c                 codes found in data
c     vtax     - value of taxonomic variables and biomass variables
c     jsigtax  - number of significant figures in taxon values and
c                 biomass variables
c     jprectax - precision of taxon values and biomass variables
c     jtottax  - number of digits in taxon values and biomass
c                 variables
c     itaxerr  - taxon variable error code
c     nbothtot - total number of taxa and biomass variables
c     ipi      - Primary investigator informationc
c                 1. primary investigator
c                 2. variable investigated
c
c*******************************************************************


      dimension isig(3), iprec(3), ip2(0:maxlevel), ierror(maxlevel)
      dimension itotfig(3),ipi(maxlevel,2)
      dimension jsig2(maxlevel), jprec2(maxlevel), sechead(maxlevel)
      dimension jsigb(maxlevel), jprecb(maxlevel), bio(maxlevel)
      dimension idsig(maxlevel),idprec(maxlevel), depth(maxlevel)
      dimension jtot2(maxlevel),jtotb(maxlevel),idtot(maxlevel)
      dimension msig(maxlevel,nvarmax), mprec(maxlevel,nvarmax)
      dimension mtot(maxlevel,nvarmax)
      dimension temp(maxlevel,nvarmax),iderror(maxlevel,0:nvarmax)
      dimension isec(maxlevel),ibio(maxlevel)
      dimension itaxnum(maxtcode,maxtax),vtax(0:maxtcode,maxtax)
      dimension jsigtax(maxtcode,maxtax),jprectax(maxtcode,maxtax)
      dimension jtottax(maxtcode,maxtax),itaxerr(maxtcode,maxtax)
      dimension itaxorigerr(maxtcode,maxtax)


c*******************************************************************
c     
c   Common Arrays and Variables:
c
c*******************************************************************

      
      common /thedata/ depth,temp
      common /flags/ ierror,iderror
      common /significant/ msig
      common /precision/ mprec
      common /totfigs/ mtot
      common /second/ jsig2,jprec2,jtot2,isec,sechead
      common /biology/ jsigb,jprecb,jtotb,ibio,bio
      common /taxon/ jsigtax,jprectax,jtottax,itaxerr,
     *  vtax,itaxnum,nbothtot,itaxorigerr

c******************************************************************
c     
c     Read in the first line of a cast into dummy character
c     variable xchar
c     
c******************************************************************

      read(nf,'(a80)',end=500) xchar

c******************************************************************
c
c     The first seven characters of a cast contain the
c     number of characters which make up the entire cast.  Read
c     this number into nchar
c     
c******************************************************************


      read(xchar(1:1),'(i1)') inc
      write(aout(3:3),'(i1)') inc
      read(xchar(2:inc+1),aout) nchar

c******************************************************************
c
c     Place the first line of the cast into the cast holder
c     character array (ichar)
c
c******************************************************************

      ichar(1:80) = xchar

c******************************************************************
c
c     Calculate the number of full (all 80 characters contain information)
c     lines in this cast.  Subtract one since the first line was
c     already read in.
c
c******************************************************************

      nlines = nchar/80

c*****************************************************************
c
c     Read each line into the dummy variable
c
c*****************************************************************

      do 49 n0 = 2,nlines
       read(nf,'(a80)') xchar

c*****************************************************************
c
c     Place the line into the whole cast array
c
c*****************************************************************

       n = 80*(n0-1)+1
       ichar(n:n+79)=xchar
49    continue

c*****************************************************************
c
c     If there is a last line with partial information, read in
c     this last line and place it into the whole cast array
c
c*****************************************************************

      if ( nlines*80 .lt. nchar .and. nlines .gt. 0) then
       read(nf,'(a80)') xchar
       n = 80*nlines+1
       ichar(n:nchar) = xchar
      endif

c*****************************************************************
c
c   Extract header information from the cast array
c
c     jj       - WOD cast number  
c     cc       - NODC country code  
c     icruise  - NODC cruise number
c     iyear    - year of cast
c     month    - month of cast
c     iday     - day of cast
c
c*****************************************************************

      istartc=inc+2
      read(ichar(istartc:istartc),'(i1)') inc
      write(aout(3:3),'(i1)') inc
      read(ichar(istartc+1:istartc+inc),aout) jj
      istartc=istartc+inc+1
      cc = ichar(istartc:istartc+1)
      istartc=istartc+2

      read(ichar(istartc:istartc),'(i1)') inc
      write(aout(3:3),'(i1)') inc
      read(ichar(istartc+1:istartc+inc),aout) icruise
      istartc=istartc+inc+1

      read(ichar(istartc:istartc+3),'(i4)') iyear
      istartc=istartc+4
      read(ichar(istartc:istartc+1),'(i2)') month
      istartc=istartc+2
      read(ichar(istartc:istartc+1),'(i2)') iday
      istartc=istartc+2


c*****************************************************************
c
c   SUBROUTINE "charout":  READS IN AN WOD ASCII FLOATING-POINT
c                          VALUE SEQUENCE (i.e. # sig-figs,
c                          # total figs, precision, value itself).
c                          * THIS WILL BE CALLED TO EXTRACT MOST 
c   Examples:              FLOATING POINT VALUES IN THE WOD ASCII.
c
c     VALUE  Precision    WOD ASCII
c     -----  ---------    ---------
c     5.35       2        332535
c     5.         0        1105
c     15.357     3        55315357
c    (missing)            -
c
c   ---------------------------------------------------------------
c
c  Read in time of cast (time) using CHAROUT subroutine:
c
c     istartc  - position in character array to begin to read
c                 in data
c     isig     - number of digits in data value
c     iprec    - precision of data value
c     ichar    - character array from which to read data
c     time     - data value
c     bmiss    - missing value marker
c
c*****************************************************************

      call charout(istartc,isig(3),iprec(3),itotfig(3),ichar,time,bmiss)

c*****************************************************************
c
c     Read in latitude (rlat) and longitude (rlon) using CHAROUT:
c     
c        Negative latitude is south.
c        Negative longitude is west.
c     
c*****************************************************************


      call charout(istartc,isig(1),iprec(1),itotfig(3),ichar,rlat,bmiss)
      call charout(istartc,isig(2),iprec(2),itotfig(3),ichar,rlon,bmiss)

c*****************************************************************
c     
c     Read in the number of depth levels (levels) using CHAROUT:
c
c*****************************************************************

      read(ichar(istartc:istartc),'(i1)') inc
      write(aout(3:3),'(i1)') inc
      read(ichar(istartc+1:istartc+inc),aout) levels
      istartc=istartc+inc+1

c*****************************************************************
c
c     Read in whether data is on observed levels (isoor=0) or
c     standard levels (isoor=1)
c
c*****************************************************************

      read(ichar(istartc:istartc),'(i1)') isoor
      istartc=istartc+1

c*****************************************************************
c
c     Read in number of variables in cast
c
c*****************************************************************


      read(ichar(istartc:istartc+1),'(i2)') nvar
      istartc=istartc+2

c*****************************************************************
c
c     Read in the variable codes (ip2()) and the whole cast
c       error flags (ierror(ip2()))
c
c*****************************************************************

      do 30 n = 1,nvar
       read(ichar(istartc:istartc),'(i1)') inc
       write(aout(3:3),'(i1)') inc
       read(ichar(istartc+1:istartc+inc),aout) ip2(n)
       istartc=istartc+inc+1
       read(ichar(istartc:istartc),'(i1)') ierror(ip2(n))
       istartc=istartc+1
30    continue

c****************************************************************
c
c     Read in number of bytes in character data
c
c****************************************************************

      read(ichar(istartc:istartc),'(i1)') inc
      istartc=istartc+1
      if ( inc .gt. 0 ) then
       write(aout(3:3),'(i1)') inc
       read(ichar(istartc+1:istartc+inc),aout) inchad
       istartc=istartc+inc

c****************************************************************
c
c    Read in number of character and primary investigator arrays
c
c****************************************************************

      npi=0
      chars(1)(1:4)='NONE'
      chars(2)(1:4)='NONE'
      read(ichar(istartc:istartc),'(i1)') ica
      istartc=istartc+1

c****************************************************************
c
c    Read in character and primary investigator data
c      1 - originators cruise code
c      2 - originators station code
c      3 - primary investigators information
c
c****************************************************************

      do 45 nn=1,ica
       read(ichar(istartc:istartc),'(i1)') icn
       istartc=istartc+1
       if ( icn .lt. 3 ) then
        read(ichar(istartc:istartc+1),'(i2)') ns
        istartc=istartc+2
        chars(icn)= '               '
        chars(icn)= ichar(istartc:istartc+ns-1)
        istartc= istartc+ns
       else
        read(ichar(istartc:istartc+1),'(i2)') npi
        istartc=istartc+2
        do 505 n=1,npi
         read(ichar(istartc:istartc),'(i1)') inc
         write(aout(3:3),'(i1)') inc
         read(ichar(istartc+1:istartc+inc),aout) ipi(n,2)
         istartc=istartc+inc+1
         read(ichar(istartc:istartc),'(i1)') inc
         write(aout(3:3),'(i1)') inc
         read(ichar(istartc+1:istartc+inc),aout) ipi(n,1)
         istartc=istartc+inc+1
505     continue
       endif
45    continue
      endif

c****************************************************************
c
c     Read in number of bytes in secondary header variables
c
c****************************************************************

      read(ichar(istartc:istartc),'(i1)') inc
      istartc=istartc+1

      if ( inc .gt. 0 ) then
       write(aout(3:3),'(i1)') inc
       read(ichar(istartc+1:istartc+inc),aout) insec
       istartc=istartc+inc

c****************************************************************
c
c     Read in number of secondary header variables (nsecond)
c
c****************************************************************


       read(ichar(istartc:istartc),'(i1)') inc
       write(aout(3:3),'(i1)') inc
       read(ichar(istartc+1:istartc+inc),aout) nsecond
       istartc=istartc+inc+1

c****************************************************************
c
c     Read in secondary header variables (sechead())
c
c****************************************************************

       do 35 n = 1,nsecond
        read(ichar(istartc:istartc),'(i1)') inc
        write(aout(3:3),'(i1)') inc
        read(ichar(istartc+1:istartc+inc),aout) nn
        istartc=istartc+inc+1
        call charout(istartc,jsig2(nn),jprec2(nn),jtot2(nn),ichar,
     *  sechead(nn),bmiss) 
        isec(n) = nn
35     continue
       endif

c****************************************************************
c
c     Read in number of bytes in biology variables 
c
c****************************************************************

      read(ichar(istartc:istartc),'(i1)') inc
      istartc=istartc+1

      if ( inc .gt. 0 ) then
       write(aout(3:3),'(i1)') inc
       read(ichar(istartc+1:istartc+inc),aout) inbio
       istartc=istartc+inc

c****************************************************************
c
c     Read in number of biological variables (nbio)
c
c****************************************************************

      read(ichar(istartc:istartc),'(i1)') inc
      write(aout(3:3),'(i1)') inc
      read(ichar(istartc+1:istartc+inc),aout) nbio
      istartc=istartc+inc+1

c****************************************************************
c
c     Read in biological variables (bio())
c
c****************************************************************

      do 40 n = 1,nbio
       read(ichar(istartc:istartc),'(i1)') inc
       write(aout(3:3),'(i1)') inc
       read(ichar(istartc+1:istartc+inc),aout) nn
       istartc=istartc+inc+1
       call charout(istartc,jsigb(nn),jprecb(nn),jtotb(nn),ichar,
     * bio(nn),bmiss)
       ibio(n) = nn
40    continue

c****************************************************************
c
c     Read in biomass and taxonomic variables
c
c****************************************************************

      read(ichar(istartc:istartc),'(i1)') inc
      write(aout(3:3),'(i1)') inc
      read(ichar(istartc+1:istartc+inc),aout) nbothtot
      istartc=istartc+inc+1

      do 41 n = 1,nbothtot
       itaxtot=0
       read(ichar(istartc:istartc),'(i1)') inc
       write(aout(3:3),'(i1)') inc
       read(ichar(istartc+1:istartc+inc),aout) nn
       istartc=istartc+inc+1
       vtax(0,n)=nn

       do 42 n2 =1,nn
        itaxtot=itaxtot+1
        read(ichar(istartc:istartc),'(i1)') inc
        write(aout(3:3),'(i1)') inc
        read(ichar(istartc+1:istartc+inc),aout) itaxnum(itaxtot,n)
        istartc=istartc+inc+1
        call charout(istartc,jsigtax(itaxtot,n),jprectax(itaxtot,n),
     *  jtottax(itaxtot,n),ichar,vtax(itaxtot,n),bmiss)
        read(ichar(istartc:istartc),'(i1)') itaxerr(itaxtot,n)
        istartc=istartc+1

42     continue
41    continue
      endif

c****************************************************************
c
c     Read in measured and calculated depth dependent variables
c       along with their individual reading flags
c
c****************************************************************
 
      do 50 n = 1,levels
        if ( isoor.eq.0 ) then
         call charout(istartc,idsig(n),idprec(n),idtot(n),ichar,
     * depth(n),bmiss)
         read(ichar(istartc:istartc),'(i1)') iderror(n,0)
        istartc=istartc+1
       endif
       do 55 i = 1,nvar
        call charout(istartc,msig(n,ip2(i)),mprec(n,ip2(i)),
     * mtot(n,ip2(i)),ichar,temp(n,ip2(i)),bmiss)
       if ( temp(n,ip2(i)) .gt. bmiss ) then
        read(ichar(istartc:istartc),'(i1)') iderror(n,ip2(i))
        istartc=istartc+1
       else
        iderror(n,ip2(i))=0
       endif
55     continue
50     continue
       return
500    ieof = 1
       return
       end
*  #] wodread1998:
*  #[ charout:
      SUBROUTINE CHAROUT(istartc,jsig,jprec,jtot,ichar,value,bmiss)
c     This subroutine reads a single real value from the
c     WOD ASCII format.  This value consists of four
c     components:  # significant figures, # total figures,
c     precision, and the value. 
c   Examples:
c     VALUE  Precision    WOD ASCII
c     -----  ---------    ---------
c     5.35       2        332535
c     5.         0        1105
c     15.357     3        55315357
c    (missing)            -           
c******************************************************
c     
c   Passed Variables:
c
c     istartc    - starting point to read in data
c     jsig       - number of significant figures in data value
c     jprec      - precision of data value
c     jtot       - number of figures in data value
c     ichar      - character array from which to read data
c     value      - data value
c     bmiss      - missing value marker
c
c*****************************************************

c*****************************************************
c
c   Character Array:
c
c     cwriter    - format statement (FORTRAN I/O)
c
c****************************************************

      character*6 cwriter
      character*(*) ichar
      data cwriter /'(fX.X)'/

c****************************************************
c     
c     Check if this is a missing value (number of 
c       figures = '-')
c
c****************************************************

      if ( ichar(istartc:istartc) .eq. '-' ) then
       istartc = istartc+1
       value = bmiss
       return
      endif

c****************************************************
c
c     Read in number of significant figure, total
c       figures and precision of value
c
c****************************************************

      read(ichar(istartc:istartc),'(i1)') jsig
      read(ichar(istartc+1:istartc+1),'(i1)') jtot
      read(ichar(istartc+2:istartc+2),'(i1)') jprec
      istartc=istartc+3

c****************************************************
c
c     Write these values into a FORTRAN format statement
c
c       e.g. "553" --> '(f5.3)'
c            "332" --> '(f3.2)'
c
c****************************************************

      write(cwriter(3:3),'(i1)') jtot
      write(cwriter(5:5),'(i1)') jprec

c****************************************************
c
c     Read in the data value using thhe FORTRAN 
c       format statement created above (cwriter).
c
c****************************************************

      read(ichar(istartc:istartc+jtot-1),cwriter) value

c****************************************************
c
c     Update the character array position (pointer)
c       and send it back to the calling program.
c
c****************************************************
      istartc=istartc+jtot
      return
      end
*  #] charout:
