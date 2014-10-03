        program kap2indices
*
*       convert the Kaplan NINO2 files to a format similar to what the
*       rest of the worlls uses
*
*       in: months since 1960, index in files nino12kap.txt, nino3kap.txt
*       out: YR MO NINO12 ANOM NINO3 ANOM NINO4 ANOM NINO3.4 ANOM
*            -----        ----       ----
*
        implicit none
        integer i,j,year,month
        real nino(2,2:5),rmonth1,datum1,rmonth2,datum2
        character string*80
*
*       open Kaplan data files
        open(1,file='nino12kap.txt',status='old')
        open(2,file='nino3kap.txt',status='old')
*
*       skip headers
        read(1,'(a)') string
        read(1,'(a)') string
        read(2,'(a)') string
        read(2,'(a)') string
        print '(2a)',' year mo  nino12    anom   nino3    anom'
     +        ,              '   nino4    anom nino3.4    anom'
*
*       init
        do i=2,5
            nino(1,i) = 999.9
            nino(2,i) = 999.9
        enddo
*
*       process data
   10   continue
        read(1,*,end=100,err=900) rmonth1,datum1
        read(2,*,end=100,err=900) rmonth2,datum2
        if ( rmonth1.ne.rmonth2 ) then
            print *,'error: files not synchronized ',rmonth1,rmonth2
            stop
        endif
        year = int(rmonth1/12 + 1960)
        month = 1 + mod(nint(rmonth1-0.5)+12000,12)
        nino(2,2) = datum1
        nino(2,3) = datum2
        print '(i5,i3,8f8.2)',year,month,nino
        goto 10
  100   continue
        stop
*       
*       error
  900   print *,'error reading data'
        end
